import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/viewers/read_report.dart';
import 'package:segui/src/rust/api/reads.dart';

/// Loader for read reports, replaced in tests to avoid the Rust bridge.
final readReportLoaderProvider =
    Provider<ReadReportLoader>((ref) => loadReadReport);

/// The read report at a path.
final readReportProvider =
    FutureProvider.autoDispose.family<ReadReportData, String>((ref, path) {
  return ref.watch(readReportLoaderProvider)(path);
});
