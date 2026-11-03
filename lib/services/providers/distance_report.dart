import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/viewers/distance_report.dart';
import 'package:segui/src/rust/api/distance_report.dart';

/// Loader for distance reports, replaced in tests to avoid the Rust
/// bridge.
final distanceReportLoaderProvider =
    Provider<DistanceReportLoader>((ref) => loadDistanceReport);

/// The distance report at a path.
final distanceReportProvider =
    FutureProvider.autoDispose.family<DistanceReportData, String>((ref, path) {
  return ref.watch(distanceReportLoaderProvider)(path);
});
