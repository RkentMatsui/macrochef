import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/backup_service.dart';
import 'ui/recovery/recovery_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final pendingApplied = await BackupService.applyPendingRestore();
  final dependencies = await RecoveryBootstrapDependencies.create(
    pendingRestoreApplied: pendingApplied,
  );
  runApp(
    RecoveryBootstrap(
      coordinator: dependencies.coordinator,
      appBuilder: (_) => const ProviderScope(child: MacroChefApp()),
    ),
  );
}
