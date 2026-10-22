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
