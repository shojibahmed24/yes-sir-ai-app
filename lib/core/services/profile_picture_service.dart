// Batch 2, item 6: Settings profile picture.
// Pick (gallery/camera) -> copy into app documents -> save the path
// in the SAME profile JSON every screen reads (profile_service /
// LocalStore demo_profile_json, keys avatar_local_path/avatar_url —
// never a second copy) -> best-effort Supabase Storage upload when
// signed in and configured. Upload failure, DEMO mode, picker cancel
// and permission denial are all non-crashes: the local picture is
// kept and the caller is told honestly that no upload happened.
// Crop: image_picker has no crop step, so there is none — the avatar
// widget clips the image to a circle, which is the square crop the
// eye sees. A real cropper (image_cropper + native config) is a
// separate, explicitly-scoped addition, not silently faked here.
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'profile_service.dart';
import 'profile_source.dart';
import 'supabase_client.dart';

/// Outcome of a picture pick. [cancelled] = user backed out (no
/// change, no message). [denied] = permission refused. [unavailable]
/// = picker/camera/storage failed. [picked] carries the saved paths;
/// [uploaded] is true ONLY when the Storage upload really succeeded.
enum PictureOutcome { picked, cancelled, denied, unavailable }

class PictureResult {
  final PictureOutcome outcome;
  final String? localPath;
  final String? remoteUrl;
  final bool uploaded;
  const PictureResult({
    required this.outcome,
    this.localPath,
    this.remoteUrl,
    this.uploaded = false,
  });
  const PictureResult.cancelled() : this(outcome: PictureOutcome.cancelled);
  const PictureResult.denied() : this(outcome: PictureOutcome.denied);
  const PictureResult.unavailable()
      : this(outcome: PictureOutcome.unavailable);
}

class ProfilePictureService {
  static const _fileName = 'profile_picture.jpg';
  static const _bucket = 'avatars';

  final ImagePicker _picker = ImagePicker();

  /// Pick, store locally, and upload when possible. Never throws:
  /// every failure maps to a PictureResult the UI can report.
  Future<PictureResult> pickAndSave(ImageSource source) async {
    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } on PlatformException catch (e) {
      // image_picker reports refusals with these codes; anything
      // else (no camera, missing activity) is 'unavailable'.
      if (e.code.contains('denied') || e.code.contains('permission')) {
        return const PictureResult.denied();
      }
      return const PictureResult.unavailable();
    } catch (_) {
      return const PictureResult.unavailable();
    }
    if (picked == null) return const PictureResult.cancelled();

    String localPath;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final saved = await File(picked.path).copy('${dir.path}/$_fileName');
      localPath = saved.path;
    } catch (_) {
      return const PictureResult.unavailable();
    }

    // Best-effort upload: signed-in Supabase user only. Any failure
    // (no bucket, no policy, offline) keeps the local picture and
    // reports uploaded=false — the UI must say so, never claim an
    // upload. The old remote URL is cleared for a local-only picture
    // so Profile never shows the previous person's photo.
    String? remoteUrl;
    var uploaded = false;
    final client = supabaseOrNull;
    final userId = authService.currentUserId;
    if (client != null && userId != null) {
      try {
        final bytes = await File(localPath).readAsBytes();
        await client.storage.from(_bucket).uploadBinary(
              '$userId/avatar.jpg',
              bytes,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );
        remoteUrl =
            client.storage.from(_bucket).getPublicUrl('$userId/avatar.jpg');
        uploaded = true;
      } catch (_) {
        uploaded = false;
      }
    }
    await profileService.updateProfileFields(
      avatarLocalPath: localPath,
      avatarUrl: remoteUrl,
      clearAvatarUrl: !uploaded,
    );
    return PictureResult(
      outcome: PictureOutcome.picked,
      localPath: localPath,
      remoteUrl: remoteUrl,
      uploaded: uploaded,
    );
  }

  /// Remove-photo: delete the local copy and drop both picture keys
  /// from the single profile source. Never throws.
  Future<void> removePicture() async {
    try {
      final profile = await profileService.loadProfile();
      final path = ProfileFields.localPicture(profile);
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {}
    await profileService.updateProfileFields(clearAvatar: true);
  }
}

final profilePictureService = ProfilePictureService();
