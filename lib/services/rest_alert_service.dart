import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

enum RestAlertScheduleResult { scheduled, notificationsDenied, unsupported }

/// The platform-only operations needed to deliver rest alerts.
///
/// Keeping this seam narrow makes the scheduling policy testable without
/// loading mobile plugins on desktop test runs.
abstract interface class RestAlertBackend {
  bool get isSupported;

  Future<void> initialize();
  Future<bool> requestNotificationsPermission();
  Future<bool> canScheduleExactNotifications();
  Future<void> cancel({required int notificationId});
  Future<void> schedule(RestAlertScheduleRequest request);
  Future<void> playForegroundTone();
  Future<void> dispose();
}

/// A complete scheduling request, including the notification behavior Android
/// must apply when it delivers the alert.
class RestAlertScheduleRequest {
  const RestAlertScheduleRequest({
    required this.when,
    required this.exact,
    required this.customSound,
    required this.playSound,
    required this.enableVibration,
    required this.timeoutAfter,
  });

  final DateTime when;
  final bool exact;
  final bool customSound;
  final bool playSound;
  final bool enableVibration;
  final Duration timeoutAfter;
}

/// Coordinates rest alert policy while [RestAlertBackend] handles plugins.
class RestAlertService {
  RestAlertService() : _backend = _FlutterRestAlertBackend();
  RestAlertService.forTesting(this._backend);

  static const _notificationId = 9001;

  final RestAlertBackend _backend;
  Future<void>? _initializing;
  Future<void> _alertOperations = Future.value();
  int _alertGeneration = 0;
  bool? _notificationsGranted;

  /// Idempotently primes the platform notification pipeline. Concurrent calls
  /// share one initialization operation.
  Future<void> init() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    if (!_backend.isSupported) return;
    await _backend.initialize();
    _notificationsGranted = await _backend.requestNotificationsPermission();
  }

  /// Reports whether a rest can use an OS notification without scheduling one.
  Future<RestAlertScheduleResult> backgroundAlertAvailability() async {
    if (!_backend.isSupported) return RestAlertScheduleResult.unsupported;
    await init();
    return _notificationsGranted == false
        ? RestAlertScheduleResult.notificationsDenied
        : RestAlertScheduleResult.scheduled;
  }

  /// Schedules one auto-expiring background alert, replacing a previous one.
  Future<RestAlertScheduleResult> scheduleBackgroundAlert(Duration after) {
    if (!_backend.isSupported) {
      return Future.value(RestAlertScheduleResult.unsupported);
    }
    final generation = ++_alertGeneration;
    return _serializeAlertOperation(
      () => _scheduleBackgroundAlert(after, generation),
    );
  }

  Future<RestAlertScheduleResult> _scheduleBackgroundAlert(
    Duration after,
    int generation,
  ) async {
    await init();
    if (!_isCurrentAlertOperation(generation)) {
      return RestAlertScheduleResult.scheduled;
    }
    if (_notificationsGranted == false) {
      return RestAlertScheduleResult.notificationsDenied;
    }
    await _backend.cancel(notificationId: _notificationId);
    if (!_isCurrentAlertOperation(generation)) {
      return RestAlertScheduleResult.scheduled;
    }
    final exact = await _backend.canScheduleExactNotifications();
    if (!_isCurrentAlertOperation(generation)) {
      return RestAlertScheduleResult.scheduled;
    }
    await _backend.schedule(
      RestAlertScheduleRequest(
        when: DateTime.now().toUtc().add(after),
        exact: exact,
        customSound: true,
        playSound: true,
        enableVibration: true,
        timeoutAfter: const Duration(seconds: 15),
      ),
    );
    return RestAlertScheduleResult.scheduled;
  }

  /// Cancels the pending alert when a rest ends early or in the foreground.
  Future<void> cancelBackgroundAlert() {
    if (!_backend.isSupported) return Future.value();
    ++_alertGeneration;
    return _serializeAlertOperation(_cancelBackgroundAlert);
  }

  Future<void> _cancelBackgroundAlert() async {
    try {
      await _backend.cancel(notificationId: _notificationId);
    } catch (_) {
      // Nothing scheduled is a valid cancellation outcome.
    }
  }

  Future<T> _serializeAlertOperation<T>(Future<T> Function() operation) {
    final result = _alertOperations.then((_) => operation());
    _alertOperations = _ignoreOperationError(result);
    return result;
  }

  Future<void> _ignoreOperationError<T>(Future<T> operation) async {
    try {
      await operation;
    } catch (_) {
      // A failed operation must not prevent a later cancellation or reschedule.
    }
  }

  bool _isCurrentAlertOperation(int generation) =>
      generation == _alertGeneration;

  /// Plays the in-app completion tone for foreground rests. Best-effort.
  Future<void> playForegroundTone() async {
    if (!_backend.isSupported) return;
    try {
      await _backend.playForegroundTone();
    } catch (_) {
      // The caller still supplies haptic feedback when audio is unavailable.
    }
  }

  Future<void> dispose() => _backend.dispose();
}

class _FlutterRestAlertBackend implements RestAlertBackend {
  static const _channelId = 'rest_timer_v2';
  static const _notificationId = 9001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _player = AudioPlayer();

  @override
  bool get isSupported => Platform.isAndroid || Platform.isIOS;

  @override
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestAlertPermission: true,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      ),
    );

    final android = _android;
    if (android == null) return;
    try {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          'Rest timer',
          description: 'Alerts you when a rest period finishes.',
          importance: Importance.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('rest_donev2'),
          enableVibration: true,
        ),
      );
    } catch (_) {
      // A default-sound channel is preferable when the custom resource is bad.
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          'Rest timer',
          description: 'Alerts you when a rest period finishes.',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
    await android.requestExactAlarmsPermission();
  }

  @override
  Future<bool> requestNotificationsPermission() async {
    final android = _android;
    if (android == null) return true;
    return await android.requestNotificationsPermission() ?? true;
  }

  @override
  Future<bool> canScheduleExactNotifications() async {
    final android = _android;
    return android == null ||
        (await android.canScheduleExactNotifications() ?? true);
  }

  @override
  Future<void> cancel({required int notificationId}) =>
      _plugin.cancel(id: notificationId);

  @override
  Future<void> schedule(RestAlertScheduleRequest request) async {
    try {
      await _schedule(request);
    } catch (_) {
      if (!request.customSound) rethrow;
      await _schedule(
        RestAlertScheduleRequest(
          when: request.when,
          exact: request.exact,
          customSound: false,
          playSound: request.playSound,
          enableVibration: request.enableVibration,
          timeoutAfter: request.timeoutAfter,
        ),
      );
    }
  }

  Future<void> _schedule(RestAlertScheduleRequest request) {
    return _plugin.zonedSchedule(
      id: _notificationId,
      title: 'Rest complete',
      body: 'Time for your next set 💪',
      scheduledDate: tz.TZDateTime.from(request.when, tz.UTC),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Rest timer',
          channelDescription: 'Alerts you when a rest period finishes.',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          sound: request.customSound
              ? const RawResourceAndroidNotificationSound('rest_donev2')
              : null,
          playSound: request.playSound,
          enableVibration: request.enableVibration,
          timeoutAfter: request.timeoutAfter.inMilliseconds,
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: request.exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> playForegroundTone() async {
    await _player.stop();
    await _player.play(AssetSource('audio/rest_donev2.mp3'));
  }

  @override
  Future<void> dispose() => _player.dispose();
}
