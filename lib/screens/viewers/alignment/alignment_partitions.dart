import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/alignment/alignment_grid.dart';
import 'package:segui/screens/viewers/alignment/selected_row_mark.dart';
import 'package:segui/services/providers/alignment_view.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/src/rust/api/alignment_view.dart';
import 'package:segui/styles/design_tokens.dart';

final NumberFormat _siteFormat = NumberFormat('#,###');

/// Partitions as colored bands above the ruler, scrolled with the grid.
/// Tap a band to go to its first site.
class AlignmentPartitionTrack extends StatelessWidget {
  const AlignmentPartitionTrack({
    super.key,
    required this.index,
    required this.controller,
    required this.siteRange,
    required this.cellSize,
    required this.current,
    required this.onSelected,
  });

  final AlignmentPartitionIndex index;
  final ScrollController controller;
  final AlignmentSiteRange siteRange;
  final double cellSize;
  final ValueListenable<int?> current;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final double dx = controller.hasClients ? controller.offset : 0;
        final int site =
            siteRange.start + (details.localPosition.dx + dx) ~/ cellSize;
        final int? partition = index.indexAt(site);
        if (partition != null) onSelected(partition);
      },
      child: SizedBox(
        height: SeguiAlignmentLayout.ruler,
        width: double.infinity,
        child: CustomPaint(
          painter: _TrackPainter(
            index: index,
            controller: controller,
            current: current,
            siteRange: siteRange,
            cellSize: cellSize,
            fills: [colors.surfaceContainerHighest, colors.secondaryContainer],
            labels: [colors.onSurface, colors.onSecondaryContainer],
            currentFill: colors.primaryContainer,
            currentLabel: colors.onPrimaryContainer,
            textStyle: theme.textTheme.labelSmall!,
          ),
        ),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({
    required this.index,
    required this.controller,
    required this.current,
    required this.siteRange,
    required this.cellSize,
    required this.fills,
    required this.labels,
    required this.currentFill,
    required this.currentLabel,
    required this.textStyle,
  }) : super(repaint: Listenable.merge([controller, current]));

  final AlignmentPartitionIndex index;
  final ScrollController controller;
  final ValueListenable<int?> current;
  final AlignmentSiteRange siteRange;
  final double cellSize;

  /// Alternating band colors, so neighbors stand apart.
  final List<Color> fills;
  final List<Color> labels;
  final Color currentFill;
  final Color currentLabel;
  final TextStyle textStyle;

  // Gap between bands and room around a name.
  static const double _gap = 1;
  static const double _pad = SeguiSpacing.xs;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final double dx = controller.hasClients ? controller.offset : 0;
    final int first = siteRange.start + dx ~/ cellSize;
    final int last = siteRange.start + (dx + size.width) ~/ cellSize + 1;
    int i = index.indexAt(first) ?? index.nextAfter(first) ?? index.length;
    final double top = SeguiSpacing.xxs;
    final double height = size.height - top * 2;
    for (; i < index.length && index.partitions[i].start < last; i++) {
      final AlignmentPartition partition = index.partitions[i];
      final int start = partition.start.clamp(siteRange.start, siteRange.end);
      final int end = partition.end.clamp(siteRange.start, siteRange.end);
      if (end <= start) continue;
      final double left = (start - siteRange.start) * cellSize - dx;
      final double width = (end - start) * cellSize - _gap;
      final bool isCurrent = i == current.value;
      final Rect band = Rect.fromLTWH(left, top, width, height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(band, const Radius.circular(SeguiRadius.xs)),
        Paint()..color = isCurrent ? currentFill : fills[i % 2],
      );
      if (width < _pad * 2 + cellSize) continue;
      // Keep the name in view while its band scrolls off the left edge.
      final double textLeft = left < 0 ? 0 : left;
      final double room = left + width - textLeft - _pad * 2;
      if (room <= 0) continue;
      final TextPainter label = TextPainter(
        text: TextSpan(
          text: partition.name,
          style: textStyle.copyWith(
            color: isCurrent ? currentLabel : labels[i % 2],
            fontWeight: isCurrent ? FontWeight.w600 : null,
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: room);
      label.paint(
        canvas,
        Offset(textLeft + _pad, top + (height - label.height) / 2),
      );
      label.dispose();
    }
  }

  @override
  bool shouldRepaint(_TrackPainter oldDelegate) {
    return oldDelegate.index != index ||
        oldDelegate.controller != controller ||
        oldDelegate.current != current ||
        oldDelegate.siteRange != siteRange ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.currentFill != currentFill ||
        oldDelegate.textStyle != textStyle;
  }
}

/// Partitions with their gap and variable-site shares, computed in Rust as
/// they scroll into view.
class PartitionSidebar extends StatelessWidget {
  const PartitionSidebar({
    super.key,
    required this.data,
    required this.current,
    required this.onSelected,
    this.width = SeguiAlignmentLayout.windowSidebar,
  });

  final AlignmentViewData data;
  final ValueListenable<int?> current;
  final ValueChanged<int> onSelected;

  /// Width of the list; [double.infinity] fills a sheet.
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ValueListenableBuilder<int?>(
        valueListenable: current,
        builder: (context, currentIndex, _) => ListView.builder(
          primary: false,
          itemCount: data.partitions.length,
          itemBuilder: (context, index) => _PartitionTile(
            data: data,
            index: index,
            isSelected: index == currentIndex,
            onTap: () => onSelected(index),
          ),
        ),
      ),
    );
  }
}

class _PartitionTile extends ConsumerWidget {
  const _PartitionTile({
    required this.data,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  final AlignmentViewData data;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final AlignmentPartition partition = data.partitions[index];
    final AsyncValue<AlignmentWindowStat?> stat = ref.watch(
      alignmentPartitionStatsProvider((data: data, index: index)),
    );
    final TextStyle detail = theme.textTheme.labelSmall!.copyWith(
      color: colors.onSurfaceVariant,
    );
    final String? model = partition.model;
    // Same layout as the window list.
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
                    partition.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: SeguiSpacing.xxs),
                  Text(
                    '${_siteFormat.format(partition.start + 1)}–'
                    '${_siteFormat.format(partition.end)} · '
                    '${_siteFormat.format(partition.end - partition.start)} sites'
                    '${partition.subsets.isEmpty ? '' : ' · ${partition.subsets.length} subsets'}'
                    '${model == null ? '' : ' · $model'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: detail,
                  ),
                  Text(_summary(stat), style: detail),
                  const SizedBox(height: SeguiSpacing.xs),
                  LinearProgressIndicator(
                    value: stat.value?.variableFraction ?? 0,
                    minHeight: SeguiStroke.thick,
                    borderRadius: BorderRadius.circular(SeguiRadius.xs),
                    color: colors.tertiary,
                    backgroundColor: colors.surfaceContainerHighest,
                    semanticsLabel: '${partition.name} variable sites',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _summary(AsyncValue<AlignmentWindowStat?> stat) {
    final AlignmentWindowStat? value = stat.value;
    if (value != null) {
      return 'Gaps ${_percent(value.gapFraction)} · '
          'Variable ${_percent(value.variableFraction)}';
    }
    if (stat.hasError) return 'Could not summarize this partition';
    return stat.isLoading ? 'Counting…' : 'No summary';
  }

  String _percent(double fraction) => '${(fraction * 100).round()}%';
}

/// Windows or partitions beside the grid, with a switch between them when
/// the alignment has partitions.
class AlignmentSideList extends ConsumerWidget {
  const AlignmentSideList({
    super.key,
    required this.data,
    required this.windows,
    required this.partitions,
    this.width = SeguiAlignmentLayout.windowSidebar,
  });

  final AlignmentViewData data;
  final Widget windows;
  final Widget partitions;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!data.hasPartitions) return windows;
    final AlignmentViewSettings settings =
        ref.watch(alignmentViewSettingsProvider);
    final bool showPartitions =
        settings.sideList == AlignmentSideListKind.partitions;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(SeguiSpacing.sm),
            child: SegmentedButton<AlignmentSideListKind>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: const [
                ButtonSegment(
                  value: AlignmentSideListKind.partitions,
                  label: Text('Partitions'),
                ),
                ButtonSegment(
                  value: AlignmentSideListKind.windows,
                  label: Text('Windows'),
                ),
              ],
              selected: {settings.sideList},
              onSelectionChanged: (selected) => ref
                  .read(alignmentViewSettingsProvider.notifier)
                  .setSideList(selected.first),
            ),
          ),
          Expanded(child: showPartitions ? partitions : windows),
        ],
      ),
    );
  }
}

/// Previous and next partition buttons around the current partition's name.
class AlignmentPartitionNavigator extends StatelessWidget {
  const AlignmentPartitionNavigator({
    super.key,
    required this.data,
    required this.current,
    required this.onSelected,
  });

  final AlignmentViewData data;
  final ValueListenable<int?> current;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int count = data.partitions.length;
    return ValueListenableBuilder<int?>(
      valueListenable: current,
      builder: (context, index, _) {
        final String label = index == null
            ? '${_siteFormat.format(count)} partitions'
            : '${data.partitions[index].name} · '
                '${_siteFormat.format(index + 1)} of ${_siteFormat.format(count)}';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Previous partition',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: index == null || index > 0
                  ? () => onSelected(index == null ? 0 : index - 1)
                  : null,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge,
              ),
            ),
            IconButton(
              tooltip: 'Next partition',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: index == null || index < count - 1
                  ? () => onSelected(index == null ? 0 : index + 1)
                  : null,
            ),
          ],
        );
      },
    );
  }
}
