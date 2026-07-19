import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/rest_alert_service.dart';

void main() {
  test('concurrent initialization only initializes the backend once', () async {
    final backend = FakeRestAlertBackend();
    final service = RestAlertService.forTesting(backend);

    await Future.wait([service.init(), service.init()]);

    expect(backend.initializeCalls, 1);
    expect(backend.permissionRequests, 1);
  });

  test('scheduling shares an in-progress initialization', () async {
    final initialization = Completer<void>();
    final backend = FakeRestAlertBackend(initialization: initialization);
    final service = RestAlertService.forTesting(backend);

    final initializing = service.init();
    final scheduling = service.scheduleBackgroundAlert(
      const Duration(seconds: 30),
    );
    await backend.initializationStarted.future;

    expect(backend.initializeCalls, 1);
    expect(backend.scheduled, isEmpty);

    initialization.complete();
    await Future.wait([initializing, scheduling]);

    expect(backend.initializeCalls, 1);
    expect(backend.scheduled, hasLength(1));
  });

  test('denied notifications do not schedule an alert', () async {
    final backend = FakeRestAlertBackend(notificationPermissionGranted: false);
    final service = RestAlertService.forTesting(backend);

    final result = await service.scheduleBackgroundAlert(
      const Duration(minutes: 1),
    );

    expect(result, RestAlertScheduleResult.notificationsDenied);
    expect(backend.scheduled, isEmpty);
  });

  test(
    'granted permission schedules an auto-expiring alarm notification',
    () async {
      final backend = FakeRestAlertBackend(notificationPermissionGranted: true);
      final service = RestAlertService.forTesting(backend);

      final result = await service.scheduleBackgroundAlert(
        const Duration(seconds: 30),
      );

      expect(result, RestAlertScheduleResult.scheduled);
      expect(
        backend.scheduled.single.timeoutAfter,
        const Duration(seconds: 15),
      );
      expect(backend.scheduled.single.playSound, isTrue);
      expect(backend.scheduled.single.enableVibration, isTrue);
      expect(backend.scheduled.single.exact, isTrue);
    },
  );

  test(
    'missing exact-alarm access uses allow-while-idle inexact scheduling',
    () async {
      final backend = FakeRestAlertBackend(canScheduleExact: false);
      final service = RestAlertService.forTesting(backend);

      await service.scheduleBackgroundAlert(const Duration(seconds: 30));

      expect(backend.scheduled.single.exact, isFalse);
    },
  );

  test(
    'cancelling while exact-alarm access is pending prevents scheduling',
    () async {
      final backend = FakeRestAlertBackend(exactPermission: Completer<bool>());
      final service = RestAlertService.forTesting(backend);

      final scheduling = service.scheduleBackgroundAlert(
        const Duration(seconds: 30),
      );
      await backend.exactPermissionRequested.future;
      final cancellation = service.cancelBackgroundAlert();
      backend.exactPermission!.complete(true);
      await Future.wait([scheduling, cancellation]);

      expect(backend.scheduled, isEmpty);
    },
  );
}

class FakeRestAlertBackend implements RestAlertBackend {
  FakeRestAlertBackend({
    this.notificationPermissionGranted = true,
    this.canScheduleExact = true,
    this.exactPermission,
    this.initialization,
  });

  @override
  bool get isSupported => true;

  final bool notificationPermissionGranted;
  final bool canScheduleExact;
  final Completer<bool>? exactPermission;
  final Completer<void>? initialization;
  final Completer<void> initializationStarted = Completer<void>();
  final Completer<void> exactPermissionRequested = Completer<void>();
  int initializeCalls = 0;
  int permissionRequests = 0;
  final List<RestAlertScheduleRequest> scheduled = [];

  @override
  Future<void> cancel({required int notificationId}) async {}

  @override
  Future<bool> canScheduleExactNotifications() async {
    exactPermissionRequested.complete();
    return exactPermission?.future ?? canScheduleExact;
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize() async {
    initializeCalls++;
    initializationStarted.complete();
    await initialization?.future;
  }

  @override
  Future<void> playForegroundTone() async {}

  @override
  Future<bool> requestNotificationsPermission() async {
    permissionRequests++;
    return notificationPermissionGranted;
  }

  @override
  Future<void> schedule(RestAlertScheduleRequest request) async {
    scheduled.add(request);
  }
}
