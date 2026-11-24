import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/io/picker_widget.dart';
import 'package:segui/services/databases/download.dart';
import 'package:segui/services/io/io.dart';
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
          DatabaseState(:final progress?) => DatabaseDownloadProgress(
              progress: progress,
              onCancel: session.cancelDownload,
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

/// Live progress bar with stage, percentage, transfer speed, and ETA.
class DatabaseDownloadProgress extends StatelessWidget {
  const DatabaseDownloadProgress({
    super.key,
    required this.progress,
    required this.onCancel,
  });

  final DownloadProgress progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double? fraction = _fraction;
    final TextStyle? detailStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _stageLabel,
                style: theme.textTheme.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (fraction != null)
              Text('${(fraction * 100).floor()}%', style: detailStyle),
            IconButton(
              tooltip: 'Stop',
              visualDensity: VisualDensity.compact,
              onPressed: onCancel,
              icon: const Icon(
                Icons.close_rounded,
                size: SeguiControlSize.iconMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: SeguiSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(SeguiRadius.full),
          child: LinearProgressIndicator(value: fraction),
        ),
        const SizedBox(height: SeguiSpacing.xs),
        Text(
          _metricsLabel,
          style: detailStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  double? get _fraction {
    if (progress.bytesTotal > 0) {
      return (progress.bytes / progress.bytesTotal).clamp(0.0, 1.0);
    }
    if (progress.total > 1 && progress.done > 0) {
      return (progress.done / progress.total).clamp(0.0, 1.0);
    }
    return null;
  }

  String get _stageLabel {
    return switch (progress.stage) {
      DownloadStage.connecting => 'Connecting…',
      DownloadStage.retrying =>
        progress.retryAttempt != null && progress.retryMax != null
            ? 'Retrying (${progress.retryAttempt}/${progress.retryMax})…'
            : 'Retrying…',
      DownloadStage.verifying => 'Verifying…',
      DownloadStage.decompressing => 'Decompressing…',
      DownloadStage.preparing => 'Preparing sequences…',
      DownloadStage.downloading => progress.total == 0
          ? 'Downloading…'
          : 'Downloading ${formatCount(progress.done)} of '
              '${formatCount(progress.total)} records',
    };
  }

  String get _metricsLabel {
    final FileUtils files = FileUtils();
    final int bytes = progress.bytes;
    final int total = progress.bytesTotal;
    final int? speed = progress.bytesPerSecond;
    if (bytes == 0 && total == 0) {
      return 'Waiting for server…';
    }
    final List<String> parts = [];
    if (total > 0) {
      parts.add('${files.formatSize(bytes)} / ${files.formatSize(total)}');
    } else if (bytes > 0) {
      parts.add(files.formatSize(bytes));
    }
    if (speed != null && speed > 0) {
      parts.add('${files.formatSize(speed)}/s');
      if (total > bytes) {
        final int seconds = ((total - bytes) / speed).ceil();
        if (seconds >= 1) {
          parts.add('${_formatEta(seconds)} left');
        }
      }
    } else if (bytes == 0 || speed == 0) {
      parts.add('Waiting for server…');
    }
    return parts.join(' · ');
  }

  String _formatEta(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final int minutes = seconds ~/ 60;
    final int remSeconds = seconds % 60;
    if (minutes < 60) {
      return remSeconds == 0 ? '${minutes}m' : '${minutes}m ${remSeconds}s';
    }
    final int hours = minutes ~/ 60;
    final int remMinutes = minutes % 60;
    return remMinutes == 0 ? '${hours}h' : '${hours}h ${remMinutes}m';
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
