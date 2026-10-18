import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/services/keyboard.dart';
import 'package:segui/src/rust/api/alignment_view.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';

/// A cell of the alignment: a taxon row and a zero-based site.
class AlignmentCell {
  const AlignmentCell(this.row, this.site);

  final int row;
  final int site;

  @override
  bool operator ==(Object other) =>
      other is AlignmentCell && other.row == row && other.site == site;

  @override
  int get hashCode => Object.hash(row, site);
}

/// Sites shown by the grid: one chunk when paged, otherwise all sites.
class AlignmentWindow {
  const AlignmentWindow(this.start, this.end);

  final int start;
  final int end;

  int get length => end - start;

  @override
  bool operator ==(Object other) =>
      other is AlignmentWindow && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Scrollable residue grid. Only the cells in view are painted.
class AlignmentGrid extends StatelessWidget {
  const AlignmentGrid({
    super.key,
    required this.data,
    required this.rowOrder,
    required this.selectedRows,
    required this.window,
    required this.cellSize,
    required this.rowHeight,
    required this.colorMode,
    required this.showLetters,
    required this.chunkSize,
    required this.showChunkBoundaries,
    required this.horizontalController,
    required this.verticalController,
    required this.hover,
    required this.selection,
    required this.onZoom,
  });

  final AlignmentViewData data;

  /// Loaded sequence shown on each grid row, top to bottom.
  final List<int> rowOrder;

  /// Sequences picked in the name panel, tinted across the grid.
  final Set<int> selectedRows;
  final AlignmentWindow window;
  final double cellSize;
  final double rowHeight;
  final AlignmentColorMode colorMode;
  final bool showLetters;
  final int chunkSize;
  final bool showChunkBoundaries;
  final ScrollController horizontalController;
  final ScrollController verticalController;
  final ValueNotifier<AlignmentCell?> hover;
  final ValueNotifier<AlignmentCell?> selection;

  /// Called with +1 to zoom in or -1 to zoom out on Ctrl + scroll, or
  /// Cmd + scroll on Apple platforms.
  final ValueChanged<int> onZoom;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: Scrollbar(
        controller: verticalController,
        thumbVisibility: true,
        notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
        child: Scrollbar(
          controller: horizontalController,
          thumbVisibility: true,
          notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
          // The scrollbars run in lanes right of and below the cells.
          child: Padding(
            padding: const EdgeInsets.only(
              right: SeguiControlSize.scrollbarGutter,
              bottom: SeguiControlSize.scrollbarGutter,
            ),
            child: TwoDimensionalScrollable(
              diagonalDragBehavior: DiagonalDragBehavior.free,
              horizontalDetails: ScrollableDetails.horizontal(
                  controller: horizontalController),
              verticalDetails:
                  ScrollableDetails.vertical(controller: verticalController),
              viewportBuilder: (context, verticalOffset, horizontalOffset) {
                return Listener(
                  onPointerSignal: _onPointerSignal,
                  child: MouseRegion(
                    onHover: (event) => hover.value = _cellAt(
                      event.localPosition,
                      horizontalOffset.pixels,
                      verticalOffset.pixels,
                    ),
                    onExit: (_) => hover.value = null,
                    child: GestureDetector(
                      onTapUp: (details) {
                        final AlignmentCell? cell = _cellAt(
                          details.localPosition,
                          horizontalOffset.pixels,
                          verticalOffset.pixels,
                        );
                        selection.value = cell == selection.value ? null : cell;
                      },
                      child: _AlignmentGridViewport(
                        horizontalOffset: horizontalOffset,
                        verticalOffset: verticalOffset,
                        data: data,
                        rowOrder: rowOrder,
                        selectedRows: selectedRows,
                        window: window,
                        cellSize: cellSize,
                        rowHeight: rowHeight,
                        colorMode: colorMode,
                        showLetters: showLetters,
                        chunkSize: chunkSize,
                        showChunkBoundaries: showChunkBoundaries,
                        devicePixelRatio:
                            MediaQuery.devicePixelRatioOf(context),
                        style: _GridStyle.of(theme, data.isDna, colorMode),
                        selection: selection,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  AlignmentCell? _cellAt(Offset position, double dx, double dy) {
    final int site = window.start + ((position.dx + dx) / cellSize).floor();
    final int row = ((position.dy + dy) / rowHeight).floor();
    if (row < 0 || row >= rowOrder.length) return null;
    if (site < window.start || site >= window.end) return null;
    return AlignmentCell(rowOrder[row], site);
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (!PlatformKeys.isPrimaryPressed) return;
    // Registered before the scrollable, so zooming replaces scrolling.
    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      final double dy = (event as PointerScrollEvent).scrollDelta.dy;
      if (dy != 0) onZoom(dy < 0 ? 1 : -1);
    });
  }
}

/// Colors the grid paints with, resolved from the theme.
class _GridStyle {
  const _GridStyle({
    required this.palette,
    required this.identity,
    required this.identityText,
    required this.selection,
    required this.boundary,
    required this.rowTint,
    required this.brightness,
  });

  factory _GridStyle.of(
    ThemeData theme,
    bool isDna,
    AlignmentColorMode mode,
  ) {
    final ColorScheme colors = theme.colorScheme;
    final ResiduePalette palette = switch (mode) {
      AlignmentColorMode.mono => ResiduePalette.mono(colors),
      _ => isDna
          ? ResiduePalette.nucleotide(colors.brightness)
          : ResiduePalette.aminoAcid(colors.brightness),
    };
    return _GridStyle(
      palette: palette,
      identity: colors.surfaceContainer,
      identityText: colors.onSurfaceVariant,
      selection: colors.primary,
      boundary: colors.tertiary,
      rowTint: colors.primary.withValues(alpha: 0.16),
      brightness: colors.brightness,
    );
  }

  final ResiduePalette palette;

  /// Residues that match the first row in [AlignmentColorMode.reference].
  final Color identity;
  final Color identityText;
  final Color selection;
  final Color boundary;

  /// Wash over selected sequences.
  final Color rowTint;
  final Brightness brightness;
}

class _AlignmentGridViewport extends LeafRenderObjectWidget {
  const _AlignmentGridViewport({
    required this.horizontalOffset,
    required this.verticalOffset,
    required this.data,
    required this.rowOrder,
    required this.selectedRows,
    required this.window,
    required this.cellSize,
    required this.rowHeight,
    required this.colorMode,
    required this.showLetters,
    required this.chunkSize,
    required this.showChunkBoundaries,
    required this.devicePixelRatio,
    required this.style,
    required this.selection,
  });

  final ViewportOffset horizontalOffset;
  final ViewportOffset verticalOffset;
  final AlignmentViewData data;
  final List<int> rowOrder;
  final Set<int> selectedRows;
  final AlignmentWindow window;
  final double cellSize;
  final double rowHeight;
  final AlignmentColorMode colorMode;
  final bool showLetters;
  final int chunkSize;
  final bool showChunkBoundaries;
  final double devicePixelRatio;
  final _GridStyle style;
  final ValueNotifier<AlignmentCell?> selection;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderAlignmentGrid(
      horizontalOffset: horizontalOffset,
      verticalOffset: verticalOffset,
      data: data,
      rowOrder: rowOrder,
      selectedRows: selectedRows,
      window: window,
      cellSize: cellSize,
      rowHeight: rowHeight,
      colorMode: colorMode,
      showLetters: showLetters,
      chunkSize: chunkSize,
      showChunkBoundaries: showChunkBoundaries,
      devicePixelRatio: devicePixelRatio,
      style: style,
      selection: selection,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderAlignmentGrid renderObject,
  ) {
    renderObject
      ..horizontalOffset = horizontalOffset
      ..verticalOffset = verticalOffset
      ..data = data
      ..rowOrder = rowOrder
      ..selectedRows = selectedRows
      ..window = window
      ..cellSize = cellSize
      ..rowHeight = rowHeight
      ..colorMode = colorMode
      ..showLetters = showLetters
      ..chunkSize = chunkSize
      ..showChunkBoundaries = showChunkBoundaries
      ..devicePixelRatio = devicePixelRatio
      ..style = style
      ..selection = selection;
  }
}

class _RenderAlignmentGrid extends RenderBox {
  _RenderAlignmentGrid({
    required ViewportOffset horizontalOffset,
    required ViewportOffset verticalOffset,
    required AlignmentViewData data,
    required List<int> rowOrder,
    required Set<int> selectedRows,
    required AlignmentWindow window,
    required double cellSize,
    required double rowHeight,
    required AlignmentColorMode colorMode,
    required bool showLetters,
    required int chunkSize,
    required bool showChunkBoundaries,
    required double devicePixelRatio,
    required _GridStyle style,
    required ValueNotifier<AlignmentCell?> selection,
  })  : _horizontalOffset = horizontalOffset,
        _verticalOffset = verticalOffset,
        _data = data,
        _rowOrder = rowOrder,
        _selectedRows = selectedRows,
        _window = window,
        _cellSize = cellSize,
        _rowHeight = rowHeight,
        _colorMode = colorMode,
        _showLetters = showLetters,
        _chunkSize = chunkSize,
        _showChunkBoundaries = showChunkBoundaries,
        _devicePixelRatio = devicePixelRatio,
        _style = style,
        _selection = selection;

  ViewportOffset _horizontalOffset;
  set horizontalOffset(ViewportOffset value) {
    if (value == _horizontalOffset) return;
    if (attached) _horizontalOffset.removeListener(markNeedsPaint);
    _horizontalOffset = value;
    if (attached) _horizontalOffset.addListener(markNeedsPaint);
    markNeedsLayout();
  }

  ViewportOffset _verticalOffset;
  set verticalOffset(ViewportOffset value) {
    if (value == _verticalOffset) return;
    if (attached) _verticalOffset.removeListener(markNeedsPaint);
    _verticalOffset = value;
    if (attached) _verticalOffset.addListener(markNeedsPaint);
    markNeedsLayout();
  }

  AlignmentViewData _data;
  set data(AlignmentViewData value) {
    if (identical(value, _data)) return;
    _data = value;
    markNeedsLayout();
  }

  List<int> _rowOrder;
  set rowOrder(List<int> value) {
    if (identical(value, _rowOrder)) return;
    _rowOrder = value;
    markNeedsLayout();
  }

  Set<int> _selectedRows;
  set selectedRows(Set<int> value) {
    if (identical(value, _selectedRows)) return;
    _selectedRows = value;
    markNeedsPaint();
  }

  AlignmentWindow _window;
  set window(AlignmentWindow value) {
    if (value == _window) return;
    _window = value;
    markNeedsLayout();
  }

  double _cellSize;
  set cellSize(double value) {
    if (value == _cellSize) return;
    _cellSize = value;
    markNeedsLayout();
  }

  double _rowHeight;
  set rowHeight(double value) {
    if (value == _rowHeight) return;
    _rowHeight = value;
    markNeedsLayout();
  }

  AlignmentColorMode _colorMode;
  set colorMode(AlignmentColorMode value) {
    if (value == _colorMode) return;
    _colorMode = value;
    markNeedsPaint();
  }

  bool _showLetters;
  set showLetters(bool value) {
    if (value == _showLetters) return;
    _showLetters = value;
    markNeedsPaint();
  }

  int _chunkSize;
  set chunkSize(int value) {
    if (value == _chunkSize) return;
    _chunkSize = value;
    markNeedsPaint();
  }

  bool _showChunkBoundaries;
  set showChunkBoundaries(bool value) {
    if (value == _showChunkBoundaries) return;
    _showChunkBoundaries = value;
    markNeedsPaint();
  }

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  _GridStyle _style;
  set style(_GridStyle value) {
    _style = value;
    markNeedsPaint();
  }

  ValueNotifier<AlignmentCell?> _selection;
  set selection(ValueNotifier<AlignmentCell?> value) {
    if (value == _selection) return;
    if (attached) _selection.removeListener(markNeedsPaint);
    _selection = value;
    if (attached) _selection.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  _ResidueAtlas? _atlas;
  Float32List _transforms = Float32List(0);
  Float32List _rects = Float32List(0);

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get sizedByParent => true;

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _horizontalOffset.addListener(markNeedsPaint);
    _verticalOffset.addListener(markNeedsPaint);
    _selection.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _horizontalOffset.removeListener(markNeedsPaint);
    _verticalOffset.removeListener(markNeedsPaint);
    _selection.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void dispose() {
    _atlas?.dispose();
    _atlas = null;
    super.dispose();
  }

  @override
  void performLayout() {
    final double contentWidth = _window.length * _cellSize;
    // A little room below the last row, so it clears the panel border.
    final double contentHeight =
        _rowOrder.length * _rowHeight + SeguiAlignmentLayout.gridBottomPadding;
    _horizontalOffset.applyViewportDimension(size.width);
    _horizontalOffset.applyContentDimensions(
      0,
      (contentWidth - size.width).clamp(0, double.infinity),
    );
    _verticalOffset.applyViewportDimension(size.height);
    _verticalOffset.applyContentDimensions(
      0,
      (contentHeight - size.height).clamp(0, double.infinity),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;
    final double dx = _horizontalOffset.pixels;
    final double dy = _verticalOffset.pixels;
    final VisibleRange cols = VisibleRange.of(
      offset: dx,
      extent: size.width,
      itemSize: _cellSize,
      count: _window.length,
    );
    final VisibleRange visibleRows = VisibleRange.of(
      offset: dy,
      extent: size.height,
      itemSize: _rowHeight,
      count: _rowOrder.length,
    );
    canvas.save();
    canvas.clipRect(offset & size);
    canvas.translate(offset.dx, offset.dy);
    final _ResidueAtlas atlas = _atlasFor();
    _paintCells(canvas, atlas, cols, visibleRows, dx, dy);
    _paintSelectedRows(canvas, visibleRows, dy);
    _paintChunkBoundaries(canvas, cols, dx);
    _paintSelection(canvas, dx, dy);
    canvas.restore();
  }

  _ResidueAtlas _atlasFor() {
    final _AtlasKey key = _AtlasKey(
      palette: _colorMode,
      isDna: _data.isDna,
      brightness: _style.brightness,
      cellSize: _cellSize,
      rowHeight: _rowHeight,
      showLetters: _showLetters &&
          _cellSize >= SeguiAlignmentLayout.letterMin &&
          _rowHeight >= SeguiAlignmentLayout.letterMin,
      devicePixelRatio: _devicePixelRatio,
    );
    final _ResidueAtlas? cached = _atlas;
    if (cached != null && cached.key == key) return cached;
    cached?.dispose();
    return _atlas = _ResidueAtlas.build(key, _style);
  }

  void _paintCells(
    Canvas canvas,
    _ResidueAtlas atlas,
    VisibleRange cols,
    VisibleRange visibleRows,
    double dx,
    double dy,
  ) {
    final int capacity = cols.length * visibleRows.length * 4;
    if (capacity == 0) return;
    if (_transforms.length < capacity) {
      _transforms = Float32List(capacity);
      _rects = Float32List(capacity);
    }
    final List<Uint8List> rows = _data.sequences;
    // Compare with the top row, which pinning can change.
    final Uint8List reference = rows[_rowOrder.first];
    final bool isReference = _colorMode == AlignmentColorMode.reference;
    final Int32List lookup = atlas.lookup;
    final Float32List sprites = atlas.sprites;
    final double scale = 1 / _devicePixelRatio;
    int n = 0;
    for (int r = visibleRows.first; r < visibleRows.last; r++) {
      final Uint8List seq = rows[_rowOrder[r]];
      final double y = r * _rowHeight - dy;
      for (int c = cols.first; c < cols.last; c++) {
        final int site = _window.start + c;
        if (site >= seq.length) break;
        final int code = seq[site];
        final int sprite = isReference &&
                r > 0 &&
                site < reference.length &&
                code == reference[site] &&
                !isGapResidue(code)
            ? _ResidueAtlas.identitySprite
            : lookup[code];
        final int i = n * 4;
        _transforms[i] = scale;
        _transforms[i + 1] = 0;
        _transforms[i + 2] = c * _cellSize - dx;
        _transforms[i + 3] = y;
        final int s = sprite * 4;
        _rects[i] = sprites[s];
        _rects[i + 1] = sprites[s + 1];
        _rects[i + 2] = sprites[s + 2];
        _rects[i + 3] = sprites[s + 3];
        n++;
      }
    }
    if (n == 0) return;
    canvas.drawRawAtlas(
      atlas.image,
      Float32List.sublistView(_transforms, 0, n * 4),
      Float32List.sublistView(_rects, 0, n * 4),
      null,
      null,
      null,
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  void _paintSelectedRows(Canvas canvas, VisibleRange visibleRows, double dy) {
    if (_selectedRows.isEmpty) return;
    final Paint paint = Paint()..color = _style.rowTint;
    for (int r = visibleRows.first; r < visibleRows.last; r++) {
      if (!_selectedRows.contains(_rowOrder[r])) continue;
      canvas.drawRect(
        Rect.fromLTWH(0, r * _rowHeight - dy, size.width, _rowHeight),
        paint,
      );
    }
  }

  void _paintChunkBoundaries(Canvas canvas, VisibleRange cols, double dx) {
    if (!_showChunkBoundaries || _chunkSize <= 0) return;
    final Paint paint = Paint()
      ..color = _style.boundary
      ..strokeWidth = SeguiStroke.regular;
    final int firstSite = _window.start + cols.first;
    int boundary = (firstSite ~/ _chunkSize + 1) * _chunkSize;
    while (boundary < _window.start + cols.last) {
      final double x = (boundary - _window.start) * _cellSize - dx;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      boundary += _chunkSize;
    }
  }

  void _paintSelection(Canvas canvas, double dx, double dy) {
    final AlignmentCell? cell = _selection.value;
    if (cell == null || cell.site < _window.start || cell.site >= _window.end) {
      return;
    }
    final Paint paint = Paint()
      ..color = _style.selection
      ..style = PaintingStyle.stroke
      ..strokeWidth = SeguiStroke.regular;
    final int row = _rowOrder.indexOf(cell.row);
    final double x = (cell.site - _window.start) * _cellSize - dx;
    final double y = row * _rowHeight - dy;
    // Column and row guides, then the cell itself.
    canvas.drawRect(
      Rect.fromLTWH(x, 0, _cellSize, size.height),
      Paint()..color = _style.selection.withValues(alpha: 0.12),
    );
    // The row may be hidden by showing only selected sequences.
    if (row < 0) return;
    canvas.drawRect(Rect.fromLTWH(x, y, _cellSize, _rowHeight), paint);
  }
}

/// Inputs that change the atlas sprites.
class _AtlasKey {
  const _AtlasKey({
    required this.palette,
    required this.isDna,
    required this.brightness,
    required this.cellSize,
    required this.rowHeight,
    required this.showLetters,
    required this.devicePixelRatio,
  });

  final AlignmentColorMode palette;
  final bool isDna;
  final Brightness brightness;
  final double cellSize;
  final double rowHeight;
  final bool showLetters;
  final double devicePixelRatio;

  @override
  bool operator ==(Object other) =>
      other is _AtlasKey &&
      other.palette == palette &&
      other.isDna == isDna &&
      other.brightness == brightness &&
      other.cellSize == cellSize &&
      other.rowHeight == rowHeight &&
      other.showLetters == showLetters &&
      other.devicePixelRatio == devicePixelRatio;

  @override
  int get hashCode => Object.hash(
        palette,
        isDna,
        brightness,
        cellSize,
        rowHeight,
        showLetters,
        devicePixelRatio,
      );
}

/// One image holding a colored, lettered tile per printable ASCII residue,
/// stamped onto the grid with [Canvas.drawRawAtlas].
class _ResidueAtlas {
  _ResidueAtlas._(this.key, this.image, this.lookup, this.sprites);

  /// Builds tiles at device resolution so letters stay sharp.
  factory _ResidueAtlas.build(_AtlasKey key, _GridStyle style) {
    final double ratio = key.devicePixelRatio;
    final double w = (key.cellSize * ratio).ceilToDouble();
    final double h = (key.rowHeight * ratio).ceilToDouble();
    final double inset = key.cellSize >= SeguiAlignmentLayout.cellGapMin
        ? SeguiStroke.thin * ratio
        : 0;
    final double fontSize =
        (key.cellSize < key.rowHeight ? key.cellSize : key.rowHeight) *
            ratio *
            0.7;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Float32List sprites = Float32List(_spriteCount * 4);
    final Paint fill = Paint();
    for (int i = 0; i < _spriteCount; i++) {
      final bool isIdentity = i == identitySprite;
      final int code = isIdentity ? _dot : _firstCode + i;
      final double left = (i % _columns) * w;
      final double top = (i ~/ _columns) * h;
      fill.color = isIdentity ? style.identity : style.palette.colorOf(code);
      canvas.drawRect(
        Rect.fromLTWH(left, top, w - inset, h - inset),
        fill,
      );
      if (key.showLetters) {
        final TextPainter letter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(code),
            style: TextStyle(
              color: isIdentity ? style.identityText : style.palette.onResidue,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        letter.paint(
          canvas,
          Offset(
            left + (w - inset - letter.width) / 2,
            top + (h - inset - letter.height) / 2,
          ),
        );
        letter.dispose();
      }
      sprites[i * 4] = left;
      sprites[i * 4 + 1] = top;
      sprites[i * 4 + 2] = left + w;
      sprites[i * 4 + 3] = top + h;
    }
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = picture.toImageSync(
      (_columns * w).ceil(),
      ((_spriteCount + _columns - 1) ~/ _columns * h).ceil(),
    );
    picture.dispose();
    final Int32List lookup = Int32List(256);
    for (int code = 0; code < 256; code++) {
      lookup[code] = code >= _firstCode && code <= _lastCode
          ? code - _firstCode
          : _questionSprite;
    }
    return _ResidueAtlas._(key, image, lookup, sprites);
  }

  static const int _firstCode = 0x21; // !
  static const int _lastCode = 0x7E; // ~
  static const int _dot = 0x2E; // .
  static const int _columns = 16;
  static const int _printable = _lastCode - _firstCode + 1;
  static const int _questionSprite = 0x3F - _firstCode;

  /// Sprite for residues identical to the first row.
  static const int identitySprite = _printable;
  static const int _spriteCount = _printable + 1;

  final _AtlasKey key;
  final ui.Image image;

  /// Sprite index for each residue code.
  final Int32List lookup;

  /// Source rectangle of each sprite: left, top, right, bottom.
  final Float32List sprites;

  void dispose() => image.dispose();
}
