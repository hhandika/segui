import 'package:material_ui/material_ui.dart';
import 'package:segui/styles/design_tokens.dart';

/// Title, a short detail line, and optional actions at the top of a
/// settings page, styled like the tool headers.
class SettingsPageHeader extends StatelessWidget {
  const SettingsPageHeader({
    super.key,
    required this.title,
    this.detail,
    this.actions = const [],
  });

  final String title;
  final String? detail;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: SeguiSpacing.xs),
                Text(
                  detail!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}

/// A list in the same card as the tool forms, with dividers between rows.
class SettingsListCard extends StatelessWidget {
  const SettingsListCard({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(SeguiFormLayout.cardRadius),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: SeguiSpacing.xs),
          itemCount: itemCount,
          separatorBuilder: (context, index) => Divider(
            height: SeguiStroke.thin,
            indent: SeguiSpacing.xl,
            endIndent: SeguiSpacing.xl,
            color: colors.outlineVariant,
          ),
          itemBuilder: itemBuilder,
        ),
      ),
    );
  }
}
