import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/training_repository.dart';
import 'package:macrochef/services/rest_alert_service.dart';
import 'package:macrochef/state/providers.dart';
import 'package:macrochef/ui/training/session_logger_screen.dart';

void main() {
  Future<void> pumpLogger(
    WidgetTester tester, {
    required RestAlertScheduleResult alertResult,
    _FakeRestAlertBackend? backend,
    RestAlertService? alertService,
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final sessionId = await TrainingRepository(
      db,
    ).startSession(date: '2026-07-19');
    final alerts =
        alertService ??
        RestAlertService.forTesting(backend ?? _FakeRestAlertBackend(alertResult));
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        restAlertServiceProvider.overrideWithValue(alerts),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: SessionLoggerScreen(sessionId: sessionId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'starting rest warns when Android notification permission is denied',
    (tester) async {
      await pumpLogger(
        tester,
        alertResult: RestAlertScheduleResult.notificationsDenied,
      );

      await tester.tap(find.byTooltip('Start rest'));
      await tester.pump();

      expect(
        find.text('Background rest alerts are disabled in Android settings.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('starting rest does not warn when the alert is scheduled', (
    tester,
  ) async {
    await pumpLogger(tester, alertResult: RestAlertScheduleResult.scheduled);

    await tester.tap(find.byTooltip('Start rest'));
    await tester.pump();

    expect(
      find.text('Background rest alerts are disabled in Android settings.'),
      findsNothing,
    );
  });

  testWidgets('logger schedules only while backgrounded and cancels on resume', (
    tester,
  ) async {
    final backend = _FakeRestAlertBackend(RestAlertScheduleResult.scheduled);
    await pumpLogger(
      tester,
      alertResult: RestAlertScheduleResult.scheduled,
      backend: backend,
    );

    await tester.tap(find.byTooltip('Start rest'));
    await tester.pump();
    expect(backend.scheduleCalls, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(backend.scheduleCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(backend.cancelCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('adjusting foreground rest defers OS scheduling until background', (
    tester,
  ) async {
    final backend = _FakeRestAlertBackend(RestAlertScheduleResult.scheduled);
    await pumpLogger(tester, alertResult: RestAlertScheduleResult.scheduled, backend: backend);

    await tester.tap(find.byTooltip('Start rest'));
    await tester.pump();
    await tester.tap(find.text('+15'));
    await tester.pump();
    expect(backend.scheduleCalls, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(backend.scheduleCalls, 1);
  });

  testWidgets('stopping rest suppresses a stale denied-permission warning', (
    tester,
  ) async {
    final result = Completer<RestAlertScheduleResult>();
    await pumpLogger(
      tester,
      alertResult: RestAlertScheduleResult.notificationsDenied,
      alertService: _DelayedResultRestAlertService(
        result,
      ),
    );

    await tester.tap(find.byTooltip('Start rest'));
    await tester.pump();
    await tester.tap(find.text('Skip'));
    await tester.pump();
    result.complete(RestAlertScheduleResult.notificationsDenied);
    await tester.pump();

    expect(
      find.text('Background rest alerts are disabled in Android settings.'),
      findsNothing,
    );
  });
}

class _FakeRestAlertBackend implements RestAlertBackend {
  _FakeRestAlertBackend(this.result);

  final RestAlertScheduleResult result;
  int scheduleCalls = 0;
  int cancelCalls = 0;

  @override
  bool get isSupported => result != RestAlertScheduleResult.unsupported;

  @override
  Future<bool> canScheduleExactNotifications() async => true;

  @override
  Future<void> cancel({required int notificationId}) async {
    cancelCalls++;
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> playForegroundTone() async {}

  @override
  Future<bool> requestNotificationsPermission() async =>
      result != RestAlertScheduleResult.notificationsDenied;

  @override
  Future<void> schedule(RestAlertScheduleRequest request) async {
    scheduleCalls++;
  }
}

class _DelayedResultRestAlertService extends RestAlertService {
  _DelayedResultRestAlertService(this.result)
    : super.forTesting(_FakeRestAlertBackend(RestAlertScheduleResult.scheduled));

  final Completer<RestAlertScheduleResult> result;

  @override
  Future<RestAlertScheduleResult> scheduleBackgroundAlert(Duration after) =>
      result.future;
}
