import 'package:material_ui/material_ui.dart';
import 'package:segui/styles/design_tokens.dart';

/// A number over a bar whose length is [fraction] of the cell and whose
/// height is the number's. The shortest bars keep a stub, so the lowest
/// value still shows a bar.
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
    // The number sets the height, and the bar fills exactly that height.
    return Align(
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: min + (1 - min) * fraction.clamp(0, 1),
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(
                      alpha: SeguiTableLayout.dataBarAlpha,
                    ),
                    borderRadius: BorderRadius.circular(SeguiRadius.xs),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            heightFactor: 1,
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
