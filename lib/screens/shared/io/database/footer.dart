import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/io/picker_widget.dart';
import 'package:segui/services/databases/download.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/io/mobile_io.dart';
import 'package:segui/services/providers/databases.dart';
import 'package:segui/services/utils.dart';
import 'package:segui/styles/design_tokens.dart';

/// Pinned bar with the selection, the progress, or the choices after a
/// download that failed in part.
class DatabasePanelFooter extends ConsumerWidget {
  const DatabasePanelFooter({
    super.key,
    required this.target,
    required this.onDownload,
    required this.onRetry,
    required this.onAddRest,
  });

  final DatabaseTarget target;
  final VoidCallback onDownload;
  final VoidCallback onRetry;
  final VoidCallback onAddRest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DatabaseState state = ref.watch(databaseSessionProvider(target));
    final DatabaseSession session =
        ref.read(databaseSessionProvider(target).notifier);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SeguiSpacing.xl,
          vertical: SeguiSpacing.lg,
        ),
        child: switch (state) {
          DatabaseState(:final progress?) => PickerCopyProgress(
              progress: InputCopyProgress(
                copied: progress.done,
                // Without sizes, no share shows until a record is done.
                total: progress.bytesTotal == 0 &&
                        (progress.done == 0 || progress.total == 1)
                    ? 0
                    : progress.total,
                bytesCopied: progress.bytes,
                bytesTotal: progress.bytesTotal,
                stage: InputCopyStage.downloading,
                onCancel: session.cancelDownload,
              ),
            ),
          DatabaseState(:final report?) => DownloadFailureActions(
              report: report,
              onBack: session.dismissReport,
              onRetry: onRetry,
              onAddRest: onAddRest,
            ),
          _ => SelectionActions(
              state: state,
              onClear: session.clearSelection,
              onDownload: onDownload,
            ),
        },
      ),
    );
  }
}

class SelectionActions extends StatelessWidget {
  const SelectionActions({
    super.key,
    required this.state,
    required this.onClear,
    required this.onDownload,
  });

  final DatabaseState state;
  final VoidCallback onClear;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final int count = state.selection.length;
    final int? bytes = state.selectionBytes;
    return Row(
      children: [
        Expanded(
          child: PickerText(
            title: Text('${formatCount(count)} selected'),
            subtitle: [
              state.content.format,
              if (count > 0)
                bytes == null
                    ? 'size unknown'
                    : 'about ${FileUtils().formatSize(bytes)}',
            ].join(' · '),
          ),
        ),
        if (count > 0)
          IconButton(
            tooltip: 'Clear selection',
            onPressed: onClear,
            icon: const Icon(Icons.clear_all_rounded),
          ),
        const SizedBox(width: SeguiSpacing.md),
        FilledButton(
          onPressed: count == 0 ? null : onDownload,
          child: const Text('Download and add'),
        ),
      ],
    );
  }
}

class DownloadFailureActions extends StatelessWidget {
  const DownloadFailureActions({
    super.key,
    required this.report,
    required this.onBack,
    required this.onRetry,
    required this.onAddRest,
  });

  final DownloadReport report;
  final VoidCallback onBack;
  final VoidCallback onRetry;
  final VoidCallback onAddRest;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: SeguiSpacing.md,
      runSpacing: SeguiSpacing.md,
      children: [
        TextButton(onPressed: onBack, child: const Text('Back')),
        if (report.completed > 0)
          OutlinedButton(
            onPressed: onAddRest,
            child: const Text('Add the rest'),
          ),
        FilledButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
