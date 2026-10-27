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

/// Filter, order, and visibility of the sample list in the read report.
class ReadSampleListSettings {
  const ReadSampleListSettings({
    this.query = '',
    this.sort = ReadSampleSort.name,
    this.ascending = true,
    this.showList = true,
  });

  final String query;
  final ReadSampleSort sort;
  final bool ascending;

  /// Whether the list shows beside the report on wider screens.
  final bool showList;

  ReadSampleListSettings copyWith({
    String? query,
    ReadSampleSort? sort,
    bool? ascending,
    bool? showList,
  }) {
    return ReadSampleListSettings(
      query: query ?? this.query,
      sort: sort ?? this.sort,
      ascending: ascending ?? this.ascending,
      showList: showList ?? this.showList,
    );
  }
}

final readSampleListProvider =
    NotifierProvider<ReadSampleList, ReadSampleListSettings>(
        ReadSampleList.new);

/// Keeps the sample list settings while reports open and close.
class ReadSampleList extends Notifier<ReadSampleListSettings> {
  @override
  ReadSampleListSettings build() => const ReadSampleListSettings();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setSort(ReadSampleSort sort) => state = state.copyWith(sort: sort);

  void setAscending(bool ascending) {
    state = state.copyWith(ascending: ascending);
  }

  void toggleList() => state = state.copyWith(showList: !state.showList);
}
