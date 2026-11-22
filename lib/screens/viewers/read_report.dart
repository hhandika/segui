import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/screens/viewers/read_report/charts.dart';
import 'package:segui/screens/viewers/read_report/cohort.dart';
import 'package:segui/screens/viewers/read_report/sample_list.dart';
import 'package:segui/screens/viewers/read_report/spread.dart';
import 'package:segui/screens/viewers/read_report/summary.dart';
import 'package:segui/screens/viewers/report/layout.dart';
import 'package:segui/screens/viewers/report/paged_table.dart';
import 'package:segui/services/providers/read_report.dart';
import 'package:segui/services/viewers/read_report.dart';
import 'package:segui/src/rust/api/reads.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';

/// Samples compared on one chart by default, before the chart gets crowded.
const int _defaultComparedSamples = 8;

final NumberFormat _countFormat = NumberFormat('#,##0');

/// Interactive charts for `read-report.json`.
class ReadReportView extends StatelessWidget {
  const ReadReportView({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(p.basename(file.path)),
        backgroundColor: getSEGULBackgroundColor(context),
        actions: [InfoButton(file: file)],
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: SafeArea(child: ReadReportBody(path: file.path)),
    );
  }
}

class ReadReportBody extends ConsumerWidget {
  const ReadReportBody({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(readReportProvider(path)).when(
          data: (report) => ReadReportContent(report: report),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyScreen(
            title: 'Failed to read the report.',
            description: error.toString(),
          ),
        );
  }
}

/// The report of one open sample, with a sample list beside it and a
/// switcher above it, like the file list of the alignment viewer.
class ReadReportContent extends ConsumerStatefulWidget {
  const ReadReportContent({super.key, required this.report});

  final ReadReportData report;

  @override
  ConsumerState<ReadReportContent> createState() => _ReadReportContentState();
}

class _ReadReportContentState extends ConsumerState<ReadReportContent> {
  late List<ReadSampleData> _samples;

  /// The open sample, as a position in [_samples].
  int _index = 0;
  late Set<int> _compared;
  SpreadView _spreadView = SpreadView.band;
  bool _relativePosition = false;

  @override
  void initState() {
    super.initState();
    _setSamples();
  }

  @override
  void didUpdateWidget(covariant ReadReportContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.report != widget.report) {
      _setSamples();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_samples.isEmpty) {
      return const EmptyScreen(
        title: 'No reads in this report.',
        description: 'The input files have no reads to summarize.',
      );
    }
    final ReadSampleListSettings list = ref.watch(readSampleListProvider);
    final List<int> view = readSampleView(
      _samples,
      query: list.query,
      sort: list.sort,
      ascending: list.ascending,
    );
    final bool hasOtherSamples = _samples.length > 1;
    final bool isCompact = isPhoneScreen(context);
    final bool showList = hasOtherSamples && list.showList && !isCompact;
    final List<ReportTab> tabs = _tabs(view);
    return CallbackShortcuts(
      bindings: {
        if (hasOtherSamples) ...{
          const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): () =>
              _select(stepThrough(view, _index, -1)),
          const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): () =>
              _select(stepThrough(view, _index, 1)),
        },
      },
      child: Focus(
        autofocus: true,
        child: Padding(
          padding: reportPadding(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showList) ...[
                SizedBox(
                  width: SeguiAlignmentLayout.fileList,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        // A Material panel, so list tiles keep their ink.
                        child: OutlinedPanel(
                          child: ReadSampleRail(
                            samples: _samples,
                            index: _index,
                            onSelected: _select,
                          ),
                        ),
                      ),
                      const ReadSampleHint(),
                    ],
                  ),
                ),
                const SizedBox(width: SeguiSpacing.md),
              ],
              Expanded(
                child: DefaultTabController(
                  length: tabs.length,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hasOtherSamples) ...[
                        ReadReportHeader(
                          switcher: ReadSampleSwitcher(
                            samples: _samples,
                            view: view,
                            index: _index,
                            onSelected: _select,
                          ),
                          isListShown: showList,
                          onToggleList: isCompact
                              ? _showSampleSheet
                              : ref
                                  .read(readSampleListProvider.notifier)
                                  .toggleList,
                        ),
                        const SizedBox(height: SeguiSpacing.md),
                      ],
                      Expanded(
                        child: OutlinedPanel(child: ReportTabView(tabs: tabs)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ReportTab> _tabs(List<int> view) {
    final ReadSampleData sample = _samples[_index];
    final String name = sample.sample;
    final List<(int, AdapterContentData)> adapters = detectedAdapters(sample);
    final bool hasRelative = sample.relativePositions.startPct.isNotEmpty;
    final bool useRelative = _relativePosition && hasRelative;
    return [
      ReportTab(label: 'Summary', sections: [
        ReportSection(
          title: 'Samples',
          description: 'Every sample in the order of the sample list. '
              'Select one to open it.',
          fill: true,
          child: ReadSummaryPanel(
            samples: _samples,
            view: view,
            index: _index,
            onSelected: _select,
          ),
        ),
      ]),
      ReportTab(label: 'Quality', sections: [
        ReportSection(
          title: useRelative
              ? 'Relative-position quality: $name'
              : 'Per-base quality: $name',
          description:
              'Median, mean, and effective quality across read position, '
              'with the middle half and 10th to 90th percentile shaded.',
          header: hasRelative
              ? PositionCoordinateToggle(
                  relative: _relativePosition,
                  onChanged: (value) =>
                      setState(() => _relativePosition = value),
                )
              : null,
          child: useRelative
              ? RelativePositionQualityChart(
                  positions: sample.relativePositions,
                )
              : PositionQualityChart(positions: sample.positions),
        ),
        _comparison(
          view,
          title: 'Per-read quality',
          description: 'Reads by their mean quality score.',
          xLabel: 'Mean quality score',
          countLabel: 'Reads',
          points: (s) => indexedPoints(s.sample, s.readQualityCounts),
          isCount: true,
        ),
        if (sample.expectedErrors.isNotEmpty)
          ReportSection(
            title: 'Expected errors per read: $name',
            description: 'Estimated sequencing errors per read.',
            child: ExpectedErrorsChart(sample: sample),
          ),
      ]),
      ReportTab(label: 'Composition', sections: [
        ReportSection(
          title: 'GC content: $name',
          description: 'Reads by GC content, with a normal distribution of '
              'the same mean and deviation. Peaks away from the curve can '
              'mean contamination.',
          child: ReadLineChart(
            xLabel: 'GC content (%)',
            yLabel: 'Reads',
            lines: [
              ChartLine(
                points: indexedPoints('Observed', sample.gcCounts),
                color: SeguiColors.of(context).seriesAt(0),
              ),
              ChartLine(
                points: indexedPoints('Theoretical', sample.gcTheoretical),
                color: SeguiColors.of(context).seriesAt(1),
                dashed: true,
              ),
            ],
          ),
        ),
        ReportSection(
          title: useRelative
              ? 'Relative base composition: $name'
              : 'Base composition: $name',
          description: 'Share of each base at each position. Lines should '
              'be flat after the first few bases of most libraries.',
          header: hasRelative
              ? PositionCoordinateToggle(
                  relative: _relativePosition,
                  onChanged: (value) =>
                      setState(() => _relativePosition = value),
                )
              : null,
          child: useRelative
              ? RelativeBaseCompositionChart(
                  positions: sample.relativePositions,
                )
              : BaseCompositionChart(positions: sample.positions),
        ),
        _comparison(
          view,
          title: 'N content',
          xLabel: 'Position (bp)',
          countLabel: 'N (%)',
          points: (s) => ChartPoints(
            name: s.sample,
            x: s.positions.start,
            y: s.positions.nPct,
          ),
          isCount: false,
        ),
      ]),
      ReportTab(label: 'Length', sections: [
        _comparison(
          view,
          title: 'Read length',
          xLabel: 'Read length (bp)',
          countLabel: 'Reads',
          points: (s) => ChartPoints(
            name: s.sample,
            x: s.lengthValues,
            y: s.lengthCounts,
          ),
          isCount: true,
        ),
        if (sample.lengthQuality.isNotEmpty)
          ReportSection(
            title: 'Quality by read length: $name',
            description: 'Effective and mean quality by read-length range.',
            child: LengthQualityChart(bins: sample.lengthQuality),
          ),
      ]),
      ReportTab(label: 'Duplication', sections: [
        ReportSection(
          title: 'Duplication: $name',
          description: 'Copies of each sequence across every read. Most '
              'reads of a diverse library appear once.',
          child: DuplicationChart(sample: sample),
        ),
      ]),
      ReportTab(label: 'Adapters', sections: [
        ReportSection(
          title: 'Adapter content: $name',
          description: 'Reads with an adapter starting at or before each '
              'position. Rising lines suggest the reads need trimming.',
          child: adapters.isEmpty
              ? const ChartPlaceholder(message: 'No adapters found.')
              : ReadLineChart(
                  xLabel: 'Position (bp)',
                  yLabel: 'Reads (%)',
                  minY: 0,
                  lines: [
                    for (final (int i, AdapterContentData adapter) in adapters)
                      ChartLine(
                        points: ChartPoints(
                          name: adapter.name,
                          x: sample.positions.start,
                          y: adapter.cumulativePct,
                        ),
                        color: SeguiColors.of(context).seriesAt(i),
                      ),
                  ],
                ),
        ),
      ]),
      ReportTab(label: 'Overrepresented', sections: [
        ReportSection(
          title: 'Overrepresented sequences: $name',
          description: 'Read starts above 0.1% of all reads. Reads longer '
              'than 75 bp are compared by their first 50 bp.',
          fill: true,
          child: OverrepresentedTable(sequences: sample.overrepresented),
        ),
      ]),
      if (widget.report.cohort != null || widget.report.pairs.isNotEmpty)
        ReportTab(label: 'Cohort', sections: [
          if (widget.report.cohort case final ReadCohortData cohort)
            ReportSection(
              title: 'Pooling depth balance',
              description: 'Read-depth distribution across all samples.',
              child: CohortBalanceSummary(
                cohort: cohort,
                qcProfile: widget.report.qcProfile,
              ),
            ),
          if (widget.report.pairs.isNotEmpty)
            ReportSection(
              title: 'Paired-end R1/R2 consistency',
              description: 'Read-count sync and R2 quality drop per pair.',
              child: ReadPairsTable(pairs: widget.report.pairs),
            ),
          if (widget.report.cohort case final ReadCohortData cohort
              when cohort.outliers.isNotEmpty)
            ReportSection(
              title: 'Cohort-relative outliers',
              description: 'Samples far from the cohort median.',
              child: CohortOutliersTable(outliers: cohort.outliers),
            ),
        ]),
    ];
  }

  /// A chart comparing samples: chosen samples as lines in small reports,
  /// and every listed sample as a band or heatmap in larger ones.
  /// [isCount] charts compare shares of reads, since depths differ, and
  /// count x values a sample lacks as zero.
  ReportSection _comparison(
    List<int> view, {
    required String title,
    required String xLabel,
    required String countLabel,
    required ChartPoints Function(ReadSampleData sample) points,
    required bool isCount,
    String? description,
  }) {
    if (_samples.length <= maxOverlaidSamples) {
      return ReportSection(
        title: title,
        description: description,
        header: SampleCompareChips(
          samples: _samples,
          selected: _compared,
          onChanged: (selected) => setState(() => _compared = selected),
        ),
        child: ReadLineChart(
          xLabel: xLabel,
          yLabel: countLabel,
          minY: isCount ? null : 0,
          lines: _overlay([
            for (int i = 0; i < _samples.length; i++)
              if (_compared.contains(i)) _samples[i],
          ], points),
        ),
      );
    }
    final String summary = _spreadView == SpreadView.band
        ? 'Every listed sample as percentiles, with '
            '${_samples[_index].sample} and outlying samples drawn on top.'
        : 'Every listed sample as a row, in the order of the sample list. '
            'Select a row to open the sample.';
    return ReportSection(
      title: title,
      description: [
        if (description != null) description,
        if (isCount) 'Shares of each sample\'s reads.',
        summary,
      ].join(' '),
      header: SpreadViewToggle(
        view: _spreadView,
        onChanged: (view) => setState(() => _spreadView = view),
      ),
      child: SampleSpreadChart(
        samples: _samples,
        view: view,
        index: _index,
        points: isCount ? (s) => sharePoints(points(s)) : points,
        missingIsZero: isCount,
        xLabel: xLabel,
        yLabel: isCount ? '$countLabel (%)' : countLabel,
        minY: 0,
        mode: _spreadView,
        onSelected: _select,
      ),
    );
  }

  /// Opens the sample at [index].
  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  void _setSamples() {
    _samples = samplesWithReads(widget.report);
    // Opens the first sample of the list, in its current order.
    final ReadSampleListSettings list = ref.read(readSampleListProvider);
    final List<int> view = readSampleView(
      _samples,
      sort: list.sort,
      ascending: list.ascending,
    );
    _index = view.isEmpty ? 0 : view.first;
    _compared = {
      for (int i = 0; i < _samples.length && i < _defaultComparedSamples; i++)
        i,
    };
  }

  List<ChartLine> _overlay(
    List<ReadSampleData> samples,
    ChartPoints Function(ReadSampleData sample) points,
  ) {
    return [
      for (final ReadSampleData sample in samples)
        ChartLine(
          points: points(sample),
          color: SeguiColors.of(context).seriesAt(_samples.indexOf(sample)),
        ),
    ];
  }

  // Narrow screens show the sample list as a sheet that closes on a pick.
  Future<void> _showSampleSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: SeguiSheetLayout.listHeight,
        child: SafeArea(
          top: false,
          child: ReadSampleRail(
            samples: _samples,
            index: _index,
            onSelected: (index) {
              Navigator.of(context).pop();
              _select(index);
            },
          ),
        ),
      ),
    );
  }
}

/// Panel above the tabs with the sample switcher and the list toggle,
/// styled like the alignment viewer's file switcher.
class ReadReportHeader extends StatelessWidget {
  const ReadReportHeader({
    super.key,
    required this.switcher,
    required this.isListShown,
    required this.onToggleList,
  });

  final Widget switcher;
  final bool isListShown;
  final VoidCallback onToggleList;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        height: SeguiControlSize.touchTarget,
        decoration: getContainerDecoration(context),
        // With the compact buttons' own padding, content sits
        // SeguiSpacing.lg from the border.
        padding: const EdgeInsets.symmetric(horizontal: SeguiSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: switcher),
            const SizedBox(
              height: SeguiControlSize.iconMedium,
              child: VerticalDivider(width: SeguiSpacing.sm),
            ),
            IconButton(
              tooltip: isListShown ? 'Hide sample list' : 'Show sample list',
              visualDensity: controlDensity(context),
              isSelected: isListShown,
              icon: const Icon(Icons.list_rounded),
              selectedIcon: const Icon(Icons.playlist_play_rounded),
              onPressed: onToggleList,
            ),
          ],
        ),
      ),
    );
  }
}

/// Most samples shown as chips. More samples go in a checkbox menu, where
/// a long list is easier to pick from.
const int _maxCompareChips = 3;

/// [selected] with sample [i] turned [on] or off.
Set<int> _toggled(Set<int> selected, int i, bool on) {
  return on ? {...selected, i} : ({...selected}..remove(i));
}

/// Toggles the samples compared on a chart: chips for a few samples, a
/// checkbox menu for more, and a checkbox sheet on phones.
class SampleCompareChips extends StatelessWidget {
  const SampleCompareChips({
    super.key,
    required this.samples,
    required this.selected,
    required this.onChanged,
  });

  final List<ReadSampleData> samples;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    if (samples.length > _maxCompareChips || isPhoneScreen(context)) {
      return Align(
        alignment: Alignment.centerLeft,
        child: SampleCompareMenu(
          samples: samples,
          selected: selected,
          onChanged: onChanged,
        ),
      );
    }
    return Wrap(
      spacing: SeguiSpacing.sm,
      runSpacing: SeguiSpacing.xs,
      children: [
        for (int i = 0; i < samples.length; i++)
          FilterChip(
            label: Text(samples[i].sample),
            selected: selected.contains(i),
            avatar: CircleAvatar(
                backgroundColor: SeguiColors.of(context).seriesAt(i)),
            showCheckmark: false,
            onSelected: (on) => onChanged(_toggled(selected, i, on)),
          ),
      ],
    );
  }
}

/// A button that opens a checkbox list of every sample, as a menu or, on
/// phones, a bottom sheet. Either stays open while samples are toggled.
class SampleCompareMenu extends StatelessWidget {
  const SampleCompareMenu({
    super.key,
    required this.samples,
    required this.selected,
    required this.onChanged,
  });

  final List<ReadSampleData> samples;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final Widget label = Text(
      'Compared: ${selected.length} of ${samples.length} samples',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (isPhoneScreen(context)) {
      return OutlinedButton.icon(
        onPressed: () => _showSheet(context),
        icon: const Icon(Icons.arrow_drop_down_rounded),
        iconAlignment: IconAlignment.end,
        label: label,
      );
    }
    final bool isAllSelected = selected.length == samples.length;
    final double maxHeight = min(
      MediaQuery.sizeOf(context).height * SeguiChartLayout.compareMenuShare,
      SeguiChartLayout.compareMenuMax,
    );
    return MenuAnchor(
      // Long sample lists scroll inside the menu.
      style: MenuStyle(
        maximumSize: WidgetStatePropertyAll(Size(double.infinity, maxHeight)),
      ),
      menuChildren: [
        MenuItemButton(
          closeOnActivate: false,
          leadingIcon: const Icon(Icons.select_all_rounded),
          onPressed: isAllSelected
              ? null
              : () => onChanged({for (int i = 0; i < samples.length; i++) i}),
          child: const Text('Select all'),
        ),
        MenuItemButton(
          closeOnActivate: false,
          leadingIcon: const Icon(Icons.deselect_rounded),
          onPressed: selected.isEmpty ? null : () => onChanged({}),
          child: const Text('Clear'),
        ),
        const Divider(height: SeguiStroke.thin),
        for (int i = 0; i < samples.length; i++)
          CheckboxMenuButton(
            closeOnActivate: false,
            value: selected.contains(i),
            onChanged: (on) => onChanged(_toggled(selected, i, on ?? false)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: SeguiControlSize.indicator / 2,
                  backgroundColor: SeguiColors.of(context).seriesAt(i),
                ),
                const SizedBox(width: SeguiSpacing.md),
                Text(samples[i].sample),
              ],
            ),
          ),
      ],
      builder: (context, controller, _) => OutlinedButton.icon(
        onPressed: controller.isOpen ? controller.close : controller.open,
        icon: const Icon(Icons.arrow_drop_down_rounded),
        iconAlignment: IconAlignment.end,
        label: label,
      ),
    );
  }

  /// Phones pick samples from a sheet that stays open while they toggle.
  Future<void> _showSheet(BuildContext context) {
    Set<int> current = selected;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      // Fits short lists and scrolls long ones.
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.sizeOf(context).height * SeguiSheetLayout.listHeight,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            void update(Set<int> next) {
              setSheetState(() => current = next);
              onChanged(next);
            }

            return SampleCompareSheet(
              samples: samples,
              selected: current,
              onChanged: update,
            );
          },
        ),
      ),
    );
  }
}

/// Every sample with a checkbox, with select all and clear, for the
/// compare sheet on phones.
class SampleCompareSheet extends StatelessWidget {
  const SampleCompareSheet({
    super.key,
    required this.samples,
    required this.selected,
    required this.onChanged,
  });

  final List<ReadSampleData> samples;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isAllSelected = selected.length == samples.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SeguiSpacing.xxl),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Compared samples',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: isAllSelected
                    ? null
                    : () =>
                        onChanged({for (int i = 0; i < samples.length; i++) i}),
                child: const Text('Select all'),
              ),
              TextButton(
                onPressed: selected.isEmpty ? null : () => onChanged({}),
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        const Divider(height: SeguiSpacing.lg),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom,
            ),
            itemCount: samples.length,
            itemBuilder: (context, i) => CheckboxListTile(
              value: selected.contains(i),
              onChanged: (on) => onChanged(_toggled(selected, i, on ?? false)),
              secondary: CircleAvatar(
                radius: SeguiControlSize.indicator / 2,
                backgroundColor: SeguiColors.of(context).seriesAt(i),
              ),
              title: Text(samples[i].sample),
            ),
          ),
        ),
      ],
    );
  }
}

/// Toggles between absolute read coordinates (bp) and relative read progress (%).
class PositionCoordinateToggle extends StatelessWidget {
  const PositionCoordinateToggle({
    super.key,
    required this.relative,
    required this.onChanged,
  });

  final bool relative;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: false, label: Text('Absolute (bp)')),
          ButtonSegment(value: true, label: Text('Relative (%)')),
        ],
        selected: {relative},
        onSelectionChanged: (values) => onChanged(values.first),
      ),
    );
  }
}

/// Share of A, C, G, T, and N across relative read position (0-100%).
class RelativeBaseCompositionChart extends StatelessWidget {
  const RelativeBaseCompositionChart({super.key, required this.positions});

  final ReadRelativePositionData positions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ResiduePalette palette = SeguiColors.fromTheme(theme).nucleotideLines;
    final List<double> x = [
      for (int i = 0; i < positions.startPct.length; i++)
        (positions.startPct[i] + positions.endPct[i]) / 2,
    ];
    final List<(String, List<double>)> bases = [
      ('A', positions.aPct),
      ('C', positions.cPct),
      ('G', positions.gPct),
      ('T', positions.tPct),
      ('N', positions.nPct),
    ];
    return ReadLineChart(
      xLabel: 'Relative position (%)',
      yLabel: 'Bases (%)',
      minY: 0,
      lines: [
        for (final (String base, List<double> y) in bases)
          ChartLine(
            points: ChartPoints(name: base, x: x, y: y),
            color: base == 'N'
                ? theme.colorScheme.outline
                : palette.colorOf(base.codeUnitAt(0)),
          ),
      ],
    );
  }
}

/// Distribution of expected sequencing errors per read.
class ExpectedErrorsChart extends StatelessWidget {
  const ExpectedErrorsChart({super.key, required this.sample});

  final ReadSampleData sample;

  @override
  Widget build(BuildContext context) {
    final ReadMetricsData m = sample.metrics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mean: ${m.meanExpectedErrors.toStringAsFixed(2)}/read '
          '(${m.expectedErrorsPer100Bp.toStringAsFixed(2)}/100 bp) · '
          'Error-free est: ${formatPercent(m.expectedErrorFreeReadsPct)} · '
          'EE < 1: ${formatPercent(m.readsEeLt1Pct)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: SeguiSpacing.md),
        ReadBarChart(
          xLabel: 'Expected errors',
          yLabel: 'Reads (%)',
          barWidth: SeguiChartLayout.wideBarWidth,
          categories: [
            for (final ReadExpectedErrorData b in sample.expectedErrors)
              b.label,
          ],
          series: [
            BarSeries(
              name: 'Reads (%)',
              values: [
                for (final ReadExpectedErrorData b in sample.expectedErrors)
                  b.readsPct,
              ],
              color: SeguiColors.of(context).seriesAt(0),
            ),
          ],
        ),
      ],
    );
  }
}

/// Effective and mean quality score stratified by read-length range.
class LengthQualityChart extends StatelessWidget {
  const LengthQualityChart({super.key, required this.bins});

  final List<ReadLengthQualityData> bins;

  @override
  Widget build(BuildContext context) {
    final SeguiColors palette = SeguiColors.of(context);
    return ReadBarChart(
      xLabel: 'Read length (bp)',
      yLabel: 'Quality score',
      categories: [for (final ReadLengthQualityData b in bins) b.label],
      series: [
        BarSeries(
          name: 'Effective Q',
          values: [
            for (final ReadLengthQualityData b in bins) b.effectiveMeanQscore,
          ],
          color: palette.seriesAt(0),
        ),
        BarSeries(
          name: 'Mean Q',
          values: [for (final ReadLengthQualityData b in bins) b.meanQscore],
          color: palette.seriesAt(1),
        ),
      ],
    );
  }
}

/// Share of A, C, G, T, and N at each position, colored like the
/// alignment viewer.
class BaseCompositionChart extends StatelessWidget {
  const BaseCompositionChart({super.key, required this.positions});

  final ReadPositionData positions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ResiduePalette palette = SeguiColors.fromTheme(theme).nucleotideLines;
    final List<(String, List<double>)> bases = [
      ('A', positions.aPct),
      ('C', positions.cPct),
      ('G', positions.gPct),
      ('T', positions.tPct),
      ('N', positions.nPct),
    ];
    return ReadLineChart(
      xLabel: 'Position (bp)',
      yLabel: 'Bases (%)',
      minY: 0,
      lines: [
        for (final (String base, List<double> y) in bases)
          ChartLine(
            points: ChartPoints(name: base, x: positions.start, y: y),
            color: base == 'N'
                ? theme.colorScheme.outline
                : palette.colorOf(base.codeUnitAt(0)),
          ),
      ],
    );
  }
}

class DuplicationChart extends StatelessWidget {
  const DuplicationChart({super.key, required this.sample});

  final ReadSampleData sample;

  @override
  Widget build(BuildContext context) {
    final ReadDuplicationData? duplication = sample.duplication;
    if (duplication == null) {
      return const ChartPlaceholder(
        message: 'Run the read summary in Complete mode to estimate '
            'duplication.',
      );
    }
    final String method = duplication.exact
        ? 'counted exactly'
        : 'estimated from ${_countFormat.format(duplication.sketchSize)} '
            'sampled sequences';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${formatPercent(duplication.duplicatePct)} of '
          '${_countFormat.format(duplication.reads)} reads repeat another '
          'read, $method.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: SeguiSpacing.md),
        ReadBarChart(
          xLabel: 'Copies of a sequence',
          yLabel: 'Share (%)',
          categories: duplication.labels,
          series: [
            BarSeries(
              name: 'Distinct sequences',
              values: duplication.distinctPct,
              color: SeguiColors.of(context).seriesAt(0),
            ),
            BarSeries(
              name: 'Reads',
              values: duplication.readsPct,
              color: SeguiColors.of(context).seriesAt(1),
            ),
          ],
        ),
      ],
    );
  }
}

class OverrepresentedTable extends StatelessWidget {
  const OverrepresentedTable({super.key, required this.sequences});

  final List<OverrepresentedData> sequences;

  @override
  Widget build(BuildContext context) {
    if (sequences.isEmpty) {
      return const Align(
        alignment: Alignment.topCenter,
        child: ChartPlaceholder(message: 'No overrepresented sequences.'),
      );
    }
    return PagedTable<OverrepresentedData>(
      rows: sequences,
      columns: [
        PagedTableColumn(
          label: 'Sequence',
          width: 460,
          sortValue: (seq) => seq.sequence,
          cell: (seq) => SelectableText(seq.sequence, maxLines: 1),
        ),
        PagedTableColumn(
          label: 'Count',
          width: 120,
          numeric: true,
          sortValue: (seq) => seq.count,
          cell: (seq) => Text(_countFormat.format(seq.count)),
        ),
        PagedTableColumn(
          label: 'Reads (%)',
          width: 160,
          numeric: true,
          sortValue: (seq) => seq.percent,
          cell: (seq) => Text(
            seq.maxErrorPct > 0
                ? '${seq.percent.toStringAsFixed(2)} '
                    '(+${seq.maxErrorPct.toStringAsFixed(3)})'
                : seq.percent.toStringAsFixed(2),
          ),
        ),
        PagedTableColumn(
          label: 'Possible source',
          width: 280,
          sortValue: (seq) => seq.source,
          cell: (seq) => Text(seq.source, overflow: TextOverflow.ellipsis),
        ),
        PagedTableColumn(
          label: '',
          width: 72,
          cell: (seq) => CopySequenceButton(sequence: seq.sequence),
        ),
      ],
    );
  }
}

class CopySequenceButton extends StatelessWidget {
  const CopySequenceButton({super.key, required this.sequence});

  final String sequence;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Copy sequence',
      icon: const Icon(Icons.copy_outlined),
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: sequence));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sequence copied.')),
          );
        }
      },
    );
  }
}
