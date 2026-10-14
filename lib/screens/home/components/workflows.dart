import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/screens/home/components/tool_catalog.dart';
import 'package:segui/screens/shared/equal_height_grid.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/styles/decoration.dart';

/// Common workflows next to an alphabetical index of every tool.
class WorkflowPanel extends StatelessWidget {
  const WorkflowPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= expandedScreenSize) {
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: WorkflowList()),
            SizedBox(width: 24),
            SizedBox(width: 300, child: ToolIndex()),
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
class ToolIndex extends ConsumerWidget {
  const ToolIndex({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<HomeTool> tools = sortedHomeTools;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                'Tool index (${tools.length})',
                style: theme.textTheme.titleMedium,
              ),
            ),
            for (final tool in tools)
              ListTile(
                dense: true,
                leading: ToolCategoryIcon(tool: tool, size: 28),
                title: Text(tool.title, overflow: TextOverflow.ellipsis),
                subtitle: Text(tool.category.label),
                onTap: () => ref.read(homeToolNavigatorProvider).open(tool),
              ),
          ],
        ),
      ),
    );
  }
}
