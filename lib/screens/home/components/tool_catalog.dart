import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/styles/decoration.dart';

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
        padding: const EdgeInsets.symmetric(vertical: 32),
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
            padding: const EdgeInsets.only(bottom: 24),
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
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => ref
                  .read(tabSelectionProvider.notifier)
                  .setTab(category.tabIndex),
              child: const Text('Open'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ToolGrid(tools: tools),
      ],
    );
  }
}

/// Lays out [tools] as cards in one to three columns.
class ToolGrid extends StatelessWidget {
  const ToolGrid({super.key, required this.tools});

  final List<HomeTool> tools;

  @override
  Widget build(BuildContext context) {
    const double spacing = 12;
    return LayoutBuilder(builder: (context, constraints) {
      final int columns = constraints.maxWidth >= expandedScreenSize
          ? 3
          : constraints.maxWidth >= 520
              ? 2
              : 1;
      final double cardWidth =
          (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final tool in tools)
            SizedBox(width: cardWidth, child: ToolCard(tool: tool)),
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
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToolCategoryIcon(tool: tool),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.title,
                      style: textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tool.description,
                      style: textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    );
  }
}

/// Tool icon on a tile tinted by the tool's category.
class ToolCategoryIcon extends StatelessWidget {
  const ToolCategoryIcon({super.key, required this.tool, this.size = 40});

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
      child: Icon(tool.icon, size: size * 0.55, color: foreground),
    );
  }
}
