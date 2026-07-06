import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/services/notification_planner.dart';
import 'package:gridpop/services/notifications.dart';
import 'package:gridpop/services/storage.dart';
import 'package:gridpop/ui/state/notifications_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingNotifications implements NotificationService {
  _RecordingNotifications({this.grant = true});

  final bool grant;
  int rescheduleCalls = 0;
  int cancelCalls = 0;
  List<ScheduledNote> lastNotes = const [];

  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermission() async => grant;
  @override
  Future<void> reschedule(List<ScheduledNote> notes) async {
    rescheduleCalls++;
    lastNotes = notes;
  }

  @override
  Future<void> cancelAll() async => cancelCalls++;
}

Future<Storage> _storage(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  return Storage.create();
}

void main() {
  test('enable requests permission, persists and schedules', () async {
    final storage = await _storage({'streak': 5});
    final service = _RecordingNotifications(grant: true);
    final c = NotificationsController(storage, service);

    final ok = await c.enable();
    expect(ok, isTrue);
    expect(c.state, isTrue);
    expect(storage.notificationsEnabled, isTrue);
    expect(service.rescheduleCalls, 1);
    expect(service.lastNotes, isNotEmpty);
  });

  test('enable fails when permission is denied', () async {
    final storage = await _storage({});
    final service = _RecordingNotifications(grant: false);
    final c = NotificationsController(storage, service);

    expect(await c.enable(), isFalse);
    expect(c.state, isFalse);
    expect(storage.notificationsEnabled, isFalse);
    expect(service.rescheduleCalls, 0);
  });

  test('disable cancels and persists off', () async {
    final storage = await _storage({'settings.notifications': true});
    final service = _RecordingNotifications();
    final c = NotificationsController(storage, service);
    expect(c.state, isTrue); // restored from storage

    await c.disable();
    expect(c.state, isFalse);
    expect(storage.notificationsEnabled, isFalse);
    expect(service.cancelCalls, 1);
  });

  test('refresh only schedules when enabled', () async {
    final storage = await _storage({});
    final service = _RecordingNotifications();
    final c = NotificationsController(storage, service);

    await c.refresh(); // disabled -> nothing
    expect(service.rescheduleCalls, 0);
  });
}
