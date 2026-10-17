import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/screens/home/components/greeting.dart';
import 'package:segui/screens/shared/equal_height_grid.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/utils.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';

/// A theme mode the user can pick, with the gull scene that previews it.
enum ThemeChoice {
  system(
    mode: ThemeMode.system,
    title: 'System default',
    description: 'Follows your device, day or night',
  ),
  light(
    mode: ThemeMode.light,
    title: 'Light',
    description: 'A bright morning by the sea',
  ),
  dark(
    mode: ThemeMode.dark,
    title: 'Dark',
    description: 'A calm evening under the stars',
  );

  const ThemeChoice({
    required this.mode,
    required this.title,
    required this.description,
  });

  final ThemeMode mode;
  final String title;
  final String description;
}

class ThemeSettings extends StatelessWidget {
  const ThemeSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
        backgroundColor: getSEGULBackgroundColor(context),
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: const SafeArea(child: ThemeSettingView()),
    );
  }
}

/// Theme choices as preview cards, stacked as rows on narrow screens.
class ThemeSettingView extends ConsumerWidget {
  const ThemeSettingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    // Keep showing the last choice while a new one saves.
    final ThemeMode current =
        ref.watch(themeSettingProvider).value ?? ThemeMode.system;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SeguiSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: SeguiContentWidth.reading,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Appearance', style: theme.textTheme.headlineSmall),
              const SizedBox(height: SeguiSpacing.xs),
              Text(
                'Choose how SEGUI looks. The gull keeps you company either '
                'way.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: SeguiSpacing.xl),
              LayoutBuilder(builder: (context, constraints) {
                final int columns = gridColumnCount(
                  constraints.maxWidth,
                  minItemWidth: SeguiContentWidth.themeChoice,
                  maxColumns: ThemeChoice.values.length,
                );
                return EqualHeightGrid(
                  columns: columns,
                  children: [
                    for (final choice in ThemeChoice.values)
                      ThemeChoiceCard(
                        choice: choice,
                        isSelected: choice.mode == current,
                        isCompact: columns == 1,
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// A selectable theme with its gull scene preview. Compact cards lay the
/// preview beside the text instead of above it.
class ThemeChoiceCard extends ConsumerWidget {
  const ThemeChoiceCard({
    super.key,
    required this.choice,
    required this.isSelected,
    this.isCompact = false,
  });

  final ThemeChoice choice;
  final bool isSelected;
  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Widget label = ThemeChoiceLabel(
      choice: choice,
      isSelected: isSelected,
    );
    return Semantics(
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: Card.outlined(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: isSelected ? colors.secondaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SeguiRadius.lg),
          side: BorderSide(
            color: isSelected ? colors.primary : colors.outlineVariant,
            width: isSelected ? SeguiStroke.regular : SeguiStroke.thin,
          ),
        ),
        child: InkWell(
          onTap: () {
            ref.read(themeSettingProvider.notifier).setTheme(choice.mode);
          },
          child: isCompact
              ? Row(
                  children: [
                    SizedBox(
                      width: SeguiControlSize.themePreview,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ThemePreview(choice: choice),
                      ),
                    ),
                    Expanded(child: label),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: ThemePreview(choice: choice),
                    ),
                    label,
                  ],
                ),
        ),
      ),
    );
  }
}

class ThemeChoiceLabel extends StatelessWidget {
  const ThemeChoiceLabel({
    super.key,
    required this.choice,
    required this.isSelected,
  });

  final ThemeChoice choice;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color textColor =
        isSelected ? colors.onSecondaryContainer : colors.onSurface;
    return Padding(
      padding: const EdgeInsets.all(SeguiSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSelected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: isSelected ? colors.primary : colors.onSurfaceVariant,
            size: SeguiControlSize.iconMedium,
          ),
          const SizedBox(width: SeguiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  choice.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: textColor,
                  ),
                ),
                Text(
                  choice.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected ? textColor : colors.onSurfaceVariant,
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

/// The gull scene drawn in the colors of [choice]: a light morning, a dark
/// evening, or the two split diagonally for the system default.
class ThemePreview extends StatelessWidget {
  const ThemePreview({super.key, required this.choice});

  final ThemeChoice choice;

  @override
  Widget build(BuildContext context) {
    final Widget light = Theme(
      data: SeguiTheme.lightTheme(),
      child: const ThemePreviewPane(time: GreetingTime.morning),
    );
    final Widget dark = Theme(
      data: SeguiTheme.darkTheme(),
      child: const ThemePreviewPane(time: GreetingTime.evening),
    );
    return switch (choice) {
      ThemeChoice.light => light,
      ThemeChoice.dark => dark,
      ThemeChoice.system => Stack(
          fit: StackFit.expand,
          children: [
            light,
            ClipPath(clipper: const ThemeSplitClipper(), child: dark),
          ],
        ),
    };
  }
}

/// A miniature SEGUI window with the gull scene for [time].
class ThemePreviewPane extends StatelessWidget {
  const ThemePreviewPane({super.key, required this.time});

  final GreetingTime time;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: getSEGULBackgroundColor(context) ?? colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: colors.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(SeguiSpacing.sm),
              child: Row(
                children: [
                  for (final Color dot in [
                    colors.primary,
                    colors.tertiary,
                    colors.secondary,
                  ]) ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: dot,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(
                        dimension: SeguiControlSize.indicator,
                      ),
                    ),
                    const SizedBox(width: SeguiSpacing.xs),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(SeguiSpacing.xs),
              child: GullScene(time: time),
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps the part right of a slanted line through the middle, so the dark
/// preview covers the right half of the light one.
class ThemeSplitClipper extends CustomClipper<Path> {
  const ThemeSplitClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width * 0.62, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.38, size.height)
      ..close();
  }

  @override
  bool shouldReclip(ThemeSplitClipper oldClipper) => false;
}
