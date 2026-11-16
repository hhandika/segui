import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/viewers/contig_report.dart';
import 'package:segui/src/rust/api/contig_report.dart';

/// Loader for contig reports, replaced in tests to avoid the Rust bridge.
final contigReportLoaderProvider =
    Provider<ContigReportLoader>((ref) => loadContigReport);

/// The contig report at a path.
final contigReportProvider =
    FutureProvider.autoDispose.family<ContigReportData, String>((ref, path) {
  return ref.watch(contigReportLoaderProvider)(path);
});
