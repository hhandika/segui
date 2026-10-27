import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/services/viewers/read_report.dart';
import 'package:segui/src/rust/api/reads.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';

/// FastQC quality zones: poor below 20, reasonable below 28, good above.
const double _poorQuality = 20;
const double _goodQuality = 28;

/// One line in a [ReadLineChart].
class ChartLine {
  const ChartLine({
    required this.points,
    required this.color,
    this.visible = true,
    this.dashed = false,
  });

  final ChartPoints points;
  final Color color;

  /// Hidden lines still bound bands drawn between lines.
  final bool visible;
  final bool dashed;
}

/// Area filled between two lines of a [ReadLineChart], by index.
class ChartBand {
  const ChartBand({required this.from, required this.to, required this.color});

  final int from;
  final int to;
  final Color color;
}

/// Horizontal zone behind a chart, such as a quality range.
class ChartZone {
  const ChartZone({required this.from, required this.to, required this.color});

  final double from;
  final double to;
  final Color color;
}

/// Text for the tooltip of one point, or null to leave the point out.
typedef ChartTooltipText = String? Function(int line, int index);

/// Line chart with tooltips and horizontal zoom and pan.
class ReadLineChart extends StatelessWidget {
  const ReadLineChart({
    super.key,
    required this.lines,
    required this.xLabel,
    required this.yLabel,
    this.bands = const [],
    this.zones = const [],
    this.minY,
    this.maxY,
    this.tooltipText,
  });

  final List<ChartLine> lines;
  final String xLabel;
  final String yLabel;
  final List<ChartBand> bands;
  final List<ChartZone> zones;
  final double? minY;
  final double? maxY;

  /// Tooltip text. By default each visible line shows its name and value.
  final ChartTooltipText? tooltipText;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextStyle tooltipStyle = theme.textTheme.bodySmall!.copyWith(
      color: colors.onInverseSurface,
    );
    final List<ChartLine> drawn =
        lines.where((l) => !l.points.isEmpty).toList();
    if (drawn.isEmpty) {
      return const ChartPlaceholder(message: 'No data to plot.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: SeguiChartLayout.height,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                for (final ChartLine line in drawn) _barData(line),
              ],
              betweenBarsData: [
                for (final ChartBand band in bands)
                  BetweenBarsData(
                    fromIndex: band.from,
                    toIndex: band.to,
                    color: band.color,
                  ),
              ],
              rangeAnnotations: RangeAnnotations(
                horizontalRangeAnnotations: [
                  for (final ChartZone zone in zones)
                    HorizontalRangeAnnotation(
                      y1: zone.from,
                      y2: zone.to,
                      color: zone.color,
                    ),
                ],
              ),
              titlesData: chartTitles(context, xLabel: xLabel, yLabel: yLabel),
              gridData: chartGrid(colors),
              borderData: chartBorder(colors),
              clipData: const FlClipData.all(),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => colors.inverseSurface,
                  maxContentWidth: SeguiChartLayout.tooltipWidth,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (spots) => [
                    for (final LineBarSpot spot in spots)
                      _tooltipItem(drawn, spot, tooltipStyle),
                  ],
                ),
              ),
            ),
            transformationConfig: const FlTransformationConfig(
              scaleAxis: FlScaleAxis.horizontal,
              maxScale: SeguiChartLayout.maxZoom,
            ),
          ),
        ),
        const SizedBox(height: SeguiSpacing.md),
        ChartLegend(
          entries: [
            for (final ChartLine line in drawn)
              if (line.visible) (line.points.name, line.color),
          ],
        ),
      ],
    );
  }

  LineChartBarData _barData(ChartLine line) {
    final ChartPoints points = line.points;
    return LineChartBarData(
      spots: [
        for (int i = 0; i < points.x.length; i++)
          FlSpot(points.x[i], points.y[i]),
      ],
      color: line.visible ? line.color : Colors.transparent,
      barWidth: line.visible ? SeguiStroke.regular : SeguiStroke.none,
      dashArray: line.dashed ? SeguiChartLayout.dash : null,
      // A few points are easier to see as dots.
      dotData: FlDotData(show: line.visible && points.x.length <= 3),
    );
  }

  LineTooltipItem? _tooltipItem(
    List<ChartLine> drawn,
    LineBarSpot spot,
    TextStyle style,
  ) {
    final String? text = tooltipText != null
        ? tooltipText!(spot.barIndex, spot.spotIndex)
        : drawn[spot.barIndex].visible
            ? '${drawn[spot.barIndex].points.name}\n'
                '$xLabel: ${formatValue(spot.x)}, ${formatValue(spot.y)}'
            : null;
    if (text == null) return null;
    return LineTooltipItem(text, style, textAlign: TextAlign.start);
  }
}

/// Quality by read position: the median and mean, with the interquartile
/// range and the 10th to 90th percentile range as bands, over FastQC zones.
class PositionQualityChart extends StatelessWidget {
  const PositionQualityChart({super.key, required this.positions});

  final ReadPositionData positions;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<double> x = positions.start;
    ChartPoints points(String name, List<double> y) =>
        ChartPoints(name: name, x: x, y: y);
    final double top = math.max(
          41,
          positions.p90Qscore.fold<double>(0, math.max),
        ) +
        1;
    final Color band = colors.primary;
    return ReadLineChart(
      xLabel: 'Position (bp)',
      yLabel: 'Quality score',
      minY: 0,
      maxY: top,
      lines: [
        ChartLine(
            points: points('P10', positions.p10Qscore),
            color: band,
            visible: false),
        ChartLine(
            points: points('P90', positions.p90Qscore),
            color: band,
            visible: false),
        ChartLine(
            points: points('Q1', positions.q1Qscore),
            color: band,
            visible: false),
        ChartLine(
            points: points('Q3', positions.q3Qscore),
            color: band,
            visible: false),
        ChartLine(
            points: points('Median', positions.medianQscore),
            color: colors.primary),
        ChartLine(
          points: points('Mean', positions.meanQscore),
          color: colors.tertiary,
          dashed: true,
        ),
      ],
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
      zones: [
        ChartZone(
          from: 0,
          to: _poorQuality,
          color: ChartPalette.fail.withValues(alpha: ChartPalette.zoneAlpha),
        ),
        ChartZone(
          from: _poorQuality,
          to: _goodQuality,
          color: ChartPalette.warn.withValues(alpha: ChartPalette.zoneAlpha),
        ),
        ChartZone(
          from: _goodQuality,
          to: top,
          color: ChartPalette.pass.withValues(alpha: ChartPalette.zoneAlpha),
        ),
      ],
      // One tooltip per position, shown on the median line.
      tooltipText: (line, i) {
        if (line != 4) return null;
        final String range = positions.start[i] == positions.end[i]
            ? formatValue(positions.start[i])
            : '${formatValue(positions.start[i])}-${formatValue(positions.end[i])}';
        return 'Position $range\n'
            'Median: ${formatValue(positions.medianQscore[i])}\n'
            'Mean: ${positions.meanQscore[i].toStringAsFixed(1)}\n'
            'Q1-Q3: ${formatValue(positions.q1Qscore[i])}-'
            '${formatValue(positions.q3Qscore[i])}\n'
            'P10-P90: ${formatValue(positions.p10Qscore[i])}-'
            '${formatValue(positions.p90Qscore[i])}';
      },
    );
  }
}

/// One series in a [ReadBarChart].
class BarSeries {
  const BarSeries(
      {required this.name, required this.values, required this.color});

  final String name;
  final List<double> values;
  final Color color;
}

/// Grouped bar chart with one group per category.
class ReadBarChart extends StatelessWidget {
  const ReadBarChart({
    super.key,
    required this.categories,
    required this.series,
    required this.xLabel,
    required this.yLabel,
  });

  final List<String> categories;
  final List<BarSeries> series;
  final String xLabel;
  final String yLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextStyle tooltipStyle = theme.textTheme.bodySmall!.copyWith(
      color: colors.onInverseSurface,
    );
    if (categories.isEmpty || series.isEmpty) {
      return const ChartPlaceholder(message: 'No data to plot.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: SeguiChartLayout.height,
          child: BarChart(
            BarChartData(
              barGroups: [
                for (int i = 0; i < categories.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      for (final BarSeries s in series)
                        BarChartRodData(
                          toY: s.values[i],
                          color: s.color,
                          width: SeguiChartLayout.barWidth,
                          borderRadius: BorderRadius.zero,
                        ),
                    ],
                  ),
              ],
              titlesData: chartTitles(
                context,
                xLabel: xLabel,
                yLabel: yLabel,
                bottomLabel: (value) {
                  final int i = value.toInt();
                  return i >= 0 && i < categories.length ? categories[i] : '';
                },
              ),
              gridData: chartGrid(colors),
              borderData: chartBorder(colors),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => colors.inverseSurface,
                  maxContentWidth: SeguiChartLayout.tooltipWidth,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                      BarTooltipItem(
                    '${categories[group.x]}\n'
                    '${series[rodIndex].name}: ${formatValue(rod.toY)}',
                    tooltipStyle,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: SeguiSpacing.md),
        ChartLegend(
            entries: [for (final BarSeries s in series) (s.name, s.color)]),
      ],
    );
  }
}

/// Color key for the series of a chart.
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.entries});

  final List<(String, Color)> entries;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall;
    return Wrap(
      spacing: SeguiSpacing.lg,
      runSpacing: SeguiSpacing.xs,
      children: [
        for (final (String name, Color color) in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: SeguiControlSize.indicator,
                height: SeguiControlSize.indicator,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: SeguiSpacing.xs),
              Text(name, style: style),
            ],
          ),
      ],
    );
  }
}

/// Message shown in place of a chart.
class ChartPlaceholder extends StatelessWidget {
  const ChartPlaceholder({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SeguiChartLayout.height,
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Axis titles with tick labels on the left and bottom.
FlTitlesData chartTitles(
  BuildContext context, {
  required String xLabel,
  required String yLabel,
  String Function(double value)? bottomLabel,
}) {
  final TextStyle? style = Theme.of(context).textTheme.labelSmall;
  const AxisTitles hidden =
      AxisTitles(sideTitles: SideTitles(showTitles: false));
  return FlTitlesData(
    topTitles: hidden,
    rightTitles: hidden,
    leftTitles: AxisTitles(
      axisNameWidget: Text(yLabel, style: style),
      axisNameSize: SeguiChartLayout.axisName,
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: SeguiChartLayout.leftAxis,
        // The top of the axis is often between ticks, so its label overlaps.
        maxIncluded: false,
        getTitlesWidget: (value, meta) => SideTitleWidget(
          meta: meta,
          child: Text(meta.formattedValue, style: style),
        ),
      ),
    ),
    bottomTitles: AxisTitles(
      axisNameWidget: Text(xLabel, style: style),
      axisNameSize: SeguiChartLayout.axisName,
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: SeguiChartLayout.bottomAxis,
        interval: bottomLabel != null ? 1 : null,
        getTitlesWidget: (value, meta) => SideTitleWidget(
          meta: meta,
          child: Text(
            bottomLabel != null ? bottomLabel(value) : meta.formattedValue,
            style: style,
          ),
        ),
      ),
    ),
  );
}

FlGridData chartGrid(ColorScheme colors) {
  return FlGridData(
    drawVerticalLine: false,
    getDrawingHorizontalLine: (_) => FlLine(
      color: colors.outlineVariant,
      strokeWidth: SeguiStroke.thin,
    ),
  );
}

FlBorderData chartBorder(ColorScheme colors) {
  final BorderSide side = BorderSide(color: colors.outline);
  return FlBorderData(show: true, border: Border(left: side, bottom: side));
}

/// A number for a tooltip: whole numbers without decimals.
String formatValue(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(2);
}
