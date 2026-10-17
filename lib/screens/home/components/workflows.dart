import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/screens/home/components/tool_catalog.dart';
import 'package:segui/screens/shared/equal_height_grid.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/styles/decoration.dart';

/// Width of the tool list beside the workflows on wide screens.
const double toolIndexWidth = 300;

/// Common workflows next to an alphabetical list of every tool.
class WorkflowPanel extends StatelessWidget {
  const WorkflowPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= expandedScreenSize) {
        // The workflows set the height. The tool list fills the same height
        // and scrolls, so it never extends past the workflow cards.
        return const Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(right: toolIndexWidth + 24),
              child: WorkflowList(),
            ),
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: toolIndexWidth,
              child: ToolIndex(isScrollable: true),
            ),
          ],
        );
      }
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WorkflowList(),
          SizedBox(height: 24),
          ToolIndex(),
        ],
      );
    });
  }
}

class WorkflowList extends StatelessWidget {
  const WorkflowList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Common workflows',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          return EqualHeightGrid(
            columns: gridColumnCount(
              constraints.maxWidth,
              minItemWidth: 360,
              maxColumns: 3,
            ),
            children: [
              for (final workflow in homeWorkflows)
                WorkflowCard(workflow: workflow),
            ],
          );
        }),
      ],
    );
  }
}

class WorkflowCard extends ConsumerWidget {
  const WorkflowCard({super.key, required this.workflow});

  final HomeWorkflow workflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(workflow.title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              workflow.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 4,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (index, tool) in workflow.steps.indexed) ...[
                  if (index > 0)
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                  ActionChip(
                    avatar: Icon(tool.icon),
                    label: Text(tool.title),
                    tooltip: tool.description,
                    onPressed: () =>
                        ref.read(homeToolNavigatorProvider).open(tool),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Alphabetical list of every tool.
///
/// With [isScrollable], the list fills the height it is given and scrolls.
/// Otherwise, it shows every tool at full height.
class ToolIndex extends ConsumerWidget {
  const ToolIndex({super.key, this.isScrollable = false});

  final bool isScrollable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<HomeTool> tools = sortedHomeTools;
    final Widget title = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 4, 4),
      child: Text('All tools', style: theme.textTheme.titleMedium),
    );
    return Card.filled(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        // Equal right and bottom padding keeps the scrollbar off both edges.
        padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
        child: isScrollable
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  title,
                  Expanded(
                    child: ListView.builder(
                      itemCount: tools.length,
                      itemBuilder: (context, index) =>
                          ToolIndexTile(tool: tools[index]),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  title,
                  for (final tool in tools) ToolIndexTile(tool: tool)
                ],
              ),
      ),
    );
  }
}

/// A tool in [ToolIndex] that opens the tool when tapped.
class ToolIndexTile extends ConsumerWidget {
  const ToolIndexTile({super.key, required this.tool});

  final HomeTool tool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      leading: ToolCategoryIcon(tool: tool, size: 28),
      title: Text(tool.title, overflow: TextOverflow.ellipsis),
      subtitle: Text(tool.category.label),
      onTap: () => ref.read(homeToolNavigatorProvider).open(tool),
    );
  }
}
