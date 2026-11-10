import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/screens/settings/color_previews.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/side_panel.dart';
import 'package:segui/services/colors.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';

/// The groups of color settings, one per page of the editor.
enum ColorCategory {
  charts('Charts', Icons.bar_chart_outlined),
  heatmaps('Heatmaps', Icons.grid_view_outlined),
  tables('Tables', Icons.table_rows_outlined),
  alignments('Alignments', Icons.view_column_outlined);

  const ColorCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

class ColorSettings extends StatelessWidget {
  const ColorSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Colors'),
        backgroundColor: getSEGULBackgroundColor(context),
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: const SafeArea(child: ColorSettingView()),
    );
  }
}

/// Color settings as an editor: a category rail, the options of the chosen
/// category, and a large preview of them. Narrow screens show the
/// categories as chips, with the preview above the options.
class ColorSettingView extends ConsumerStatefulWidget {
  const ColorSettingView({super.key});

  @override
  ConsumerState<ColorSettingView> createState() => _ColorSettingViewState();
}

class _ColorSettingViewState extends ConsumerState<ColorSettingView> {
  ColorCategory _category = ColorCategory.charts;

  /// Color vision deficiency simulated in the preview, or null for none.
  String? _cvd;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorChoices choices =
        ref.watch(colorChoicesProvider(theme.brightness));
    final Widget options = ColorOptionList(
      category: _category,
      choices: choices,
    );
    final Widget preview = ColorPreview(
      category: _category,
      choices: choices,
      cvd: _cvd,
      onCvdChanged: (cvd) => setState(() => _cvd = cvd),
    );
    return LayoutBuilder(builder: (context, constraints) {
      final double content =
          constraints.maxWidth - SeguiColorSettingsLayout.railWidth;
      if (content >=
          SeguiColorSettingsLayout.optionsWidth +
              SeguiColorSettingsLayout.previewWidth) {
        // The option list takes a share of the space, so swatches and
        // gradients grow on wide screens.
        final double optionsWidth =
            (content * SeguiColorSettingsLayout.optionsShare).clamp(
          SeguiColorSettingsLayout.optionsWidth,
          SeguiColorSettingsLayout.optionsMaxWidth,
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColorCategoryRail(
              selected: _category,
              onSelected: (c) => setState(() => _category = c),
            ),
            SizedBox(
              width: optionsWidth,
              // The preview's padding supplies the gap between the two
              // columns, so every edge is spaced alike.
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  SeguiSpacing.xl,
                  SeguiSpacing.xl,
                  0,
                  SeguiSpacing.xl,
                ),
                child: options,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(SeguiSpacing.xl),
                child: preview,
              ),
            ),
          ],
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(SeguiSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColorCategoryChips(
              selected: _category,
              onSelected: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: SeguiSpacing.lg),
            preview,
            const SizedBox(height: SeguiSpacing.lg),
            options,
          ],
        ),
      );
    });
  }
}

/// The inner rail of the Colors page, styled like the tool list.
class ColorCategoryRail extends StatelessWidget {
  const ColorCategoryRail({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ColorCategory selected;
  final ValueChanged<ColorCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SidePanel(
      width: SeguiColorSettingsLayout.railWidth,
      children: [
        for (final ColorCategory category in ColorCategory.values)
          SidePanelTile(
            icon: category.icon,
            title: category.label,
            isSelected: category == selected,
            onTap: () => onSelected(category),
          ),
      ],
    );
  }
}

/// Categories as chips, for narrow screens.
class ColorCategoryChips extends StatelessWidget {
  const ColorCategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ColorCategory selected;
  final ValueChanged<ColorCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: SeguiSpacing.md,
      runSpacing: SeguiSpacing.xs,
      children: [
        for (final ColorCategory category in ColorCategory.values)
          ChoiceChip(
            avatar: Icon(category.icon),
            label: Text(category.label),
            selected: category == selected,
            showCheckmark: false,
            onSelected: (_) => onSelected(category),
          ),
      ],
    );
  }
}

/// The options of one category, each with a small sample of its colors.
class ColorOptionList extends ConsumerWidget {
  const ColorOptionList({
    super.key,
    required this.category,
    required this.choices,
  });

  final ColorCategory category;
  final ColorChoices choices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<Widget> tiles = switch (category) {
      ColorCategory.charts => [
          for (final PaletteChoice choice in choices.palettes)
            ColorOptionTile(
              label: choice.label,
              semanticsLabel: '${choice.label}, ${paletteSafety(choice)}',
              isSelected: choice.name == ref.watch(chartPaletteProvider),
              onSelected: () =>
                  ref.read(chartPaletteProvider.notifier).set(choice.name),
              sample: PaletteSwatch(fills: choice.fills, lines: choice.lines),
            ),
        ],
      ColorCategory.heatmaps => [
          for (final ColormapChoice choice in choices.colormaps)
            ColorOptionTile(
              label: choice.label,
              semanticsLabel: choice.label,
              isSelected: choice.name == ref.watch(heatmapColormapProvider),
              onSelected: () =>
                  ref.read(heatmapColormapProvider.notifier).set(choice.name),
              sample: GradientBar(stops: choice.stops),
            ),
        ],
      ColorCategory.tables => [
          for (final TableBarColor choice in TableBarColor.values)
            ColorOptionTile(
              label: choice.label,
              semanticsLabel: choice.label,
              isSelected: choice == ref.watch(tableBarColorProvider),
              onSelected: () =>
                  ref.read(tableBarColorProvider.notifier).set(choice),
              sample: GradientBar(
                stops: [
                  choice == TableBarColor.palette
                      ? SeguiColors.fromTheme(theme).seriesAt(0)
                      : theme.colorScheme.primary,
                ],
              ),
            ),
        ],
      ColorCategory.alignments => [
          for (final ResidueChoice choice in choices.residueSchemes)
            ColorOptionTile(
              label: choice.label,
              semanticsLabel: choice.label,
              isSelected: choice.name == ref.watch(residueSchemeProvider),
              onSelected: () =>
                  ref.read(residueSchemeProvider.notifier).set(choice.name),
              sample: MiniAlignment(
                palette: choice.nucleotide,
                rows: sampleDna.sublist(0, 1),
              ),
            ),
        ],
    };
    // No padding of its own, so the tiles line up with the preview card.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (int index, Widget tile) in tiles.indexed) ...[
          if (index > 0) const SizedBox(height: SeguiSpacing.sm),
          tile,
        ],
      ],
    );
  }
}

/// How many colors of a palette stay distinct with color vision
/// deficiencies, in a few words.
String paletteSafety(PaletteChoice choice) {
  if (choice.isColorblindSafe) return 'Colorblind safe';
  if (choice.colorblindSafe == 0) return 'Not colorblind safe';
  return 'Colorblind safe up to ${choice.colorblindSafe}';
}

/// A selectable option with a sample of its colors. Selection shows as a
/// check and a thicker outline, not by color alone.
class ColorOptionTile extends StatelessWidget {
  const ColorOptionTile({
    super.key,
    required this.label,
    required this.semanticsLabel,
    required this.isSelected,
    required this.onSelected,
    required this.sample,
  });

  final String label;
  final String semanticsLabel;
  final bool isSelected;
  final VoidCallback onSelected;
  final Widget sample;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color textColor =
        isSelected ? colors.onSecondaryContainer : colors.onSurface;
    return Semantics(
      label: semanticsLabel,
      selected: isSelected,
      button: true,
      inMutuallyExclusiveGroup: true,
      excludeSemantics: true,
      child: Card.outlined(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: isSelected ? colors.secondaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SeguiRadius.md),
          side: BorderSide(
            color: isSelected ? colors.primary : colors.outlineVariant,
            width: isSelected ? SeguiStroke.regular : SeguiStroke.thin,
          ),
        ),
        child: InkWell(
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.all(SeguiSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        size: SeguiControlSize.iconSmall,
                        color: textColor,
                      ),
                  ],
                ),
                const SizedBox(height: SeguiSpacing.sm),
                sample,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A large preview of the chosen category in the current colors, as seen
/// with typical vision or a color vision deficiency.
class ColorPreview extends ConsumerWidget {
  const ColorPreview({
    super.key,
    required this.category,
    required this.choices,
    required this.cvd,
    required this.onCvdChanged,
  });

  final ColorCategory category;
  final ColorChoices choices;
  final String? cvd;
  final ValueChanged<String?> onCvdChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorLibraryServices library = ref.watch(colorLibraryProvider);
    final AlignmentColorMode mode = ref.watch(alignmentColorModeProvider);
    final String paletteName = ref.watch(chartPaletteProvider);
    final SeguiColors chosen = SeguiColors.fromTheme(theme);
    final SeguiColors colors =
        cvd == null ? chosen : library.simulateAll(chosen, cvd!);
    final ContrastSummary? contrast = _summarize(library, colors, theme);
    final PaletteChoice? palette =
        choices.palettes.where((p) => p.name == paletteName).firstOrNull;
    final List<Widget> badges = [
      if (category == ColorCategory.charts && palette != null)
        ColorPreviewBadge(
          icon: palette.isColorblindSafe
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          label: paletteSafety(palette),
        ),
      if (contrast != null && category == ColorCategory.charts)
        ContrastBadge(
          label: 'Lines',
          ratio: contrast.lines,
          minimum: nonTextContrast,
        ),
      if (contrast != null && category == ColorCategory.tables)
        ContrastBadge(
          label: 'Text',
          ratio: contrast.table,
          minimum: textContrast,
        ),
      if (contrast != null && category == ColorCategory.alignments)
        ContrastBadge(
          label: 'Text',
          ratio: contrast.residues,
          minimum: textContrast,
        ),
    ];
    // Same card as the tool forms.
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(SeguiFormLayout.cardRadius),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SeguiFormLayout.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Preview', style: theme.textTheme.titleMedium),
                ),
                if (choices.cvdKinds.isNotEmpty)
                  // Rounded and filled like the tool form fields.
                  FormFieldTheme(
                    child: DropdownMenu<String?>(
                      initialSelection: cvd,
                      label: const Text('Color vision'),
                      onSelected: onCvdChanged,
                      menuStyle: MenuStyle(
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              SeguiFormLayout.fieldRadius,
                            ),
                          ),
                        ),
                      ),
                      dropdownMenuEntries: [
                        const DropdownMenuEntry(
                          value: null,
                          label: 'Typical vision',
                        ),
                        for (final (String name, String label)
                            in choices.cvdKinds)
                          DropdownMenuEntry(value: name, label: label),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: SeguiSpacing.xl),
            switch (category) {
              ColorCategory.charts => MiniChart(colors: colors, series: 6),
              ColorCategory.heatmaps => HeatmapPreview(colors: colors),
              ColorCategory.tables => MiniDataTable(
                  barColor: colors.dataBar(theme.colorScheme),
                ),
              ColorCategory.alignments => AlignmentPreview(
                  colors: colors,
                  mode: mode,
                ),
            },
            if (badges.isNotEmpty) ...[
              const SizedBox(height: SeguiSpacing.lg),
              Wrap(
                spacing: SeguiSpacing.md,
                runSpacing: SeguiSpacing.xs,
                children: badges,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // The bridge is missing in some tests; the badges are then left out.
  ContrastSummary? _summarize(
    ColorLibraryServices library,
    SeguiColors colors,
    ThemeData theme,
  ) {
    try {
      return library.summarize(colors, theme.colorScheme);
    } catch (_) {
      return null;
    }
  }
}

/// A heatmap with its low-to-high legend.
class HeatmapPreview extends StatelessWidget {
  const HeatmapPreview({super.key, required this.colors});

  final SeguiColors colors;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MiniHeatmap(colors: colors, rows: 10, columns: 24),
        const SizedBox(height: SeguiSpacing.md),
        GradientBar(stops: colors.heatmap),
        const SizedBox(height: SeguiSpacing.xxs),
        Row(
          children: [
            Text('Low', style: style),
            const Spacer(),
            Text('High', style: style),
          ],
        ),
      ],
    );
  }
}

/// DNA and amino acid samples with the color mode switch.
class AlignmentPreview extends ConsumerWidget {
  const AlignmentPreview({super.key, required this.colors, required this.mode});

  final SeguiColors colors;
  final AlignmentColorMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MiniAlignment(
          palette: colors.nucleotide,
          rows: sampleDna,
          mode: mode,
          cellSize: SeguiColorSettingsLayout.previewResidueCell,
        ),
        const SizedBox(height: SeguiSpacing.lg),
        MiniAlignment(
          palette: colors.aminoAcid,
          rows: sampleProtein,
          mode: mode,
          cellSize: SeguiColorSettingsLayout.previewResidueCell,
        ),
        const SizedBox(height: SeguiSpacing.xl),
        SegmentedButton<AlignmentColorMode>(
          segments: [
            for (final AlignmentColorMode m in AlignmentColorMode.values)
              ButtonSegment(value: m, label: Text(m.label)),
          ],
          selected: {mode},
          onSelectionChanged: (selected) =>
              ref.read(alignmentColorModeProvider.notifier).set(selected.first),
        ),
      ],
    );
  }
}

class ColorPreviewBadge extends StatelessWidget {
  const ColorPreviewBadge({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
