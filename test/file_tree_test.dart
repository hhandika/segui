import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/shared/io/file_browser.dart';
import 'package:segui/screens/shared/io/file_list.dart';
import 'package:segui/screens/shared/io/file_tree_view.dart';
import 'package:segui/screens/shared/io/input_view.dart';
import 'package:segui/screens/shared/io/output_view.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/file_tree.dart';
import 'package:segui/services/io/output.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('segui-file-tree-');
  });

  tearDown(() {
    dir.deleteSync(recursive: true);
  });

  File createFile(List<String> parts) {
    final File file = File(p.joinAll([dir.path, ...parts]));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('content');
    return file;
  }

  List<FileTreeFile> asNew(List<File> files) {
    return [for (final File file in files) (file: file, isNew: true)];
  }

  List<String> rowLabels(FileTree tree, Set<String> expanded) {
    return tree
        .rows(expanded: expanded, shownCounts: const {}, pageSize: 20)
        .map((row) => switch (row) {
              FileTreeFolderRow() => '${row.depth}:${row.folder.name}/',
              FileTreeFileRow() =>
                '${row.depth}:${p.basename(row.file.file.path)}',
              FileTreeMoreRow() => '${row.depth}:+${row.remaining}',
            })
        .toList();
  }

  test('Tree lists folders before files, sorted by name', () {
    final FileTree tree = FileTree.fromFiles(
      asNew([
        createFile(['b.nex']),
        createFile(['loci', 'z.fas']),
        createFile(['A.csv']),
        createFile(['loci', 'a.fas']),
      ]),
      rootPath: dir.path,
    );
    final String loci = p.join(dir.path, 'loci');

    expect(rowLabels(tree, {}), ['0:loci/', '0:A.csv', '0:b.nex']);
    expect(rowLabels(tree, {loci}), [
      '0:loci/',
      '1:a.fas',
      '1:z.fas',
      '0:A.csv',
      '0:b.nex',
    ]);
    expect(tree.root.fileCount, 4);
    expect(tree.root.folders.single.hasNewFiles, isTrue);
  });

  test('Tree joins folders that only hold one folder', () {
    final FileTree tree = FileTree.fromFiles(
      asNew([
        createFile(['run', 'nexus', 'locus.nex'])
      ]),
      rootPath: dir.path,
    );
    final FileTreeFolder folder = tree.root.folders.single;

    expect(folder.name, p.join('run', 'nexus'));
    expect(folder.path, p.join(dir.path, 'run', 'nexus'));
    expect(folder.files, hasLength(1));
  });

  test('Tree leaves out unsupported files and counts them', () {
    final FileTree tree = FileTree.fromFiles(
      asNew([
        createFile(['locus.nex']),
        createFile(['notes.docx']),
        createFile(['image.png']),
        createFile(['.DS_Store']),
      ]),
      rootPath: dir.path,
    );

    expect(rowLabels(tree, {}), ['0:locus.nex']);
    expect(tree.unsupportedCount, 2);
  });

  test('Tree roots input files at the folder they share', () {
    final FileTree tree = FileTree.fromFiles([
      for (final File file in [
        createFile(['input', 'set_a', 'a.nex']),
        createFile(['input', 'set_b', 'b.nex']),
      ])
        (file: file, isNew: false),
    ]);

    expect(tree.root.path, p.join(dir.path, 'input'));
    expect(tree.root.folders.map((e) => e.name), ['set_a', 'set_b']);
  });

  test('Common directory is empty when paths share no folder', () {
    final p.Context windows = p.Context(style: p.Style.windows);
    final List<String> paths = [
      windows.join(r'C:\', 'data', 'a.nex'),
      windows.join(r'D:\', 'data', 'b.nex'),
    ];
    expect(commonDirectory(paths, context: windows), isEmpty);
    expect(
      commonDirectory([
        windows.join(r'C:\', 'data', 'set_a', 'a.nex'),
        windows.join(r'C:\', 'data', 'set_b', 'b.nex'),
      ], context: windows),
      windows.join(r'C:\', 'data'),
    );
    expect(commonDirectory(const []), isEmpty);
  });

  test('Tree pages the files of each folder', () {
    final FileTree tree = FileTree.fromFiles(
      asNew([
        for (int i = 0; i < 25; i++) createFile(['locus_$i.nex']),
      ]),
      rootPath: dir.path,
    );
    final List<FileTreeRow> rows =
        tree.rows(expanded: {}, shownCounts: const {}, pageSize: 20);

    expect(rows.whereType<FileTreeFileRow>(), hasLength(20));
    expect((rows.last as FileTreeMoreRow).remaining, 5);
  });

  test('New output files include subfolders one level down', () {
    createFile(['old.nex']);
    createFile(['per_locus', 'kept.csv']);
    final SegulOutputFile selected = SegulOutputFile.fromDirectory(
      dir,
      isRecursive: false,
    );
    expect(
      selected.files.map((e) => p.relative(e.file.path, from: dir.path)),
      unorderedEquals(['old.nex', p.join('per_locus', 'kept.csv')]),
    );
    expect(selected.files.any((e) => e.isNew), isFalse);

    createFile(['concat.nex']);
    createFile(['per_locus', 'locus_1.csv']);
    createFile(['summary', 'nested', 'deep.csv']);
    createFile(['.hidden', 'secret.nex']);
    // A rerun overwrites a file that was there before.
    final File rewritten = File(p.join(dir.path, 'per_locus', 'kept.csv'))
      ..setLastModifiedSync(DateTime.now().add(const Duration(seconds: 5)));
    final SegulOutputFile updated = SegulOutputFile.updateFiles(selected);
    final List<String> newFiles = updated.files
        .where((e) => e.isNew)
        .map((e) => p.relative(e.file.path, from: dir.path))
        .toList()
      ..sort();

    expect(newFiles, [
      'concat.nex',
      p.join('per_locus', 'kept.csv'),
      p.join('per_locus', 'locus_1.csv'),
    ]);
    expect(rewritten.existsSync(), isTrue);
    expect(updated.files.where((e) => !e.isNew).map((e) => e.file.path),
        [p.join(dir.path, 'old.nex')]);
  });

  testWidgets('Nested rows leave a gap after the guide line', (tester) async {
    const Key row = Key('row');
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: FileTreeGuides(
          depth: 2,
          child: SizedBox(key: row, height: 40),
        ),
      ),
    ));
    // The innermost line sits at the second level's chevron.
    const double line =
        fileTreeIndent + SeguiSpacing.md + SeguiControlSize.iconSmall / 2;
    expect(tester.getTopLeft(find.byKey(row)).dx, line + fileTreeGuideGap);
  });

  testWidgets('Output tree opens folders and notes unsupported files',
      (tester) async {
    tester.view.physicalSize = const Size(600, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final List<File> files = [
      for (int i = 0; i < 21; i++) createFile(['loci', 'locus_$i.nex']),
      createFile(['concat.nex']),
      createFile(['report.docx']),
    ];
    final output = SegulOutputFile(
      directory: dir,
      files: [for (final File file in files) (file: file, isNew: true)],
    );
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: Scaffold(body: OutputFileList(data: output)),
      ),
    ));
    await tester.pump();

    expect(find.text('1 unsupported file not shown'), findsOneWidget);
    // More than a page of files, so folders start closed.
    expect(find.byType(FileTreeFolderHeader), findsOneWidget);
    expect(find.text('21 files'), findsOneWidget);
    expect(find.byType(FileBrowserTile), findsOneWidget);

    await tester.tap(find.byType(FileTreeFolderHeader));
    await tester.pump();
    expect(find.byType(FileBrowserTile), findsNWidgets(21));
    expect(find.text('Show 1 more'), findsOneWidget);

    await tester.tap(find.byType(FileTreeFolderHeader));
    await tester.pump();
    expect(find.byType(FileBrowserTile), findsOneWidget);
  });

  Future<ProviderContainer> pumpInput(
    WidgetTester tester,
    List<File> files,
  ) async {
    tester.view.physicalSize = const Size(600, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(fileInputProvider.notifier).addFiles(
          files.map((e) => XFile(e.path)).toList(),
          sequenceTypeGroup,
        );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: const Scaffold(body: InputScreen()),
      ),
    ));
    await tester.pump();
    return container;
  }

  testWidgets('Search shows only for more than a page of files',
      (tester) async {
    await pumpInput(tester, [
      for (int i = 0; i < fileListPageSize; i++)
        createFile(['set_a', 'uce-$i.nex']),
    ]);
    expect(find.byType(FileSearchField), findsNothing);
  });

  testWidgets('Search lists matching files in their folders', (tester) async {
    await pumpInput(tester, [
      createFile(['set_a', 'uce-1.nex']),
      createFile(['set_a', 'uce-2.nex']),
      for (int i = 0; i < fileListPageSize - 1; i++)
        createFile(['set_b', 'exon-$i.nex']),
    ]);
    expect(find.byType(FileSearchField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'UCE');
    await tester.pump();
    expect(find.byType(FileBrowserTile), findsNWidgets(2));
    expect(find.byType(FileTreeFolderHeader), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pump();
    expect(find.text('No matching files'), findsOneWidget);
  });

  testWidgets('Selection removes only the selected input files',
      (tester) async {
    final container = await pumpInput(tester, [
      createFile(['set_a', 'a.nex']),
      createFile(['set_a', 'b.nex']),
      createFile(['set_b', 'c.nex']),
    ]);
    // Removing waits for selection.
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.text('Remove'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);

    await tester.tap(find.text('Select'));
    await tester.pump();
    expect(find.text('Select all'), findsOneWidget);
    expect(find.text('Clear all'), findsOneWidget);
    expect(find.text('Select files'), findsOneWidget);

    // Folder and file checkboxes line up at the row end.
    final Set<double> checkboxEnds = {
      for (final Element box in find.byType(Checkbox).evaluate())
        tester.getRect(find.byWidget(box.widget)).right,
    };
    expect(checkboxEnds, hasLength(1));

    // A folder checkbox selects every file in it.
    await tester.tap(find.descendant(
      of: find.widgetWithText(FileTreeFolderHeader, 'set_a'),
      matching: find.byType(Checkbox),
    ));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    Checkbox checkboxOf(String name) => tester.widget<Checkbox>(find.descendant(
          of: find.ancestor(
            of: find.text(name),
            matching: find.byWidgetPredicate(
                (w) => w is FileBrowserTile || w is FileTreeFolderHeader),
          ),
          matching: find.byType(Checkbox),
        ));
    expect(checkboxOf('set_a').value, isTrue);
    expect(checkboxOf('a.nex').value, isTrue);
    expect(checkboxOf('c.nex').value, isFalse);

    await tester.tap(find.text('Select all'));
    await tester.pump();
    expect(find.text('3 selected'), findsOneWidget);
    await tester.tap(find.text('Clear all'));
    await tester.pump();
    expect(find.text('Select files'), findsOneWidget);

    await tester.tap(find.widgetWithText(FileBrowserTile, 'c.nex'));
    await tester.pump();
    // The toolbar sits under the tree instead of covering its rows.
    expect(
      tester.getRect(find.byType(FileTreeView)).bottom,
      lessThanOrEqualTo(tester.getTopLeft(find.byType(FileActionToolbar)).dy),
    );
    // The count sits between the actions and the destructive Remove.
    expect(
      tester.getCenter(find.text('1 selected')).dx,
      lessThan(tester.getCenter(find.text('Remove')).dx),
    );

    // Removing asks first, and Cancel keeps the files.
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.byType(RemoveInputFilesAlert), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(container.read(fileInputProvider).value, hasLength(3));
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(RemoveInputFilesAlert),
      matching: find.text('Remove'),
    ));
    await tester.pumpAndSettle();

    final names = container
        .read(fileInputProvider)
        .value!
        .map((e) => p.basename(e.file.path));
    expect(names, unorderedEquals(['a.nex', 'b.nex']));
    // Removing ends selection.
    expect(find.text('Select'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
  });
}
