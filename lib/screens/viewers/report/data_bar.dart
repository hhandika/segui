import 'package:material_ui/material_ui.dart';
import 'package:segui/styles/design_tokens.dart';

/// A number over a bar whose length is [fraction] of the cell. The
/// shortest bars keep a stub, so the lowest value still shows a bar.
class DataBarCell extends StatelessWidget {
  const DataBarCell({
    super.key,
    required this.fraction,
    required this.color,
    required this.child,
  });

  final double fraction;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double min = SeguiTableLayout.dataBarMinFraction;
    return SizedBox.expand(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: min + (1 - min) * fraction.clamp(0, 1),
              heightFactor: SeguiTableLayout.dataBarHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: SeguiTableLayout.dataBarAlpha),
                  borderRadius: BorderRadius.circular(SeguiRadius.xs),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            // Long counts shrink rather than wrap.
            child: FittedBox(fit: BoxFit.scaleDown, child: child),
          ),
        ],
      ),
    );
  }
}

/// What the bars of a table with [DataBarCell]s mean, with one swatch per
/// bar color.
class DataBarLegend extends StatelessWidget {
  const DataBarLegend({super.key, this.swatches = const []});

  final List<(Color, String)> swatches;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall;
    return Wrap(
      spacing: SeguiSpacing.lg,
      runSpacing: SeguiSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Bars run from the lowest to the highest value in each column.',
          style: style,
        ),
        for (final (Color color, String label) in swatches)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: SeguiControlSize.iconSmall,
                height: SeguiControlSize.indicator,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: SeguiTableLayout.dataBarAlpha,
                  ),
                  borderRadius: BorderRadius.circular(SeguiRadius.xs),
                ),
              ),
              const SizedBox(width: SeguiSpacing.xs),
              Text(label, style: style),
            ],
          ),
      ],
    );
  }
}
