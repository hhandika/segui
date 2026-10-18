import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/providers/alignment_view.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/src/rust/api/alignment_view.dart';
import 'package:segui/styles/design_tokens.dart';

final NumberFormat _siteFormat = NumberFormat('#,###');

/// One toolbar of labeled groups: file summary, color, zoom, chunk
/// navigation, and go to site. Groups wrap onto more lines when narrow.
class AlignmentToolbar extends ConsumerWidget {
  const AlignmentToolbar({
    super.key,
    required this.fileName,
    required this.data,
    required this.canShowChunkList,
    required this.siteController,
    required this.onPrevious,
    required this.onNext,
    required this.onGoToSite,
  });

  final String fileName;
  final AlignmentViewData data;
  final bool canShowChunkList;
  final TextEditingController siteController;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  /// Called with the submitted one-based site text.
  final ValueChanged<String> onGoToSite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AlignmentViewSettings settings =
        ref.watch(alignmentViewSettingsProvider);
    final AlignmentViewSettingsNotifier notifier =
        ref.read(alignmentViewSettingsProvider.notifier);
    final ThemeData theme = Theme.of(context);
    final AlignmentChunks chunks =
        AlignmentChunks(length: data.length, size: settings.chunkSize);
    final int chunk = chunks.clamp(settings.chunk);
    return Wrap(
      runSpacing: SeguiSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _ToolbarGroup(
          isFirst: true,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(fileName, style: theme.textTheme.titleSmall),
                Text(
                  '${_siteFormat.format(data.names.length)} taxa · '
                  '${_siteFormat.format(data.length)} sites · '
                  '${data.isDna ? 'DNA' : 'Amino acid'}'
                  '${data.isAligned ? '' : ' · unaligned'}',
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        _ToolbarGroup(
          label: 'Color',
          children: [
            // Shrinks rather than overflows when the toolbar is narrow.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: SegmentedButton<AlignmentColorMode>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: [
                  for (final AlignmentColorMode mode
                      in AlignmentColorMode.values)
                    ButtonSegment(value: mode, label: Text(mode.label)),
                ],
                selected: {settings.colorMode},
                onSelectionChanged: (modes) =>
                    notifier.setColorMode(modes.first),
              ),
            ),
            FilterChip(
              label: const Text('Letters'),
              visualDensity: VisualDensity.compact,
              selected: settings.showLetters,
              onSelected: (_) => notifier.toggleLetters(),
            ),
          ],
        ),
        _ToolbarGroup(
          label: 'Zoom',
          children: [
            IconButton(
              tooltip: 'Zoom out',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove_rounded),
              onPressed: notifier.zoomOut,
            ),
            SizedBox(
              width: SeguiContentWidth.summaryTile,
              child: Slider(
                value: settings.cellSize,
                min: SeguiAlignmentLayout.cellMin,
                max: SeguiAlignmentLayout.cellMax,
                divisions: (SeguiAlignmentLayout.cellMax -
                        SeguiAlignmentLayout.cellMin)
                    .round(),
                label: '${settings.cellSize.round()} px',
                onChanged: notifier.setCellSize,
              ),
            ),
            IconButton(
              tooltip: 'Zoom in',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_rounded),
              onPressed: notifier.zoomIn,
            ),
          ],
        ),
        _ToolbarGroup(
          label: 'Chunk',
          children: [
            DropdownButton<int>(
              value: settings.chunkSize,
              isDense: true,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(SeguiRadius.sm),
              items: [
                for (final int size in alignmentChunkSizes)
                  DropdownMenuItem(
                    value: size,
                    child: Text('${_siteFormat.format(size)} sites'),
                  ),
              ],
              onChanged: (size) {
                if (size != null) notifier.setChunkSize(size);
              },
            ),
            IconButton(
              tooltip: 'Previous chunk',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: chunk > 0 ? onPrevious : null,
            ),
            Text(
              '${_siteFormat.format(chunks.startOf(chunk) + 1)}–'
              '${_siteFormat.format(chunks.endOf(chunk))} '
              '(${chunk + 1} of ${chunks.count})',
            ),
            IconButton(
              tooltip: 'Next chunk',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: chunk < chunks.count - 1 ? onNext : null,
            ),
            FilterChip(
              label: const Text('Page'),
              tooltip: 'Show one chunk at a time',
              visualDensity: VisualDensity.compact,
              selected: settings.isPaged,
              onSelected: notifier.setPaged,
            ),
          ],
        ),
        _ToolbarGroup(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: SeguiAlignmentLayout.siteFieldMax,
              ),
              // Sized to the label or hint, whichever is wider.
              child: IntrinsicWidth(
                child: FormFieldTheme(
                  child: TextField(
                    controller: siteController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.go,
                    decoration: InputDecoration(
                      isDense: true,
                      maintainLabelSize: true,
                      maintainHintSize: true,
                      labelText: 'Go to site',
                      hintText: '1–${_siteFormat.format(data.length)}',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: SeguiControlSize.iconSmall,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: SeguiControlSize.badge,
                      ),
                    ),
                    onSubmitted: onGoToSite,
                  ),
                ),
              ),
            ),
            if (canShowChunkList)
              IconButton(
                tooltip: settings.showChunkList
                    ? 'Hide chunk list'
                    : 'Show chunk list',
                isSelected: settings.showChunkList,
                icon: const Icon(Icons.view_sidebar_outlined),
                selectedIcon: const Icon(Icons.view_sidebar_rounded),
                onPressed: notifier.toggleChunkList,
              ),
          ],
        ),
      ],
    );
  }
}

/// Controls with an optional muted label, set off from the previous group
/// by a divider. Controls wrap when the group is wider than the toolbar.
class _ToolbarGroup extends StatelessWidget {
  const _ToolbarGroup({
    required this.children,
    this.label,
    this.isFirst = false,
  });

  final List<Widget> children;
  final String? label;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? label = this.label;
    return Container(
      padding: EdgeInsets.only(
        left: isFirst ? 0 : SeguiSpacing.lg,
        right: SeguiSpacing.lg,
      ),
      decoration: isFirst
          ? null
          : BoxDecoration(
              border: Border(
                left: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
      child: Wrap(
        spacing: SeguiSpacing.sm,
        runSpacing: SeguiSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (label != null)
            Text(
              label,
              style: theme.textTheme.labelSmall!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}
