import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:segui/screens/shared/equal_height_grid.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

/// Every SEGUI tool grouped by category, filtered by [query].
class ToolCatalog extends StatelessWidget {
  const ToolCatalog({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final List<ToolCategory> categories = ToolCategory.values
        .where((category) => filterHomeTools(category, query).isNotEmpty)
        .toList();
    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: SeguiSpacing.xxxl),
        child: Text(
          'No tools match "${query.trim()}".',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final category in categories)
          Padding(
            padding: const EdgeInsets.only(bottom: SeguiSpacing.xxl),
            child: ToolCategorySection(
              category: category,
              tools: filterHomeTools(category, query),
            ),
          ),
      ],
    );
  }
}

class ToolCategorySection extends ConsumerWidget {
  const ToolCategorySection({
    super.key,
    required this.category,
    required this.tools,
  });

  final ToolCategory category;
  final List<HomeTool> tools;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text.rich(
                TextSpan(
                  text: category.label,
                  style: textTheme.titleMedium,
                  children: [
                    TextSpan(
                      text: '  ${category.description}',
                      style: textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: SeguiSpacing.md),
            TextButton(
              onPressed: () => ref
                  .read(tabSelectionProvider.notifier)
                  .setTab(category.tabIndex),
              child: const Text('Open'),
            ),
          ],
        ),
        const SizedBox(height: SeguiSpacing.md),
        ToolGrid(tools: tools),
      ],
    );
  }
}

/// Lays out [tools] as equal-size cards, adding columns as the width grows.
class ToolGrid extends StatelessWidget {
  const ToolGrid({super.key, required this.tools});

  final List<HomeTool> tools;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return EqualHeightGrid(
        columns: gridColumnCount(
          constraints.maxWidth,
          minItemWidth: 300,
          maxColumns: 6,
        ),
        children: [
          for (final tool in tools) ToolCard(tool: tool),
        ],
      );
    });
  }
}

class ToolCard extends ConsumerWidget {
  const ToolCard({super.key, required this.tool});

  final HomeTool tool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ref.read(homeToolNavigatorProvider).open(tool),
        child: Padding(
          padding: const EdgeInsets.all(SeguiSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToolCategoryIcon(tool: tool),
              const SizedBox(width: SeguiSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.title,
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: SeguiSpacing.xxs),
                    ToolDescription(text: tool.description),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tool description that always takes two lines, so cards in different
/// category grids line up at the same height.
class ToolDescription extends StatelessWidget {
  const ToolDescription({super.key, required this.text});

  static const int lines = 2;

  final String text;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return Stack(
      children: [
        // Invisible placeholder that reserves two lines at the current
        // text scale.
        ExcludeSemantics(
          child: Opacity(
            opacity: 0,
            child: Text('\n' * (lines - 1), style: style, maxLines: lines),
          ),
        ),
        Text(
          text,
          style: style,
          maxLines: lines,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Tool SVG icon on a tile tinted by the tool's category.
class ToolCategoryIcon extends StatelessWidget {
  const ToolCategoryIcon({
    super.key,
    required this.tool,
    this.size = SeguiControlSize.control,
  });

  final HomeTool tool;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final (Color background, Color foreground) = switch (tool.category) {
      ToolCategory.genomics => (
          colors.tertiaryContainer,
          colors.onTertiaryContainer
        ),
      ToolCategory.alignment => (
          colors.primaryContainer,
          colors.onPrimaryContainer
        ),
      ToolCategory.sequence => (
          colors.secondaryContainer,
          colors.onSecondaryContainer
        ),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        tool.svgAsset,
        width: size * 0.55,
        height: size * 0.55,
        colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
        semanticsLabel: tool.title,
      ),
    );
  }
}
