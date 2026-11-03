import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/distance_report.dart';
import 'package:segui/screens/viewers/distance_report/matrix.dart';
import 'package:segui/screens/viewers/report/heatmap_cell.dart';
import 'package:segui/screens/viewers/report/metric_bars.dart';
import 'package:segui/services/providers/distance_report.dart';
import 'package:segui/services/viewers/distance_report.dart';
import 'package:segui/src/rust/api/distance_report.dart';
import 'package:segui/styles/themes.dart';

Float64List _values(List<double> values) => Float64List.fromList(values);

/// A matrix of [names] with [values] row by row.
DistanceMatrixData _matrix(List<String> names, List<double> values) {
  return DistanceMatrixData(names: names, values: _values(values));
}

/// Three samples in two groups over two loci. The second locus has one
/// sample, so its statistics are missing.
DistanceReportData _report() {
  const List<String> samples = ['sp1_a', 'sp1_b', 'sp2_a'];
  return DistanceReportData(
    datatype: 'dna',
    model: 'K2P',
    summary: const DistanceOverviewData(
      loci: 2,
      samples: 3,
      pairs: 3,
      undefinedPairs: 0,
      min: 0.01,
      max: 0.2,
      mean: 0.12,
      sd: 0.1,
      medianLocusMean: 0.12,
      meanComparedSites: 100,
      groups: 2,
      unassigned: 0,
    ),
    binWidth: 0.001,
    histogram:
        _values([for (int i = 0; i <= 200; i++) i == 10 || i >= 180 ? 1 : 0]),
    loci: DistanceLociData(
      names: const ['locus_1', 'locus_2'],
      paths: const ['aln/locus_1.fas', 'aln/locus_2.fas'],
      ntax: _values([3, 1]),
      nchar: _values([100, 80]),
      pairs: _values([3, 0]),
      undefinedPairs: _values([0, 0]),
      mean: _values([0.12, double.nan]),
      median: _values([0.15, double.nan]),
      sd: _values([0.1, double.nan]),
      min: _values([0.01, double.nan]),
      max: _values([0.2, double.nan]),
      meanComparedSites: _values([100, double.nan]),
    ),
    samples: DistanceSamplesData(
      names: samples,
      groups: const ['sp1', 'sp1', 'sp2'],
      loci: _values([2, 1, 1]),
      pairs: _values([2, 2, 2]),
      mean: _values([0.08, 0.105, 0.175]),
      sd: _values([0.1, 0.1, 0.03]),
      min: _values([0.01, 0.01, 0.15]),
      max: _values([0.15, 0.2, 0.2]),
      nearest: const ['sp1_b', 'sp1_a', 'sp1_a'],
      nearestDistance: _values([0.01, 0.01, 0.15]),
      maxWithin: _values([0.01, 0.01, double.nan]),
      minBetween: _values([0.15, 0.2, 0.15]),
    ),
    matrix: _matrix(samples, [0, 0.01, 0.15, 0.01, 0, 0.2, 0.15, 0.2, 0]),
    groups: DistanceGroupsData(
      names: const ['sp1', 'sp2'],
      samples: _values([2, 1]),
      pairs: _values([1, 0]),
      meanWithin: _values([0.01, double.nan]),
      sdWithin: _values([double.nan, double.nan]),
      maxWithin: _values([0.01, double.nan]),
      matrix: _matrix(const ['sp1', 'sp2'], [0.01, 0.175, 0.175, double.nan]),
    ),
  );
}

Future<void> _pumpReport(WidgetTester tester, DistanceReportData report) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        distanceReportLoaderProvider.overrideWithValue((_) async => report),
      ],
      child: MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: const Scaffold(
          body: DistanceReportBody(path: 'distance-report.json'),
        ),
      ),
    ),
  );
}

void main() {
  group('Distance report data', () {
    test('Reports are found by name', () {
      expect(isDistanceReport(File('out/distance-report.json')), isTrue);
      expect(isDistanceReport(File('out/k2p_distance-report.json')), isTrue);
      expect(isDistanceReport(File('out/alignment-report.json')), isFalse);
    });

    test('Distances show four decimals or a dash', () {
      expect(formatDistance(0.123456), '0.1235');
      expect(formatDistance(double.nan), '–');
    });

    test('Fine bins join into round bars', () {
      final DistanceBars bars = DistanceBars.of(
        _values([for (int i = 0; i <= 200; i++) 1]),
        0.001,
      );
      expect(bars.labels.first, '0.00-0.02');
      expect(bars.counts.length, lessThanOrEqualTo(distanceHistogramBars));
      expect(bars.counts.reduce((a, b) => a + b), 201);
      expect(DistanceBars.of(_values([]), 0.001).counts, isEmpty);
    });

    test('Matrix range leaves out the diagonal and missing values', () {
      final DistanceReportData report = _report();
      expect(matrixRange(report.matrix!), (0.01, 0.2));
      expect(matrixValue(report.matrix!, 2, 1), 0.2);
      expect(nearestGroupMeans(report.groups!), [0.175, 0.175]);
      expect(matrixRange(_matrix(const ['a'], [0])), isNull);
    });
  });

  testWidgets('Report shows every tab', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pumpReport(tester, _report());
    await tester.pumpAndSettle();

    expect(find.text('Dataset'), findsOneWidget);
    expect(find.text('K2P'), findsOneWidget);
    expect(find.text('Pairwise distances'), findsOneWidget);

    // A locus without pairs shows dashes, not a broken bar.
    await tester.tap(find.text('Loci').first);
    await tester.pumpAndSettle();
    expect(find.text('Locus: locus_1'), findsOneWidget);
    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();
    expect(find.text('–'), findsWidgets);

    await tester.tap(find.text('Samples').first);
    await tester.pumpAndSettle();
    expect(find.text('Sample: sp1_a'), findsOneWidget);

    await tester.tap(find.text('Groups').first);
    await tester.pumpAndSettle();
    expect(find.text('Group: sp1'), findsOneWidget);

    // The nearest samples to the chosen one, nearest first.
    await tester.tap(find.text('Matrix').first);
    await tester.pumpAndSettle();
    expect(find.byType(DistanceMatrixPanel), findsOneWidget);
    final List<String> nearest = [
      for (final MetricBar bar in tester.widgetList<MetricBar>(
        find.byType(MetricBar),
      ))
        bar.name,
    ];
    expect(nearest, ['sp1_b', 'sp2_a']);
    await tester.tap(find.text('Heatmap'));
    await tester.pumpAndSettle();
    expect(find.byType(HeatmapCell), findsNWidgets(6));
    expect(
      find.text('Colors run from the lowest to the highest distance.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Group matrix').first);
    await tester.pumpAndSettle();
    expect(find.byType(DistanceMatrixPanel), findsOneWidget);
  });

  testWidgets('Large matrices show only the nearest samples', (tester) async {
    final List<String> names = [
      for (int i = 0; i <= maxHeatmapItems; i++) 's$i',
    ];
    final int n = names.length;
    await tester.pumpWidget(
      MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: Scaffold(
          body: DistanceMatrixPanel(
            matrix: _matrix(names, [
              for (int i = 0; i < n * n; i++) (i ~/ n - i % n).abs() / n,
            ]),
            itemLabel: 'Sample',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Heatmap'), findsNothing);
    expect(find.byType(MetricBar), findsWidgets);
  });
}
