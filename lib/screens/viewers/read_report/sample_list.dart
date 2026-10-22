import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/viewers/alignment/selected_row_mark.dart';
import 'package:segui/services/keyboard.dart';
import 'package:segui/services/providers/read_report.dart';
import 'package:segui/services/viewers/read_report.dart';
import 'package:segui/src/rust/api/reads.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';

/// Dot in the color of a sample's overall quality status.
class SampleStatusDot extends StatelessWidget {
  const SampleStatusDot({super.key, required this.sample});

  final ReadSampleData sample;

  @override
  Widget build(BuildContext context) {
    final ReadQcStatus status = overallStatus(readQcChecks(sample));
    return Tooltip(
      message: status.label,
      child: Container(
        width: SeguiControlSize.indicator,
        height: SeguiControlSize.indicator,
        decoration: BoxDecoration(
          color: statusColor(status),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

Color statusColor(ReadQcStatus status) {
  return switch (status) {
    ReadQcStatus.pass => ChartPalette.pass,
    ReadQcStatus.warn => ChartPalette.warn,
    ReadQcStatus.fail => ChartPalette.fail,
  };
}

/// Sample switcher above the report tabs. Steps through the samples as
/// listed with arrows, or picks one from a searchable list.
class ReadSampleSwitcher extends StatelessWidget {
  const ReadSampleSwitcher({
    super.key,
    required this.samples,
    required this.view,
    required this.index,
    required this.onSelected,
  });

  final List<ReadSampleData> samples;

  /// Samples in list order, as positions in [samples].
  final List<int> view;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReadSampleData sample = samples[index];
    final int position = view.indexOf(index);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Previous sample (${PlatformKeys.altLabel} + ↑)',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.keyboard_arrow_up_rounded),
          onPressed: () => onSelected(stepThrough(view, index, -1)),
        ),
        Flexible(
          child: SearchAnchor(
            viewHintText: 'Filter ${samples.length} samples',
            isFullScreen: isPhoneScreen(context),
            viewBackgroundColor: theme.colorScheme.surface,
            viewConstraints: const BoxConstraints(
              minWidth: SeguiContentWidth.searchViewMin,
              maxWidth: SeguiContentWidth.dialog,
              maxHeight: SeguiControlSize.searchViewMax,
            ),
            builder: (context, controller) => TextButton(
              onPressed: controller.openView,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
                visualDensity: VisualDensity.compact,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SampleStatusDot(sample: sample),
                  const SizedBox(width: SeguiSpacing.sm),
                  Flexible(
                    // The name keeps most of the room when space is short.
                    flex: 3,
                    child: Text(
                      sample.sample,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  // Phones keep the room for the name.
                  if (!isPhoneScreen(context)) ...[
                    const SizedBox(width: SeguiSpacing.sm),
                    Flexible(
                      child: Text(
                        position < 0
                            ? 'Filtered out'
                            : '${position + 1} of ${view.length}',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: theme.textTheme.labelMedium!.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  const Icon(Icons.arrow_drop_down_rounded),
                ],
              ),
            ),
            suggestionsBuilder: (context, controller) {
              final List<int> matches =
                  readSampleView(samples, query: controller.text);
              if (matches.isEmpty) {
                return const [ListTile(title: Text('No samples match.'))];
              }
              return [
                for (final int i in matches)
                  ReadSampleTile(
                    sample: samples[i],
                    isSelected: i == index,
                    onTap: () {
                      controller.closeView(null);
                      onSelected(i);
                    },
                  ),
              ];
            },
          ),
        ),
        IconButton(
          tooltip: 'Next sample (${PlatformKeys.altLabel} + ↓)',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () => onSelected(stepThrough(view, index, 1)),
        ),
      ],
    );
  }
}

/// A sample in a list, with its status, reads, and Q30 share.
class ReadSampleTile extends StatelessWidget {
  const ReadSampleTile({
    super.key,
    required this.sample,
    required this.isSelected,
    required this.onTap,
  });

  final ReadSampleData sample;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ReadMetricsData m = sample.metrics;
    // Inset row marked on its left when selected, as in the file list.
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SeguiSpacing.sm,
        vertical: SeguiSpacing.xxs,
      ),
      child: SelectedRowMark(
        isSelected: isSelected,
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SeguiRadius.md),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: SeguiSpacing.sm,
          ),
          leading: SampleStatusDot(sample: sample),
          minLeadingWidth: SeguiControlSize.indicator,
          title: Text(sample.sample, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${formatCompact(m.readCount)} reads · '
            'Q30 ${formatPercent(m.q30Pct)}',
            overflow: TextOverflow.ellipsis,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

/// Every sample of the report, with a filter, a sort order, and arrows
/// that step through the samples as listed.
class ReadSampleRail extends ConsumerStatefulWidget {
  const ReadSampleRail({
    super.key,
    required this.samples,
    required this.index,
    required this.onSelected,
  });

  final List<ReadSampleData> samples;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  ConsumerState<ReadSampleRail> createState() => _ReadSampleRailState();
}

class _ReadSampleRailState extends ConsumerState<ReadSampleRail> {
  late final TextEditingController _query = TextEditingController(
    text: ref.read(readSampleListProvider).query,
  );

  @override
  void initState() {
    super.initState();
    _query.addListener(
      () => ref.read(readSampleListProvider.notifier).setQuery(_query.text),
    );
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReadSampleListSettings settings = ref.watch(readSampleListProvider);
    final List<int> view = readSampleView(
      widget.samples,
      query: settings.query,
      sort: settings.sort,
      ascending: settings.ascending,
    );
    final double most = widget.samples
        .map((s) => s.metrics.readCount)
        .fold(0, (a, b) => a > b ? a : b);
    final int position = view.indexOf(widget.index);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(SeguiSpacing.lg),
          child: FormFieldTheme(
            child: TextField(
              controller: _query,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Filter samples',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: SeguiControlSize.iconSmall,
                ),
                suffixIcon: _SampleSortButton(),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SeguiSpacing.lg),
          child: Text(
            '${view.length} of ${widget.samples.length} samples · '
            'by ${settings.sort.label.toLowerCase()}',
            style: theme.textTheme.labelSmall!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: SeguiSpacing.xs),
        Expanded(
          child: ListView.builder(
            itemCount: view.length,
            itemBuilder: (context, i) {
              final ReadSampleData sample = widget.samples[view[i]];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ReadSampleTile(
                    sample: sample,
                    isSelected: view[i] == widget.index,
                    onTap: () => widget.onSelected(view[i]),
                  ),
                  if (most > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SeguiSpacing.lg,
                      ),
                      child: LinearProgressIndicator(
                        value: sample.metrics.readCount / most,
                        minHeight: SeguiStroke.regular,
                        color: theme.colorScheme.primary,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        semanticsLabel: 'Relative read count',
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const Divider(height: SeguiStroke.thin),
        // Icon buttons carry their own padding, which with this inset
        // lines their icons up with the content above.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SeguiSpacing.xs),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Previous sample in list',
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
                onPressed: view.isEmpty
                    ? null
                    : () =>
                        widget.onSelected(stepThrough(view, widget.index, -1)),
              ),
              Expanded(
                child: Text(
                  position < 0
                      ? 'Not in list'
                      : '${position + 1} of ${view.length}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium,
                ),
              ),
              IconButton(
                tooltip: 'Next sample in list',
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                onPressed: view.isEmpty
                    ? null
                    : () =>
                        widget.onSelected(stepThrough(view, widget.index, 1)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sort order and direction of the sample list, inside the filter field.
/// Opens a menu on larger screens and a bottom sheet on phones.
class _SampleSortButton extends ConsumerWidget {
  const _SampleSortButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isPhoneScreen(context)) {
      return IconButton(
        tooltip: 'Sort samples',
        icon: const Icon(Icons.sort_rounded),
        visualDensity: VisualDensity.compact,
        onPressed: () => showResponsiveSheet<void>(
          context: context,
          builder: (context) => SheetContent(
            title: 'Sort samples',
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
            child: const _SampleSortChoices(),
          ),
        ),
      );
    }
    final ReadSampleListSettings settings = ref.watch(readSampleListProvider);
    final ReadSampleList notifier = ref.read(readSampleListProvider.notifier);
    return MenuAnchor(
      menuChildren: [
        for (final ReadSampleSort option in ReadSampleSort.values)
          MenuItemButton(
            leadingIcon: _Check(isOn: option == settings.sort),
            onPressed: () => notifier.setSort(option),
            child: Text('Sort by ${option.label.toLowerCase()}'),
          ),
        const Divider(height: SeguiStroke.thin),
        for (final bool ascending in const [true, false])
          MenuItemButton(
            leadingIcon: _Check(isOn: ascending == settings.ascending),
            onPressed: () => notifier.setAscending(ascending),
            child: Text(
              ascending ? settings.sort.ascending : settings.sort.descending,
            ),
          ),
      ],
      builder: (context, controller, _) => IconButton(
        tooltip: 'Sort samples',
        icon: const Icon(Icons.sort_rounded),
        visualDensity: VisualDensity.compact,
        onPressed: controller.isOpen ? controller.close : controller.open,
      ),
    );
  }
}

/// Sort and direction choices for the phone sheet. Choices apply right
/// away, so the sheet can stay open while both are set.
class _SampleSortChoices extends ConsumerWidget {
  const _SampleSortChoices();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReadSampleListSettings settings = ref.watch(readSampleListProvider);
    final ReadSampleList notifier = ref.read(readSampleListProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final ReadSampleSort option in ReadSampleSort.values)
          ListTile(
            title: Text('Sort by ${option.label.toLowerCase()}'),
            trailing: _Check(isOn: option == settings.sort),
            onTap: () => notifier.setSort(option),
          ),
        const Divider(),
        for (final bool ascending in const [true, false])
          ListTile(
            title: Text(
              ascending ? settings.sort.ascending : settings.sort.descending,
            ),
            trailing: _Check(isOn: ascending == settings.ascending),
            onTap: () => notifier.setAscending(ascending),
          ),
      ],
    );
  }
}

/// A check mark that keeps its space when off, so labels stay aligned.
class _Check extends StatelessWidget {
  const _Check({required this.isOn});

  final bool isOn;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.check_rounded,
      color: isOn ? null : Colors.transparent,
      semanticLabel: isOn ? 'Selected' : null,
    );
  }
}

/// Keyboard hint under the sample list.
class ReadSampleHint extends StatelessWidget {
  const ReadSampleHint({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SeguiSpacing.lg,
        SeguiSpacing.xs,
        SeguiSpacing.lg,
        0,
      ),
      child: Text(
        '${PlatformKeys.altLabel} + ↑ / ↓ to switch samples',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall!.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
