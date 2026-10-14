import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/summary.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/styles/segui_icons.dart';

/// Input and output summaries, each with a button to open its file list.
class FileSummaryView extends ConsumerWidget {
  const FileSummaryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FileSetSummary input =
        ref.watch(inputSummaryProvider).value ?? const FileSetSummary.empty();
    final OutputSummary? output = ref.watch(outputSummaryProvider).value;
    final String? outputDir = output?.directory?.path;
    final int otherCount = output?.otherFileCount ?? 0;
    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      children: [
        FileSummaryCard(
          title: 'Input',
          icon: SeguiIcons.inputFolderFilled,
          summary: input,
          emptyText: 'No input files selected.',
          buttonLabel: 'View input files',
          onViewFiles: input.isEmpty
              ? null
              : () => ref
                  .read(filePanelViewProvider.notifier)
                  .show(FilePanelView.input),
        ),
        const SizedBox(height: 12),
        FileSummaryCard(
          title: 'Output',
          icon: SeguiIcons.outputFolderFilled,
          subtitle: outputDir == null ? null : p.basename(outputDir),
          summary: output?.newFiles ?? const FileSetSummary.empty(),
          emptyText: outputDir == null
              ? 'No output folder selected.'
              : 'No new output files yet.',
          note: otherCount > 0
              ? '$otherCount other ${otherCount == 1 ? 'file' : 'files'} '
                  'already in the folder'
              : null,
          buttonLabel: 'View output files',
          onViewFiles: outputDir == null
              ? null
              : () => ref
                  .read(filePanelViewProvider.notifier)
                  .show(FilePanelView.output),
        ),
      ],
    );
  }
}

/// Count, size, and formats of one file set, with a button to list them.
class FileSummaryCard extends StatelessWidget {
  const FileSummaryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.summary,
    required this.emptyText,
    required this.buttonLabel,
    required this.onViewFiles,
    this.subtitle,
    this.note,
  });

  final String title;
  final IconData icon;
  final FileSetSummary summary;
  final String emptyText;
  final String buttonLabel;
  final VoidCallback? onViewFiles;
  final String? subtitle;

  /// Extra line below the formats, such as files from earlier runs.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (summary.isEmpty)
            Text(
              emptyText,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: SummaryStat(
                    value: '${summary.fileCount}',
                    label: summary.fileCount == 1 ? 'file' : 'files',
                  ),
                ),
                Expanded(
                  child: SummaryStat(
                    value: summary.totalSize,
                    label: 'total size',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final format in summary.formatCounts)
                  FormatCountChip(format: format.format, count: format.count),
              ],
            ),
          ],
          if (note != null) ...[
            const SizedBox(height: 10),
            Text(
              note!,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onViewFiles,
              icon: const Icon(Icons.arrow_forward_rounded),
              iconAlignment: IconAlignment.end,
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryStat extends StatelessWidget {
  const SummaryStat({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Format icon and name with its file count.
class FormatCountChip extends StatelessWidget {
  const FormatCountChip({
    super.key,
    required this.format,
    required this.count,
  });

  final FileIconType format;
  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            format.assetPath,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(colors.tertiary, BlendMode.srcIn),
          ),
          const SizedBox(width: 6),
          Text(format.label, style: textTheme.labelLarge),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
