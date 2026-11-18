import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/settings/data_usage.dart';
import 'package:segui/screens/settings/data_usage_tree.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/screens/viewers/tabulated.dart';
import 'package:segui/services/io/data_usage.dart';
import 'package:segui/styles/themes.dart';

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('segui-data-usage-');
  });

  tearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  File createFile(List<String> parts, {int size = 4, DateTime? modified}) {
    final File file = File(p.joinAll([dir.path, ...parts]));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('x' * size);
    if (modified != null) {
      file.setLastModifiedSync(modified);
    }
    return file;
  }

  Directory createFolder(List<String> parts) {
    return Directory(p.joinAll([dir.path, ...parts]))
      ..createSync(recursive: true);
  }

  List<String> labels(DataUsageTree tree, Set<String> expanded,
      {DataUsageSort sort = DataUsageSort.name}) {
    return tree
        .rows(expanded: expanded, sort: sort)
        .map((row) => switch (row) {
              DataUsageFolderRow() => '${row.depth}:${row.folder.name}/',
              DataUsageFileRow() => '${row.depth}:${row.file.name}',
              DataUsageEmptyRow() => '${row.depth}:(empty)',
            })
        .toList();
  }

  group('DataUsageTree', () {
    test('Lists folders, including empty ones, before files', () {
      createFile(['segui.log']);
      createFile(['concat', 'concat.nex']);
      createFolder(['empty_run']);

      final tree = DataUsageTree.fromDirectory(dir);

      expect(labels(tree, {}), ['0:concat/', '0:empty_run/', '0:segui.log']);
      expect(tree.folderCount, 2);
      expect(tree.fileCount, 2);
    });

    test('Totals sizes and file counts through subfolders', () {
      createFile(['run', 'a.nex'], size: 10);
      createFile(['run', 'loci', 'b.fas'], size: 20);
      createFile(['run', 'loci', 'c.fas'], size: 30);
      createFile(['top.log'], size: 5);

      final tree = DataUsageTree.fromDirectory(dir);
      final DataUsageFolder run = tree.root.folders.single;

      expect(tree.size, 65);
      expect(run.size, 60);
      expect(run.fileCount, 3);
      expect(run.itemCount, 2);
      expect(run.folders.single.size, 50);
    });

    test('Leaves out hidden files and folders', () {
      createFile(['.DS_Store']);
      createFile(['.cache', 'tmp.txt']);
      createFile(['run', 'a.nex']);

      final tree = DataUsageTree.fromDirectory(dir);

      expect(labels(tree, {}), ['0:run/']);
      expect(tree.fileCount, 1);
    });

    test('Shows the contents of open folders only', () {
      createFile(['run', 'loci', 'b.fas']);
      createFile(['run', 'a.nex']);
      final String run = p.join(dir.path, 'run');
      final String loci = p.join(run, 'loci');

      final tree = DataUsageTree.fromDirectory(dir);

      expect(labels(tree, {run}), ['0:run/', '1:loci/', '1:a.nex']);
      expect(
        labels(tree, {run, loci}),
        ['0:run/', '1:loci/', '2:b.fas', '1:a.nex'],
      );
      expect(tree.root.folderPaths, containsAll([run, loci]));
    });

    test('Marks an open empty folder', () {
      createFolder(['empty_run']);

      final tree = DataUsageTree.fromDirectory(dir);

      expect(
        labels(tree, {p.join(dir.path, 'empty_run')}),
        ['0:empty_run/', '1:(empty)'],
      );
      expect(tree.root.folders.single.isEmpty, isTrue);
    });

    test('Sorts by size, name, and most recent change', () {
      final DateTime old = DateTime(2024, 1, 1);
      final DateTime recent = DateTime(2026, 1, 1);
      createFile(['big', 'a.nex'], size: 100, modified: old);
      createFile(['Small', 'a.nex'], size: 1, modified: recent);
      createFile(['large.log'], size: 50, modified: old);
      createFile(['tiny.log'], size: 2, modified: recent);

      final tree = DataUsageTree.fromDirectory(dir);

      expect(
        labels(tree, {}, sort: DataUsageSort.size),
        ['0:big/', '0:Small/', '0:large.log', '0:tiny.log'],
      );
      expect(
        labels(tree, {}, sort: DataUsageSort.name),
        ['0:big/', '0:Small/', '0:large.log', '0:tiny.log'],
      );
      expect(
        labels(tree, {}, sort: DataUsageSort.recent).last,
        '0:large.log',
      );
    });

    test('Breaks sizes down by format, top three then Other', () {
      createFile(['run', 'a.nex'], size: 100);
      createFile(['run', 'b.nex'], size: 50);
      createFile(['reads.csv'], size: 60);
      createFile(['loci', 'c.fas'], size: 30);
      createFile(['notes.txt'], size: 5);
      createFile(['segui.log'], size: 2);
      createFile(['mystery.xyz'], size: 1);

      final shares = DataUsageTree.fromDirectory(dir).typeShares();

      expect(
        shares.map((e) => '${e.label}:${e.size}:${e.isOther}'),
        ['NEXUS:150:false', 'CSV:60:false', 'FASTA:30:false', 'Other:8:true'],
      );
    });

    test('Leaves Other out when three formats or fewer', () {
      createFile(['a.nex'], size: 10);
      createFile(['b.csv'], size: 5);

      final shares = DataUsageTree.fromDirectory(dir).typeShares();

      expect(shares.map((e) => e.label), ['NEXUS', 'CSV']);
    });
  });

  group('DataUsageSelection', () {
    late DataUsageTree tree;
    late DataUsageFolder run;
    late DataUsageFolder loci;

    setUp(() {
      createFile(['run', 'a.nex']);
      createFile(['run', 'loci', 'b.fas']);
      createFile(['run', 'loci', 'c.fas']);
      createFile(['segui.log']);
      createFolder(['empty_run']);
      tree = DataUsageTree.fromDirectory(dir);
      run = tree.root.folders.firstWhere((e) => e.name == 'run');
      loci = run.folders.single;
    });

    test('Picking a folder picks everything inside it', () {
      final selection = const DataUsageSelection().toggleFolder(tree, run);

      expect(selection.folderState(run), isTrue);
      expect(selection.folderState(loci), isTrue);
      expect(selection.files(tree).map((e) => p.basename(e.path)),
          unorderedEquals(['a.nex', 'b.fas', 'c.fas']));
      expect(selection.entities(tree).map((e) => e.path), [run.path]);
    });

    test('A partly picked folder is mixed and not deleted whole', () {
      final DataUsageFile b = loci.files.firstWhere((e) => e.name == 'b.fas');
      final selection = const DataUsageSelection().toggleFile(tree, b);

      expect(selection.folderState(loci), isNull);
      expect(selection.folderState(run), isNull);
      expect(selection.entities(tree).map((e) => e.path), [b.file.path]);
    });

    test('Picking every file in a folder picks the folder', () {
      DataUsageSelection selection = const DataUsageSelection();
      for (final DataUsageFile file in loci.files) {
        selection = selection.toggleFile(tree, file);
      }

      expect(selection.folderState(loci), isTrue);
      expect(selection.entities(tree).map((e) => e.path), [loci.path]);
    });

    test('Unpicking a file unpicks the folders holding it', () {
      final DataUsageFile a = run.files.single;
      final selection = const DataUsageSelection()
          .toggleFolder(tree, run)
          .toggleFile(tree, a);

      expect(selection.folderState(run), isNull);
      expect(selection.folderState(loci), isTrue);
      expect(selection.entities(tree).map((e) => e.path), [loci.path]);
    });

    test('Empty folders can be picked and select all covers them', () {
      final DataUsageFolder empty =
          tree.root.folders.firstWhere((e) => e.name == 'empty_run');
      final selection = const DataUsageSelection().toggleFolder(tree, empty);

      expect(selection.folderState(empty), isTrue);
      expect(selection.files(tree), isEmpty);
      expect(
          DataUsageSelection.all(tree).entities(tree).map(
                (e) => p.basename(e.path),
              ),
          unorderedEquals(['run', 'empty_run', 'segui.log']));
    });

    test('Pruning drops paths that were deleted', () {
      final selection = const DataUsageSelection().toggleFolder(tree, run);
      Directory(run.path).deleteSync(recursive: true);

      final pruned = selection.prune(DataUsageTree.fromDirectory(dir));

      expect(pruned.isEmpty, isTrue);
    });
  });

  group('DataUsageCleaner', () {
    test('Deletes a folder with everything inside it', () async {
      createFile(['run', 'loci', 'b.fas']);
      final Directory run = Directory(p.join(dir.path, 'run'));

      await DataUsageCleaner(root: dir).delete(run);

      expect(run.existsSync(), isFalse);
    });

    test('Refuses to delete outside the data folder', () async {
      final Directory outside =
          Directory.systemTemp.createTempSync('segui-outside-');
      addTearDown(() => outside.deleteSync(recursive: true));

      expect(
        () => DataUsageCleaner(root: dir).delete(outside),
        throwsArgumentError,
      );
      expect(
        () => DataUsageCleaner(root: dir).delete(dir),
        throwsArgumentError,
      );
      expect(outside.existsSync(), isTrue);
    });

    test('Clears everything except the latest log', () async {
      createFile(['old.log'], modified: DateTime(2024, 1, 1));
      final File latest =
          createFile(['segui.log'], modified: DateTime(2026, 1, 1));
      createFile(['run', 'a.nex']);
      createFolder(['empty_run']);

      await DataUsageCleaner(root: dir).clearAll();

      expect(
        dir.listSync().map((e) => p.basename(e.path)),
        [p.basename(latest.path)],
      );
    });
  });

  group('DataUsageTreeCard', () {
    testWidgets('Shows folders and opens them on tap', (tester) async {
      createFile(['run', 'concat.nex']);
      createFolder(['empty_run']);
      final tree = DataUsageTree.fromDirectory(dir);
      final Set<String> expanded = {};

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: SeguiTheme.lightTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => DataUsageTreeCard(
                rows: tree.rows(expanded: expanded, sort: DataUsageSort.name),
                onToggle: (path) => setState(() {
                  if (!expanded.remove(path)) {
                    expanded.add(path);
                  }
                }),
                onSelectFolder: (_) {},
                onSelectFile: (_) {},
              ),
            ),
          ),
        ),
      ));

      expect(find.text('run'), findsOneWidget);
      expect(find.text('empty_run'), findsOneWidget);
      expect(find.text('Empty'), findsOneWidget);
      expect(find.text('concat.nex'), findsNothing);

      await tester.tap(find.text('run'));
      await tester.pump();
      expect(find.text('concat.nex'), findsOneWidget);

      await tester.tap(find.text('empty_run'));
      await tester.pump();
      expect(find.text('No files'), findsOneWidget);
    });

    testWidgets('Shows checkboxes while selecting', (tester) async {
      createFile(['run', 'concat.nex']);
      final tree = DataUsageTree.fromDirectory(dir);
      DataUsageSelection selection = const DataUsageSelection();

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: SeguiTheme.lightTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => DataUsageTreeCard(
                rows: tree.rows(
                  expanded: tree.root.folderPaths.toSet(),
                  sort: DataUsageSort.name,
                ),
                selection: selection,
                onToggle: (_) {},
                onSelectFolder: (folder) => setState(
                    () => selection = selection.toggleFolder(tree, folder)),
                onSelectFile: (file) => setState(
                    () => selection = selection.toggleFile(tree, file)),
              ),
            ),
          ),
        ),
      ));

      expect(find.byType(Checkbox), findsNWidgets(2));
      await tester.tap(find.text('concat.nex'));
      await tester.pump();
      final Checkbox folderBox =
          tester.widget<Checkbox>(find.byType(Checkbox).first);
      expect(folderBox.value, isTrue);
    });
  });

  group('Data usage controls', () {
    Widget wrap(Widget child) {
      return MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: Scaffold(body: child),
      );
    }

    testWidgets('Sort sheet marks the current order and returns a choice',
        (tester) async {
      DataUsageSort? chosen;
      await tester.pumpWidget(wrap(Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            chosen = await showModalBottomSheet<DataUsageSort>(
              context: context,
              builder: (context) =>
                  const DataUsageSortSheet(sort: DataUsageSort.size),
            );
          },
          child: const Text('Open'),
        ),
      )));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.tap(find.text('Recent'));
      await tester.pumpAndSettle();
      expect(chosen, DataUsageSort.recent);
    });

    testWidgets('Export and Delete sit apart and wait for a pick',
        (tester) async {
      await tester.pumpWidget(wrap(const DataUsageSelectionActions(
        onExport: null,
        onDelete: null,
      )));

      final Rect export = tester.getRect(find.text('Export'));
      final Rect delete = tester.getRect(find.text('Delete'));
      expect(delete.left - export.right, greaterThan(200));
      for (final ButtonStyleButton button
          in tester.widgetList<ButtonStyleButton>(find
              .byWidgetPredicate((widget) => widget is ButtonStyleButton))) {
        expect(button.onPressed, isNull);
      }
    });

    testWidgets('Summary shows the format legend', (tester) async {
      createFile(['run', 'a.nex'], size: 2048);
      createFile(['reads.csv'], size: 10);
      final tree = DataUsageTree.fromDirectory(dir);

      await tester.pumpWidget(ProviderScope(
        child: wrap(DataUsageSummary(tree: tree)),
      ));

      expect(find.byType(DataUsageTypeBar), findsOneWidget);
      final Iterable<ColoredBox> segments = tester.widgetList<ColoredBox>(
        find.descendant(
          of: find.byType(DataUsageTypeBar),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(segments, hasLength(2));
      for (final Element segment in find
          .descendant(
            of: find.byType(DataUsageTypeBar),
            matching: find.byType(ColoredBox),
          )
          .evaluate()) {
        expect(tester.getSize(find.byWidget(segment.widget)).height,
            greaterThan(0));
      }
      expect(find.text('NEXUS'), findsOneWidget);
      expect(find.text('CSV'), findsOneWidget);
      expect(find.text('10 B'), findsOneWidget);
    });

    testWidgets('An empty table is as wide as the file card', (tester) async {
      final File csv = createFile(['empty.csv']);
      csv.writeAsStringSync('sample,reads\n');

      await tester.pumpWidget(wrap(TabulatedFileView(file: csv)));
      // The file is read off the test clock, so wait for it in real time.
      for (int i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }

      expect(find.text('Table is empty'), findsOneWidget);
      Finder cardAround(Finder child) => find
          .ancestor(
            of: child,
            matching: find.byWidgetPredicate((widget) =>
                widget is Container && widget.decoration is BoxDecoration),
          )
          .first;
      final double fileCard =
          tester.getSize(cardAround(find.byType(FileIOSubtitle))).width;
      final double tableCard =
          tester.getSize(cardAround(find.text('Table is empty'))).width;
      expect(tableCard, fileCard);
    });
  });
}
