// Account deletion (Play User Data policy): the app calls the
// account-delete Edge function with the live session; the function
// verifies the user and deletes the auth row (profile/progress cascade
// from FKs). Never deletes anything when not signed in.
import 'supabase_client.dart';

enum DeleteAccountResult { done, notSignedIn, failed }

Future<DeleteAccountResult> deleteMyAccount() async {
  final client = supabaseOrNull;
  if (client == null) return DeleteAccountResult.notSignedIn;
  if (client.auth.currentSession == null) {
    return DeleteAccountResult.notSignedIn;
  }
  try {
    final res = await client.functions.invoke(
      'account-delete',
      body: {'confirm': true},
    );
    return res.status == 200
        ? DeleteAccountResult.done
        : DeleteAccountResult.failed;
  } catch (_) {
    return DeleteAccountResult.failed;
  }
}
