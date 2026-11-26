import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/alignment/selected_row_mark.dart';
import 'package:segui/services/providers/alignment_view.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/src/rust/api/alignment_view.dart';
import 'package:segui/styles/design_tokens.dart';

final NumberFormat _siteFormat = NumberFormat('#,###');

/// Windows of the alignment with their gap and variable-site shares. Shares
/// load from Rust a page at a time, only for the windows scrolled into view.
class WindowSidebar extends StatelessWidget {
  const WindowSidebar({
    super.key,
    required this.data,
    required this.windowSize,
    required this.currentWindow,
    required this.onSelected,
    this.width = SeguiAlignmentLayout.windowSidebar,
  });

  final AlignmentViewData data;
  final int windowSize;
  final int currentWindow;
  final ValueChanged<int> onSelected;

  /// Width of the list; [double.infinity] fills a sheet.
  final double width;

  @override
  Widget build(BuildContext context) {
    final AlignmentWindows windows =
        AlignmentWindows(length: data.length, size: windowSize);
    return SizedBox(
      width: width,
      child: ListView.builder(
        primary: false,
        itemCount: windows.count,
        itemBuilder: (context, index) => _WindowTile(
          data: data,
          windows: windows,
          index: index,
          isSelected: index == currentWindow,
          onTap: () => onSelected(index),
        ),
      ),
    );
  }
}

class _WindowTile extends ConsumerWidget {
  const _WindowTile({
    required this.data,
    required this.windows,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  final AlignmentViewData data;
  final AlignmentWindows windows;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<AlignmentWindowStat>> page = ref.watch(
      alignmentWindowPageProvider((
        data: data,
        windowSize: windows.size,
        page: index ~/ windowPageSize,
      )),
    );
    final int offset = index % windowPageSize;
    final List<AlignmentWindowStat>? stats = page.value;
    final AlignmentWindowStat? stat =
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
                    '${_siteFormat.format(windows.startOf(index) + 1)}–'
                    '${_siteFormat.format(windows.endOf(index))}',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: SeguiSpacing.xxs),
                  Text(
                    _summary(page, stat),
                    style: detail,
                  ),
                  const SizedBox(height: SeguiSpacing.xs),
                  // Rounds the value end as well as the track.
                  LinearProgressIndicator(
                    value: stat?.variableFraction ?? 0,
                    minHeight: SeguiStroke.thick,
                    borderRadius: BorderRadius.circular(SeguiRadius.xs),
                    color: colors.tertiary,
                    backgroundColor: colors.surfaceContainerHighest,
                    semanticsLabel: 'Window ${index + 1} variable sites',
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
    AsyncValue<List<AlignmentWindowStat>> page,
    AlignmentWindowStat? stat,
  ) {
    if (stat != null) {
      return 'Gaps ${_percent(stat.gapFraction)} · '
          'Variable ${_percent(stat.variableFraction)}';
    }
    if (page.hasError) return 'Could not summarize this window';
    return page.isLoading ? 'Counting…' : 'No summary';
  }

  String _percent(double fraction) => '${(fraction * 100).round()}%';
}
