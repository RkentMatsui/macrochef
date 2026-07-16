import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Fires the rest-timer alert two ways so it reaches the lifter whether or not
/// the app is in the foreground:
///
///  - **Foreground:** an in-app tone (a short rising "ding-ding") via
///    [audioplayers], paired with a haptic the caller triggers. No banner.
///  - **Background / screen-off:** a scheduled local notification with the same
///    tone + vibration, set to fire at the exact wall-clock moment the rest
///    ends. Survives the app being backgrounded or the screen turned off.
///
/// The two are mutually exclusive at runtime: the session logger schedules the
/// notification when a rest starts, then — if the rest completes while the app
/// is still foreground — plays the in-app tone and cancels the pending
/// notification so the alert only fires once.
///
/// No-op on non-mobile platforms (desktop/tests), so it is safe to construct
/// and call anywhere.
class RestAlertService {
  static const _channelId = 'rest_timer_v2';
  static const _notificationId = 9001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _player = AudioPlayer();

  bool _ready = false;
  bool get _supported => Platform.isAndroid || Platform.isIOS;

  /// Idempotent: initialises timezone data, the notifications plugin, the
  /// Android channel (carrying the custom sound), and requests the runtime
  /// permissions. Safe to await more than once.
  Future<void> init() async {
    if (_ready || !_supported) return;
    tz_data.initializeTimeZones();

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestAlertPermission: true,
    );
    await _plugin.initialize(
      settings:
          const InitializationSettings(android: androidInit, iOS: darwinInit),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      try {
        await android
            .createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          'Rest timer',
          description: 'Alerts you when a rest period finishes.',
          importance: Importance.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('rest_donev2'),
          enableVibration: true,
        ));
      } catch (_) {
        // Custom sound unresolvable (missing raw resource): a default-sound
        // channel beats leaving the service permanently uninitialised.
        await android
            .createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          'Rest timer',
          description: 'Alerts you when a rest period finishes.',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ));
      }
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }
    _ready = true;
  }

  /// Schedules the background alert to fire after [after] from now. Replaces any
  /// previously-scheduled rest alert (single timer at a time).
  Future<void> scheduleBackgroundAlert(Duration after) async {
    if (!_supported) return;
    await init();
    await cancelBackgroundAlert();
    // Exact scheduling needs the user-grantable SCHEDULE_EXACT_ALARM on
    // Android 14+ (the app never declares USE_EXACT_ALARM — Play policy reserves
    // it for alarm-clock apps). When the grant is missing, fall back to inexact:
    // the alert may land up to ~a minute late but never throws.
    var scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null &&
        !(await android.canScheduleExactNotifications() ?? true)) {
      scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
    }
    // UTC instant + duration → correct absolute moment regardless of zone, so
    // we don't need the device's timezone location resolved.
    final when = tz.TZDateTime.now(tz.UTC).add(after);
    try {
      await _schedule(when, scheduleMode, withCustomSound: true);
    } catch (_) {
      // The custom sound failed to resolve (e.g. the raw resource missing from
      // the build — the plugin rejects the schedule with invalid_sound). A
      // default-sound alert beats no alert: retry without the custom sound.
      await _schedule(when, scheduleMode, withCustomSound: false);
    }
  }

  Future<void> _schedule(
    tz.TZDateTime when,
    AndroidScheduleMode scheduleMode, {
    required bool withCustomSound,
  }) {
    return _plugin.zonedSchedule(
      id: _notificationId,
      title: 'Rest complete',
      body: 'Time for your next set 💪',
      scheduledDate: when,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Rest timer',
          channelDescription: 'Alerts you when a rest period finishes.',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          sound: withCustomSound
              ? const RawResourceAndroidNotificationSound('rest_donev2')
              : null,
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: scheduleMode,
    );
  }

  /// Cancels the pending background alert (e.g. rest stopped early, or it
  /// completed while the app was foreground and we played the in-app tone).
  Future<void> cancelBackgroundAlert() async {
    if (!_supported) return;
    try {
      await _plugin.cancel(id: _notificationId);
    } catch (_) {/* nothing scheduled */}
  }

  /// Plays the in-app completion tone (foreground path). Best-effort.
  Future<void> playForegroundTone() async {
    if (!_supported) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/rest_donev2.mp3'));
    } catch (_) {/* audio unavailable — haptic still fires from the caller */}
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
