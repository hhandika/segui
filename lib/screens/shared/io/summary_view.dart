import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/summary.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/styles/segui_icons.dart';
import 'package:segui/styles/design_tokens.dart';

/// Input and output summaries side by side, each opening its file list.
/// The tiles stack when the panel is too narrow for both.
class FileSummaryTiles extends ConsumerWidget {
  const FileSummaryTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FileSetSummary input =
        ref.watch(inputSummaryProvider).value ?? const FileSetSummary.empty();
    final OutputSummary? output = ref.watch(outputSummaryProvider).value;
    final String? outputDir = output?.directory?.path;
    final int otherCount = output?.otherFileCount ?? 0;
    final Widget inputTile = FileSummaryCard(
      title: 'Input',
      icon: SeguiIcons.inputFolderOutlined,
      summary: input,
      emptyText: 'No input files selected.',
      buttonLabel: 'View input files',
      onViewFiles: input.isEmpty
          ? null
          : () => ref
              .read(filePanelViewProvider.notifier)
              .show(FilePanelView.input),
    );
    final Widget outputTile = FileSummaryCard(
      title: 'Output',
      icon: SeguiIcons.outputFolderOutlined,
      folderName: outputDir == null ? null : p.basename(outputDir),
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
    );
    return LayoutBuilder(builder: (context, constraints) {
      final bool isSideBySide = constraints.maxWidth >=
          SeguiContentWidth.summaryTile * 2 + SeguiSpacing.md;
      if (!isSideBySide) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            inputTile,
            const SizedBox(height: SeguiSpacing.md),
            outputTile,
          ],
        );
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: inputTile),
            const SizedBox(width: SeguiSpacing.md),
            Expanded(child: outputTile),
          ],
        ),
      );
    });
  }
}

/// Count, size, and formats of one file set. Tapping it lists the files.
class FileSummaryCard extends StatelessWidget {
  const FileSummaryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.summary,
    required this.emptyText,
    required this.buttonLabel,
    required this.onViewFiles,
    this.folderName,
    this.note,
  });

  final String title;
  final IconData icon;
  final FileSetSummary summary;
  final String emptyText;

  /// Semantic label of the tile's tap action.
  final String buttonLabel;
  final VoidCallback? onViewFiles;

  /// Name of the folder that holds the files, shown above the counts.
  final String? folderName;

  /// Extra line below the formats, such as files from earlier runs.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? mutedSmall =
        textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant);
    return Material(
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SeguiRadius.lg),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onViewFiles,
        child: Semantics(
          button: onViewFiles != null,
          label: buttonLabel,
          child: Padding(
            padding: const EdgeInsets.all(SeguiSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PanelCardHeader(
                  icon: icon,
                  title: title,
                  trailing: onViewFiles == null
                      ? null
                      : Icon(
                          Icons.chevron_right_rounded,
                          size: SeguiControlSize.iconMedium,
                          color: colors.onSurfaceVariant,
                        ),
                ),
                if (folderName != null) ...[
                  FolderNameRow(name: folderName!),
                  const SizedBox(height: SeguiSpacing.md),
                ],
                if (summary.isEmpty)
                  Text(emptyText, style: mutedSmall)
                else ...[
                  SummaryStat(
                    value: '${summary.fileCount}',
                    label: '${summary.fileCount == 1 ? 'file' : 'files'}'
                        ' · ${summary.totalSize}',
                  ),
                  const SizedBox(height: SeguiSpacing.md),
                  Wrap(
                    spacing: SeguiSpacing.sm,
                    runSpacing: SeguiSpacing.sm,
                    children: [
                      for (final format in summary.formatCounts)
                        FormatCountChip(
                          format: format.format,
                          count: format.count,
                        ),
                    ],
                  ),
                ],
                if (note != null) ...[
                  const SizedBox(height: SeguiSpacing.md),
                  Text(note!, style: mutedSmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card title with its icon, ruled off from the card content below.
class PanelCardHeader extends StatelessWidget {
  const PanelCardHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: colors.primary,
              size: SeguiControlSize.iconMedium,
            ),
            const SizedBox(width: SeguiSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: SeguiSpacing.md),
          child: Divider(
            height: SeguiStroke.thin,
            thickness: SeguiStroke.thin,
            color: colors.outlineVariant,
          ),
        ),
      ],
    );
  }
}

/// Folder that holds a file set, as card content rather than a caption.
class FolderNameRow extends StatelessWidget {
  const FolderNameRow({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Output folder',
      child: Row(
        children: [
          Icon(
            Icons.folder_outlined,
            size: SeguiControlSize.iconSmall,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: SeguiSpacing.sm),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.symmetric(
          horizontal: SeguiSpacing.sm, vertical: SeguiSpacing.xs),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(SeguiRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            format.assetPath,
            width: SeguiControlSize.iconSmall,
            height: SeguiControlSize.iconSmall,
            colorFilter: ColorFilter.mode(colors.tertiary, BlendMode.srcIn),
          ),
          const SizedBox(width: SeguiSpacing.sm),
          Text(format.label, style: textTheme.labelMedium),
          const SizedBox(width: SeguiSpacing.xs),
          Text(
            '$count',
            style: textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
