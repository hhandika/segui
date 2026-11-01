import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;
import 'package:segui/src/rust/api/alignment_report.dart';

/// File name suffix of the report written by the alignment summary.
const String alignmentReportSuffix = 'alignment-report.json';

/// Loads an alignment report from its path.
typedef AlignReportLoader = Future<AlignReportData> Function(String path);

/// Reads `alignment-report.json` through the Rust bridge.
Future<AlignReportData> loadAlignmentReport(String path) {
  return AlignReportServices(path: path).load();
}

/// Whether [file] is an alignment report, with or without an output prefix.
bool isAlignmentReport(File file) {
  return p.basename(file.path).endsWith(alignmentReportSuffix);
}

/// One numeric column of loci or taxa in the alignment report, with how
/// to show its values.
class ReportMetric {
  const ReportMetric({
    required this.label,
    required this.values,
    required this.format,
    this.width = 130,
  });

  final String label;

  /// One value per locus or taxon, in report order.
  final List<double> values;
  final String Function(double value) format;

  /// Width of the metric's table column.
  final double width;
}

/// Positions of [names] that contain [query], ignoring case, in report
/// order, or highest [metric] value first when [highestFirst] is set.
List<int> reportItemView(
  List<String> names, {
  String query = '',
  ReportMetric? metric,
  bool highestFirst = false,
}) {
  final String needle = query.trim().toLowerCase();
  final List<int> view = [
    for (int i = 0; i < names.length; i++)
      if (needle.isEmpty || names[i].toLowerCase().contains(needle)) i,
  ];
  if (highestFirst && metric != null) {
    view.sort((a, b) => metric.values[b].compareTo(metric.values[a]));
  }
  return view;
}

/// Counts of values in ranges of equal width, for a histogram.
class Histogram {
  const Histogram({required this.labels, required this.counts});

  /// Range of each bin, such as "120-139".
  final List<String> labels;
  final List<double> counts;

  /// Bins of [values] in at most [maxBins] ranges of a round width. Whole
  /// numbers with few distinct values get one bin per value.
  factory Histogram.of(
    List<double> values, {
    int maxBins = 12,
    String Function(double value)? format,
  }) {
    final String Function(double) show = format ?? _formatBound;
    if (values.isEmpty) return const Histogram(labels: [], counts: []);
    final double low = values.reduce((a, b) => a < b ? a : b);
    final double high = values.reduce((a, b) => a > b ? a : b);
    final bool isWhole = values.every((v) => v == v.roundToDouble());
    if (isWhole && high - low + 1 <= maxBins) {
      final int start = low.toInt();
      final List<double> counts = List<double>.filled(
        high.toInt() - start + 1,
        0,
      );
      for (final double v in values) {
        counts[v.toInt() - start]++;
      }
      return Histogram(
        labels: [for (int i = 0; i < counts.length; i++) show(start + i + 0.0)],
        counts: counts,
      );
    }
    double width = _roundStep((high - low) / maxBins);
    if (isWhole && width < 1) width = 1;
    final double start = (low / width).floor() * width;
    final int bins = ((high - start) / width).floor() + 1;
    final List<double> counts = List<double>.filled(bins, 0);
    for (final double v in values) {
      counts[((v - start) / width).floor().clamp(0, bins - 1)]++;
    }
    return Histogram(
      labels: [
        for (int i = 0; i < bins; i++)
          isWhole
              ? '${show(start + i * width)}-${show(start + (i + 1) * width - 1)}'
              : '${show(start + i * width)}-${show(start + (i + 1) * width)}',
      ],
      counts: counts,
    );
  }

  /// A width of 1, 2, or 5 times a power of ten at least [raw].
  static double _roundStep(double raw) {
    if (raw <= 0) return 1;
    final double scale =
        math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    for (final double step in [1, 2, 5, 10]) {
      if (step * scale >= raw) return step * scale;
    }
    return 10 * scale;
  }

  static String _formatBound(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }
}

/// The middle value of [values], or zero when there are none.
double medianOf(List<double> values) {
  if (values.isEmpty) return 0;
  final List<double> sorted = List<double>.of(values)..sort();
  final int mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}

/// Chart label of an alignment character, naming gaps (`-`) and missing
/// data (`?`).
String characterLabel(String character) {
  return switch (character) {
    '-' => '- (gap)',
    '?' => '? (missing)',
    _ => character,
  };
}
