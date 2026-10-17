import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/home/components/illustration.dart';
import 'package:segui/screens/home/components/tool_catalog.dart';
import 'package:segui/screens/shared/equal_height_grid.dart';
import 'package:segui/screens/shared/illustrations.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/services/quick_start.dart';
import 'package:segui/services/utils.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

/// How to run a task, then a guide for every tool with its feature diagram.
class QuickStartPage extends StatefulWidget {
  const QuickStartPage({super.key});

  @override
  State<QuickStartPage> createState() => _QuickStartPageState();
}

class _QuickStartPageState extends State<QuickStartPage> {
  /// Category shown in the guide grid, or every tool when null.
  ToolCategory? _category;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick start'),
        backgroundColor: getSEGULBackgroundColor(context),
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal:
              isPhoneScreen(context) ? SeguiSpacing.xl : SeguiSpacing.xxxl,
          vertical: SeguiSpacing.xl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: SeguiContentWidth.guide),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const QuickStartHeader(),
                const SizedBox(height: SeguiSpacing.xl),
                const QuickStartSteps(),
                const SizedBox(height: SeguiSpacing.xxxl),
                Text('Feature guides', style: theme.textTheme.titleMedium),
                const SizedBox(height: SeguiSpacing.xs),
                Text(
                  'See what each tool does to your data, then open it.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: SeguiSpacing.lg),
                FeatureGuideFilter(
                  selected: _category,
                  onSelected: (category) {
                    setState(() {
                      _category = category;
                    });
                  },
                ),
                const SizedBox(height: SeguiSpacing.lg),
                FeatureGuideGrid(tools: featureGuidesFor(_category)),
                const SizedBox(height: SeguiSpacing.xl),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: LaunchDocButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The gull with the quick start title.
class QuickStartHeader extends StatelessWidget {
  const QuickStartHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: [
        const QuickStartGull(size: SeguiControlSize.illustrationSmall),
        const SizedBox(width: SeguiSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Run your first task in five steps',
                style: theme.textTheme.headlineSmall,
              ),
              Text(
                'Every tool works the same way.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The SEGUL gull, drawn in theme colors.
class QuickStartGull extends StatelessWidget {
  const QuickStartGull({super.key, required this.size});

  static const String asset = 'assets/images/quick_start_gull.svg';

  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SvgPicture(
        SvgAssetLoader(
          asset,
          colorMapper: HomeIllustrationColors(
            line: colors.primary,
            accent: colors.tertiaryContainer,
            fill: colors.surface,
          ),
        ),
        width: size,
        height: size,
      ),
    );
  }
}

/// The five steps shared by every tool, in a row on wide screens.
class QuickStartSteps extends StatelessWidget {
  const QuickStartSteps({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return EqualHeightGrid(
        columns: gridColumnCount(
          constraints.maxWidth,
          minItemWidth: 180,
          maxColumns: quickStartSteps.length,
        ),
        children: [
          for (final (index, step) in quickStartSteps.indexed)
            QuickStartStepCard(number: index + 1, step: step),
        ],
      );
    });
  }
}

class QuickStartStepCard extends StatelessWidget {
  const QuickStartStepCard({
    super.key,
    required this.number,
    required this.step,
  });

  final int number;
  final QuickStartStep step;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(SeguiSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: SeguiControlSize.badge / 2,
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  child: Text(
                    '$number',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.onPrimary,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(step.icon, color: colors.primary),
              ],
            ),
            const SizedBox(height: SeguiSpacing.lg),
            Text(step.title, style: theme.textTheme.titleSmall),
            const SizedBox(height: SeguiSpacing.xs),
            Text(
              step.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chips that filter the feature guides by category.
class FeatureGuideFilter extends StatelessWidget {
  const FeatureGuideFilter({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ToolCategory? selected;
  final ValueChanged<ToolCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: SeguiSpacing.md,
      runSpacing: SeguiSpacing.md,
      children: [
        ChoiceChip(
          label: Text('All (${homeTools.length})'),
          selected: selected == null,
          onSelected: (_) => onSelected(null),
        ),
        for (final category in ToolCategory.values)
          ChoiceChip(
            label: Text(
              '${category.label} (${featureGuidesFor(category).length})',
            ),
            selected: selected == category,
            onSelected: (_) => onSelected(category),
          ),
      ],
    );
  }
}

class FeatureGuideGrid extends StatelessWidget {
  const FeatureGuideGrid({super.key, required this.tools});

  final List<HomeTool> tools;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return EqualHeightGrid(
        columns: gridColumnCount(
          constraints.maxWidth,
          minItemWidth: 300,
          maxColumns: 3,
        ),
        children: [for (final tool in tools) FeatureGuideCard(tool: tool)],
      );
    });
  }
}

/// A tool's feature diagram with buttons to read its guide or open it.
class FeatureGuideCard extends ConsumerWidget {
  const FeatureGuideCard({super.key, required this.tool});

  final HomeTool tool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openGuide(context),
        // The grid measures cards with an unbounded height, so push the
        // buttons down with spaceBetween instead of a Spacer.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: SeguiControlSize.diagramPreview,
                  color: colors.surfaceContainerLow,
                  padding: const EdgeInsets.all(SeguiSpacing.lg),
                  child: FeatureDiagram(asset: tool.diagramAssets.first),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SeguiSpacing.xl,
                    SeguiSpacing.lg,
                    SeguiSpacing.xl,
                    SeguiSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      ToolCategoryIcon(
                          tool: tool, size: SeguiControlSize.badge),
                      const SizedBox(width: SeguiSpacing.lg),
                      Expanded(
                        child: Text(
                          tool.title,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: SeguiSpacing.xl),
                  child: Text(
                    tool.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SeguiSpacing.lg,
                SeguiSpacing.md,
                SeguiSpacing.lg,
                SeguiSpacing.lg,
              ),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: SeguiSpacing.xs,
                runSpacing: SeguiSpacing.xs,
                children: [
                  TextButton(
                    onPressed: () => _openGuide(context),
                    child: const Text('View guide'),
                  ),
                  OpenToolButton(tool: tool),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openGuide(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => FeatureGuidePage(tool: tool)),
    );
  }
}

/// Leaves the quick start and opens [tool] on its page.
class OpenToolButton extends ConsumerWidget {
  const OpenToolButton({super.key, required this.tool});

  final HomeTool tool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.tonal(
      onPressed: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ref.read(homeToolNavigatorProvider).open(tool);
      },
      child: const Text('Open tool'),
    );
  }
}

/// The full feature guide for one tool.
class FeatureGuidePage extends StatelessWidget {
  const FeatureGuidePage({super.key, required this.tool});

  /// Narrowest width a diagram is drawn at. Narrower screens scroll it.
  static const double minDiagramWidth = 520;

  final HomeTool tool;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tool.title),
        backgroundColor: getSEGULBackgroundColor(context),
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal:
              isPhoneScreen(context) ? SeguiSpacing.xl : SeguiSpacing.xxxl,
          vertical: SeguiSpacing.xl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SeguiContentWidth.wide),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ToolCategoryIcon(tool: tool, size: SeguiControlSize.avatar),
                    const SizedBox(width: SeguiSpacing.lg),
                    Expanded(
                      child: Text(
                        tool.category.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SeguiSpacing.lg),
                Text(tool.about, style: theme.textTheme.bodyLarge),
                const SizedBox(height: SeguiSpacing.xl),
                for (final asset in tool.diagramAssets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: SeguiSpacing.xl),
                    child: Card.filled(
                      margin: EdgeInsets.zero,
                      color: colors.surfaceContainerLow,
                      child: Padding(
                        padding: const EdgeInsets.all(SeguiSpacing.xl),
                        child: LayoutBuilder(builder: (context, constraints) {
                          final double width = math.max(
                            constraints.maxWidth,
                            minDiagramWidth,
                          );
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: width,
                              child: FeatureDiagram(
                                asset: asset,
                                semanticsLabel: '${tool.title} diagram',
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                Text('How to run it', style: theme.textTheme.titleMedium),
                const SizedBox(height: SeguiSpacing.md),
                for (final (index, step) in quickStartSteps.indexed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: SeguiControlSize.badge / 2,
                      backgroundColor: colors.primaryContainer,
                      foregroundColor: colors.onPrimaryContainer,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(step.title),
                    subtitle: Text(step.description),
                  ),
                const SizedBox(height: SeguiSpacing.xl),
                Wrap(
                  spacing: SeguiSpacing.md,
                  runSpacing: SeguiSpacing.md,
                  children: [
                    OpenToolButton(tool: tool),
                    OutlinedButton(
                      onPressed: launchSegulFeaturesUrl,
                      child: const Text('Feature guides on the website'),
                    ),
                  ],
                ),
                const SizedBox(height: SeguiSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LaunchDocButton extends StatelessWidget {
  const LaunchDocButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: launchSegulDocUrl,
      child: const Text('Read the documentation'),
    );
  }
}
