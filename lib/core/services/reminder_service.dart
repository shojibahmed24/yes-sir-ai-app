// Local study reminders (2026-11-22).
//
// Real OS notifications, scheduled ON the phone — no server push and
// no cost. Seven events, all driven by the Settings switches:
//   daily study, streak rescue, daily goal, weekly model test,
//   saved-question revision, weekly report, new-content.
// New-content has no server trigger, so it rides the weekly check:
// the app compares the stored content version when it opens and, if
// it changed, posts one "নতুন প্রশ্ন যোগ হয়েছে" notification.
//
// All schedules are INEXACT on purpose (no exact-alarm permission,
// no battery complaints): a reminder may land a few minutes late,
// never not at all. Quiet hours are respected by the chosen times.
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _channelId = 'ys_study_reminders';

  /// Called once from main; never throws (a phone with notifications
  /// disabled must not block the app).
  static Future<void> init() async {
    if (_ready) return;
    try {
      tz.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Unknown zone: keep the default; schedules still work.
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    try {
      await _plugin.initialize(const InitializationSettings(android: android));
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          'Study reminders',
          description: 'Daily study, streak and test reminders',
        ),
      );
      await androidPlugin?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      debugPrint('ReminderService init: $e');
    }
  }

  static NotificationDetails _details() => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Study reminders',
      channelDescription: 'Daily study, streak and test reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );

  static Future<void> _daily(
    int id,
    int hour,
    int minute,
    String title,
    String body,
  ) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _next(hour, minute),
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> _weekly(
    int id,
    int weekday,
    int hour,
    int minute,
    String title,
    String body,
  ) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _next(hour, minute, weekday: weekday),
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Next occurrence of [hour]:[minute] (optionally on [weekday],
  /// DateTime.monday..sunday) in the device zone.
  static tz.TZDateTime _next(int hour, int minute, {int? weekday}) {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (weekday != null) {
      while (d.weekday != weekday) {
        d = d.add(const Duration(days: 1));
      }
    }
    if (!d.isAfter(now)) {
      d = weekday == null
          ? d.add(const Duration(days: 1))
          : d.add(const Duration(days: 7));
    }
    return d;
  }

  /// Reads the three Settings switches and re-creates every schedule.
  /// Called on app start and right after Settings saves.
  static Future<void> reschedule() async {
    await init();
    if (!_ready) return;
    final prefs = await SharedPreferences.getInstance();
    final daily = prefs.getBool('ys_notif_daily') ?? true;
    final tests = prefs.getBool('ys_notif_tests') ?? true;
    final streak = prefs.getBool('ys_notif_streak') ?? true;
    // User-chosen daily time (minutes since midnight); default 19:00.
    final minutes = prefs.getInt('ys_notif_time') ?? 19 * 60;
    final hour = (minutes ~/ 60).clamp(0, 23);
    final minute = (minutes % 60).clamp(0, 59);
    try {
      await _plugin.cancelAll();
      if (daily) {
        await _daily(
          1,
          hour,
          minute,
          'আজকের পড়া শুরু করো',
          '১৫ মিনিট পড়লেও আজকের লক্ষ্য এগিয়ে যাবে।',
        );
        await _daily(
          3,
          8,
          0,
          'আজকের গোল',
          'আজকের লক্ষ্য পূরণ করতে একটু সময় বের করো।',
        );
      }
      if (streak) {
        await _daily(
          2,
          21,
          30,
          'স্ট্রিক বাঁচাও!',
          'আজকের কুইজ এখনো বাকি — রাত ১২টার আগে শেষ করো।',
        );
      }
      if (tests) {
        await _weekly(
          4,
          DateTime.saturday,
          10,
          0,
          'সাপ্তাহিক মডেল টেস্ট',
          'এই সপ্তাহের মডেল টেস্ট দিয়ে নিজেকে যাচাই করো।',
        );
        await _weekly(
          6,
          DateTime.sunday,
          18,
          0,
          'সাপ্তাহিক রিপোর্ট',
          'এই সপ্তাহে কী শিখলে দেখে নাও।',
        );
      }
      await _daily(
        5,
        20,
        0,
        'সেভ করা প্রশ্ন রিভিশন',
        'সেভ করা প্রশ্নগুলো একবার দেখে নাও।',
      );
    } catch (e) {
      debugPrint('ReminderService reschedule: $e');
    }
  }

  /// One-shot "new content" notice for the weekly check.
  static Future<void> contentChanged(String version) async {
    await init();
    if (!_ready) return;
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString('ys_content_version');
    if (last == version) return;
    await prefs.setString('ys_content_version', version);
    if (last == null) return; // first run: nothing to announce
    try {
      await _plugin.show(
        7,
        'নতুন প্রশ্ন যোগ হয়েছে',
        'অ্যাপে নতুন গাইড/প্রশ্ন এসেছে — দেখে নাও।',
        _details(),
      );
    } catch (_) {}
  }
}
