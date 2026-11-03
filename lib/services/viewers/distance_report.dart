import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;
import 'package:segui/src/rust/api/distance_report.dart';

/// File name suffix of the report written by the genetic distance tool.
const String distanceReportSuffix = 'distance-report.json';

/// Most bars in the pairwise distance histogram.
const int distanceHistogramBars = 20;

/// Loads a distance report from its path.
typedef DistanceReportLoader = Future<DistanceReportData> Function(
  String path,
);

/// Reads `distance-report.json` through the Rust bridge.
Future<DistanceReportData> loadDistanceReport(String path) {
  return DistanceReportServices(path: path).load();
}

/// Whether [file] is a distance report, with or without an output prefix.
bool isDistanceReport(File file) {
  return p.basename(file.path).endsWith(distanceReportSuffix);
}

/// A distance with four decimals, or a dash when there is none.
String formatDistance(double value) {
  return value.isFinite ? value.toStringAsFixed(4) : '–';
}

/// The value of items [row] and [column] in [matrix].
double matrixValue(DistanceMatrixData matrix, int row, int column) {
  return matrix.values[row * matrix.names.length + column];
}

/// Lowest and highest finite value of [matrix], leaving out each item
/// with itself, or null when there is none.
(double, double)? matrixRange(DistanceMatrixData matrix) {
  final int n = matrix.names.length;
  double low = double.infinity;
  double high = double.negativeInfinity;
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < n; j++) {
      final double v = matrix.values[i * n + j];
      if (i == j || !v.isFinite) continue;
      low = math.min(low, v);
      high = math.max(high, v);
    }
  }
  return low.isFinite ? (low, high) : null;
}

/// Lowest mean distance from each group to any other group.
List<double> nearestGroupMeans(DistanceGroupsData groups) {
  final DistanceMatrixData matrix = groups.matrix;
  final int n = matrix.names.length;
  return [
    for (int i = 0; i < n; i++)
      [
        for (int j = 0; j < n; j++)
          if (j != i && matrixValue(matrix, i, j).isFinite)
            matrixValue(matrix, i, j),
      ].fold(double.nan, (a, b) => a.isNaN || b < a ? b : a),
  ];
}

/// Pairwise distance counts in at most [maxBars] bars of a round width.
class DistanceBars {
  const DistanceBars({required this.labels, required this.counts});

  /// Range of each bar, such as "0.00-0.05".
  final List<String> labels;
  final List<double> counts;

  /// Bars from the report's histogram of fine bins of [binWidth].
  factory DistanceBars.of(
    List<double> bins,
    double binWidth, {
    int maxBars = distanceHistogramBars,
  }) {
    if (bins.isEmpty || binWidth <= 0) {
      return const DistanceBars(labels: [], counts: []);
    }
    final double step = math.max(
      _roundStep(bins.length * binWidth / maxBars),
      binWidth,
    );
    final int perBar = math.max(1, (step / binWidth).round());
    final int decimals = math.max(0, -(math.log(step) / math.ln10).floor());
    final List<String> labels = [];
    final List<double> counts = [];
    for (int start = 0; start < bins.length; start += perBar) {
      final double from = start * binWidth;
      final double to = from + perBar * binWidth;
      labels.add(
        '${from.toStringAsFixed(decimals)}-${to.toStringAsFixed(decimals)}',
      );
      counts.add(
        bins
            .sublist(start, math.min(start + perBar, bins.length))
            .fold(0, (a, b) => a + b),
      );
    }
    return DistanceBars(labels: labels, counts: counts);
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
}
