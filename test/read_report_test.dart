import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/read_report.dart';
import 'package:segui/services/providers/read_report.dart';
import 'package:segui/services/viewers/read_report.dart';
import 'package:segui/src/rust/api/reads.dart';
import 'package:segui/styles/themes.dart';

ReadMetricsData _metrics({
  double readCount = 100,
  double q30Pct = 92,
  double meanQscore = 35,
  double nContent = 0.001,
  double? duplicatePct = 12,
  double? adapterReadsPct = 7,
}) {
  return ReadMetricsData(
    readCount: readCount,
    baseCount: readCount * 4,
    minReadLength: 4,
    maxReadLength: 4,
    meanReadLength: 4,
    medianReadLength: 4,
    stdevReadLength: 0,
    n50ReadLength: 4,
    gcContent: 0.5,
    nContent: nContent,
    meanQscore: meanQscore,
    q20Pct: 98,
    q30Pct: q30Pct,
    meanReadQscore: meanQscore,
    lowQualityReads: 0,
    phredOffset: 33,
    duplicatePct: duplicatePct,
    adapterReadsPct: adapterReadsPct,
    polyGReadsPct: duplicatePct == null ? null : 0,
    overrepresentedCount: duplicatePct == null ? null : 1,
  );
}

Float64List _values(List<double> values) => Float64List.fromList(values);

ReadSampleData _sample(String name, ReadMetricsData metrics) {
  final Float64List positions = _values([1, 2, 3, 4]);
  final Float64List quality = _values([30, 32, 34, 36]);
  final Float64List share = _values([25, 25, 25, 25]);
  return ReadSampleData(
    sample: name,
    fileName: '$name.fastq',
    filePath: '$name.fastq',
    metrics: metrics,
    lengthValues: _values([4]),
    lengthCounts: _values([metrics.readCount]),
    readQualityCounts: _values([0, 10, 90]),
    gcCounts: _values([0, 50, 50]),
    gcTheoretical: _values([10, 40, 40]),
    positions: ReadPositionData(
      start: positions,
      end: positions,
      meanQscore: quality,
      p10Qscore: quality,
      q1Qscore: quality,
      medianQscore: quality,
      q3Qscore: quality,
      p90Qscore: quality,
      aPct: share,
      cPct: share,
      gPct: share,
      tPct: share,
      nPct: _values([0, 0, 0, 0]),
    ),
    duplication: ReadDuplicationData(
      sampledReads: metrics.readCount,
      duplicatePct: metrics.duplicatePct ?? 0,
      labels: const ['1', '2'],
      distinctPct: _values([90, 10]),
      readsPct: _values([80, 20]),
    ),
    overrepresented: const [
      OverrepresentedData(
        sequence: 'AGATCGGAAGAG',
        count: 5,
        percent: 5,
        source: 'Illumina Universal',
      ),
    ],
    adapters: [
      AdapterContentData(
        name: 'Illumina Universal',
        sequence: 'AGATCGGAAGAG',
        cumulativePct: _values([0, 1, 2, 3]),
      ),
    ],
  );
}

void main() {
  group('Read quality checks', () {
    test('Thresholds follow FastQC', () {
      expect(statusAbove(85, warn: 80, fail: 70), ReadQcStatus.pass);
      expect(statusAbove(75, warn: 80, fail: 70), ReadQcStatus.warn);
      expect(statusAbove(60, warn: 80, fail: 70), ReadQcStatus.fail);
      expect(statusBelow(4, warn: 5, fail: 10), ReadQcStatus.pass);
      expect(statusBelow(5, warn: 5, fail: 10), ReadQcStatus.warn);
      expect(statusBelow(10, warn: 5, fail: 10), ReadQcStatus.fail);
    });

    test('Complete mode adds checks', () {
      final List<ReadQcCheck> complete = readQcChecks(_sample('a', _metrics()));
      final List<ReadQcCheck> defaults = readQcChecks(
        _sample('a', _metrics(duplicatePct: null, adapterReadsPct: null)),
      );
      expect(complete.length, greaterThan(defaults.length));
      // 7% adapters warns and 5% overrepresented fails.
      expect(overallStatus(complete), ReadQcStatus.fail);
      expect(
        complete.firstWhere((c) => c.name == 'Adapters').status,
        ReadQcStatus.warn,
      );
      expect(overallStatus(defaults), ReadQcStatus.pass);
    });
  });

  test('Read reports are found by name', () {
    expect(isReadReport(File('qc_read-report.json')), isTrue);
    expect(isReadReport(File('read-report.json')), isTrue);
    expect(isReadReport(File('report.json')), isFalse);
  });

  test('Empty samples have no charts', () {
    final ReadReportData report = ReadReportData(samples: [
      _sample('a', _metrics()),
      _sample('empty', _metrics(readCount: 0)),
    ]);
    expect(samplesWithReads(report).map((s) => s.sample), ['a']);
    final ChartPoints points = indexedPoints('a', [3, 4]);
    expect(points.x, [0, 1]);
  });

  testWidgets('Report shows samples and switches tabs', (tester) async {
    final ReadReportData report = ReadReportData(samples: [
      _sample('alpha', _metrics()),
      _sample('beta', _metrics(q30Pct: 60)),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readReportLoaderProvider.overrideWithValue((_) async => report),
        ],
        child: MaterialApp(
          theme: SeguiTheme.lightTheme(),
          home: const Scaffold(body: ReadReportBody(path: 'read-report.json')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('alpha'), findsWidgets);
    expect(find.text('beta'), findsWidgets);
    expect(find.text('Checks for alpha'), findsOneWidget);

    await tester.tap(find.text('Per-base quality'));
    await tester.pumpAndSettle();
    expect(find.text('Quality score'), findsOneWidget);

    // The last tab starts outside the scrollable tab bar.
    await tester.ensureVisible(find.text('Overrepresented'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Overrepresented'));
    await tester.pumpAndSettle();
    expect(find.text('AGATCGGAAGAG'), findsOneWidget);
    expect(find.byTooltip('Copy sequence'), findsOneWidget);
  });
}
