import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/alignment_report.dart';
import 'package:segui/screens/viewers/contig_report.dart';
import 'package:segui/screens/viewers/report/heatmap_cell.dart';
import 'package:segui/screens/viewers/report/metric_bars.dart';
import 'package:segui/services/providers/contig_report.dart';
import 'package:segui/services/viewers/contig_report.dart';
import 'package:segui/src/rust/api/contig_report.dart';
import 'package:segui/styles/themes.dart';

Float64List _values(List<double> values) => Float64List.fromList(values);

/// A report of two samples and three length bins.
ContigReportData _report() {
  return ContigReportData(
    summary: const ContigOverviewData(
      samples: 2,
      contigs: 30,
      bases: 45000,
      nucleotides: 44900,
      nCount: 100,
      unknown: 0,
      gc: 0.42,
      at: 0.58,
      propN: 0.0022,
      minContigs: 10,
      maxContigs: 20,
      meanContigs: 15,
      minN50: 1200,
      maxN50: 2400,
      medianN50: 1800,
      longest: 9000,
    ),
    lengthBins: const ['0-200', '200-500', '500+'],
    samples: ContigSamplesData(
      names: const ['sample_a', 'sample_b'],
      paths: const ['a.fa', 'b.fa'],
      contigs: _values([10, 20]),
      bases: _values([15000, 30000]),
      min: _values([150, 120]),
      max: _values([9000, 8000]),
      mean: _values([1500, 1500]),
      median: _values([1300, 1100]),
      n50: _values([1200, 2400]),
      n75: _values([900, 1500]),
      n90: _values([400, 600]),
      longContigs: _values([6, 12]),
      gc: _values([0.4, 0.44]),
      propN: _values([0.001, 0.003]),
      lengthDistribution: [
        _values([1, 4, 5]),
        _values([2, 8, 10]),
      ],
    ),
  );
}

Future<void> _pumpReport(WidgetTester tester, ContigReportData report) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        contigReportLoaderProvider.overrideWithValue((_) async => report),
      ],
      child: MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: const Scaffold(
          body: ContigReportBody(path: 'contig-report.json'),
        ),
      ),
    ),
  );
}

void main() {
  group('Contig report data', () {
    test('Reports are found by name', () {
      expect(isContigReport(File('out/contig-report.json')), isTrue);
      expect(isContigReport(File('out/run_contig-report.json')), isTrue);
      expect(isContigReport(File('out/alignment-report.json')), isFalse);
    });

    test('Length bins sum over samples', () {
      expect(contigLengthTotals(_report()), [3, 12, 15]);
    });

    test('Each length bin is a metric', () {
      final metrics = lengthMetrics(_report());
      expect(metrics.map((m) => m.label), ['0-200', '200-500', '500+']);
      expect(metrics[2].values, [5, 10]);
    });
  });

  testWidgets('Report shows every tab', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pumpReport(tester, _report());
    await tester.pumpAndSettle();

    expect(find.text('Assemblies'), findsOneWidget);
    expect(find.text('42.0%'), findsOneWidget);
    expect(find.widgetWithText(StatTile, 'Longest contig'), findsOneWidget);
    expect(find.text('Contig length'), findsOneWidget);

    await tester.tap(find.text('Samples').first);
    await tester.pumpAndSettle();
    expect(find.byType(MetricBar), findsNWidgets(2));
    expect(find.text('Sample: sample_a'), findsOneWidget);

    await tester.tap(find.text('Lengths'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Heatmap'));
    await tester.pumpAndSettle();
    expect(find.byType(HeatmapCell), findsNWidgets(6));
    expect(tester.takeException(), isNull);
  });
}
