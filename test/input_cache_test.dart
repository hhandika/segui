import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:segui/services/io/input_cache.dart';

void main() {
  late Directory root;
  late Directory tempDir;
  late Directory supportDir;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('segui-input-cache-');
    tempDir = await Directory(p.join(root.path, 'tmp')).create();
    supportDir = await Directory(p.join(root.path, 'support')).create();
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  InputCacheServices cache({bool mobile = true}) {
    return InputCacheServices(
      tempDir: tempDir,
      supportDir: supportDir,
      includePickerCopies: mobile,
    );
  }

  File createFile(Directory dir, List<String> parts) {
    final File file = File(p.joinAll([dir.path, ...parts]));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('content');
    return file;
  }

  group('Input cache', () {
    test('Pruning keeps inputs and removes other copies and empty folders',
        () async {
      final File kept =
          createFile(supportDir, [inputCacheDirName, 'archive-1', 'a.nex']);
      final File stale =
          createFile(supportDir, [inputCacheDirName, 'archive-2', 'b.nex']);
      final File pickerCopy =
          createFile(tempDir, ['file_picker', '1', 'c.nex']);
      final File inboxCopy = createFile(tempDir, ['segui-Inbox', 'd.nex']);

      final int deleted = await cache().prune({kept.path});

      expect(deleted, 3);
      expect(kept.existsSync(), isTrue);
      expect(stale.existsSync(), isFalse);
      expect(stale.parent.existsSync(), isFalse);
      expect(pickerCopy.existsSync(), isFalse);
      expect(inboxCopy.existsSync(), isFalse);
    });

    test('Desktop pruning leaves the shared temp folder alone', () async {
      final File pickerCopy =
          createFile(tempDir, ['file_picker', '1', 'c.nex']);
      final File inboxCopy = createFile(tempDir, ['other-Inbox', 'd.nex']);
      final File cached =
          createFile(supportDir, [inputCacheDirName, 'archive-1', 'a.nex']);

      await cache(mobile: false).clear();

      expect(pickerCopy.existsSync(), isTrue);
      expect(inboxCopy.existsSync(), isTrue);
      expect(cached.existsSync(), isFalse);
    });

    test('Session folders in use are not pruned', () async {
      final services = cache();
      final File written = await services.withSessionDir('folder', (dir) async {
        final File file = createFile(dir, ['loci', 'a.nex']);
        await services.clear();
        expect(file.existsSync(), isTrue);
        return file;
      });
      expect(written.existsSync(), isTrue);

      await services.clear();
      expect(written.existsSync(), isFalse);
    });

    test('Cached paths are recognized', () async {
      final services = cache();
      final File cached =
          createFile(supportDir, [inputCacheDirName, 'archive-1', 'a.nex']);
      final File picked = createFile(tempDir, ['file_picker', 'b.nex']);
      final File original = createFile(root, ['data', 'c.nex']);

      expect(await services.isCached(cached.path), isTrue);
      expect(await services.isCached(picked.path), isTrue);
      expect(await services.isCached(original.path), isFalse);
    });
  });
}
