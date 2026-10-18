import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/alignment/selected_row_mark.dart';
import 'package:segui/services/providers/alignment_view.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/src/rust/api/alignment_view.dart';
import 'package:segui/styles/design_tokens.dart';

final NumberFormat _siteFormat = NumberFormat('#,###');

/// Chunks of the alignment with their gap and variable-site shares.
class ChunkSidebar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ChunkStat>> stats = ref.watch(
      alignmentChunkStatsProvider((data: data, chunkSize: chunkSize)),
    );
    return SizedBox(
      width: SeguiAlignmentLayout.chunkSidebar,
      child: stats.when(
        data: (stats) => ListView.builder(
          primary: false,
          itemCount: stats.length,
          itemBuilder: (context, index) => _ChunkTile(
            stat: stats[index],
            index: index,
            isSelected: index == currentChunk,
            onTap: () => onSelected(index),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(SeguiSpacing.lg),
          child: Text('Could not summarize chunks. $error'),
        ),
      ),
    );
  }
}

class _ChunkTile extends StatelessWidget {
  const _ChunkTile({
    required this.stat,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  final ChunkStat stat;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
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
                    '${_siteFormat.format(stat.start + 1)}–'
                    '${_siteFormat.format(stat.end)}',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: SeguiSpacing.xxs),
                  Text(
                    'Gaps ${_percent(stat.gapFraction)} · '
                    'Variable ${_percent(stat.variableFraction)}',
                    style: detail,
                  ),
                  const SizedBox(height: SeguiSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(SeguiRadius.xs),
                    child: LinearProgressIndicator(
                      value: stat.variableFraction,
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

  String _percent(double fraction) => '${(fraction * 100).round()}%';
}
