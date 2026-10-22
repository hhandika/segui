import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:segui/src/rust/api/reads.dart';

/// File name suffix of the read report written by a complete read summary.
const String readReportSuffix = 'read-report.json';

/// Loads a read report from its path.
typedef ReadReportLoader = Future<ReadReportData> Function(String path);

/// Reads `read-report.json` through the Rust bridge.
Future<ReadReportData> loadReadReport(String path) {
  return ReadReportServices(path: path).load();
}

/// Whether [file] is a read report, with or without an output prefix.
bool isReadReport(File file) {
  return p.basename(file.path).endsWith(readReportSuffix);
}

/// Outcome of a quality check, following FastQC conventions.
enum ReadQcStatus {
  pass('Pass'),
  warn('Warn'),
  fail('Fail');

  const ReadQcStatus(this.label);

  final String label;
}

/// One quality check for a sample.
class ReadQcCheck {
  const ReadQcCheck({
    required this.name,
    required this.value,
    required this.status,
  });

  final String name;

  /// Value shown with the check, such as "92.4%".
  final String value;
  final ReadQcStatus status;
}

/// Status for a value where lower is better.
ReadQcStatus statusBelow(double value,
    {required double warn, required double fail}) {
  if (value >= fail) return ReadQcStatus.fail;
  if (value >= warn) return ReadQcStatus.warn;
  return ReadQcStatus.pass;
}

/// Status for a value where higher is better.
ReadQcStatus statusAbove(double value,
    {required double warn, required double fail}) {
  if (value < fail) return ReadQcStatus.fail;
  if (value < warn) return ReadQcStatus.warn;
  return ReadQcStatus.pass;
}

/// Quality checks for [sample]. Checks that need Complete mode statistics
/// are left out when those statistics are missing.
List<ReadQcCheck> readQcChecks(ReadSampleData sample) {
  final ReadMetricsData m = sample.metrics;
  final double topOverrepresented =
      sample.overrepresented.isEmpty ? 0 : sample.overrepresented.first.percent;
  return [
    ReadQcCheck(
      name: 'Q30 bases',
      value: formatPercent(m.q30Pct),
      status: statusAbove(m.q30Pct, warn: 80, fail: 70),
    ),
    ReadQcCheck(
      name: 'Mean quality',
      value: m.meanQscore.toStringAsFixed(1),
      status: statusAbove(m.meanQscore, warn: 28, fail: 20),
    ),
    ReadQcCheck(
      name: 'N content',
      value: formatPercent(100 * m.nContent),
      status: statusBelow(100 * m.nContent, warn: 5, fail: 20),
    ),
    if (m.duplicatePct != null)
      ReadQcCheck(
        name: 'Duplication',
        value: formatPercent(m.duplicatePct!),
        status: statusBelow(m.duplicatePct!, warn: 20, fail: 50),
      ),
    if (m.adapterReadsPct != null)
      ReadQcCheck(
        name: 'Adapters',
        value: formatPercent(m.adapterReadsPct!),
        status: statusBelow(m.adapterReadsPct!, warn: 5, fail: 10),
      ),
    if (m.polyGReadsPct != null)
      ReadQcCheck(
        name: 'Poly-G',
        value: formatPercent(m.polyGReadsPct!),
        status: statusBelow(m.polyGReadsPct!, warn: 5, fail: 10),
      ),
    if (m.overrepresentedCount != null)
      ReadQcCheck(
        name: 'Overrepresented',
        value: formatPercent(topOverrepresented),
        status: statusBelow(topOverrepresented, warn: 0.1, fail: 1),
      ),
  ];
}

/// The worst status among [checks].
ReadQcStatus overallStatus(List<ReadQcCheck> checks) {
  if (checks.any((c) => c.status == ReadQcStatus.fail)) {
    return ReadQcStatus.fail;
  }
  if (checks.any((c) => c.status == ReadQcStatus.warn)) {
    return ReadQcStatus.warn;
  }
  return ReadQcStatus.pass;
}

String formatPercent(double value) => '${value.toStringAsFixed(1)}%';

/// One series of (x, y) points for a chart.
class ChartPoints {
  const ChartPoints({required this.name, required this.x, required this.y});

  final String name;
  final List<double> x;
  final List<double> y;

  bool get isEmpty => x.isEmpty;
}

/// Points from a histogram where the index is the x value.
ChartPoints indexedPoints(String name, List<double> counts) {
  return ChartPoints(
    name: name,
    x: [for (int i = 0; i < counts.length; i++) i.toDouble()],
    y: List<double>.of(counts),
  );
}

/// Samples with at least one read, which are the only ones with charts.
List<ReadSampleData> samplesWithReads(ReadReportData report) {
  return report.samples.where((s) => s.metrics.readCount > 0).toList();
}

/// A per-sample statistic plotted on the summary bars.
enum ReadMetric {
  reads('Reads'),
  bases('Bases'),
  meanLength('Mean length (bp)'),
  n50('N50 (bp)'),
  q30('Q30 bases (%)'),
  meanQuality('Mean quality'),
  gc('GC (%)'),
  duplication('Duplication (%)'),
  adapters('Adapters (%)');

  const ReadMetric(this.label);

  final String label;

  /// The metric for [metrics], or null when the run did not compute it.
  double? valueOf(ReadMetricsData metrics) {
    return switch (this) {
      ReadMetric.reads => metrics.readCount,
      ReadMetric.bases => metrics.baseCount,
      ReadMetric.meanLength => metrics.meanReadLength,
      ReadMetric.n50 => metrics.n50ReadLength,
      ReadMetric.q30 => metrics.q30Pct,
      ReadMetric.meanQuality => metrics.meanQscore,
      ReadMetric.gc => 100 * metrics.gcContent,
      ReadMetric.duplication => metrics.duplicatePct,
      ReadMetric.adapters => metrics.adapterReadsPct,
    };
  }

  /// [value] as shown beside a bar.
  String format(double value) {
    return switch (this) {
      ReadMetric.reads || ReadMetric.bases => formatCompact(value),
      ReadMetric.n50 => value.round().toString(),
      _ => value.toStringAsFixed(1),
    };
  }

  /// Metrics computed for every sample of [samples].
  static List<ReadMetric> availableFor(List<ReadSampleData> samples) {
    return [
      for (final ReadMetric metric in values)
        if (samples.every((s) => metric.valueOf(s.metrics) != null)) metric,
    ];
  }
}

/// A count with a K, M, or G suffix, such as 4.1M.
String formatCompact(double value) {
  const List<(double, String)> units = [(1e9, 'G'), (1e6, 'M'), (1e3, 'K')];
  for (final (double size, String suffix) in units) {
    if (value.abs() >= size) {
      return '${(value / size).toStringAsFixed(1)}$suffix';
    }
  }
  return value.round().toString();
}

/// Orders for the sample list.
enum ReadSampleSort {
  name('Name', 'A to Z', 'Z to A'),
  status('Status', 'Failing last', 'Failing first'),
  reads('Reads', 'Fewest first', 'Most first'),
  q30('Q30 bases', 'Lowest first', 'Highest first');

  const ReadSampleSort(this.label, this.ascending, this.descending);

  final String label;

  /// Names of the two directions in the sort menu.
  final String ascending;
  final String descending;
}

/// Positions in [samples] of those whose name contains [query], ignoring
/// case, ordered by [sort]. Names sort naturally, so `s2` comes before
/// `s10`, and break ties in the other orders.
List<int> readSampleView(
  List<ReadSampleData> samples, {
  String query = '',
  ReadSampleSort sort = ReadSampleSort.name,
  bool ascending = true,
}) {
  final String needle = query.trim().toLowerCase();
  final List<int> view = [
    for (int i = 0; i < samples.length; i++)
      if (samples[i].sample.toLowerCase().contains(needle)) i,
  ];
  int byName(int a, int b) =>
      compareNatural(samples[a].sample, samples[b].sample);
  int status(int i) => overallStatus(readQcChecks(samples[i])).index;
  int byValue(int a, int b) => switch (sort) {
        ReadSampleSort.name => 0,
        ReadSampleSort.status => status(a).compareTo(status(b)),
        ReadSampleSort.reads =>
          samples[a].metrics.readCount.compareTo(samples[b].metrics.readCount),
        ReadSampleSort.q30 =>
          samples[a].metrics.q30Pct.compareTo(samples[b].metrics.q30Pct),
      };

  view.sort((a, b) {
    final int primary = byValue(a, b);
    final int ordered = primary != 0 ? primary : byName(a, b);
    return ascending ? ordered : -ordered;
  });
  return view;
}

/// Compares strings with runs of digits as numbers, ignoring case.
int compareNatural(String a, String b) {
  final RegExp chunks = RegExp(r'\d+|\D+');
  final List<String> left =
      chunks.allMatches(a.toLowerCase()).map((m) => m[0]!).toList();
  final List<String> right =
      chunks.allMatches(b.toLowerCase()).map((m) => m[0]!).toList();
  for (int i = 0; i < left.length && i < right.length; i++) {
    final int? x = int.tryParse(left[i]);
    final int? y = int.tryParse(right[i]);
    final int result =
        x != null && y != null ? x.compareTo(y) : left[i].compareTo(right[i]);
    if (result != 0) return result;
  }
  return left.length.compareTo(right.length);
}

/// Position [delta] steps from [index] through [view], wrapping at both
/// ends. Starts at either end when [index] is filtered out.
int stepThrough(List<int> view, int index, int delta) {
  if (view.isEmpty) return index;
  final int position = view.indexOf(index);
  if (position < 0) return delta > 0 ? view.first : view.last;
  return view[(position + delta) % view.length];
}
