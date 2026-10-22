import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:segui/screens/viewers/alignment/alignment_axes.dart';
import 'package:segui/screens/viewers/alignment/alignment_grid.dart';
import 'package:segui/screens/viewers/alignment/alignment_gull.dart';
import 'package:segui/screens/viewers/alignment/alignment_toolbar.dart';
import 'package:segui/screens/viewers/alignment/alignment_view.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/providers/alignment_view.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';

Uint8List _seq(String residues) => Uint8List.fromList(residues.codeUnits);

AlignmentViewData _data(List<String> rows, {bool isDna = true}) {
  return AlignmentViewData.fromSequences(
    [for (int i = 0; i < rows.length; i++) 'taxon_$i'],
    rows.map(_seq).toList(),
    isDna: isDna,
  );
}

List<Uint8List> _rows(AlignmentViewData data) {
  return (data.residues as MemoryResidues).rows;
}

void main() {
  group('VisibleRange', () {
    test('Covers partly visible items at both edges', () {
      final VisibleRange range = VisibleRange.of(
        offset: 15,
        extent: 30,
        itemSize: 10,
        count: 100,
      );
      expect(range, const VisibleRange(1, 5));
    });

    test('Stops at the item count', () {
      final VisibleRange range = VisibleRange.of(
        offset: 0,
        extent: 500,
        itemSize: 10,
        count: 12,
      );
      expect(range, const VisibleRange(0, 12));
    });

    test('Is empty without a viewport', () {
      final VisibleRange range = VisibleRange.of(
        offset: 0,
        extent: 0,
        itemSize: 10,
        count: 12,
      );
      expect(range.length, 0);
    });
  });

  group('AlignmentChunks', () {
    const AlignmentChunks chunks = AlignmentChunks(length: 2500, size: 1000);

    test('Counts a shorter last chunk', () {
      expect(chunks.count, 3);
      expect(chunks.startOf(2), 2000);
      expect(chunks.endOf(2), 2500);
    });

    test('Maps sites to chunks and clamps', () {
      expect(chunks.chunkOf(0), 0);
      expect(chunks.chunkOf(999), 0);
      expect(chunks.chunkOf(1000), 1);
      expect(chunks.chunkOf(9999), 2);
      expect(chunks.clamp(-1), 0);
      expect(chunks.clamp(5), 2);
    });

    test('Handles an empty alignment', () {
      const AlignmentChunks empty = AlignmentChunks(length: 0, size: 500);
      expect(empty.count, 0);
      expect(empty.chunkOf(10), 0);
      expect(empty.clamp(3), 0);
    });
  });

  group('UngappedIndex', () {
    test('Skips gaps and missing data', () {
      final UngappedIndex index = UngappedIndex([_seq('A--C?G')]);
      expect(index.positionOf(0, 0), 1);
      expect(index.positionOf(0, 1), isNull);
      expect(index.positionOf(0, 3), 2);
      expect(index.positionOf(0, 4), isNull);
      expect(index.positionOf(0, 5), 3);
      expect(index.positionOf(0, 6), isNull);
    });
  });

  group('isAlignmentViewable', () {
    test('Accepts FASTA, NEXUS, and PHYLIP only', () {
      expect(isAlignmentViewable(File(p.join('data', 'locus.FAS'))), isTrue);
      expect(isAlignmentViewable(File(p.join('data', 'locus.nex'))), isTrue);
      expect(isAlignmentViewable(File(p.join('data', 'locus.phy'))), isTrue);
      expect(isAlignmentViewable(File(p.join('data', 'reads.fq'))), isFalse);
      expect(isAlignmentViewable(File(p.join('data', 'reads.gz'))), isFalse);
    });
  });

  group('ResiduePalette', () {
    test('Colors bases apart and gaps alike', () {
      final ResiduePalette palette =
          ResiduePalette.nucleotide(Brightness.light);
      final Set<Color> bases = {
        for (final int code in 'ACGT'.codeUnits) palette.colorOf(code),
      };
      expect(bases, hasLength(4));
      expect(palette.colorOf(0x2D), palette.gap);
      expect(palette.colorOf(0x3F), palette.gap);
      expect(palette.colorOf(0x55), palette.colorOf(0x54));
    });
  });

  group('AlignmentViewSettings', () {
    test('Zoom stays within the cell range', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      final AlignmentViewSettingsNotifier notifier =
          container.read(alignmentViewSettingsProvider.notifier);
      notifier.setCellSize(1000);
      expect(container.read(alignmentViewSettingsProvider).cellSize,
          SeguiAlignmentLayout.cellMax);
      notifier.setCellSize(0);
      expect(container.read(alignmentViewSettingsProvider).cellSize,
          SeguiAlignmentLayout.cellMin);
      expect(container.read(alignmentViewSettingsProvider).rowHeight,
          SeguiAlignmentLayout.rowMin);
    });

    test('Changing chunk size keeps the first site in view', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      final AlignmentViewSettingsNotifier notifier =
          container.read(alignmentViewSettingsProvider.notifier);
      notifier.setChunk(3); // Sites 3,001-4,000.
      notifier.setChunkSize(500);
      expect(container.read(alignmentViewSettingsProvider).chunk, 6);
    });
  });

  group('RowSelection', () {
    final List<int> order = [0, 1, 2, 3, 4];

    test('A plain tap selects one row, and again clears it', () {
      final RowSelection one = const RowSelection().tap(2, order);
      expect(one.rows, {2});
      expect(one.tap(2, order).rows, isEmpty);
      expect(one.tap(3, order).rows, {3});
    });

    test('Shift extends over the display order', () {
      final RowSelection range =
          const RowSelection().tap(1, order).tap(3, order, extend: true);
      expect(range.rows, {1, 2, 3});
      final RowSelection pinned = range.tap(0, [3, 1, 0, 2], extend: true);
      expect(pinned.rows, {0, 1, 2, 3});
    });

    test('Ctrl or Cmd toggles rows', () {
      final RowSelection rows = const RowSelection()
          .tap(0, order, toggle: true)
          .tap(4, order, toggle: true)
          .tap(0, order, toggle: true);
      expect(rows.rows, {4});
    });

    test('Orders pinned and hidden rows', () {
      final RowSelection rows =
          const RowSelection().tap(3, order).tap(1, order, toggle: true);
      expect(rows.orderOf(5), order);
      expect(rows.copyWith(pinSelected: true).orderOf(5), [1, 3, 0, 2, 4]);
      expect(rows.copyWith(showOnlySelected: true).orderOf(5), [1, 3]);
    });

    test('Clearing turns off pinning and filtering', () {
      final RowSelection rows = const RowSelection()
          .tap(3, order)
          .copyWith(showOnlySelected: true, pinSelected: true)
          .tap(3, order);
      expect(rows.isEmpty, isTrue);
      expect(rows.showOnlySelected, isFalse);
      expect(rows.pinSelected, isFalse);
      expect(rows.orderOf(5), order);
    });
  });

  test('fastaOf writes selected sequences in alignment order', () {
    final AlignmentViewData data = _data(['AC-T', 'GGCC', 'TTAA']);
    expect(
      fastaOf(data.names, _rows(data), {2, 0}),
      '>taxon_0\nAC-T\n>taxon_2\nTTAA\n',
    );
  });

  group('AlignmentExplorer', () {
    final AlignmentViewData data = _data([
      for (int i = 0; i < 20; i++) ('ACGT-' * 600).substring(i),
    ]);

    Future<void> pumpExplorer(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: SeguiTheme.lightTheme(),
          home: Scaffold(
            body: AlignmentExplorer(fileName: 'locus.fas', data: data),
          ),
        ),
      ));
      await tester.pump();
    }

    testWidgets('Shows the summary and first chunk', (tester) async {
      await pumpExplorer(tester);
      expect(find.textContaining('20 taxa'), findsOneWidget);
      expect(find.textContaining('3,000 sites'), findsOneWidget);
      expect(find.textContaining('unaligned'), findsOneWidget);
      expect(find.text('1–1,000 (1 of 3)'), findsOneWidget);
    });

    testWidgets('Next chunk pages forward', (tester) async {
      await pumpExplorer(tester);
      await tester.tap(find.byTooltip('Next chunk'));
      await tester.pump();
      await tester.pump();
      expect(find.text('1,001–2,000 (2 of 3)'), findsOneWidget);
    });

    testWidgets('Zoom buttons change the cell size', (tester) async {
      await pumpExplorer(tester);
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(AlignmentExplorer)),
      );
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pump();
      expect(
        container.read(alignmentViewSettingsProvider).cellSize,
        SeguiAlignmentLayout.cellDefault + SeguiAlignmentLayout.cellStep,
      );
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pump();
      expect(
        container.read(alignmentViewSettingsProvider).cellSize,
        SeguiAlignmentLayout.cellDefault - SeguiAlignmentLayout.cellStep,
      );
    });

    testWidgets('Repeated zoom keeps the middle site', (tester) async {
      await pumpExplorer(tester);
      final List<ScrollableState> grid = tester
          .stateList<ScrollableState>(find.descendant(
            of: find.byType(AlignmentGrid),
            matching: find.byWidgetPredicate((w) => w is Scrollable),
          ))
          .toList();
      final ScrollPosition horizontal =
          grid.firstWhere((s) => s.position.axis == Axis.horizontal).position;
      horizontal.jumpTo(5000);
      await tester.pump();
      final double half = horizontal.viewportDimension / 2;
      final double site =
          (horizontal.pixels + half) / SeguiAlignmentLayout.cellDefault;
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pump();
      await tester.pump();
      const double cell =
          SeguiAlignmentLayout.cellDefault - 2 * SeguiAlignmentLayout.cellStep;
      expect((horizontal.pixels + half) / cell, closeTo(site, 1));
    });

    testWidgets('Tapping names selects sequences', (tester) async {
      await pumpExplorer(tester);
      final Finder names = find.byType(AlignmentNames);
      final Offset topLeft = tester.getTopLeft(names);
      const double row = SeguiAlignmentLayout.cellDefault;
      await tester.tapAt(topLeft + const Offset(20, row * 2.5));
      await tester.pump();
      expect(find.text('1 selected'), findsOneWidget);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.tapAt(topLeft + const Offset(20, row * 5.5));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pump();
      expect(find.text('4 selected'), findsOneWidget);
      await tester.tap(find.text('Only selected'));
      await tester.pump();
      final AlignmentGrid grid = tester.widget(find.byType(AlignmentGrid));
      expect(grid.rowOrder, [2, 3, 4, 5]);
      await tester.tap(find.text('Clear'));
      await tester.pump();
      expect(find.textContaining('selected'), findsNothing);
      expect(
        tester.widget<AlignmentGrid>(find.byType(AlignmentGrid)).rowOrder,
        hasLength(20),
      );
    });

    testWidgets('Copy as FASTA copies the selected sequences', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      await pumpExplorer(tester);
      await tester.tapAt(
        tester.getTopLeft(find.byType(AlignmentNames)) + const Offset(20, 4),
      );
      await tester.pump();
      await tester.tap(find.text('Copy as FASTA'));
      await tester.pump();
      expect(copied, startsWith('>taxon_0\nACGT-'));
      expect(find.text('Copied 1 sequence'), findsOneWidget);
    });

    testWidgets('Dragging the divider resizes the names', (tester) async {
      await pumpExplorer(tester);
      double width() => tester.getSize(find.byType(AlignmentNames)).width;
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(AlignmentNameDivider)),
      );
      // Past the drag threshold, so later moves resize one to one.
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      final double start = width();
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      expect(width(), start + 60);
      await gesture.moveBy(const Offset(-1000, 0));
      await tester.pump();
      expect(width(), SeguiAlignmentLayout.nameColumnMin);
      await gesture.up();
      // Let the divider's double-tap timer expire.
      await tester.pump(kDoubleTapTimeout);
    });

    testWidgets('Go to site matches tool form fields and fits its text',
        (tester) async {
      await pumpExplorer(tester);
      final Finder field = find.widgetWithText(TextField, 'Go to site');
      final InputDecorator decorator = tester.widget(
        find.descendant(of: field, matching: find.byType(InputDecorator)),
      );
      final InputBorder border = decorator.decoration.enabledBorder!;
      expect(
        (border as OutlineInputBorder).borderRadius,
        BorderRadius.circular(SeguiFormLayout.fieldRadius),
      );
      final double width = tester.getSize(field).width;
      final double label = tester.getSize(find.text('Go to site')).width;
      expect(width, greaterThan(label));
      expect(width, lessThanOrEqualTo(SeguiAlignmentLayout.siteFieldMax));
    });

    testWidgets('The gull stands on the toolbar and can hold still',
        (tester) async {
      await pumpExplorer(tester);
      final Finder gull = find.byType(AlignmentGull);
      expect(gull, findsOneWidget);
      List<Matrix4> pose() => tester
          .widgetList<Transform>(
            find.descendant(of: gull, matching: find.byType(Transform)),
          )
          .map((t) => t.transform)
          .toList();
      final List<Matrix4> start = pose();
      await tester.pump(const Duration(milliseconds: 1200));
      expect(pose(), isNot(equals(start)));
      final Finder panel = find.ancestor(
        of: find.byType(AlignmentToolbar),
        matching: find.byType(Container),
      );
      final double feet =
          tester.getTopLeft(gull).dy + AlignmentGull.standingHeight;
      expect(feet, closeTo(tester.getTopLeft(panel.first).dy, 0.5));

      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await tester.pump();
      final List<Matrix4> still = pose();
      await tester.pump(const Duration(milliseconds: 1200));
      expect(pose(), equals(still));
    });

    testWidgets('The last sequence clears the panel border', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // Taller than the grid, so it scrolls.
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: SeguiTheme.lightTheme(),
          home: Scaffold(
            body: AlignmentExplorer(
              fileName: 'tall.fas',
              data: _data([for (int i = 0; i < 100; i++) 'ACGT' * 50]),
            ),
          ),
        ),
      ));
      await tester.pump();
      final ScrollPosition vertical = tester
          .stateList<ScrollableState>(find.descendant(
            of: find.byType(AlignmentGrid),
            matching: find.byWidgetPredicate((w) => w is Scrollable),
          ))
          .firstWhere((s) => s.position.axis == Axis.vertical)
          .position;
      const double rows = 100 * SeguiAlignmentLayout.cellDefault;
      expect(
        vertical.maxScrollExtent + vertical.viewportDimension,
        rows + SeguiAlignmentLayout.gridBottomPadding,
      );
    });

    testWidgets('Selection toggles with the platform key', (tester) async {
      Future<void> tapName(int row) => tester.tapAt(
            tester.getTopLeft(find.byType(AlignmentNames)) +
                Offset(20, SeguiAlignmentLayout.cellDefault * (row + 0.5)),
          );
      for (final (
            TargetPlatform platform,
            LogicalKeyboardKey key,
            LogicalKeyboardKey other
          ) in [
        (
          TargetPlatform.macOS,
          LogicalKeyboardKey.metaLeft,
          LogicalKeyboardKey.controlLeft
        ),
        (
          TargetPlatform.linux,
          LogicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.metaLeft
        ),
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        await pumpExplorer(tester);
        await tapName(0);
        await tester.pump();
        // The other platform's key starts a new selection.
        await tester.sendKeyDownEvent(other);
        await tapName(1);
        await tester.sendKeyUpEvent(other);
        await tester.pump();
        expect(find.text('1 selected'), findsOneWidget, reason: '$platform');
        await tester.sendKeyDownEvent(key);
        await tapName(2);
        await tester.sendKeyUpEvent(key);
        await tester.pump();
        expect(find.text('2 selected'), findsOneWidget, reason: '$platform');
        await tester.pumpWidget(const SizedBox());
      }
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Rejects a site outside the alignment', (tester) async {
      await pumpExplorer(tester);
      await tester.enterText(
          find.widgetWithText(TextField, 'Go to site'), '99999');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pump();
      expect(find.text('Enter a site from 1 to 3,000.'), findsOneWidget);
    });
  });
}
