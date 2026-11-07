import 'package:material_ui/material_ui.dart';
import 'package:segui/styles/design_tokens.dart';

/// Small pill that marks a feature still in beta.
class BetaBadge extends StatelessWidget {
  const BetaBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Tooltip(
      message: 'Beta: may change before the stable release',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SeguiSpacing.sm,
          vertical: SeguiSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: colors.tertiaryContainer,
          borderRadius: BorderRadius.circular(SeguiRadius.full),
        ),
        child: Text(
          'Beta',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onTertiaryContainer,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

/// One-line [text] followed by a [BetaBadge] when [isBeta].
class BetaTitle extends StatelessWidget {
  const BetaTitle({
    super.key,
    required this.text,
    required this.isBeta,
    this.style,
    this.maxLines = 1,
  });

  final String text;
  final bool isBeta;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final Widget title = Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
    if (!isBeta) {
      return title;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: title),
        const SizedBox(width: SeguiSpacing.sm),
        const BetaBadge(),
      ],
    );
  }
}
