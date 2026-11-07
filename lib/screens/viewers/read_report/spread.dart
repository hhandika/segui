import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/read_report/charts.dart';
import 'package:segui/screens/viewers/report/layout.dart';
import 'package:segui/services/viewers/read_report.dart';
import 'package:segui/src/rust/api/reads.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';

/// How a comparison chart summarizes many samples.
enum SpreadView {
  band('Band', Icons.area_chart_outlined),
  heatmap('Heatmap', Icons.grid_on_rounded);

  const SpreadView(this.label, this.icon);

  final String label;
  final IconData icon;
}

class SpreadViewToggle extends StatelessWidget {
  const SpreadViewToggle({
    super.key,
    required this.view,
    required this.onChanged,
  });

  final SpreadView view;
  final ValueChanged<SpreadView> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<SpreadView>(
        showSelectedIcon: false,
        segments: [
          for (final SpreadView option in SpreadView.values)
            ButtonSegment(
              value: option,
              label: Text(option.label),
              icon: Icon(option.icon),
            ),
        ],
        selected: {view},
        onSelectionChanged: (views) => onChanged(views.first),
      ),
    );
  }
}

/// Every listed sample on one chart: percentile bands with the open sample
/// and outliers drawn on top, or a heatmap with one row per sample.
class SampleSpreadChart extends StatelessWidget {
  const SampleSpreadChart({
    super.key,
    required this.samples,
    required this.view,
    required this.index,
    required this.points,
    required this.missingIsZero,
    required this.xLabel,
    required this.yLabel,
    required this.mode,
    required this.onSelected,
    this.minY,
  });

  final List<ReadSampleData> samples;

  /// Samples in list order, as positions in [samples].
  final List<int> view;

  /// The open sample, as a position in [samples].
  final int index;
  final ChartPoints Function(ReadSampleData sample) points;

  /// Whether x values a sample lacks count as zero. See [SampleMatrix.of].
  final bool missingIsZero;
  final String xLabel;
  final String yLabel;
  final SpreadView mode;
  final ValueChanged<int> onSelected;
  final double? minY;

  @override
  Widget build(BuildContext context) {
    if (view.isEmpty) {
      return const ChartPlaceholder(message: 'No samples match the filter.');
    }
    final List<ChartPoints> rows = [
      for (final int i in view) points(samples[i]),
    ];
    final SampleMatrix matrix = SampleMatrix.of(
      rows,
      missingIsZero: missingIsZero,
    );
    return switch (mode) {
      SpreadView.band => _band(context, rows, matrix),
      SpreadView.heatmap => SampleHeatmap(
          matrix: matrix,
          names: [for (final int i in view) samples[i].sample],
          openRow: view.indexOf(index),
          xLabel: xLabel,
          valueLabel: yLabel,
          onSelected: (row) => onSelected(view[row]),
        ),
    };
  }

  Widget _band(
    BuildContext context,
    List<ChartPoints> rows,
    SampleMatrix matrix,
  ) {
    final Color band = Theme.of(context).colorScheme.primary;
    final SeguiColors palette = SeguiColors.of(context);
    final SampleSpread spread = SampleSpread.of(matrix);
    final int openRow = view.indexOf(index);
    final List<int> outliers =
        spread.outliers.where((row) => row != openRow).toList();
    ChartPoints spreadPoints(String name, List<double> y) =>
        ChartPoints(name: name, x: spread.x, y: y);
    const int medianLine = 4;
    // Percentile bounds only shape the bands.
    final List<ChartLine> lines = [
      for (final (String name, List<double> y) in [
        ('P10', spread.p10),
        ('P90', spread.p90),
        ('Q1', spread.q1),
        ('Q3', spread.q3),
      ])
        ChartLine(points: spreadPoints(name, y), color: band, visible: false),
      ChartLine(points: spreadPoints('Median', spread.median), color: band),
      for (final int row in outliers)
        ChartLine(
          points: rows[row],
          color: palette.outlier,
          width: SeguiStroke.thin,
        ),
      if (openRow >= 0) ChartLine(points: rows[openRow], color: palette.open),
    ];
    return ReadLineChart(
      xLabel: xLabel,
      yLabel: yLabel,
      minY: minY,
      lines: lines,
      bands: [
        ChartBand(
          from: 0,
          to: 1,
          color: band.withValues(alpha: ChartPalette.outerBandAlpha),
        ),
        ChartBand(
          from: 2,
          to: 3,
          color: band.withValues(alpha: ChartPalette.innerBandAlpha),
        ),
      ],
      legend: [
        ('Median of ${rows.length} samples', band),
        (
          '25th-75th percentile',
          band.withValues(alpha: ChartPalette.innerBandAlpha)
        ),
        (
          '10th-90th percentile',
          band.withValues(alpha: ChartPalette.outerBandAlpha)
        ),
        if (openRow >= 0) (rows[openRow].name, palette.open),
        if (outliers.isNotEmpty)
          (
            'Outliers: ${outliers.map((row) => rows[row].name).join(', ')}',
            palette.outlier
          ),
      ],
      tooltipText: (line, i) {
        if (line < medianLine) return null;
        final ChartPoints drawn = lines[line].points;
        if (line > medianLine) {
          return '${drawn.name}\n'
              '$xLabel: ${formatValue(drawn.x[i])}, ${formatValue(drawn.y[i])}';
        }
        return '$xLabel: ${formatValue(spread.x[i])}\n'
            'Median: ${formatValue(spread.median[i])}\n'
            '25th-75th: ${formatValue(spread.q1[i])}-'
            '${formatValue(spread.q3[i])}\n'
            '10th-90th: ${formatValue(spread.p10[i])}-'
            '${formatValue(spread.p90[i])}';
      },
    );
  }
}

/// One row per sample and one column per x value, shaded by value. The
/// open sample is outlined, and a tap on a row opens its sample.
class SampleHeatmap extends StatefulWidget {
  const SampleHeatmap({
    super.key,
    required this.matrix,
    required this.names,
    required this.openRow,
    required this.xLabel,
    required this.valueLabel,
    required this.onSelected,
  });

  final SampleMatrix matrix;
  final List<String> names;

  /// Row of the open sample, or -1 when the filter hides it.
  final int openRow;
  final String xLabel;
  final String valueLabel;
  final ValueChanged<int> onSelected;

  @override
  State<SampleHeatmap> createState() => _SampleHeatmapState();
}

class _SampleHeatmapState extends State<SampleHeatmap> {
  (int, int)? _hovered;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final SeguiColors palette = SeguiColors.fromTheme(theme);
    final TextStyle labelStyle = theme.textTheme.labelSmall!.copyWith(
      color: colors.onSurfaceVariant,
    );
    final int rowCount = widget.names.length;
    final double rowHeight = (SeguiChartLayout.height / rowCount).clamp(
      SeguiChartLayout.heatmapRowMin,
      SeguiChartLayout.heatmapRowMax,
    );
    final double maxValue = widget.matrix.maxValue;
    final _HeatmapGeometry geometry = _HeatmapGeometry(
      rows: rowCount,
      columns: widget.matrix.x.length,
      rowHeight: rowHeight,
      labelWidth: SeguiChartLayout.barLabel,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_hoverText(), style: theme.textTheme.bodySmall),
        const SizedBox(height: SeguiSpacing.sm),
        MinWidthScroll(
          minWidth: math.max(
            SeguiChartLayout.minWidth,
            SeguiChartLayout.barLabel +
                widget.matrix.x.length * SeguiChartLayout.heatmapColumnMin,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final Size size = Size(
                constraints.maxWidth,
                rowCount * rowHeight + SeguiChartLayout.bottomAxis,
              );
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                onHover: (event) => _hover(geometry.cellAt(
                  event.localPosition,
                  size.width,
                )),
                onExit: (_) => _hover(null),
                child: GestureDetector(
                  onTapDown: (details) => _hover(geometry.cellAt(
                    details.localPosition,
                    size.width,
                  )),
                  onTapUp: (details) {
                    final (int, int)? cell = geometry.cellAt(
                      details.localPosition,
                      size.width,
                    );
                    if (cell != null) widget.onSelected(cell.$1);
                  },
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: size,
                      painter: _HeatmapPainter(
                        matrix: widget.matrix,
                        names: widget.names,
                        openRow: widget.openRow,
                        geometry: geometry,
                        maxValue: maxValue,
                        cellColor: colors.primary,
                        colormap: palette.heatmap,
                        openColor: palette.lineFor(palette.open),
                        labelStyle: labelStyle,
                        // Bold rather than colored, so the name keeps 4.5:1.
                        openLabelStyle: labelStyle.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Center(child: Text(widget.xLabel, style: labelStyle)),
        const SizedBox(height: SeguiSpacing.md),
        _HeatmapLegend(
          valueLabel: widget.valueLabel,
          maxValue: maxValue,
          color: colors.primary,
          colormap: palette.heatmap,
          openColor: palette.lineFor(palette.open),
          openName: widget.openRow >= 0 ? widget.names[widget.openRow] : null,
        ),
      ],
    );
  }

  String _hoverText() {
    final (int, int)? cell = _hovered;
    if (cell == null) {
      return 'Point at a cell to see its value. Select a row to open the '
          'sample.';
    }
    final (int row, int column) = cell;
    final double? value = widget.matrix.values[row][column];
    return '${widget.names[row]} · ${widget.xLabel} '
        '${formatValue(widget.matrix.x[column])}: '
        '${value == null ? 'no reads' : '${formatValue(value)} '
            '${widget.valueLabel.toLowerCase()}'}';
  }

  void _hover((int, int)? cell) {
    if (cell == _hovered) return;
    setState(() => _hovered = cell);
  }
}

/// Where rows, columns, and labels of a heatmap sit.
class _HeatmapGeometry {
  const _HeatmapGeometry({
    required this.rows,
    required this.columns,
    required this.rowHeight,
    required this.labelWidth,
  });

  final int rows;
  final int columns;
  final double rowHeight;
  final double labelWidth;

  double cellWidth(double width) =>
      columns == 0 ? 0 : math.max(0, width - labelWidth) / columns;

  /// Row and column under [position], or null outside the cells.
  (int, int)? cellAt(Offset position, double width) {
    final double cell = cellWidth(width);
    if (cell <= 0 || position.dx < labelWidth || position.dy < 0) return null;
    final int row = position.dy ~/ rowHeight;
    final int column = (position.dx - labelWidth) ~/ cell;
    if (row >= rows || column >= columns) return null;
    return (row, column);
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.matrix,
    required this.names,
    required this.openRow,
    required this.geometry,
    required this.maxValue,
    required this.cellColor,
    required this.colormap,
    required this.openColor,
    required this.labelStyle,
    required this.openLabelStyle,
  });

  final SampleMatrix matrix;
  final List<String> names;
  final int openRow;
  final _HeatmapGeometry geometry;
  final double maxValue;
  final Color cellColor;

  /// Colormap stops from the SEGUL color library, low to high. When empty,
  /// cells shade [cellColor] by opacity instead.
  final List<Color> colormap;
  final Color openColor;
  final TextStyle labelStyle;
  final TextStyle openLabelStyle;

  /// Bottom axis ticks, before labels crowd.
  static const int _ticks = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = geometry.cellWidth(size.width);
    final double rowHeight = geometry.rowHeight;
    final double left = geometry.labelWidth;
    final Paint paint = Paint();
    for (int row = 0; row < matrix.values.length; row++) {
      final List<double?> values = matrix.values[row];
      for (int column = 0; column < values.length; column++) {
        final double? value = values[column];
        // Blank cells tell "none" apart from the faintest shade.
        if (value == null || value <= 0) continue;
        final double share = maxValue > 0 ? value / maxValue : 0;
        paint.color = _shade(share.clamp(0, 1));
        canvas.drawRect(
          Rect.fromLTWH(left + column * cell, row * rowHeight, cell, rowHeight),
          paint,
        );
      }
    }
    if (openRow >= 0) {
      canvas.drawRect(
        Rect.fromLTWH(
            left, openRow * rowHeight, cell * geometry.columns, rowHeight),
        Paint()
          ..color = openColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = SeguiStroke.regular,
      );
    }
    _paintNames(canvas, rowHeight);
    _paintTicks(canvas, size, cell);
  }

  // Short rows label every few samples, leaving room for the open one.
  void _paintNames(Canvas canvas, double rowHeight) {
    final int step =
        math.max(1, (SeguiChartLayout.heatmapLabelRow / rowHeight).ceil());
    for (int row = 0; row < names.length; row++) {
      final bool isOpen = row == openRow;
      final bool nearOpen = openRow >= 0 && (row - openRow).abs() < step;
      if (!isOpen && (row % step != 0 || nearOpen)) continue;
      _paintText(
        canvas,
        names[row],
        isOpen ? openLabelStyle : labelStyle,
        maxWidth: geometry.labelWidth - SeguiSpacing.md,
        // Right-aligned beside the row, centered on it.
        anchor: Offset(
          geometry.labelWidth - SeguiSpacing.md,
          row * rowHeight + rowHeight / 2,
        ),
        alignEnd: true,
      );
    }
  }

  void _paintTicks(Canvas canvas, Size size, double cell) {
    final int columns = geometry.columns;
    if (columns == 0) return;
    final int step = math.max(1, (columns / _ticks).ceil());
    final double top = geometry.rows * geometry.rowHeight + SeguiSpacing.md;
    for (int column = 0; column < columns; column += step) {
      _paintText(
        canvas,
        formatValue(matrix.x[column]),
        labelStyle,
        maxWidth: cell * step,
        anchor: Offset(geometry.labelWidth + (column + 0.5) * cell, top),
        center: true,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    TextStyle style, {
    required double maxWidth,
    required Offset anchor,
    bool alignEnd = false,
    bool center = false,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(0, maxWidth));
    final double dx = alignEnd
        ? anchor.dx - painter.width
        : center
            ? anchor.dx - painter.width / 2
            : anchor.dx;
    final double dy = center ? anchor.dy : anchor.dy - painter.height / 2;
    painter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter old) {
    return old.matrix != matrix ||
        old.openRow != openRow ||
        old.geometry.rowHeight != geometry.rowHeight ||
        old.cellColor != cellColor ||
        !listEquals(old.colormap, colormap) ||
        old.openColor != openColor ||
        old.labelStyle != labelStyle;
  }

  Color _shade(double share) {
    if (colormap.isEmpty) {
      return cellColor.withValues(
        alpha: SeguiChartLayout.heatmapMinAlpha +
            (1 - SeguiChartLayout.heatmapMinAlpha) * share,
      );
    }
    final double position = share * (colormap.length - 1);
    final int low = position.floor();
    return Color.lerp(
        colormap[low], colormap[position.ceil()], position - low)!;
  }
}

/// Shade scale from the faintest to the darkest cell, and the outline of
/// the open sample.
class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend({
    required this.valueLabel,
    required this.maxValue,
    required this.color,
    required this.colormap,
    required this.openColor,
    required this.openName,
  });

  final String valueLabel;
  final double maxValue;
  final Color color;
  final List<Color> colormap;
  final Color openColor;
  final String? openName;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall;
    return Wrap(
      spacing: SeguiSpacing.lg,
      runSpacing: SeguiSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$valueLabel  0', style: style),
            const SizedBox(width: SeguiSpacing.xs),
            Container(
              width: SeguiChartLayout.barLabel,
              height: SeguiControlSize.indicator,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SeguiRadius.xs),
                gradient: LinearGradient(
                  colors: colormap.isNotEmpty
                      ? colormap
                      : [
                          color.withValues(
                            alpha: SeguiChartLayout.heatmapMinAlpha,
                          ),
                          color,
                        ],
                ),
              ),
            ),
            const SizedBox(width: SeguiSpacing.xs),
            Text(formatValue(maxValue), style: style),
          ],
        ),
        if (openName != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: SeguiControlSize.iconSmall,
                height: SeguiControlSize.indicator,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: openColor,
                    width: SeguiStroke.regular,
                  ),
                ),
              ),
              const SizedBox(width: SeguiSpacing.xs),
              Text(openName!, style: style),
            ],
          ),
      ],
    );
  }
}
