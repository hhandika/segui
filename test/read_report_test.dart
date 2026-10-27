import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/read_report.dart';
import 'package:segui/screens/viewers/read_report/sample_list.dart';
import 'package:segui/screens/viewers/read_report/summary.dart';
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
      reads: metrics.readCount,
      distinctSequences: metrics.readCount * 0.9,
      duplicatePct: metrics.duplicatePct ?? 0,
      sketchSize: 100000,
      exact: true,
      labels: const ['1', '2'],
      distinctPct: _values([90, 10]),
      readsPct: _values([80, 20]),
    ),
    overrepresented: const [
      OverrepresentedData(
        sequence: 'AGATCGGAAGAG',
        count: 5,
        percent: 5,
        maxErrorPct: 0,
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

  group('Sample list', () {
    final List<ReadSampleData> samples = [
      _sample('s10', _metrics(readCount: 50)),
      _sample('s2', _metrics(readCount: 300, q30Pct: 60)),
      _sample('s1', _metrics(readCount: 100)),
    ];

    test('Names sort naturally', () {
      expect(compareNatural('s2', 's10'), lessThan(0));
      expect(compareNatural('S1', 's1'), 0);
      expect(readSampleView(samples), [2, 1, 0]);
      expect(readSampleView(samples, ascending: false), [0, 1, 2]);
    });

    test('Filters and sorts by metric and status', () {
      expect(readSampleView(samples, query: '1'), [2, 0]);
      expect(
        readSampleView(samples, sort: ReadSampleSort.reads, ascending: false),
        [1, 2, 0],
      );
      // Default-mode samples skip the overrepresented check. s2 fails Q30,
      // so it goes last when passing samples come first.
      final List<ReadSampleData> statuses = [
        _sample('s1', _metrics(duplicatePct: null, adapterReadsPct: null)),
        _sample(
          's2',
          _metrics(q30Pct: 60, duplicatePct: null, adapterReadsPct: null),
        ),
        _sample('s3', _metrics(duplicatePct: null, adapterReadsPct: null)),
      ];
      expect(readSampleView(statuses, sort: ReadSampleSort.status), [0, 2, 1]);
      expect(
        readSampleView(statuses, sort: ReadSampleSort.status, ascending: false)
            .first,
        1,
      );
    });

    test('Steps through the listed samples', () {
      final List<int> view = [2, 1, 0];
      expect(stepThrough(view, 2, 1), 1);
      expect(stepThrough(view, 0, 1), 2);
      expect(stepThrough(view, 2, -1), 0);
      // A filtered-out sample starts at either end.
      expect(stepThrough([1, 0], 2, 1), 1);
      expect(stepThrough([1, 0], 2, -1), 0);
    });

    test('Metrics need every sample', () {
      final List<ReadMetric> complete = ReadMetric.availableFor(samples);
      expect(complete, contains(ReadMetric.duplication));
      final List<ReadMetric> defaults = ReadMetric.availableFor([
        _sample('a', _metrics(duplicatePct: null, adapterReadsPct: null)),
      ]);
      expect(defaults, isNot(contains(ReadMetric.duplication)));
      expect(formatCompact(4100000), '4.1M');
      expect(formatCompact(950), '950');
    });
  });

  testWidgets('Report switches samples like the file list', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final ReadReportData report = ReadReportData(samples: [
      _sample('alpha', _metrics()),
      _sample('beta', _metrics(q30Pct: 60)),
      _sample('gamma', _metrics(readCount: 50)),
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
    // The rail lists every sample and the summary has one bar each.
    expect(find.byType(ReadSampleTile), findsNWidgets(3));
    expect(find.byType(SampleMetricBar), findsNWidgets(3));
    expect(find.text('Checks for alpha'), findsOneWidget);
    expect(find.text('1 of 3'), findsWidgets);

    // A bar opens its sample.
    await tester.tap(find.widgetWithText(SampleMetricBar, 'beta'));
    await tester.pumpAndSettle();
    expect(find.text('Checks for beta'), findsOneWidget);

    // Keyboard and switcher arrows step through the list.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(find.text('Checks for gamma'), findsOneWidget);
    await tester.tap(find.byTooltip(RegExp('^Next sample \\(')).first);
    await tester.pumpAndSettle();
    expect(find.text('Checks for alpha'), findsOneWidget);

    // The table lists the same samples.
    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);

    // The rail filter narrows the list.
    await tester.enterText(find.byType(TextField).first, 'gam');
    await tester.pumpAndSettle();
    expect(find.byType(ReadSampleTile), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quality'));
    await tester.pumpAndSettle();
    expect(find.text('Per-base quality: alpha'), findsOneWidget);

    await tester.tap(find.text('Duplication'));
    await tester.pumpAndSettle();
    expect(find.textContaining('counted exactly'), findsOneWidget);

    await tester.tap(find.text('Overrepresented'));
    await tester.pumpAndSettle();
    expect(find.text('AGATCGGAAGAG'), findsOneWidget);
    expect(find.byTooltip('Copy sequence'), findsOneWidget);

    // Hiding the list leaves the switcher.
    await tester.tap(find.byTooltip('Hide sample list'));
    await tester.pumpAndSettle();
    expect(find.byType(ReadSampleRail), findsNothing);
    expect(find.byType(ReadSampleSwitcher), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Phones show the sample list as a sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final ReadReportData report = ReadReportData(samples: [
      _sample('alpha', _metrics()),
      _sample('beta', _metrics()),
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
    expect(find.byType(ReadSampleRail), findsNothing);
    expect(find.byType(ReadSampleSwitcher), findsOneWidget);
    await tester.tap(find.byTooltip('Show sample list'));
    await tester.pumpAndSettle();
    expect(find.byType(ReadSampleRail), findsOneWidget);
    await tester.tap(find.widgetWithText(ReadSampleTile, 'beta'));
    await tester.pumpAndSettle();
    expect(find.byType(ReadSampleRail), findsNothing);
    expect(find.text('Checks for beta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
