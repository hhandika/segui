import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/alignment/selected_row_mark.dart';
import 'package:segui/services/providers/alignment_view.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/src/rust/api/alignment_view.dart';
import 'package:segui/styles/design_tokens.dart';

final NumberFormat _siteFormat = NumberFormat('#,###');

/// Chunks of the alignment with their gap and variable-site shares. Shares
/// load from Rust a page at a time, only for the chunks scrolled into view.
class ChunkSidebar extends StatelessWidget {
  const ChunkSidebar({
    super.key,
    required this.data,
    required this.chunkSize,
    required this.currentChunk,
    required this.onSelected,
  });

  final AlignmentViewData data;
  final int chunkSize;
  final int currentChunk;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final AlignmentChunks chunks =
        AlignmentChunks(length: data.length, size: chunkSize);
    return SizedBox(
      width: SeguiAlignmentLayout.chunkSidebar,
      child: ListView.builder(
        primary: false,
        itemCount: chunks.count,
        itemBuilder: (context, index) => _ChunkTile(
          data: data,
          chunks: chunks,
          index: index,
          isSelected: index == currentChunk,
          onTap: () => onSelected(index),
        ),
      ),
    );
  }
}

class _ChunkTile extends ConsumerWidget {
  const _ChunkTile({
    required this.data,
    required this.chunks,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  final AlignmentViewData data;
  final AlignmentChunks chunks;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<AlignmentChunkStat>> page = ref.watch(
      alignmentChunkPageProvider((
        data: data,
        chunkSize: chunks.size,
        page: index ~/ chunkPageSize,
      )),
    );
    final int offset = index % chunkPageSize;
    final List<AlignmentChunkStat>? stats = page.value;
    final AlignmentChunkStat? stat =
        stats != null && offset < stats.length ? stats[offset] : null;
    final ColorScheme colors = theme.colorScheme;
    final TextStyle detail = theme.textTheme.labelSmall!.copyWith(
      color: colors.onSurfaceVariant,
    );
    // Inset row marked on its left when selected, matching the file list;
    // content stays SeguiSpacing.lg from the panel edge.
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SeguiSpacing.sm,
        vertical: SeguiSpacing.xxs,
      ),
      child: SelectedRowMark(
        isSelected: isSelected,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(SeguiRadius.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SeguiSpacing.sm,
                vertical: SeguiSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_siteFormat.format(chunks.startOf(index) + 1)}–'
                    '${_siteFormat.format(chunks.endOf(index))}',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: SeguiSpacing.xxs),
                  Text(
                    _summary(page, stat),
                    style: detail,
                  ),
                  const SizedBox(height: SeguiSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(SeguiRadius.xs),
                    child: LinearProgressIndicator(
                      value: stat?.variableFraction ?? 0,
                      minHeight: SeguiStroke.thick,
                      color: colors.tertiary,
                      backgroundColor: colors.surfaceContainerHighest,
                      semanticsLabel: 'Chunk ${index + 1} variable sites',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _summary(
    AsyncValue<List<AlignmentChunkStat>> page,
    AlignmentChunkStat? stat,
  ) {
    if (stat != null) {
      return 'Gaps ${_percent(stat.gapFraction)} · '
          'Variable ${_percent(stat.variableFraction)}';
    }
    if (page.hasError) return 'Could not summarize this chunk';
    return page.isLoading ? 'Counting…' : 'No summary';
  }

  String _percent(double fraction) => '${(fraction * 100).round()}%';
}
