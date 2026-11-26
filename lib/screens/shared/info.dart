import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/styles/design_tokens.dart';

class SharedInfoForm extends StatelessWidget {
  const SharedInfoForm({
    super.key,
    required this.description,
    required this.onClosed,
    required this.onExpanded,
    required this.isShowingInfo,
  });

  final VoidCallback onExpanded;
  final VoidCallback onClosed;
  final String? description;
  final bool isShowingInfo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Visibility(
          visible: isShowingInfo,
          child: CommonCard(
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                const Icon(Icons.info_outline_rounded),
                const SizedBox(height: SeguiSpacing.xs),
                Text(
                  description ?? '',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: SeguiSpacing.xxs),
        Center(
          child: IconButton(
            tooltip: isShowingInfo ? 'Hide info' : 'Show info',
            icon: Icon(
              isShowingInfo
                  ? Icons.expand_less_outlined
                  : Icons.expand_more_outlined,
            ),
            onPressed: () {
              if (isShowingInfo) {
                onClosed();
              } else {
                onExpanded();
              }
            },
          ),
        )
      ],
    );
  }
}

/// Note that some workflow steps happen outside SEGUI.
const String workflowExternalStepsNote =
    'Some workflows may need steps outside SEGUI, such as alignment or '
    'tree inference.';

/// Info icon that shows [workflowExternalStepsNote] on hover or tap.
class WorkflowNoteIcon extends StatelessWidget {
  const WorkflowNoteIcon({super.key, this.size = SeguiControlSize.iconSmall});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: workflowExternalStepsNote,
      // Tap opens it on touch screens, where there is no hover.
      triggerMode: TooltipTriggerMode.tap,
      child: Icon(
        Icons.info_outline_rounded,
        size: size,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        semanticLabel: workflowExternalStepsNote,
      ),
    );
  }
}

/// [workflowExternalStepsNote] as a caption with a leading info icon.
class WorkflowNoteCaption extends StatelessWidget {
  const WorkflowNoteCaption({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: SeguiControlSize.iconSmall,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(width: SeguiSpacing.xs),
        Expanded(
          child: Text(
            workflowExternalStepsNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
