import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/alignment/alignment_grid.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/styles/design_tokens.dart';

// Narrowest gap between ruler labels.
const double _minTickGap = 64;
const List<int> _tickSteps = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000];

/// One-based site numbers above the grid, scrolled with it.
class AlignmentRuler extends StatelessWidget {
  const AlignmentRuler({
    super.key,
    required this.controller,
    required this.window,
    required this.cellSize,
  });

  final ScrollController controller;
  final AlignmentWindow window;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      height: SeguiAlignmentLayout.ruler,
      width: double.infinity,
      child: CustomPaint(
        painter: _RulerPainter(
          controller: controller,
          window: window,
          cellSize: cellSize,
          color: theme.colorScheme.onSurfaceVariant,
          textStyle: theme.textTheme.labelSmall!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.controller,
    required this.window,
    required this.cellSize,
    required this.color,
    required this.textStyle,
  }) : super(repaint: controller);

  final ScrollController controller;
  final AlignmentWindow window;
  final double cellSize;
  final Color color;
  final TextStyle textStyle;

  static final NumberFormat _format = NumberFormat('#,###');

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final double dx = controller.hasClients ? controller.offset : 0;
    final VisibleRange cols = VisibleRange.of(
      offset: dx,
      extent: size.width,
      itemSize: cellSize,
      count: window.length,
    );
    final int step = _tickSteps.firstWhere(
      (s) => s * cellSize >= _minTickGap,
      orElse: () => _tickSteps.last,
    );
    final Paint tick = Paint()
      ..color = color
      ..strokeWidth = SeguiStroke.thin;
    // Label sites whose one-based number is a multiple of the step.
    int site = ((window.start + cols.first) ~/ step + 1) * step;
    while (site <= window.start + cols.last) {
      final double x = (site - 1 - window.start + 0.5) * cellSize - dx;
      canvas.drawLine(
        Offset(x, size.height - SeguiSpacing.sm),
        Offset(x, size.height),
        tick,
      );
      final TextPainter label = TextPainter(
        text: TextSpan(text: _format.format(site), style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(x - label.width / 2, SeguiSpacing.xxs));
      label.dispose();
      site += step;
    }
  }

  @override
  bool shouldRepaint(_RulerPainter oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.window != window ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.color != color ||
        oldDelegate.textStyle != textStyle;
  }
}

/// Taxon names beside the grid, scrolled with it. Scrolling over the names
/// scrolls the grid. Tap a name to select its sequence; Shift extends and
/// Ctrl or Cmd toggles.
class AlignmentNames extends StatelessWidget {
  const AlignmentNames({
    super.key,
    required this.names,
    required this.rowOrder,
    required this.selectedRows,
    required this.controller,
    required this.rowHeight,
    required this.width,
    required this.selection,
    required this.onRowTap,
  });

  final List<String> names;

  /// Loaded sequence shown on each row, top to bottom.
  final List<int> rowOrder;
  final Set<int> selectedRows;
  final ScrollController controller;
  final double rowHeight;
  final double width;
  final ValueNotifier<AlignmentCell?> selection;

  /// Called with the tapped sequence and the held modifier keys.
  final void Function(int row, {required bool extend, required bool toggle})
      onRowTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: GestureDetector(
        onTapUp: _onTapUp,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: SizedBox(
            width: width,
            height: double.infinity,
            child: CustomPaint(
              painter: _NamesPainter(
                names: names,
                rowOrder: rowOrder,
                selectedRows: selectedRows,
                controller: controller,
                selection: selection,
                rowHeight: rowHeight,
                highlight: colors.primary.withValues(alpha: 0.12),
                selectedFill: colors.primary.withValues(alpha: 0.16),
                selectedMark: colors.primary,
                textStyle: theme.textTheme.bodySmall!.copyWith(
                  color: colors.onSurface,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTapUp(TapUpDetails details) {
    final double dy = controller.hasClients ? controller.offset : 0;
    final int index = ((details.localPosition.dy + dy) / rowHeight).floor();
    if (index < 0 || index >= rowOrder.length) return;
    final HardwareKeyboard keyboard = HardwareKeyboard.instance;
    onRowTap(
      rowOrder[index],
      extend: keyboard.isShiftPressed,
      toggle: keyboard.isControlPressed || keyboard.isMetaPressed,
    );
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !controller.hasClients) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      final ScrollPosition position = controller.position;
      final double target =
          (position.pixels + (event as PointerScrollEvent).scrollDelta.dy)
              .clamp(position.minScrollExtent, position.maxScrollExtent);
      position.jumpTo(target);
    });
  }
}

/// Drag handle between the names and the grid. Double-tap resets the width.
class AlignmentNameDivider extends StatelessWidget {
  const AlignmentNameDivider({
    super.key,
    required this.onDrag,
    required this.onReset,
  });

  /// Called with the horizontal drag distance.
  final ValueChanged<double> onDrag;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Resize sequence names',
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
          onDoubleTap: onReset,
          child: Container(
            width: SeguiAlignmentLayout.nameDivider,
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(
                  color: colors.outlineVariant,
                  width: SeguiStroke.thin / 2,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: Container(
              width: SeguiStroke.regular,
              height: SeguiControlSize.iconLarge,
              decoration: BoxDecoration(
                color: colors.outline,
                borderRadius: BorderRadius.circular(SeguiRadius.xs),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NamesPainter extends CustomPainter {
  _NamesPainter({
    required this.names,
    required this.rowOrder,
    required this.selectedRows,
    required this.controller,
    required this.selection,
    required this.rowHeight,
    required this.highlight,
    required this.selectedFill,
    required this.selectedMark,
    required this.textStyle,
  }) : super(repaint: Listenable.merge([controller, selection]));

  final List<String> names;
  final List<int> rowOrder;
  final Set<int> selectedRows;
  final Color selectedFill;
  final Color selectedMark;
  final ScrollController controller;
  final ValueNotifier<AlignmentCell?> selection;
  final double rowHeight;
  final Color highlight;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final double dy = controller.hasClients ? controller.offset : 0;
    final VisibleRange rows = VisibleRange.of(
      offset: dy,
      extent: size.height,
      itemSize: rowHeight,
      count: rowOrder.length,
    );
    final int? selected = selection.value?.row;
    final double fontSize = (rowHeight * 0.7).clamp(0, textStyle.fontSize!);
    final TextStyle style = textStyle.copyWith(fontSize: fontSize);
    final double maxWidth = size.width - SeguiSpacing.md * 2;
    for (int r = rows.first; r < rows.last; r++) {
      final int row = rowOrder[r];
      final double y = r * rowHeight - dy;
      if (selectedRows.contains(row)) {
        canvas.drawRect(
          Rect.fromLTWH(0, y, size.width, rowHeight),
          Paint()..color = selectedFill,
        );
        canvas.drawRect(
          Rect.fromLTWH(0, y, SeguiStroke.thick, rowHeight),
          Paint()..color = selectedMark,
        );
      } else if (row == selected) {
        canvas.drawRect(
          Rect.fromLTWH(0, y, size.width, rowHeight),
          Paint()..color = highlight,
        );
      }
      final TextPainter label = TextPainter(
        text: TextSpan(text: names[row], style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxWidth);
      label.paint(
        canvas,
        Offset(SeguiSpacing.md, y + (rowHeight - label.height) / 2),
      );
      label.dispose();
    }
  }

  @override
  bool shouldRepaint(_NamesPainter oldDelegate) {
    return oldDelegate.names != names ||
        oldDelegate.rowOrder != rowOrder ||
        oldDelegate.selectedRows != selectedRows ||
        oldDelegate.selectedFill != selectedFill ||
        oldDelegate.selectedMark != selectedMark ||
        oldDelegate.controller != controller ||
        oldDelegate.selection != selection ||
        oldDelegate.rowHeight != rowHeight ||
        oldDelegate.highlight != highlight ||
        oldDelegate.textStyle != textStyle;
  }
}
