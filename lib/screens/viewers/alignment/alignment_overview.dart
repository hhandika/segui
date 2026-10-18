import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/alignment/alignment_grid.dart';
import 'package:segui/src/rust/api/alignment_view.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';

// Overview image size. One pixel samples one site and one taxon at most.
const int _maxImageWidth = 2048;
const int _maxImageHeight = 96;

/// Minimap of the whole alignment. The outlined box is the part in view;
/// tap or drag to move it.
class AlignmentOverview extends StatefulWidget {
  const AlignmentOverview({
    super.key,
    required this.data,
    required this.rowOrder,
    required this.selectedRows,
    required this.window,
    required this.cellSize,
    required this.rowHeight,
    required this.horizontalController,
    required this.verticalController,
    required this.onJump,
  });

  final AlignmentViewData data;

  /// Loaded sequence shown on each grid row, top to bottom.
  final List<int> rowOrder;

  /// Selected sequences keep their colors; the rest are dimmed.
  final Set<int> selectedRows;
  final AlignmentWindow window;
  final double cellSize;
  final double rowHeight;
  final ScrollController horizontalController;
  final ScrollController verticalController;

  /// Called with the zero-based site and grid row under the pointer.
  final void Function(int site, int row) onJump;

  @override
  State<AlignmentOverview> createState() => _AlignmentOverviewState();
}

class _AlignmentOverviewState extends State<AlignmentOverview> {
  ui.Image? _image;
  Brightness? _brightness;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Brightness brightness = Theme.of(context).colorScheme.brightness;
    if (brightness != _brightness) {
      _brightness = brightness;
      _buildImage();
    }
  }

  @override
  void didUpdateWidget(AlignmentOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data) ||
        !identical(oldWidget.rowOrder, widget.rowOrder) ||
        !identical(oldWidget.selectedRows, widget.selectedRows)) {
      _buildImage();
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: SeguiAlignmentLayout.overview,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          onTapDown: (d) => _jump(d.localPosition, constraints.biggest),
          onPanUpdate: (d) => _jump(d.localPosition, constraints.biggest),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SeguiRadius.xs),
            child: CustomPaint(
              size: constraints.biggest,
              painter: _OverviewPainter(
                image: _image,
                data: widget.data,
                rowCount: widget.rowOrder.length,
                window: widget.window,
                cellSize: widget.cellSize,
                rowHeight: widget.rowHeight,
                horizontalController: widget.horizontalController,
                verticalController: widget.verticalController,
                background: colors.surfaceContainerLow,
                frame: colors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _jump(Offset position, Size size) {
    final AlignmentViewData data = widget.data;
    final int rows = widget.rowOrder.length;
    if (data.length == 0 || rows == 0) return;
    final int site = (position.dx / size.width * data.length)
        .floor()
        .clamp(0, data.length - 1);
    final int row =
        (position.dy / size.height * rows).floor().clamp(0, rows - 1);
    widget.onJump(site, row);
  }

  void _buildImage() {
    final AlignmentViewData data = widget.data;
    final List<int> order = widget.rowOrder;
    final Set<int> selected = widget.selectedRows;
    final int rows = order.length;
    if (data.length == 0 || rows == 0) return;
    final int width =
        data.length < _maxImageWidth ? data.length : _maxImageWidth;
    final int height = rows < _maxImageHeight ? rows : _maxImageHeight;
    final ResiduePalette palette = data.isDna
        ? ResiduePalette.nucleotide(_brightness!)
        : ResiduePalette.aminoAcid(_brightness!);
    final Map<int, int> rgba = {};
    final Uint8List pixels = Uint8List(width * height * 4);
    for (int y = 0; y < height; y++) {
      final int row = order[y * rows ~/ height];
      final Uint8List seq = data.sequences[row];
      final bool isDimmed = selected.isNotEmpty && !selected.contains(row);
      for (int x = 0; x < width; x++) {
        final int site = x * data.length ~/ width;
        final int i = (y * width + x) * 4;
        if (site >= seq.length) continue;
        final int color = isDimmed
            ? palette.gap.toARGB32()
            : rgba.putIfAbsent(
                seq[site],
                () => palette.colorOf(seq[site]).toARGB32(),
              );
        pixels[i] = (color >> 16) & 0xFF;
        pixels[i + 1] = (color >> 8) & 0xFF;
        pixels[i + 2] = color & 0xFF;
        pixels[i + 3] = 0xFF;
      }
    }
    final List<int> source = order;
    ui.decodeImageFromPixels(pixels, width, height, ui.PixelFormat.rgba8888,
        (image) {
      if (!mounted || !identical(source, widget.rowOrder)) {
        image.dispose();
        return;
      }
      setState(() {
        _image?.dispose();
        _image = image;
      });
    });
  }
}

class _OverviewPainter extends CustomPainter {
  _OverviewPainter({
    required this.image,
    required this.data,
    required this.rowCount,
    required this.window,
    required this.cellSize,
    required this.rowHeight,
    required this.horizontalController,
    required this.verticalController,
    required this.background,
    required this.frame,
  }) : super(
          repaint: Listenable.merge([horizontalController, verticalController]),
        );

  final ui.Image? image;
  final AlignmentViewData data;
  final int rowCount;
  final AlignmentWindow window;
  final double cellSize;
  final double rowHeight;
  final ScrollController horizontalController;
  final ScrollController verticalController;
  final Color background;
  final Color frame;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..color = background);
    final ui.Image? image = this.image;
    if (image != null) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        bounds,
        Paint()..filterQuality = FilterQuality.none,
      );
    }
    if (data.length == 0 || rowCount == 0) return;
    final Rect view = Rect.fromLTRB(
      _fraction(_firstSite(), data.length) * size.width,
      _fraction(_offsetOf(verticalController) / rowHeight, rowCount) *
          size.height,
      _fraction(_firstSite() + _extentOf(horizontalController) / cellSize,
              data.length) *
          size.width,
      _fraction(
              (_offsetOf(verticalController) + _extentOf(verticalController)) /
                  rowHeight,
              rowCount) *
          size.height,
    );
    final Paint outline = Paint()
      ..color = frame
      ..style = PaintingStyle.stroke
      ..strokeWidth = SeguiStroke.regular;
    // Keep a sliver visible when the view is a tiny part of the alignment.
    final Rect visible = view.width < SeguiStroke.thick
        ? Rect.fromLTWH(view.left, view.top, SeguiStroke.thick, view.height)
        : view;
    canvas.drawRect(visible.deflate(SeguiStroke.thin), outline);
  }

  double _firstSite() =>
      window.start + _offsetOf(horizontalController) / cellSize;

  double _offsetOf(ScrollController c) => c.hasClients ? c.offset : 0;

  double _extentOf(ScrollController c) {
    if (!c.hasClients || !c.position.hasViewportDimension) return 0;
    return c.position.viewportDimension;
  }

  double _fraction(double value, int total) => (value / total).clamp(0, 1);

  @override
  bool shouldRepaint(_OverviewPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.data != data ||
        oldDelegate.rowCount != rowCount ||
        oldDelegate.window != window ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.rowHeight != rowHeight ||
        oldDelegate.background != background ||
        oldDelegate.frame != frame;
  }
}

/// Residue colors used by the grid and overview.
class AlignmentLegend extends StatelessWidget {
  const AlignmentLegend({super.key, required this.isDna});

  final bool isDna;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Brightness brightness = theme.colorScheme.brightness;
    final ResiduePalette palette = isDna
        ? ResiduePalette.nucleotide(brightness)
        : ResiduePalette.aminoAcid(brightness);
    final List<(String, int)> entries = isDna
        ? const [('A', 0x41), ('C', 0x43), ('G', 0x47), ('T', 0x54)]
        : const [
            ('Hydrophobic', 0x41),
            ('Positive', 0x4B),
            ('Negative', 0x44),
            ('Polar', 0x4E),
            ('Aromatic', 0x48),
            ('G', 0x47),
            ('P', 0x50),
            ('C', 0x43),
          ];
    return Wrap(
      spacing: SeguiSpacing.lg,
      runSpacing: SeguiSpacing.xs,
      children: [
        for (final (String label, int code) in entries)
          _LegendItem(label: label, color: palette.colorOf(code)),
        _LegendItem(label: 'Gap', color: palette.gap),
        _LegendItem(label: 'Other', color: palette.fallback),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: SeguiSpacing.md,
          height: SeguiSpacing.md,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(SeguiSpacing.xxs),
          ),
        ),
        const SizedBox(width: SeguiSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelSmall!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
