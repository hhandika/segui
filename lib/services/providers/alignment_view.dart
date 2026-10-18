import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/src/rust/api/alignment_view.dart';
import 'package:segui/styles/design_tokens.dart';

/// Sequences of the file at a path, parsed by SEGUL.
final alignmentDataProvider =
    FutureProvider.autoDispose.family<AlignmentViewData, String>(
  (ref, path) => loadAlignmentView(path),
);

/// Gap and variable-site shares per chunk of loaded sequences.
final alignmentChunkStatsProvider = FutureProvider.autoDispose
    .family<List<ChunkStat>, ({AlignmentViewData data, int chunkSize})>(
  (ref, args) => computeChunkStats(args.data, args.chunkSize),
);

/// Display settings of the open alignment viewer.
class AlignmentViewSettings {
  const AlignmentViewSettings({
    this.cellSize = SeguiAlignmentLayout.cellDefault,
    this.colorMode = AlignmentColorMode.base,
    this.showLetters = true,
    this.chunkSize = defaultAlignmentChunkSize,
    this.isPaged = false,
    this.chunk = 0,
    this.showChunkList = true,
    this.nameWidth,
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

  /// Width of the name panel set by dragging, or null for the default.
  final double? nameWidth;

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
    double? Function()? nameWidth,
  }) {
    return AlignmentViewSettings(
      cellSize: cellSize ?? this.cellSize,
      colorMode: colorMode ?? this.colorMode,
      showLetters: showLetters ?? this.showLetters,
      chunkSize: chunkSize ?? this.chunkSize,
      isPaged: isPaged ?? this.isPaged,
      chunk: chunk ?? this.chunk,
      showChunkList: showChunkList ?? this.showChunkList,
      nameWidth: nameWidth == null ? this.nameWidth : nameWidth(),
    );
  }
}

final alignmentViewSettingsProvider = NotifierProvider.autoDispose<
    AlignmentViewSettingsNotifier,
    AlignmentViewSettings>(AlignmentViewSettingsNotifier.new);

class AlignmentViewSettingsNotifier extends Notifier<AlignmentViewSettings> {
  @override
  AlignmentViewSettings build() => const AlignmentViewSettings();

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
  }

  void toggleLetters() {
    state = state.copyWith(showLetters: !state.showLetters);
  }

  void toggleChunkList() {
    state = state.copyWith(showChunkList: !state.showChunkList);
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
