import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:segui/services/providers/alignment_view.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/providers/viewer.dart';
import 'package:segui/services/viewers/viewer_files.dart';
import 'package:segui/src/rust/api/file_sort.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Orders paths alphabetically, standing in for the Rust natural sort.
List<int> pathOrder(
  List<String> paths,
  FileSortKey key, {
  required bool ascending,
  List<int?> sizes = const [],
}) {
  return List.generate(paths.length, (i) => i)
    ..sort((a, b) => paths[a].compareTo(paths[b]));
}

void main() {
  late Directory dir;
  late SharedPreferences preferences;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('segui-viewer-files-');
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  File write(String name) {
    final File file = File(p.join(dir.path, name));
    file.createSync(recursive: true);
    file.writeAsStringSync('>a\nACGT\n');
    return file;
  }

  ProviderContainer makeContainer() {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        settingProvider.overrideWithValue(preferences),
        fileOrderProvider.overrideWithValue(pathOrder),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('Viewer lists formats it can open and skips hidden files', () {
    bool viewable(String name) => isViewerFile(File(p.join(dir.path, name)));
    expect(viewable('locus.fas'), isTrue);
    expect(viewable('locus.nex'), isTrue);
    expect(viewable('summary.csv'), isTrue);
    expect(viewable('notes.txt'), isTrue);
    expect(viewable('reads.fq.gz'), isFalse);
    expect(viewable('data.zip'), isFalse);
    expect(viewable('image.png'), isFalse);
    expect(viewable('.hidden.fas'), isFalse);
  });

  test('A folder adds its viewable files only, without subfolders', () async {
    write('b.fas');
    write('a.nex');
    write('photo.png');
    write('.secret.fas');
    write(p.join('nested', 'c.fas'));
    final ProviderContainer container = makeContainer();
    final ViewerFiles files = container.read(viewerFilesProvider.notifier);

    expect(await files.addFolder(dir), 2);
    expect(
      container.read(viewerFilesProvider).map((f) => p.basename(f.path)),
      ['a.nex', 'b.fas'],
    );
    // Opening the same folder again adds nothing.
    expect(await files.addFolder(dir), 0);
    expect(container.read(viewerRecentsProvider).single.isFolder, isTrue);
  });

  test('Recents keep the newest ten and survive a restart', () {
    final ProviderContainer container = makeContainer();
    final ViewerFiles files = container.read(viewerFilesProvider.notifier);
    for (int i = 0; i < 12; i++) {
      files.addFiles([write('f$i.fas')]);
    }
    // Reopening moves an entry to the front.
    files.addFiles([File(p.join(dir.path, 'f5.fas'))]);

    final List<ViewerRecent> recents = container.read(viewerRecentsProvider);
    expect(recents, hasLength(viewerRecentLimit));
    expect(recents.first.name, 'f5.fas');
    expect(recents.map((r) => r.name), isNot(contains('f0.fas')));

    final List<ViewerRecent> restored =
        makeContainer().read(viewerRecentsProvider);
    expect(restored, recents);
  });

  test('Recents report files that are gone', () {
    final File file = write('gone.fas');
    final ViewerRecent recent = ViewerRecent(path: file.path, isFolder: false);
    expect(recent.exists, isTrue);
    file.deleteSync();
    expect(recent.exists, isFalse);
  });
}
