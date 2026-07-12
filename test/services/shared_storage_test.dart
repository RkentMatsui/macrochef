import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/shared_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SharedBackup preserves MediaStore metadata', () {
    final b = SharedBackup(
      id: 'content://downloads/7',
      name: 'macrochef-backup-20260711-1200.sqlite',
      addedAt: DateTime.fromMillisecondsSinceEpoch(1000),
      sizeBytes: 123,
      relativePath: 'Download/MacroChef/',
      ownedByApp: false,
    );
    expect(b.sizeBytes, 123);
    expect(b.ownedByApp, isFalse);
  });

  test(
    'NoopSharedStorage reports copy unavailable and delete notFound',
    () async {
      const storage = NoopSharedStorage();
      final backup = SharedBackup(id: 'x', name: 'x', addedAt: DateTime(2026));
      expect(
        () => storage.copyToPrivate(backup, File('unused')),
        throwsA(isA<SharedStorageAccessException>()),
      );
      expect(await storage.deleteDownload('x'), SharedDeleteResult.notFound);
    },
  );

  test('MediaStoreSharedStorage filters with the supplied prefix', () async {
    const channel = MethodChannel('com.macrochef.app/downloads_backup');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'list');
      expect(call.arguments, {'prefix': 'custom-backup-'});
      return [
        {
          'id': 'content://downloads/7',
          'name': 'custom-backup-20260712.sqlite',
          'addedAtMs': 1000,
          'sizeBytes': 123,
          'relativePath': 'Download/MacroChef/',
          'ownedByApp': true,
        },
        {
          'id': 'content://downloads/8',
          'name': 'different-backup.sqlite',
          'addedAtMs': 2000,
          'sizeBytes': 456,
          'relativePath': 'Download/MacroChef/',
          'ownedByApp': true,
        },
      ];
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final backups = await const MediaStoreSharedStorage().listDownloads(
      'custom-backup-',
    );

    expect(backups.map((backup) => backup.name), [
      'custom-backup-20260712.sqlite',
    ]);
  });
}
