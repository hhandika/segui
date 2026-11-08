import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/keyboard.dart';
import 'package:segui/services/providers/alignment_view.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/styles/design_tokens.dart';

final NumberFormat _siteFormat = NumberFormat('#,###');

/// Shortcut that shows or hides the display settings: Cmd + \ on Apple
/// platforms, Ctrl + \ elsewhere.
SingleActivator get alignmentSettingsShortcut => SingleActivator(
      LogicalKeyboardKey.backslash,
      meta: PlatformKeys.isApple,
      control: !PlatformKeys.isApple,
    );

/// Top row of the viewer panel: [leading] (such as the file switcher) or
/// the file name, the file summary, go to site, the chunk list toggle, and
/// the button that shows or hides the display settings. Stays visible when
/// the settings are hidden.
class AlignmentHeaderBar extends ConsumerWidget {
  const AlignmentHeaderBar({
    super.key,
    required this.fileName,
    required this.data,
    required this.canShowChunkList,
    required this.siteController,
    required this.onGoToSite,
    this.leading,
  });

  final String fileName;
  final AlignmentViewData data;
  final bool canShowChunkList;
  final TextEditingController siteController;

  /// Called with the submitted one-based site text.
  final ValueChanged<String> onGoToSite;

  /// Shown in place of the file name, such as the file switcher.
  final Widget? leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AlignmentViewSettings settings =
        ref.watch(alignmentViewSettingsProvider);
    final AlignmentViewSettingsNotifier notifier =
        ref.read(alignmentViewSettingsProvider.notifier);
    final ThemeData theme = Theme.of(context);
    final Widget? leading = this.leading;
    final String shortcut = '${PlatformKeys.primaryLabel} + \\';
    // The buttons stay level with the first line when the rest wraps.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: SeguiSpacing.md,
            runSpacing: SeguiSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (leading != null)
                leading
              else
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
              _SiteField(
                controller: siteController,
                length: data.length,
                onSubmitted: onGoToSite,
              ),
            ],
          ),
        ),
        if (canShowChunkList)
          IconButton(
            tooltip:
                settings.showChunkList ? 'Hide chunk list' : 'Show chunk list',
            isSelected: settings.showChunkList,
            icon: const Icon(Icons.view_sidebar_outlined),
            selectedIcon: const Icon(Icons.view_sidebar_rounded),
            onPressed: notifier.toggleChunkList,
          ),
        IconButton(
          tooltip: settings.showSettings
              ? 'Hide settings ($shortcut)'
              : 'Show settings ($shortcut)',
          icon: Icon(
            settings.showSettings
                ? Icons.keyboard_arrow_up_rounded
                : Icons.tune_rounded,
          ),
          onPressed: notifier.toggleSettings,
        ),
      ],
    );
  }
}

/// Labeled groups of display controls: color, zoom, and chunk navigation.
/// Groups wrap onto more lines when narrow.
class AlignmentToolbar extends ConsumerWidget {
  const AlignmentToolbar({
    super.key,
    required this.data,
    required this.onPrevious,
    required this.onNext,
  });

  final AlignmentViewData data;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AlignmentViewSettings settings =
        ref.watch(alignmentViewSettingsProvider);
    final AlignmentViewSettingsNotifier notifier =
        ref.read(alignmentViewSettingsProvider.notifier);
    final AlignmentChunks chunks =
        AlignmentChunks(length: data.length, size: settings.chunkSize);
    final int chunk = chunks.clamp(settings.chunk);
    return Wrap(
      runSpacing: SeguiSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _ToolbarGroup(
          isFirst: true,
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
      ],
    );
  }
}

/// Go-to-site field, sized to its label or hint, whichever is wider.
class _SiteField extends StatelessWidget {
  const _SiteField({
    required this.controller,
    required this.length,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final int length;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: SeguiAlignmentLayout.siteFieldMax,
      ),
      child: IntrinsicWidth(
        child: FormFieldTheme(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.go,
            decoration: InputDecoration(
              isDense: true,
              maintainLabelSize: true,
              maintainHintSize: true,
              labelText: 'Go to site',
              hintText: '1–${_siteFormat.format(length)}',
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: SeguiControlSize.iconSmall,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: SeguiControlSize.badge,
              ),
            ),
            onSubmitted: onSubmitted,
          ),
        ),
      ),
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
