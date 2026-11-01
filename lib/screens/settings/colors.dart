import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/screens/settings/color_previews.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/equal_height_grid.dart';
import 'package:segui/services/colors.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';

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

/// Chart, heatmap, table, and residue colors, chosen from preview cards,
/// with a live preview of the choices.
class ColorSettingView extends ConsumerStatefulWidget {
  const ColorSettingView({super.key});

  @override
  ConsumerState<ColorSettingView> createState() => _ColorSettingViewState();
}

class _ColorSettingViewState extends ConsumerState<ColorSettingView> {
  /// Color vision deficiency simulated in the preview, or null for none.
  String? _cvd;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorChoices choices =
        ref.watch(colorChoicesProvider(theme.brightness));
    final Widget options = ColorChoiceList(choices: choices);
    final Widget preview = ColorPreviewPanel(
      cvdKinds: choices.cvdKinds,
      cvd: _cvd,
      onCvdChanged: (cvd) => setState(() => _cvd = cvd),
    );
    return LayoutBuilder(builder: (context, constraints) {
      final bool isWide = constraints.maxWidth >=
          SeguiContentWidth.form + SeguiColorSettingsLayout.previewWidth;
      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(SeguiSpacing.xl),
                child: options,
              ),
            ),
            SizedBox(
              width: SeguiColorSettingsLayout.previewWidth,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: SeguiSpacing.xl,
                  right: SeguiSpacing.xl,
                  bottom: SeguiSpacing.xl,
                ),
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
            options,
            const SizedBox(height: SeguiSpacing.xxl),
            preview,
          ],
        ),
      );
    });
  }
}

/// One section of preview cards per color setting.
class ColorChoiceList extends ConsumerWidget {
  const ColorChoiceList({super.key, required this.choices});

  final ColorChoices choices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final String palette = ref.watch(chartPaletteProvider);
    final String colormap = ref.watch(heatmapColormapProvider);
    final TableBarColor tableBar = ref.watch(tableBarColorProvider);
    final String scheme = ref.watch(residueSchemeProvider);
    final AlignmentColorMode mode = ref.watch(alignmentColorModeProvider);
    final SeguiColors colors = SeguiColors.fromTheme(theme);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Data colors', style: theme.textTheme.headlineSmall),
        const SizedBox(height: SeguiSpacing.xs),
        Text(
          'Colors for charts, heatmaps, tables, and the alignment viewer. '
          'They come from the SEGUL color library, so SEGUL plots match. '
          'Lines are darkened or lightened where needed to reach 3:1 '
          'contrast, and text reaches 4.5:1 (WCAG 2.2 AA).',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const ColorSectionTitle(
          title: 'Chart palette',
          subtitle: 'Colors of series in bar and line charts. The strip '
              'under each color is its line color.',
        ),
        ColorChoiceGrid(
          children: [
            for (final PaletteChoice choice in choices.palettes)
              ColorChoiceCard(
                label: choice.label,
                semanticsLabel: '${choice.label} palette, '
                    '${_safety(choice)}',
                isSelected: choice.name == palette,
                onSelected: () =>
                    ref.read(chartPaletteProvider.notifier).set(choice.name),
                badges: [
                  ColorChoiceBadge(
                    icon: choice.isColorblindSafe
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    label: _safety(choice),
                  ),
                  if (choice.adjusted.isNotEmpty)
                    ColorChoiceBadge(
                      icon: Icons.contrast,
                      label: '${choice.adjusted.length} adjusted for lines',
                    ),
                ],
                child: PaletteSwatch(fills: choice.fills, lines: choice.lines),
              ),
          ],
        ),
        if (choices.colormaps.isNotEmpty) ...[
          const ColorSectionTitle(
            title: 'Heatmap colormap',
            subtitle: 'Shades of heatmap cells, from low to high values.',
          ),
          ColorChoiceGrid(
            children: [
              for (final ColormapChoice choice in choices.colormaps)
                ColorChoiceCard(
                  label: choice.label,
                  semanticsLabel: '${choice.label} colormap, '
                      '${choice.isDiverging ? 'diverging' : 'sequential'}',
                  isSelected: choice.name == colormap,
                  onSelected: () => ref
                      .read(heatmapColormapProvider.notifier)
                      .set(choice.name),
                  badges: [
                    ColorChoiceBadge(
                      icon: choice.isDiverging
                          ? Icons.compare_arrows
                          : Icons.trending_up,
                      label: choice.isDiverging ? 'Diverging' : 'Sequential',
                    ),
                  ],
                  child: GradientBar(stops: choice.stops),
                ),
            ],
          ),
        ],
        const ColorSectionTitle(
          title: 'Table data bars',
          subtitle: 'Bars behind numbers in report tables.',
        ),
        ColorChoiceGrid(
          children: [
            for (final TableBarColor choice in TableBarColor.values)
              ColorChoiceCard(
                label: choice.label,
                semanticsLabel: 'Table bars in ${choice.label.toLowerCase()}',
                isSelected: choice == tableBar,
                onSelected: () =>
                    ref.read(tableBarColorProvider.notifier).set(choice),
                child: MiniDataTable(
                  barColor: choice == TableBarColor.palette
                      ? colors.seriesAt(0)
                      : theme.colorScheme.primary,
                ),
              ),
          ],
        ),
        const ColorSectionTitle(
          title: 'Alignment residues',
          subtitle: 'Residue colors in the alignment viewer, for DNA and '
              'amino acids.',
        ),
        ColorChoiceGrid(
          children: [
            for (final ResidueChoice choice in choices.residueSchemes)
              ColorChoiceCard(
                label: choice.label,
                semanticsLabel: '${choice.label} residue colors',
                isSelected: choice.name == scheme,
                onSelected: () =>
                    ref.read(residueSchemeProvider.notifier).set(choice.name),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MiniAlignment(
                      palette: choice.nucleotide,
                      rows: sampleDna,
                      mode: mode,
                    ),
                    const SizedBox(height: SeguiSpacing.sm),
                    MiniAlignment(
                      palette: choice.aminoAcid,
                      rows: sampleProtein,
                      mode: mode,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: SeguiSpacing.lg),
        Text('Color mode', style: theme.textTheme.titleSmall),
        const SizedBox(height: SeguiSpacing.sm),
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

  static String _safety(PaletteChoice choice) {
    if (choice.isColorblindSafe) return 'Colorblind safe';
    if (choice.colorblindSafe == 0) return 'Not colorblind safe';
    return 'Colorblind safe for ${choice.colorblindSafe} colors';
  }
}

class ColorSectionTitle extends StatelessWidget {
  const ColorSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: SeguiSpacing.xxl,
        bottom: SeguiSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: SeguiSpacing.xxs),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Choice cards in as many columns as fit.
class ColorChoiceGrid extends StatelessWidget {
  const ColorChoiceGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return EqualHeightGrid(
        columns: gridColumnCount(
          constraints.maxWidth,
          minItemWidth: SeguiColorSettingsLayout.choiceWidth,
          maxColumns: 3,
        ),
        children: children,
      );
    });
  }
}

/// A selectable color option with its preview. Selection shows as a check
/// and a thicker outline, not by color alone.
class ColorChoiceCard extends StatelessWidget {
  const ColorChoiceCard({
    super.key,
    required this.label,
    required this.semanticsLabel,
    required this.isSelected,
    required this.onSelected,
    required this.child,
    this.badges = const [],
  });

  final String label;
  final String semanticsLabel;
  final bool isSelected;
  final VoidCallback onSelected;
  final Widget child;
  final List<Widget> badges;

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
          borderRadius: BorderRadius.circular(SeguiRadius.lg),
          side: BorderSide(
            color: isSelected ? colors.primary : colors.outlineVariant,
            width: isSelected ? SeguiStroke.regular : SeguiStroke.thin,
          ),
        ),
        child: InkWell(
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.all(SeguiSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                child,
                const SizedBox(height: SeguiSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: textColor,
                        ),
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
                if (badges.isNotEmpty) ...[
                  const SizedBox(height: SeguiSpacing.xs),
                  Wrap(
                    spacing: SeguiSpacing.md,
                    runSpacing: SeguiSpacing.xxs,
                    children: badges,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ColorChoiceBadge extends StatelessWidget {
  const ColorChoiceBadge({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: SeguiControlSize.iconSmall, color: color),
        const SizedBox(width: SeguiSpacing.xxs),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
      ],
    );
  }
}

/// A chart, heatmap, table, and alignment drawn with the chosen colors,
/// optionally as seen with a color vision deficiency, and the weakest
/// contrast among them.
class ColorPreviewPanel extends ConsumerWidget {
  const ColorPreviewPanel({
    super.key,
    required this.cvdKinds,
    required this.cvd,
    required this.onCvdChanged,
  });

  final List<(String, String)> cvdKinds;
  final String? cvd;
  final ValueChanged<String?> onCvdChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorLibraryServices library = ref.watch(colorLibraryProvider);
    final AlignmentColorMode mode = ref.watch(alignmentColorModeProvider);
    final SeguiColors chosen = SeguiColors.fromTheme(theme);
    final SeguiColors colors =
        cvd == null ? chosen : library.simulateAll(chosen, cvd!);
    final ContrastSummary? contrast = _summarize(library, colors, theme);
    return OutlinedPanel(
      child: Padding(
        padding: const EdgeInsets.all(SeguiSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Preview', style: theme.textTheme.titleMedium),
            const SizedBox(height: SeguiSpacing.md),
            if (cvdKinds.isNotEmpty) ...[
              Text('Seen with', style: theme.textTheme.labelMedium),
              const SizedBox(height: SeguiSpacing.xs),
              DropdownMenu<String?>(
                initialSelection: cvd,
                expandedInsets: EdgeInsets.zero,
                label: const Text('Color vision'),
                onSelected: onCvdChanged,
                dropdownMenuEntries: [
                  const DropdownMenuEntry(value: null, label: 'Typical vision'),
                  for (final (String name, String label) in cvdKinds)
                    DropdownMenuEntry(value: name, label: label),
                ],
              ),
              const SizedBox(height: SeguiSpacing.lg),
            ],
            Text('Charts', style: theme.textTheme.labelMedium),
            const SizedBox(height: SeguiSpacing.xs),
            MiniChart(colors: colors),
            const SizedBox(height: SeguiSpacing.lg),
            Text('Heatmap', style: theme.textTheme.labelMedium),
            const SizedBox(height: SeguiSpacing.xs),
            MiniHeatmap(colors: colors),
            const SizedBox(height: SeguiSpacing.lg),
            Text('Table', style: theme.textTheme.labelMedium),
            MiniDataTable(barColor: colors.dataBar(theme.colorScheme)),
            const SizedBox(height: SeguiSpacing.lg),
            Text('Alignment', style: theme.textTheme.labelMedium),
            const SizedBox(height: SeguiSpacing.xs),
            MiniAlignment(
              palette: colors.nucleotide,
              rows: sampleDna,
              mode: mode,
            ),
            const SizedBox(height: SeguiSpacing.xs),
            MiniAlignment(
              palette: colors.aminoAcid,
              rows: sampleProtein,
              mode: mode,
            ),
            if (contrast != null) ...[
              const SizedBox(height: SeguiSpacing.lg),
              Wrap(
                spacing: SeguiSpacing.md,
                runSpacing: SeguiSpacing.xs,
                children: [
                  ContrastBadge(
                    label: 'Text',
                    ratio: contrast.text,
                    minimum: textContrast,
                  ),
                  ContrastBadge(
                    label: 'Lines',
                    ratio: contrast.lines,
                    minimum: nonTextContrast,
                  ),
                ],
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
