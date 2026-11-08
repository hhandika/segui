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

/// Chunks summarized per request to Rust.
const int chunkPageSize = 64;

/// Gap and variable-site shares of one page of [chunkPageSize] chunks.
/// Rust keeps the counts behind them, so a page scrolled back into view or
/// another chunk size over the same sites is quick.
final alignmentChunkPageProvider = FutureProvider.autoDispose.family<
    List<AlignmentChunkStat>,
    ({AlignmentViewData data, int chunkSize, int page})>(
  (ref, args) => args.data.residues.chunkStats(
    args.chunkSize,
    args.page * chunkPageSize,
    chunkPageSize,
  ),
);

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
    this.chunkSize = defaultAlignmentChunkSize,
    this.isPaged = false,
    this.chunk = 0,
    this.showChunkList = true,
    this.showSettings = true,
    this.nameWidth,
    this.showFileList = false,
    this.fileSort = AlignmentFileSort.name,
    this.fileSortAscending = true,
  });

  final double cellSize;
  final AlignmentColorMode colorMode;
  final bool showLetters;
  final int chunkSize;

  /// Shows one chunk at a time instead of the whole alignment.
  final bool isPaged;

  /// Current chunk, zero-based.
  final int chunk;
  final bool showChunkList;

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
    int? chunkSize,
    bool? isPaged,
    int? chunk,
    bool? showChunkList,
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
      chunkSize: chunkSize ?? this.chunkSize,
      isPaged: isPaged ?? this.isPaged,
      chunk: chunk ?? this.chunk,
      showChunkList: showChunkList ?? this.showChunkList,
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

  void toggleChunkList() {
    state = state.copyWith(showChunkList: !state.showChunkList);
  }

  void toggleSettings() {
    state = state.copyWith(showSettings: !state.showSettings);
  }

  /// Changes the chunk size, keeping the first site of the current chunk.
  void setChunkSize(int size) {
    final int site = state.chunk * state.chunkSize;
    state = state.copyWith(chunkSize: size, chunk: site ~/ size);
  }

  void setPaged(bool isPaged) {
    state = state.copyWith(isPaged: isPaged);
  }

  void setChunk(int chunk) {
    state = state.copyWith(chunk: chunk < 0 ? 0 : chunk);
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
