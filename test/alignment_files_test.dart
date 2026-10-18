import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/viewers/alignment/alignment_files.dart';
import 'package:segui/screens/viewers/alignment/alignment_gull.dart';
import 'package:segui/screens/viewers/alignment/alignment_view.dart';
import 'package:segui/screens/viewers/alignment/selected_row_mark.dart';
import 'package:segui/services/providers/alignment_view.dart';
import 'package:segui/services/viewers/alignment_files.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/src/rust/api/file_sort.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';

File _file(String name) => File(p.join('data', name));

AlignmentViewData _data(String path) {
  // Each file gets its own length, so tests can tell them apart.
  final int length = 100 + p.basename(path).length;
  return AlignmentViewData.fromSequences(const [
    'a',
    'b'
  ], [
    Uint8List.fromList(List.filled(length, 0x41)),
    Uint8List.fromList(List.filled(length, 0x43)),
  ]);
}

/// Stand-in for the Rust file order, which needs the native library.
/// Plain text order; natural order is tested in `file_sort.rs`.
List<int> _order(
  List<String> paths,
  FileSortKey key, {
  required bool ascending,
  List<int?> sizes = const [],
}) {
  final List<int> order = List.generate(paths.length, (i) => i);
  int text(int a, int b) {
    final String x = key == FileSortKey.path ? paths[a] : p.basename(paths[a]);
    final String y = key == FileSortKey.path ? paths[b] : p.basename(paths[b]);
    return x.compareTo(y);
  }

  order.sort((a, b) {
    if (key == FileSortKey.size) {
      final int? x = sizes[a];
      final int? y = sizes[b];
      if (x == null || y == null) {
        if (x != y) return x == null ? 1 : -1;
      } else if (x != y) {
        return ascending ? x.compareTo(y) : y.compareTo(x);
      }
    }
    final int byText = text(a, b);
    return byText == 0 ? a.compareTo(b) : (ascending ? byText : -byText);
  });
  return order;
}

void main() {
  group('AlignmentFileList', () {
    final AlignmentFileList files = AlignmentFileList(
      _file('b.nex'),
      order: _order,
      [
        _file('c.fas'),
        _file('notes.txt'),
        _file('a.phy'),
        _file('reads.fq'),
        _file('b.nex'),
      ],
    );

    test('Keeps viewable files once, ordered by path', () {
      expect(files.files.map((f) => p.basename(f.path)),
          ['a.phy', 'b.nex', 'c.fas']);
      expect(files.indexOf(_file('b.nex')), 1);
    });

    test('Includes the open file even when not listed', () {
      final AlignmentFileList alone =
          AlignmentFileList(_file('x.fas'), order: _order, []);
      expect(alone.length, 1);
      expect(alone.indexOf(_file('x.fas')), 0);
    });

    test('Steps wrap at both ends', () {
      expect(files.step(0, -1), 2);
      expect(files.step(2, 1), 0);
      expect(files.step(1, 1), 2);
    });

    test('Filters by name and sorts by size', () {
      expect(files.view(query: 'B.'), [1]);
      final Map<String, int> sizes = {
        files.files[0].path: 10,
        files.files[2].path: 30,
      };
      // Files without a size go last in both directions.
      expect(
        files.view(sort: AlignmentFileSort.size, sizes: sizes),
        [0, 2, 1],
      );
      expect(
        files.view(
          sort: AlignmentFileSort.size,
          ascending: false,
          sizes: sizes,
        ),
        [2, 0, 1],
      );
      expect(files.view(ascending: false), [2, 1, 0]);
    });

    test('Asks the order for paths, then names or sizes', () {
      final List<FileSortKey> keys = [];
      List<int> reversed(
        List<String> paths,
        FileSortKey key, {
        required bool ascending,
        List<int?> sizes = const [],
      }) {
        keys.add(key);
        return List.generate(paths.length, (i) => paths.length - 1 - i);
      }

      final AlignmentFileList list = AlignmentFileList(
        _file('a.fas'),
        [_file('a.fas'), _file('b.fas'), _file('c.fas')],
        order: reversed,
      );
      expect(list.files.map((f) => p.basename(f.path)),
          ['c.fas', 'b.fas', 'a.fas']);
      // Filtered positions map back to the full list.
      expect(list.view(query: 'a.'), [2]);
      list.view(sort: AlignmentFileSort.size);
      expect(keys, [FileSortKey.path, FileSortKey.name, FileSortKey.size]);
    });

    test('Equal by paths', () {
      expect(
        AlignmentFileList(_file('a.phy'), order: _order, [_file('c.fas')]),
        AlignmentFileList(_file('c.fas'), order: _order, [_file('a.phy')]),
      );
    });
  });

  group('AlignmentFileView', () {
    Future<void> pumpView(WidgetTester tester, {Size? size}) async {
      tester.view.physicalSize = size ?? const Size(1600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          fileOrderProvider.overrideWithValue(_order),
          alignmentDataProvider.overrideWith((ref, path) async => _data(path)),
          alignmentFileSizesProvider.overrideWith((ref, files) async => {
                for (final File f in files.files) f.path: f.path.length,
              }),
        ],
        child: MaterialApp(
          theme: SeguiTheme.lightTheme(),
          home: AlignmentFileView(
            file: _file('b.nex'),
            siblings: [_file('a.phy'), _file('b.nex'), _file('cc.fas')],
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();
    }

    ProviderContainer containerOf(WidgetTester tester) =>
        ProviderScope.containerOf(
          tester.element(find.byType(AlignmentFileView)),
        );

    testWidgets('Arrows and shortcuts switch files', (tester) async {
      await pumpView(tester);
      expect(find.text('2 of 3'), findsOneWidget);
      expect(find.textContaining('105 sites'), findsOneWidget);

      await tester.tap(find.byTooltip('Next file (Alt + ↓)'));
      await tester.pump();
      await tester.pump();
      expect(find.text('3 of 3'), findsOneWidget);
      expect(find.textContaining('106 sites'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();
      await tester.pump();
      expect(find.text('1 of 3'), findsOneWidget);
    });

    testWidgets('Settings carry over and selections reset', (tester) async {
      await pumpView(tester);
      final ProviderContainer container = containerOf(tester);
      await tester.tap(find.byTooltip('Zoom in'));
      container.read(alignmentRowSelectionProvider.notifier).tap(0, [0, 1]);
      await tester.pump();
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous file (Alt + ↑)'));
      await tester.pump();
      await tester.pump();
      expect(find.text('1 of 3'), findsOneWidget);
      expect(
        container.read(alignmentViewSettingsProvider).cellSize,
        SeguiAlignmentLayout.cellDefault + SeguiAlignmentLayout.cellStep,
      );
      expect(find.textContaining('selected'), findsNothing);
    });

    testWidgets('File list filters and opens files', (tester) async {
      await pumpView(tester);
      expect(find.byType(AlignmentFileRail), findsNothing);
      await tester.tap(find.byTooltip('Show file list'));
      await tester.pump();
      expect(find.byType(AlignmentFileRail), findsOneWidget);
      expect(find.text('3 of 3 files'), findsOneWidget);
      expect(find.text('Alt + ↑ / ↓ to switch files'), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byType(AlignmentFileRail),
          matching: find.byType(TextField),
        ),
        'cc',
      );
      await tester.pump();
      expect(find.text('1 of 3 files'), findsOneWidget);
      await tester.tap(find.descendant(
        of: find.byType(AlignmentFileRail),
        matching: find.text('cc.fas'),
      ));
      await tester.pump();
      await tester.pump();
      expect(find.text('3 of 3'), findsOneWidget);
    });

    List<String> listedNames(WidgetTester tester) => tester
        .widgetList<ListTile>(find.descendant(
          of: find.byType(AlignmentFileRail),
          matching: find.byType(ListTile),
        ))
        .map((tile) => (tile.title! as Text).data!)
        .toList();

    testWidgets('The open file is marked on its left only', (tester) async {
      await pumpView(tester);
      await tester.tap(find.byTooltip('Show file list'));
      await tester.pump();
      await tester.pump();
      final Finder marks = find.descendant(
        of: find.byType(AlignmentFileRail),
        matching: find.byType(SelectedRowMark),
      );
      expect(
        tester
            .widgetList<SelectedRowMark>(marks)
            .where((mark) => mark.isSelected),
        hasLength(1),
      );
      // No tile switches to the selected colors.
      expect(
        tester
            .widgetList<ListTile>(find.descendant(
              of: find.byType(AlignmentFileRail),
              matching: find.byType(ListTile),
            ))
            .any((tile) => tile.selected),
        isFalse,
      );
    });

    testWidgets('The gull hides when it does not fit', (tester) async {
      await pumpView(tester);
      expect(find.byType(AlignmentGull), findsOneWidget);

      // With the file list open, a 750 px window leaves no room for it.
      await pumpView(tester, size: const Size(750, 1200));
      expect(find.byType(AlignmentGull), findsOneWidget);
      await tester.tap(find.byTooltip('Show file list'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(AlignmentGull), findsNothing);
      expect(find.byType(AlignmentFileSwitcher), findsOneWidget);
    });

    testWidgets('Apple platforms name Option and Cmd', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await pumpView(tester);
      expect(find.byTooltip('Previous file (Option + ↑)'), findsOneWidget);
      expect(find.textContaining('Cmd + scroll to zoom'), findsOneWidget);
      await tester.tap(find.byTooltip('Show file list'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Option + ↑ / ↓ to switch files'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('The sort menu orders the file list', (tester) async {
      await pumpView(tester);
      await tester.tap(find.byTooltip('Show file list'));
      await tester.pump();
      await tester.pump();
      expect(listedNames(tester), ['a.phy', 'b.nex', 'cc.fas']);
      await tester.tap(find.byTooltip('Sort files'));
      await tester.pump();
      await tester.tap(find.text('Sort by size'));
      // The menu runs its action after it closes.
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byTooltip('Sort files'));
      await tester.pump();
      await tester.tap(find.text('Largest first'));
      await tester.pump();
      await tester.pump();
      // Sizes are path lengths here, so the longest name comes first.
      expect(listedNames(tester).first, 'cc.fas');
      expect(
        containerOf(tester).read(alignmentViewSettingsProvider).fileSort,
        AlignmentFileSort.size,
      );
    });

    testWidgets('Phones sort from a bottom sheet', (tester) async {
      await pumpView(tester, size: const Size(390, 900));
      await tester.tap(find.byTooltip('Show file list'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byTooltip('Sort files'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Sort files'), findsWidgets);
      expect(find.byType(MenuItemButton), findsNothing);
      await tester.tap(find.text('Sort by size'));
      await tester.pump();
      // The sheet stays open, so the direction can be set too.
      await tester.tap(find.text('Largest first'));
      await tester.pump();
      await tester.tap(find.text('Done'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(listedNames(tester).first, 'cc.fas');
    });

    testWidgets('Phones show the file list as a sheet', (tester) async {
      await pumpView(tester, size: const Size(390, 900));
      await tester.tap(find.byTooltip('Show file list'));
      // The gull never settles, so pump past the sheet animation instead.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final Finder rail = find.byType(AlignmentFileRail);
      expect(rail, findsOneWidget);
      await tester.tap(find.descendant(of: rail, matching: find.text('a.phy')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(AlignmentFileRail), findsNothing);
      // Phones show the name without the count.
      expect(
        find.descendant(
          of: find.byType(AlignmentFileSwitcher),
          matching: find.text('a.phy'),
        ),
        findsOneWidget,
      );
      expect(find.text('1 of 3'), findsNothing);
    });
  });
}
