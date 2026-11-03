import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/settings/color_previews.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';

/// A number on a cell colored by the heatmap colormap at [fraction], with
/// black or white text, whichever reads better on the color. Cells of the
/// [selected] row are outlined, since the colors hide the row's tint.
class HeatmapCell extends StatelessWidget {
  const HeatmapCell({
    super.key,
    required this.fraction,
    required this.text,
    this.selected = false,
  });

  final double fraction;
  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color fill = heatmapColor(context, fraction);
    final Color ink =
        ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
            ? Colors.white
            : Colors.black;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: SeguiTableLayout.heatmapInset,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(SeguiRadius.xs),
          border: selected
              ? Border.all(
                  color: theme.colorScheme.onSurface,
                  width: SeguiStroke.regular,
                )
              : null,
        ),
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: SeguiSpacing.sm),
            child: Align(
              alignment: Alignment.centerRight,
              // Long counts shrink rather than wrap.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  maxLines: 1,
                  softWrap: false,
                  style: theme.textTheme.bodyMedium?.copyWith(color: ink),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The colormap of a table of [HeatmapCell]s, from low to high.
class HeatmapLegend extends StatelessWidget {
  const HeatmapLegend({
    super.key,
    this.text = 'Colors run from the lowest to the highest value in each '
        'column.',
  });

  /// How the colors are scaled.
  final String text;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall;
    return Wrap(
      spacing: SeguiSpacing.md,
      runSpacing: SeguiSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(text, style: style),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Low', style: style),
            const SizedBox(width: SeguiSpacing.xs),
            SizedBox(
              width: SeguiTableLayout.heatmapLegendWidth,
              child: GradientBar(
                stops: SeguiColors.of(context).heatmap,
                height: SeguiControlSize.indicator,
              ),
            ),
            const SizedBox(width: SeguiSpacing.xs),
            Text('High', style: style),
          ],
        ),
      ],
    );
  }
}

/// Heatmap color at [fraction], or the primary color by strength before
/// the library loads.
Color heatmapColor(BuildContext context, double fraction) {
  final double t = fraction.isFinite ? fraction.clamp(0.0, 1.0) : 0.0;
  return SeguiColors.of(context).heatmapAt(t) ??
      Theme.of(context).colorScheme.primary.withValues(
            alpha: SeguiChartLayout.heatmapMinAlpha +
                (1 - SeguiChartLayout.heatmapMinAlpha) * t,
          );
}
