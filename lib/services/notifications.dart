/// Local notification delivery. [NoopNotifications] is used in tests and until
/// the user opts in; [LocalNotifications] schedules real offline notifications
/// via flutter_local_notifications. The WHAT/WHEN decisions live in the pure
/// [NotificationPlanner]; this file only delivers.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notification_planner.dart';

abstract class NotificationService {
  Future<void> initialize();

  /// Asks the OS for permission. Returns whether it was granted.
  Future<bool> requestPermission();

  /// Cancels everything, then schedules the given notes.
  Future<void> reschedule(List<ScheduledNote> notes);

  Future<void> cancelAll();
}

/// No-op used in tests and before opt-in.
class NoopNotifications implements NotificationService {
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> reschedule(List<ScheduledNote> notes) async {}
  @override
  Future<void> cancelAll() async {}
}

class LocalNotifications implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channelId = 'gridpop_reminders';
  static const _channelName = 'Erinnerungen';

  @override
  Future<void> initialize() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (_) {
      // Fall back to UTC if the platform name can't be resolved.
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  @override
  Future<void> reschedule(List<ScheduledNote> notes) async {
    await initialize();
    await cancelAll();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Tägliche Erinnerung, Streak-Warnung, Comeback',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );
    for (final note in notes) {
      final when = tz.TZDateTime.from(note.when, tz.local);
      // Skip anything already in the past (defensive).
      if (!when.isAfter(tz.TZDateTime.now(tz.local))) continue;
      await _plugin.zonedSchedule(
        note.id,
        note.title,
        note.body,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}
