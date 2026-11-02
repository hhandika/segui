import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/viewers/alignment_report.dart';
import 'package:segui/src/rust/api/alignment_report.dart';

/// Loader for alignment reports, replaced in tests to avoid the Rust
/// bridge.
final alignReportLoaderProvider =
    Provider<AlignReportLoader>((ref) => loadAlignmentReport);

/// The alignment report at a path.
final alignReportProvider =
    FutureProvider.autoDispose.family<AlignReportData, String>((ref, path) {
  return ref.watch(alignReportLoaderProvider)(path);
});
