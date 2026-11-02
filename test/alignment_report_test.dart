import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/alignment_report.dart';
import 'package:segui/screens/viewers/alignment_report/items.dart';
import 'package:segui/screens/viewers/report/data_bar.dart';
import 'package:segui/screens/viewers/report/heatmap_cell.dart';
import 'package:segui/screens/viewers/report/metric_bars.dart';
import 'package:segui/screens/viewers/report/paged_table.dart';
import 'package:segui/screens/viewers/tabulated.dart';
import 'package:segui/services/providers/alignment_report.dart';
import 'package:segui/services/viewers/alignment_report.dart';
import 'package:segui/services/viewers/natural_sort.dart';
import 'package:segui/src/rust/api/alignment_report.dart';
import 'package:segui/styles/themes.dart';

Float64List _values(List<double> values) => Float64List.fromList(values);

const SiteTypeData _sites = SiteTypeData(
  loci: 3,
  propLoci: 1,
  sites: 30,
  propSites: 0.5,
  min: 5,
  max: 15,
  mean: 10,
);

/// A DNA report of [count] loci named locus_000, locus_001, ... and three
/// taxa.
AlignReportData _report({int count = 3}) {
  final List<double> index = [for (int i = 0; i < count; i++) i.toDouble()];
  return AlignReportData(
    datatype: 'dna',
    summary: AlignOverviewData(
      taxa: 3,
      loci: count.toDouble(),
      sites: 600,
      chars: 1800,
      missing: 90,
      propMissing: 0.05,
      gc: 0.42,
      at: 0.58,
      minSites: 100,
      maxSites: 300,
      meanSites: 200,
      minTaxa: 2,
      maxTaxa: 3,
      meanTaxa: 2.7,
      conserved: _sites,
      variable: _sites,
      informative: _sites,
    ),
    completenessPercent: _values([100, 95, 90]),
    completenessLoci: _values([1, 2, count.toDouble()]),
    charNames: const ['-', 'A', 'C', 'G', 'T'],
    charCounts: _values([90, 500, 400, 380, 430]),
    loci: AlignLociData(
      names: [for (int i = 0; i < count; i++) 'locus_${'$i'.padLeft(3, '0')}'],
      paths: [for (int i = 0; i < count; i++) 'aln/locus_$i.fas'],
      ntax: _values([for (final double i in index) 2 + i % 2]),
      chars: _values([for (final double i in index) 300 + i]),
      sites: _values([for (final double i in index) 100 + 10 * i]),
      conserved: _values([for (final double i in index) 50 + i]),
      variable: _values([for (final double i in index) 20 + i]),
      informative: _values([for (final double i in index) 5 + i]),
      missing: _values([for (final double i in index) i]),
      propMissing: _values([for (final double i in index) i / 1000]),
      gc: _values([for (final double _ in index) 0.42]),
    ),
    taxa: AlignTaxaData(
      names: const ['alpha', 'beta', 'gamma'],
      loci: _values([3, 2, 3]),
      chars: _values([600, 500, 700]),
      missing: _values([10, 50, 30]),
      propMissing: _values([0.02, 0.1, 0.04]),
      gc: _values([0.4, 0.43, 0.44]),
    ),
  );
}

Future<void> _pumpReport(WidgetTester tester, AlignReportData report) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        alignReportLoaderProvider.overrideWithValue((_) async => report),
      ],
      child: MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: const Scaffold(
          body: AlignmentReportBody(path: 'alignment-report.json'),
        ),
      ),
    ),
  );
}

void main() {
  test('Gaps and missing data are labeled', () {
    expect(characterLabel('-'), '- (gap)');
    expect(characterLabel('?'), '? (missing)');
    expect(characterLabel('A'), 'A');
  });

  group('Alignment report data', () {
    test('Reports are found by name', () {
      expect(isAlignmentReport(File('out/alignment-report.json')), isTrue);
      expect(isAlignmentReport(File('out/x_alignment-report.json')), isTrue);
      expect(isAlignmentReport(File('out/read-report.json')), isFalse);
    });

    test('Whole numbers with few values get one bin each', () {
      final Histogram bins = Histogram.of([2, 3, 3, 4]);
      expect(bins.labels, ['2', '3', '4']);
      expect(bins.counts, [1, 2, 1]);
    });

    test('Wide ranges use round bins', () {
      final Histogram bins = Histogram.of(
        [for (int i = 100; i < 300; i++) i.toDouble()],
        maxBins: 10,
      );
      expect(bins.labels.first, '100-119');
      expect(bins.counts.length, 10);
      expect(bins.counts.reduce((a, b) => a + b), 200);
      final Histogram shares = Histogram.of([0.5, 1.2, 9.9], maxBins: 5);
      expect(shares.labels.first, '0-2');
      expect(shares.counts.reduce((a, b) => a + b), 3);
    });

    test('Items filter by name and sort by value', () {
      const List<String> names = ['gene_a', 'gene_b', 'other'];
      expect(reportItemView(names, query: 'GENE'), [0, 1]);
      final ReportMetric metric = ReportMetric(
        label: 'Sites',
        values: const [1, 3, 2],
        format: (v) => '$v',
      );
      expect(
        reportItemView(names, metric: metric, highestFirst: true),
        [1, 2, 0],
      );
      expect(medianOf([3, 1, 2]), 2);
      expect(medianOf([4, 1, 2, 3]), 2.5);
    });
  });

  testWidgets('Report shows every tab', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pumpReport(tester, _report());
    await tester.pumpAndSettle();

    expect(find.text('Dataset'), findsOneWidget);
    expect(find.text('42.0%'), findsOneWidget);
    expect(find.widgetWithText(StatTile, 'Loci'), findsOneWidget);
    // Dataset and site type tiles share one height, with or without detail.
    final Set<double> heights = {
      for (final Element tile in find.byType(StatTile).evaluate())
        tile.size!.height,
    };
    expect(heights, hasLength(1));

    // Loci as bars, then as a table, and selecting one shows its values.
    await tester.tap(find.text('Loci').first);
    await tester.pumpAndSettle();
    expect(find.byType(MetricBar), findsNWidgets(3));
    expect(find.text('Locus: locus_000'), findsOneWidget);
    await tester.tap(find.widgetWithText(MetricBar, 'locus_002'));
    await tester.pumpAndSettle();
    expect(find.text('Locus: locus_002'), findsOneWidget);
    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();
    expect(find.byType(PagedTable<int>), findsOneWidget);
    expect(find.text('Informative'), findsOneWidget);
    await tester.tap(find.text('Heatmap'));
    await tester.pumpAndSettle();
    expect(find.byType(HeatmapCell), findsWidgets);
    // Only the open locus is outlined, one cell per metric.
    final Iterable<HeatmapCell> outlined = tester
        .widgetList<HeatmapCell>(find.byType(HeatmapCell))
        .where((cell) => cell.selected);
    expect(outlined, hasLength(7));
    expect(find.byType(HeatmapLegend), findsOneWidget);
    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    // The filter narrows the table.
    await tester.enterText(find.byType(TextField), '001');
    await tester.pumpAndSettle();
    expect(find.text('locus_001'), findsOneWidget);
    expect(find.text('locus_000'), findsNothing);

    await tester.tap(find.text('Taxa').first);
    await tester.pumpAndSettle();
    expect(find.text('Taxon: alpha'), findsOneWidget);
    expect(find.byType(MetricBar), findsNWidgets(3));

    await tester.tap(find.text('Distributions'));
    await tester.pumpAndSettle();
    expect(find.text('Locus length'), findsOneWidget);
    expect(find.textContaining('Median 110 across 3 loci'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Large reports page the loci table', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pumpReport(tester, _report(count: 120));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Loci').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();
    expect(find.text('1–50 of 120'), findsOneWidget);
    // Sorting by sites, highest first, puts the longest locus on top.
    await tester.tap(find.text('Sites'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sites'));
    await tester.pumpAndSettle();
    final double top = tester.getTopLeft(find.text('locus_119')).dy;
    final double next = tester.getTopLeft(find.text('locus_118')).dy;
    expect(top, lessThan(next));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Phones scroll the whole tab', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pumpReport(tester, _report());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Loci').first);
    await tester.pumpAndSettle();
    expect(find.byType(ReportItemPanel), findsOneWidget);
    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('CSV table', () {
    test('Names sort naturally', () {
      final List<NaturalText> names = [
        const NaturalText('gene_10'),
        const NaturalText('Gene_2'),
        const NaturalText('gene_1'),
      ]..sort();
      expect(names.map((n) => n.text), ['gene_1', 'Gene_2', 'gene_10']);
    });

    testWidgets('Name columns sort naturally and resize', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: SeguiTheme.lightTheme(),
          home: const Scaffold(
            body: CsvTable(
              content: [
                ['locus', 'sites'],
                ['gene_10', 20],
                ['gene_2', 1500],
                ['gene_1', 7],
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('locus'));
      await tester.pumpAndSettle();
      double top(String text) => tester.getTopLeft(find.text(text)).dy;
      expect(top('gene_1'), lessThan(top('gene_2')));
      expect(top('gene_2'), lessThan(top('gene_10')));

      // Dragging the handle widens the column, and a double tap resets it.
      final Finder handle = find.bySemanticsLabel('Resize locus column');
      final double before = tester.getTopLeft(find.text('sites')).dx;
      await tester.drag(handle, const Offset(120, 0));
      await tester.pumpAndSettle();
      final double after = tester.getTopLeft(find.text('sites')).dx;
      expect(after, closeTo(before + 120, 20));
      await tester.tap(handle);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(handle);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('sites')).dx, closeTo(before, 1));
      expect(tester.takeException(), isNull);
    });

    test('Numeric columns hold only numbers', () {
      final CsvColumnStats numbers = CsvColumnStats.of([3, null, 1.5, '']);
      expect(numbers.isNumeric, isTrue);
      expect(numbers.low, 1.5);
      expect(numbers.high, 3);
      expect(CsvColumnStats.of([1, 'a']).isNumeric, isFalse);
      expect(CsvColumnStats.of([null, '']).isNumeric, isFalse);
    });

    testWidgets('Numbers get data bars and sort', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: SeguiTheme.lightTheme(),
          home: const Scaffold(
            body: CsvTable(
              content: [
                ['locus', 'sites'],
                ['b', 20],
                ['a', 1500],
                ['c', 7],
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1,500'), findsOneWidget);
      expect(find.byType(DataBarCell), findsNWidgets(3));
      await tester.tap(find.text('sites'));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('c')).dy,
        lessThan(tester.getTopLeft(find.text('a')).dy),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
