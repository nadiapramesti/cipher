import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Notifikasi pengingat harian. Lokal di HP, tanpa server.
class ReminderService {
  ReminderService._();
  static final instance = ReminderService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  static const _id = 7;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings);
    _ready = true;
  }

  /// Minta izin notifikasi (Android 13+). Balik true kalau diizinkan.
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  /// Jadwalkan pengingat tiap hari di jam lokal [hour]:[minute].
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String channelName,
  }) async {
    await init();
    await _plugin.cancel(_id);

    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    // dijadwalkan dalam UTC; Indonesia gak pakai DST jadi jamnya tetap
    final when = tz.TZDateTime.from(next.toUtc(), tz.UTC);

    await _plugin.zonedSchedule(
      _id,
      title,
      body,
      when,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'cipher_daily',
          channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel() async {
    await init();
    await _plugin.cancel(_id);
  }
}
