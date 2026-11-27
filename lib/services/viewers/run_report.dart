import 'dart:convert';
import 'dart:io';

/// Summary categories inside a unified Schema v2 `report.json` that have
/// dedicated interactive chart/table viewers in SEGUI.
enum RunReportSummaryKind {
  alignSummary,
  alignDistance,
  contigSummary,
  readSummary,
  other,
}

/// Lightweight header parsed directly in Dart from a unified `report.json`
/// without calling across the Rust bridge.
class RunReportHeader {
  const RunReportHeader({
    required this.schemaVersion,
    required this.kind,
    required this.summaryKind,
    required this.frontendName,
    required this.frontendVersion,
    required this.checksumMode,
    required this.inputCount,
    required this.outputCount,
    required this.hasStatistics,
    this.statistics,
  });

  final int schemaVersion;
  final String kind;
  final RunReportSummaryKind summaryKind;
  final String frontendName;
  final String frontendVersion;
  final String checksumMode;
  final int inputCount;
  final int outputCount;
  final bool hasStatistics;
  final Map<String, dynamic>? statistics;
}

/// Inspect [file] synchronously and return its [RunReportHeader] if it is a
/// valid Schema v2 `report.json`, or null otherwise.
RunReportHeader? readRunReportHeader(File file) {
  if (!file.path.toLowerCase().endsWith('.json')) {
    return null;
  }
  try {
    final Object? decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final int? schemaVersion = (decoded['schema_version'] as num?)?.toInt();
    final String? kind = decoded['kind'] as String?;
    final Object? run = decoded['run'];
    final Object? inputs = decoded['inputs'];
    final Object? outputs = decoded['outputs'];
    if (schemaVersion == null ||
        schemaVersion < 2 ||
        kind == null ||
        run is! Map<String, dynamic> ||
        inputs is! Map<String, dynamic> ||
        outputs is! Map<String, dynamic>) {
      return null;
    }
    final Map<String, dynamic>? frontend =
        run['frontend'] as Map<String, dynamic>?;
    final List<dynamic> primary =
        inputs['primary'] as List<dynamic>? ?? const [];
    final List<dynamic> outFiles =
        outputs['files'] as List<dynamic>? ?? const [];
    final Object? statsRaw = decoded['statistics'];
    final Map<String, dynamic>? stats =
        statsRaw is Map<String, dynamic> ? statsRaw : null;

    final RunReportSummaryKind summaryKind = switch (kind) {
      'align.summary' => RunReportSummaryKind.alignSummary,
      'align.distance' => RunReportSummaryKind.alignDistance,
      'contig.summary' => RunReportSummaryKind.contigSummary,
      'read.summary' => RunReportSummaryKind.readSummary,
      _ => RunReportSummaryKind.other,
    };

    return RunReportHeader(
      schemaVersion: schemaVersion,
      kind: kind,
      summaryKind: summaryKind,
      frontendName: frontend?['name'] as String? ?? 'segul',
      frontendVersion: frontend?['version'] as String? ?? '',
      checksumMode: run['checksum_mode'] as String? ?? 'none',
      inputCount: primary.length,
      outputCount: outFiles.length,
      hasStatistics: stats != null,
      statistics: stats,
    );
  } catch (_) {
    return null;
  }
}

/// Whether [file] is a unified Schema v2 `report.json`.
bool isRunReportFile(File file) => readRunReportHeader(file) != null;

/// Reads a JSON report and returns its statistics map, unwrapping Schema v2
/// envelopes when present and falling back to the root object for legacy v1
/// `*-report.json` files.
Future<Map<String, dynamic>?> readReportStatisticsOrLegacy(File file) async {
  final Object? decoded = jsonDecode(await file.readAsString());
  if (decoded is! Map<String, dynamic>) {
    return null;
  }
  if (decoded['schema_version'] is num &&
      decoded['statistics'] is Map<String, dynamic>) {
    return decoded['statistics'] as Map<String, dynamic>;
  }
  return decoded;
}
