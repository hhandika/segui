import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/screens/shared/io/summary_view.dart';
import 'package:segui/screens/shared/tool_layout.dart';
import 'package:segui/services/workbench.dart';
import 'package:segui/styles/design_tokens.dart';

/// Compatible tools listed before the rest are folded away.
const int _visibleToolCount = 4;

/// File summary and run settings, then the next steps after a run:
/// workflow steps and other tools that take the run's data.
class WorkbenchView extends ConsumerWidget {
  const WorkbenchView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ToolRun? run = ref.watch(lastRunProvider);
    final WorkbenchSuggestions? suggestions =
        ref.watch(workbenchSuggestionsProvider);
    return ListView(
      padding:
          const EdgeInsets.only(top: SeguiSpacing.xl, bottom: SeguiSpacing.md),
      children: [
        const WorkbenchSectionTitle(title: 'Summary'),
        const FileSummaryTiles(),
        if (run != null && run.parameters.isNotEmpty) ...[
          const SizedBox(height: SeguiSpacing.md),
          RunParametersCard(run: run),
        ],
        if (suggestions == null) ...[
          const SizedBox(height: SeguiSpacing.xl),
          const NextStepsHint(),
        ] else ...[
          if (suggestions.workflows.isNotEmpty) ...[
            WorkbenchSectionTitle(
              title: 'Suggested workflows',
              trailing: '${suggestions.workflows.length}',
            ),
            for (final (index, progress) in suggestions.workflows.indexed) ...[
              if (index > 0) const SizedBox(height: SeguiSpacing.md),
              WorkflowProgressCard(progress: progress),
            ],
          ],
          WorkbenchSectionTitle(
            title: 'Other compatible tools',
            trailing: suggestions.tools.isEmpty
                ? null
                : '${suggestions.tools.length}',
          ),
          CompatibleToolList(steps: suggestions.tools),
        ],
      ],
    );
  }
}

/// Section heading in the workbench, with an optional count.
class WorkbenchSectionTitle extends StatelessWidget {
  const WorkbenchSectionTitle({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextStyle? style = Theme.of(context)
        .textTheme
        .labelLarge
        ?.copyWith(color: colors.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          SeguiSpacing.xs, SeguiSpacing.xl, SeguiSpacing.xs, SeguiSpacing.md),
      child: Row(
        children: [
          Expanded(child: Text(title, style: style)),
          if (trailing != null) Text(trailing!, style: style),
        ],
      ),
    );
  }
}

/// Explains that next steps appear once the tool has run.
class NextStepsHint extends StatelessWidget {
  const NextStepsHint({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.route_outlined,
          size: SeguiControlSize.iconMedium,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(width: SeguiSpacing.md),
        Expanded(
          child: Text(
            'Run the tool to see suggested workflows and tools that can '
            'use its output.',
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Settings of the last successful run.
class RunParametersCard extends StatelessWidget {
  const RunParametersCard({super.key, required this.run});

  final ToolRun run;

  @override
  Widget build(BuildContext context) {
    return WorkbenchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PanelCardHeader(icon: Icons.tune_outlined, title: 'Parameters'),
          RunParameterRow(parameter: RunParameter('Tool', run.tool.title)),
          for (final parameter in run.parameters)
            RunParameterRow(parameter: parameter),
        ],
      ),
    );
  }
}

/// One setting as a label and its value.
class RunParameterRow extends StatelessWidget {
  const RunParameterRow({super.key, required this.parameter});

  final RunParameter parameter;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SeguiSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              parameter.label,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: SeguiSpacing.md),
          Expanded(
            child: Text(
              parameter.value,
              style: textTheme.bodySmall,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// A workflow that includes the tool that ran, with its next step.
class WorkflowProgressCard extends ConsumerWidget {
  const WorkflowProgressCard({super.key, required this.progress});

  final WorkflowProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final WorkbenchStep? next = progress.next;
    final int stepCount = progress.workflow.steps.length;
    return WorkbenchCard(
      isHighlighted: next != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  progress.workflow.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (progress.isComplete)
                Tooltip(
                  message: 'Workflow complete',
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: SeguiControlSize.iconMedium,
                    color: colors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: SeguiSpacing.md),
          WorkflowStepper(progress: progress),
          const SizedBox(height: SeguiSpacing.sm),
          Text(
            progress.isComplete
                ? 'Final step done'
                : 'Step ${progress.stepIndex + 1} of $stepCount done',
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: SeguiSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next: ${next.tool.title}',
                        style: textTheme.bodyMedium,
                      ),
                      Text(
                        stepInputCaption(next),
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: SeguiSpacing.md),
                FilledButton.tonalIcon(
                  onPressed: () => openWorkbenchStep(context, ref, next),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  iconAlignment: IconAlignment.end,
                  label: const Text('Continue'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Steps of a workflow as dots: done, next, and later steps.
class WorkflowStepper extends StatelessWidget {
  const WorkflowStepper({super.key, required this.progress});

  final WorkflowProgress progress;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final (index, tool) in progress.workflow.steps.indexed) ...[
          if (index > 0)
            Expanded(
              child: Divider(
                thickness: SeguiStroke.thin,
                color: index <= progress.stepIndex
                    ? colors.primary
                    : colors.outlineVariant,
              ),
            ),
          Tooltip(
            message: tool.title,
            child: WorkflowStepDot(
              number: index + 1,
              isDone: index <= progress.stepIndex,
              isNext: index == progress.stepIndex + 1,
            ),
          ),
        ],
      ],
    );
  }
}

class WorkflowStepDot extends StatelessWidget {
  const WorkflowStepDot({
    super.key,
    required this.number,
    required this.isDone,
    required this.isNext,
  });

  final int number;
  final bool isDone;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color background = isDone
        ? colors.primary
        : isNext
            ? colors.primaryContainer
            : Colors.transparent;
    final Color foreground = isDone
        ? colors.onPrimary
        : isNext
            ? colors.onPrimaryContainer
            : colors.onSurfaceVariant;
    return Container(
      width: SeguiControlSize.icon,
      height: SeguiControlSize.icon,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border:
            isDone || isNext ? null : Border.all(color: colors.outlineVariant),
      ),
      child: isDone
          ? Icon(
              Icons.check_rounded,
              size: SeguiControlSize.iconSmall,
              color: foreground,
            )
          : Text(
              '$number',
              style: textTheme.labelMedium?.copyWith(color: foreground),
            ),
    );
  }
}

/// Tools that take the run's data, with the rest folded behind a button.
class CompatibleToolList extends StatefulWidget {
  const CompatibleToolList({super.key, required this.steps});

  final List<WorkbenchStep> steps;

  @override
  State<CompatibleToolList> createState() => _CompatibleToolListState();
}

class _CompatibleToolListState extends State<CompatibleToolList> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    if (widget.steps.isEmpty) {
      return Text(
        'No other tools take this data.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
      );
    }
    final int hiddenCount = widget.steps.length - _visibleToolCount;
    final List<WorkbenchStep> visible = _isExpanded || hiddenCount <= 0
        ? widget.steps
        : widget.steps.take(_visibleToolCount).toList();
    return WorkbenchCard(
      padding: const EdgeInsets.symmetric(vertical: SeguiSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, step) in visible.indexed) ...[
            if (index > 0) Divider(height: SeguiStroke.thin),
            CompatibleToolTile(step: step),
          ],
          if (hiddenCount > 0)
            TextButton(
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
              child:
                  Text(_isExpanded ? 'Show fewer' : 'Show $hiddenCount more'),
            ),
        ],
      ),
    );
  }
}

/// A tool that opens with the run's files as its input.
class CompatibleToolTile extends ConsumerWidget {
  const CompatibleToolTile({super.key, required this.step});

  final WorkbenchStep step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => openWorkbenchStep(context, ref, step),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: SeguiSpacing.lg, vertical: SeguiSpacing.md),
        child: Row(
          children: [
            ToolIconTile(
              tool: step.tool,
              isSelected: false,
              size: SeguiControlSize.iconLarge,
            ),
            const SizedBox(width: SeguiSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.tool.title,
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    stepInputCaption(step),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Outlined surface for workbench sections, accented when [isHighlighted].
class WorkbenchCard extends StatelessWidget {
  const WorkbenchCard({
    super.key,
    required this.child,
    this.isHighlighted = false,
    this.padding = const EdgeInsets.all(SeguiSpacing.lg),
  });

  final Widget child;
  final bool isHighlighted;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SeguiRadius.lg),
        side: BorderSide(
          color: isHighlighted ? colors.primary : colors.outlineVariant,
          width: isHighlighted ? SeguiStroke.regular : SeguiStroke.thin,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Which files [step] opens with.
String stepInputCaption(WorkbenchStep step) {
  final int count = step.fileCount;
  if (count == 0) {
    return 'Opens without input files';
  }
  final String source = step.isFromOutput ? 'output' : 'input';
  final String files = count == 1 ? 'file' : 'files';
  final String partition = step.inputs.length > 1 ? ' and partition' : '';
  return 'Uses $count $source $files$partition';
}

/// Opens [step]'s tool with its files, closing the files page on compact
/// screens.
Future<void> openWorkbenchStep(
  BuildContext context,
  WidgetRef ref,
  WorkbenchStep step,
) async {
  // Read first: popping the files page disposes this widget's ref.
  final WorkbenchNavigator workbench = ref.read(workbenchNavigatorProvider);
  final NavigatorState navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
  }
  await workbench.open(step);
}
