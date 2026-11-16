import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:segui/src/rust/api/contig_report.dart';

/// File name suffix of the report written by the contig summary.
const String contigReportSuffix = 'contig-report.json';

/// Loads a contig report from its path.
typedef ContigReportLoader = Future<ContigReportData> Function(String path);

/// Reads `contig-report.json` through the Rust bridge.
Future<ContigReportData> loadContigReport(String path) {
  return ContigReportServices(path: path).load();
}

/// Whether [file] is a contig report, with or without an output prefix.
bool isContigReport(File file) {
  return p.basename(file.path).endsWith(contigReportSuffix);
}

/// Contigs in each length bin, summed over every sample.
List<double> contigLengthTotals(ContigReportData report) {
  final List<double> totals = List<double>.filled(report.lengthBins.length, 0);
  for (final List<double> sample in report.samples.lengthDistribution) {
    for (int i = 0; i < totals.length && i < sample.length; i++) {
      totals[i] += sample[i];
    }
  }
  return totals;
}
