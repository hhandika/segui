import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/report/data_bar.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';

/// Sample alignments for residue previews: four taxa of twelve sites.
const List<String> sampleDna = [
  'ACGTACGTTAGC',
  'ACGTTCGTTAGC',
  'ACG-ACGATAGC',
  'ACGTACGTTNGC',
];

const List<String> sampleProtein = [
  'MKVLAAGIDEPS',
  'MKVLSAGIDEPC',
  'MRVL-AGWDEPS',
  'MKVIAAGHDYPS',
];

/// Values for the sample table, chart, and heatmap.
const List<double> _sampleValues = [0.92, 0.64, 0.31];
const List<String> _sampleNames = ['Sample A', 'Sample B', 'Sample C'];

/// A strip of palette fills, each with its line color drawn underneath.
class PaletteSwatch extends StatelessWidget {
  const PaletteSwatch({super.key, required this.fills, required this.lines});

  final List<Color> fills;
  final List<Color> lines;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SeguiRadius.xs),
        child: Row(
          children: [
            for (int i = 0; i < fills.length; i++)
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: SeguiColorSettingsLayout.swatchHeight,
                      color: fills[i],
                    ),
                    Container(
                      height: SeguiColorSettingsLayout.swatchLine,
                      color: lines[i],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A colormap from low (left) to high (right).
class GradientBar extends StatelessWidget {
  const GradientBar({
    super.key,
    required this.stops,
    this.height = SeguiColorSettingsLayout.gradientHeight,
  });

  final List<Color> stops;
  final double height;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = stops.length > 1
        ? stops
        : [
            for (int i = 0; i < 2; i++)
              stops.isEmpty ? Theme.of(context).colorScheme.primary : stops[0],
          ];
    return ExcludeSemantics(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SeguiRadius.xs),
          gradient: LinearGradient(colors: colors),
        ),
      ),
    );
  }
}

/// Three numbers over data bars, drawn with the report tables' cell.
class MiniDataTable extends StatelessWidget {
  const MiniDataTable({super.key, required this.barColor});

  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? style = theme.textTheme.bodySmall;
    return ExcludeSemantics(
      child: Column(
        children: [
          for (int i = 0; i < _sampleValues.length; i++)
            SizedBox(
              height: SeguiColorSettingsLayout.tableRow,
              child: Row(
                children: [
                  Expanded(child: Text(_sampleNames[i], style: style)),
                  Expanded(
                    child: DataBarCell(
                      fraction: _sampleValues[i],
                      color: barColor,
                      child: Text(
                        (_sampleValues[i] * 100).toStringAsFixed(1),
                        style: style,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Four taxa of a small alignment, colored like the alignment viewer.
class MiniAlignment extends StatelessWidget {
  const MiniAlignment({
    super.key,
    required this.palette,
    required this.rows,
    this.mode = AlignmentColorMode.base,
    this.cellSize = SeguiColorSettingsLayout.residueCell,
  });

  final ResiduePalette palette;
  final List<String> rows;
  final AlignmentColorMode mode;

  /// Side of a residue cell. Rows shrink to fit narrow screens.
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final ResiduePalette shown =
        mode == AlignmentColorMode.mono ? ResiduePalette.mono(colors) : palette;
    final TextTheme text = Theme.of(context).textTheme;
    final TextStyle style = (cellSize > SeguiColorSettingsLayout.residueCell
            ? text.labelLarge!
            : text.labelSmall!)
        .copyWith(fontFamily: 'monospace', height: 1);
    return ExcludeSemantics(
      child: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int r = 0; r < rows.length; r++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int s = 0; s < rows[r].length; s++)
                    _ResidueCell(
                      code: rows[r].codeUnitAt(s),
                      isIdentity: mode == AlignmentColorMode.reference &&
                          r > 0 &&
                          rows[r][s] != '-' &&
                          rows[r][s] == rows[0][s],
                      palette: shown,
                      style: style,
                      size: cellSize,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ResidueCell extends StatelessWidget {
  const _ResidueCell({
    required this.code,
    required this.isIdentity,
    required this.palette,
    required this.style,
    required this.size,
  });

  final int code;
  final bool isIdentity;
  final ResiduePalette palette;
  final TextStyle style;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: isIdentity ? colors.surfaceContainer : palette.colorOf(code),
      child: Text(
        isIdentity ? '.' : String.fromCharCode(code),
        style: style.copyWith(
          color: isIdentity ? colors.onSurfaceVariant : palette.onResidue,
        ),
      ),
    );
  }
}

/// A sample line and bar chart in the palette's colors.
class MiniChart extends StatelessWidget {
  const MiniChart({
    super.key,
    required this.colors,
    this.series = 4,
    this.height = SeguiColorSettingsLayout.chartHeight,
  });

  final SeguiColors colors;

  /// Bars and lines drawn, one per palette color.
  final int series;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: CustomPaint(
          size: Size.infinite,
          painter: _MiniChartPainter(
            fills: [for (int i = 0; i < series; i++) colors.seriesAt(i)],
            lines: [for (int i = 0; i < series; i++) colors.lineAt(i)],
            axis: scheme.outline,
          ),
        ),
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  _MiniChartPainter({
    required this.fills,
    required this.lines,
    required this.axis,
  });

  final List<Color> fills;
  final List<Color> lines;
  final Color axis;

  @override
  void paint(Canvas canvas, Size size) {
    final double half = size.width / 2;
    final Paint axisPaint = Paint()
      ..color = axis
      ..strokeWidth = SeguiStroke.thin;
    // Bars on the left half, each fill outlined in its line color.
    final double barWidth = (half - SeguiSpacing.xl) / fills.length;
    for (int i = 0; i < fills.length; i++) {
      final double height = size.height * (0.92 - 0.7 * i / fills.length);
      final Rect bar = Rect.fromLTWH(
        i * barWidth + SeguiSpacing.xs,
        size.height - height,
        barWidth - SeguiSpacing.xs,
        height,
      );
      final RRect rounded = RRect.fromRectAndCorners(
        bar,
        topLeft: const Radius.circular(SeguiRadius.xs),
        topRight: const Radius.circular(SeguiRadius.xs),
      );
      canvas.drawRRect(rounded, Paint()..color = fills[i]);
      canvas.drawRRect(
        rounded,
        Paint()
          ..color = lines[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = SeguiStroke.thin,
      );
    }
    // Lines on the right half.
    for (int i = 0; i < lines.length; i++) {
      final Path path = Path();
      for (int x = 0; x <= 12; x++) {
        final double t = x / 12;
        final double y = size.height *
            (0.5 +
                0.35 *
                    math.sin(t * math.pi * 2 + i) *
                    (1 - 0.6 * i / lines.length));
        final Offset point = Offset(
          half + SeguiSpacing.md + t * (half - SeguiSpacing.xl),
          y,
        );
        if (x == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = lines[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = SeguiStroke.regular,
      );
    }
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniChartPainter old) {
    return old.fills != fills || old.lines != lines || old.axis != axis;
  }
}

/// A small heatmap of the colormap, as in the sample spread charts.
class MiniHeatmap extends StatelessWidget {
  const MiniHeatmap({
    super.key,
    required this.colors,
    this.rows = 4,
    this.columns = 16,
    this.height = SeguiColorSettingsLayout.heatmapHeight,
  });

  final SeguiColors colors;
  final int rows;
  final int columns;
  final double height;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            for (int r = 0; r < rows; r++)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int c = 0; c < columns; c++)
                      Expanded(
                        child: ColoredBox(
                          color: _shade(
                            (math.sin(c / 3 + r) + 1) / 2,
                            primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _shade(double t, Color primary) {
    return colors.heatmapAt(t) ??
        primary.withValues(
          alpha: SeguiChartLayout.heatmapMinAlpha +
              (1 - SeguiChartLayout.heatmapMinAlpha) * t,
        );
  }
}

/// A contrast ratio with whether it meets its WCAG minimum. The pass or
/// fail is shown with an icon and words, not color alone.
class ContrastBadge extends StatelessWidget {
  const ContrastBadge({
    super.key,
    required this.label,
    required this.ratio,
    required this.minimum,
  });

  final String label;
  final double ratio;
  final double minimum;

  @override
  Widget build(BuildContext context) {
    final bool passes = ratio >= minimum;
    final String verdict = passes ? 'meets' : 'below';
    return Semantics(
      label: '$label contrast ${ratio.toStringAsFixed(1)} to 1, $verdict '
          'the ${minimum.toStringAsFixed(1)} to 1 minimum',
      excludeSemantics: true,
      child: Chip(
        avatar: Icon(passes ? Icons.check_circle_outline : Icons.error_outline),
        label: Text('$label ${ratio.toStringAsFixed(1)}:1'),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
