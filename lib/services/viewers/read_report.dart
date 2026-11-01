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
    required this.rule,
  });

  ReadQcCheck.of({
    required this.name,
    required double measured,
    required this.value,
    required this.rule,
  }) : status = rule.statusOf(measured);

  final String name;

  /// Value shown with the check, such as "92.4%".
  final String value;
  final ReadQcStatus status;

  /// Thresholds that set [status].
  final ReadQcRule rule;
}

/// Thresholds of a quality check and what it measures.
class ReadQcRule {
  const ReadQcRule({
    required this.description,
    required this.warn,
    required this.fail,
    required this.higherIsBetter,
    this.unit = '',
  });

  final String description;
  final double warn;
  final double fail;
  final bool higherIsBetter;

  /// Suffix of values, such as "%".
  final String unit;

  ReadQcStatus statusOf(double value) => higherIsBetter
      ? statusAbove(value, warn: warn, fail: fail)
      : statusBelow(value, warn: warn, fail: fail);

  /// The range of values for each status, from pass to fail.
  List<(ReadQcStatus, String)> get ranges {
    final String w = _format(warn);
    final String f = _format(fail);
    return higherIsBetter
        ? [
            (ReadQcStatus.pass, '$w or higher'),
            (ReadQcStatus.warn, '$f to below $w'),
            (ReadQcStatus.fail, 'Below $f'),
          ]
        : [
            (ReadQcStatus.pass, 'Below $w'),
            (ReadQcStatus.warn, '$w to below $f'),
            (ReadQcStatus.fail, '$f or higher'),
          ];
  }

  String _format(double value) {
    final String number = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
    return '$number$unit';
  }
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
    ReadQcCheck.of(
      name: 'Q30 bases',
      measured: m.q30Pct,
      value: formatPercent(m.q30Pct),
      rule: const ReadQcRule(
        description: 'Share of bases with a quality score of 30 or more, '
            'a 1 in 1,000 chance of a wrong base call.',
        warn: 80,
        fail: 70,
        higherIsBetter: true,
        unit: '%',
      ),
    ),
    ReadQcCheck.of(
      name: 'Mean quality',
      measured: m.meanQscore,
      value: m.meanQscore.toStringAsFixed(1),
      rule: const ReadQcRule(
        description: 'Mean quality score of every base, following the '
            'FastQC quality zones.',
        warn: 28,
        fail: 20,
        higherIsBetter: true,
      ),
    ),
    ReadQcCheck.of(
      name: 'N content',
      measured: 100 * m.nContent,
      value: formatPercent(100 * m.nContent),
      rule: const ReadQcRule(
        description: 'Share of bases called as N, where the sequencer '
            'could not tell the base.',
        warn: 5,
        fail: 20,
        higherIsBetter: false,
        unit: '%',
      ),
    ),
    if (m.duplicatePct != null)
      ReadQcCheck.of(
        name: 'Duplication',
        measured: m.duplicatePct!,
        value: formatPercent(m.duplicatePct!),
        rule: const ReadQcRule(
          description: 'Share of reads that repeat another read. High '
              'duplication can mean low library complexity or PCR '
              'over-amplification.',
          warn: 20,
          fail: 50,
          higherIsBetter: false,
          unit: '%',
        ),
      ),
    if (m.adapterReadsPct != null)
      ReadQcCheck.of(
        name: 'Adapters',
        measured: m.adapterReadsPct!,
        value: formatPercent(m.adapterReadsPct!),
        rule: const ReadQcRule(
          description: 'Share of reads with a known adapter sequence. '
              'High values suggest the reads need trimming.',
          warn: 5,
          fail: 10,
          higherIsBetter: false,
          unit: '%',
        ),
      ),
    if (m.polyGReadsPct != null)
      ReadQcCheck.of(
        name: 'Poly-G',
        measured: m.polyGReadsPct!,
        value: formatPercent(m.polyGReadsPct!),
        rule: const ReadQcRule(
          description: 'Share of reads ending in a run of G, which '
              'two-color sequencers call when the signal is lost.',
          warn: 5,
          fail: 10,
          higherIsBetter: false,
          unit: '%',
        ),
      ),
    if (m.overrepresentedCount != null)
      ReadQcCheck.of(
        name: 'Overrepresented',
        measured: topOverrepresented,
        value: formatPercent(topOverrepresented),
        rule: const ReadQcRule(
          description: 'Share of reads from the most common read start. '
              'Overrepresented sequences can be adapters, primers, or '
              'contamination.',
          warn: 0.1,
          fail: 1,
          higherIsBetter: false,
          unit: '%',
        ),
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

/// Reports with more samples than this summarize them on comparison charts
/// instead of drawing one line per sample.
const int maxOverlaidSamples = 10;

/// Most outlier samples drawn on a band chart, before it gets crowded.
const int maxSpreadOutliers = 8;

/// Points as a share of their total, in percent, so samples of different
/// depths compare.
ChartPoints sharePoints(ChartPoints counts) {
  final double total = counts.y.fold(0, (a, b) => a + b);
  return ChartPoints(
    name: counts.name,
    x: counts.x,
    y: [for (final double y in counts.y) total > 0 ? 100 * y / total : 0],
  );
}

/// Values of many samples on a shared x grid: one row per sample, one
/// column per x value. Cells without a value are null.
class SampleMatrix {
  const SampleMatrix({required this.x, required this.values});

  /// Every x value of any sample, ascending.
  final List<double> x;
  final List<List<double?>> values;

  /// Aligns [samples] on the x values of all of them. With [missingIsZero],
  /// x values a sample lacks count as zero, as in histograms; otherwise
  /// they stay empty, as past the end of shorter reads.
  factory SampleMatrix.of(
    List<ChartPoints> samples, {
    required bool missingIsZero,
  }) {
    final List<double> x = {
      for (final ChartPoints s in samples) ...s.x,
    }.toList()
      ..sort();
    final Map<double, int> column = {
      for (int i = 0; i < x.length; i++) x[i]: i,
    };
    final List<List<double?>> values = [
      for (final ChartPoints s in samples)
        () {
          final List<double?> row =
              List<double?>.filled(x.length, missingIsZero ? 0 : null);
          for (int i = 0; i < s.x.length; i++) {
            row[column[s.x[i]]!] = s.y[i];
          }
          return row;
        }(),
    ];
    return SampleMatrix(x: x, values: values);
  }

  /// Largest value of any cell, or zero.
  double get maxValue {
    double largest = 0;
    for (final List<double?> row in values) {
      for (final double? v in row) {
        if (v != null && v > largest) largest = v;
      }
    }
    return largest;
  }
}

/// How samples spread at each x: percentiles across samples, and the
/// samples furthest from the median.
class SampleSpread {
  const SampleSpread({
    required this.x,
    required this.p10,
    required this.q1,
    required this.median,
    required this.q3,
    required this.p90,
    required this.outliers,
  });

  final List<double> x;
  final List<double> p10;
  final List<double> q1;
  final List<double> median;
  final List<double> q3;
  final List<double> p90;

  /// Rows of the matrix that sit far from the median, most distant first.
  final List<int> outliers;

  /// Percentiles of each column of [matrix]. Outliers are samples whose
  /// mean distance from the median is above the Tukey fence of all
  /// samples, at most [maxSpreadOutliers] of them.
  factory SampleSpread.of(SampleMatrix matrix) {
    final List<double> x = [];
    final List<List<double>> rows = [[], [], [], [], []];
    const List<double> levels = [0.1, 0.25, 0.5, 0.75, 0.9];
    for (int col = 0; col < matrix.x.length; col++) {
      final List<double> column = [
        for (final List<double?> row in matrix.values)
          if (row[col] != null) row[col]!,
      ]..sort();
      if (column.isEmpty) continue;
      x.add(matrix.x[col]);
      for (int i = 0; i < levels.length; i++) {
        rows[i].add(_percentile(column, levels[i]));
      }
    }
    return SampleSpread(
      x: x,
      p10: rows[0],
      q1: rows[1],
      median: rows[2],
      q3: rows[3],
      p90: rows[4],
      outliers: _outliers(matrix, rows[2]),
    );
  }

  static List<int> _outliers(SampleMatrix matrix, List<double> median) {
    // The median row skips empty columns, so map columns to its entries.
    final Map<double, double> medianAt = {};
    int next = 0;
    for (int col = 0; col < matrix.x.length; col++) {
      if (matrix.values.any((row) => row[col] != null)) {
        medianAt[matrix.x[col]] = median[next++];
      }
    }
    final List<double> distance = [
      for (final List<double?> row in matrix.values)
        () {
          double sum = 0;
          int count = 0;
          for (int col = 0; col < row.length; col++) {
            final double? v = row[col];
            if (v == null) continue;
            sum += (v - medianAt[matrix.x[col]]!).abs();
            count++;
          }
          return count == 0 ? 0.0 : sum / count;
        }(),
    ];
    if (distance.length < 4) return const [];
    final List<double> sorted = List<double>.of(distance)..sort();
    final double q1 = _percentile(sorted, 0.25);
    final double q3 = _percentile(sorted, 0.75);
    final double fence = q3 + 1.5 * (q3 - q1);
    final List<int> outliers = [
      for (int i = 0; i < distance.length; i++)
        if (distance[i] > fence) i,
    ]..sort((a, b) => distance[b].compareTo(distance[a]));
    return outliers.take(maxSpreadOutliers).toList();
  }
}

/// Linear interpolation between the closest ranks of [sorted].
double _percentile(List<double> sorted, double level) {
  final double rank = (sorted.length - 1) * level;
  final int low = rank.floor();
  final int high = rank.ceil();
  return sorted[low] + (sorted[high] - sorted[low]) * (rank - low);
}
