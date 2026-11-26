import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/services/viewers/alignment_files.dart';
import 'package:segui/src/rust/api/alignment_view.dart';
import 'package:segui/styles/design_tokens.dart';

/// The open alignment at a path. Its residues are read as they are shown
/// and released when the viewer closes.
final alignmentDataProvider =
    FutureProvider.autoDispose.family<AlignmentViewData, String>(
  (ref, path) async {
    bool isDisposed = false;
    AlignmentViewData? data;
    ref.onDispose(() {
      isDisposed = true;
      data?.dispose();
    });
    final AlignmentViewData loaded = await loadAlignmentView(path);
    if (isDisposed) {
      loaded.dispose();
    } else {
      data = loaded;
    }
    return loaded;
  },
);

/// Windows summarized per request to Rust.
const int windowPageSize = 64;

/// Gap and variable-site shares of one page of [windowPageSize] windows.
/// Rust keeps the counts behind them, so a page scrolled back into view or
/// another window size over the same sites is quick.
final alignmentWindowPageProvider = FutureProvider.autoDispose.family<
    List<AlignmentWindowStat>,
    ({AlignmentViewData data, int windowSize, int page})>(
  (ref, args) => args.data.residues.windowStats(
    args.windowSize,
    args.page * windowPageSize,
    windowPageSize,
  ),
);

/// Gap and variable-site shares of one partition of an alignment.
final alignmentPartitionStatsProvider = FutureProvider.autoDispose
    .family<AlignmentWindowStat?, ({AlignmentViewData data, int index})>(
  (ref, args) {
    final AlignmentPartition partition = args.data.partitions[args.index];
    return args.data.residues.rangeStats(partition.start, partition.end);
  },
);

/// What the side list of the alignment viewer shows.
enum AlignmentSideListKind { windows, partitions }

/// How the viewer orders its file list: in Rust, unless overridden.
final fileOrderProvider = Provider<FileOrder>((ref) => rustFileOrder);

/// Sizes in bytes of the files the viewer can switch between.
final alignmentFileSizesProvider =
    FutureProvider.autoDispose.family<Map<String, int>, AlignmentFileList>(
  (ref, files) => alignmentFileSizes(files),
);

/// Display settings of the open alignment viewer. They carry over when
/// the viewer switches files.
class AlignmentViewSettings {
  const AlignmentViewSettings({
    this.cellSize = SeguiAlignmentLayout.cellDefault,
    this.colorMode = AlignmentColorMode.base,
    this.showLetters = true,
    this.windowSize = defaultAlignmentWindowSize,
    this.isPaged = false,
    this.window = 0,
    this.showWindowList = true,
    this.sideList = AlignmentSideListKind.partitions,
    this.showSettings = true,
    this.nameWidth,
    this.showFileList = false,
    this.fileSort = AlignmentFileSort.name,
    this.fileSortAscending = true,
  });

  final double cellSize;
  final AlignmentColorMode colorMode;
  final bool showLetters;
  final int windowSize;

  /// Shows one window at a time instead of the whole alignment.
  final bool isPaged;

  /// Current window, zero-based.
  final int window;
  final bool showWindowList;

  /// List shown beside the grid when the alignment has partitions.
  /// Alignments without partitions always list windows.
  final AlignmentSideListKind sideList;

  /// Shows the display settings, overview, and legend above the grid.
  /// Hiding them leaves more room for the grid.
  final bool showSettings;

  /// Width of the name panel set by dragging, or null for the default.
  final double? nameWidth;

  /// Shows the list of files to switch between beside the viewer.
  final bool showFileList;
  final AlignmentFileSort fileSort;
  final bool fileSortAscending;

  /// Height of a row, which stays readable when cells are narrow.
  double get rowHeight => cellSize < SeguiAlignmentLayout.rowMin
      ? SeguiAlignmentLayout.rowMin
      : cellSize;

  AlignmentViewSettings copyWith({
    double? cellSize,
    AlignmentColorMode? colorMode,
    bool? showLetters,
    int? windowSize,
    bool? isPaged,
    int? window,
    bool? showWindowList,
    AlignmentSideListKind? sideList,
    bool? showSettings,
    double? Function()? nameWidth,
    bool? showFileList,
    AlignmentFileSort? fileSort,
    bool? fileSortAscending,
  }) {
    return AlignmentViewSettings(
      cellSize: cellSize ?? this.cellSize,
      colorMode: colorMode ?? this.colorMode,
      showLetters: showLetters ?? this.showLetters,
      windowSize: windowSize ?? this.windowSize,
      isPaged: isPaged ?? this.isPaged,
      window: window ?? this.window,
      showWindowList: showWindowList ?? this.showWindowList,
      sideList: sideList ?? this.sideList,
      showSettings: showSettings ?? this.showSettings,
      nameWidth: nameWidth == null ? this.nameWidth : nameWidth(),
      showFileList: showFileList ?? this.showFileList,
      fileSort: fileSort ?? this.fileSort,
      fileSortAscending: fileSortAscending ?? this.fileSortAscending,
    );
  }
}

final alignmentViewSettingsProvider = NotifierProvider.autoDispose<
    AlignmentViewSettingsNotifier,
    AlignmentViewSettings>(AlignmentViewSettingsNotifier.new);

class AlignmentViewSettingsNotifier extends Notifier<AlignmentViewSettings> {
  /// Opens with the saved color mode; the other settings start fresh.
  @override
  AlignmentViewSettings build() {
    return AlignmentViewSettings(colorMode: _savedColorMode());
  }

  void setCellSize(double size) {
    state = state.copyWith(
      cellSize: size.clamp(
        SeguiAlignmentLayout.cellMin,
        SeguiAlignmentLayout.cellMax,
      ),
    );
  }

  void zoomIn() => setCellSize(state.cellSize + SeguiAlignmentLayout.cellStep);

  void zoomOut() => setCellSize(state.cellSize - SeguiAlignmentLayout.cellStep);

  void setColorMode(AlignmentColorMode mode) {
    state = state.copyWith(colorMode: mode);
    try {
      ref.read(alignmentColorModeProvider.notifier).set(mode);
    } catch (_) {
      // No saved preferences, as in widget tests.
    }
  }

  AlignmentColorMode _savedColorMode() {
    try {
      return ref.read(alignmentColorModeProvider);
    } catch (_) {
      // No saved preferences, as in widget tests.
      return AlignmentColorMode.base;
    }
  }

  void toggleLetters() {
    state = state.copyWith(showLetters: !state.showLetters);
  }

  void toggleWindowList() {
    state = state.copyWith(showWindowList: !state.showWindowList);
  }

  void setSideList(AlignmentSideListKind list) {
    state = state.copyWith(sideList: list);
  }

  void toggleSettings() {
    state = state.copyWith(showSettings: !state.showSettings);
  }

  /// Changes the window size, keeping the first site of the current window.
  void setWindowSize(int size) {
    final int site = state.window * state.windowSize;
    state = state.copyWith(windowSize: size, window: site ~/ size);
  }

  void setPaged(bool isPaged) {
    state = state.copyWith(isPaged: isPaged);
  }

  void setWindow(int window) {
    state = state.copyWith(window: window < 0 ? 0 : window);
  }

  void setNameWidth(double width) {
    final double clamped = width.clamp(
      SeguiAlignmentLayout.nameColumnMin,
      SeguiAlignmentLayout.nameColumnMax,
    );
    state = state.copyWith(nameWidth: () => clamped);
  }

  void resetNameWidth() {
    state = state.copyWith(nameWidth: () => null);
  }

  void toggleFileList() {
    state = state.copyWith(showFileList: !state.showFileList);
  }

  void setFileSort(AlignmentFileSort sort) {
    state = state.copyWith(fileSort: sort);
  }

  void setFileSortAscending(bool ascending) {
    state = state.copyWith(fileSortAscending: ascending);
  }
}

final alignmentRowSelectionProvider =
    NotifierProvider.autoDispose<AlignmentRowSelectionNotifier, RowSelection>(
  AlignmentRowSelectionNotifier.new,
);

class AlignmentRowSelectionNotifier extends Notifier<RowSelection> {
  @override
  RowSelection build() => const RowSelection();

  void tap(
    int row,
    List<int> order, {
    bool extend = false,
    bool toggle = false,
  }) {
    state = state.tap(row, order, extend: extend, toggle: toggle);
  }

  void clear() => state = const RowSelection();

  void setShowOnlySelected(bool value) {
    if (state.isEmpty) return;
    state = state.copyWith(showOnlySelected: value);
  }

  void setPinSelected(bool value) {
    if (state.isEmpty) return;
    state = state.copyWith(pinSelected: value);
  }
}
