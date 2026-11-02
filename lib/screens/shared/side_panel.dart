import 'package:material_ui/material_ui.dart';
import 'package:segui/styles/design_tokens.dart';

/// Side list on the left of a page, such as the tool list or the settings
/// list, with an optional title above its items.
class SidePanel extends StatelessWidget {
  const SidePanel({
    super.key,
    required this.width,
    required this.children,
    this.title,
    this.subtitle,
  });

  final double width;
  final List<Widget> children;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(right: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(SeguiSpacing.xxl,
                  SeguiSpacing.xxl, SeguiSpacing.xxl, SeguiSpacing.xs),
              child: Text(
                title!,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  SeguiSpacing.xxl, 0, SeguiSpacing.xxl, SeguiSpacing.lg),
              child: Text(
                subtitle!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                SeguiSpacing.lg,
                title == null ? SeguiSpacing.lg : SeguiSpacing.xs,
                SeguiSpacing.lg,
                SeguiSpacing.xl,
              ),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// One item in a [SidePanel]: an icon tile, a title, and an optional
/// subtitle. The selected item is raised above the panel.
class SidePanelTile extends StatelessWidget {
  const SidePanelTile({
    super.key,
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: SeguiSpacing.xs),
      child: Semantics(
        selected: isSelected,
        child: Material(
          color:
              isSelected ? colors.surfaceContainerLowest : Colors.transparent,
          elevation: isSelected ? 1 : 0,
          shadowColor: colors.shadow.withAlpha(60),
          borderRadius: BorderRadius.circular(SeguiRadius.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: SeguiSpacing.lg, vertical: SeguiSpacing.md),
              child: Row(
                children: [
                  IconTile(icon: icon, isSelected: isSelected),
                  const SizedBox(width: SeguiSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An icon on a rounded tile, highlighted when [isSelected].
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.isSelected,
    this.size = 36,
  });

  final IconData icon;
  final bool isSelected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: size * 0.55,
        color: isSelected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
      ),
    );
  }
}
