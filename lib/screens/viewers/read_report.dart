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
import 'package:segui/screens/shared/badges.dart';

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
        title: BetaTitle(text: p.basename(file.path), isBeta: true),
        backgroundColor: getSEGULBackgroundColor(context),
        actions: [InfoButton(file: file)],
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: ReadReportBody(path: file.path),
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
          padding: const EdgeInsets.all(SeguiSpacing.xl),
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
                        child: OutlinedPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TabBar(
                                isScrollable: true,
                                tabAlignment: TabAlignment.start,
                                tabs: [
                                  for (final ReportTab tab in tabs)
                                    Tab(text: tab.label),
                                ],
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    for (final ReportTab tab in tabs)
                                      ReportPanel(tab: tab),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
          title: 'Per-base quality: $name',
          description: 'Median and mean quality at each position, with the '
              'middle half of bases and the 10th to 90th percentile shaded.',
          child: PositionQualityChart(positions: sample.positions),
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
          title: 'Base composition: $name',
          description: 'Share of each base at each position. Lines should '
              'be flat after the first few bases of most libraries.',
          child: BaseCompositionChart(positions: sample.positions),
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
          child: ReadLineChart(
            xLabel: 'Position (bp)',
            yLabel: 'Reads (%)',
            minY: 0,
            lines: [
              for (int i = 0; i < sample.adapters.length; i++)
                ChartLine(
                  points: ChartPoints(
                    name: sample.adapters[i].name,
                    x: sample.positions.start,
                    y: sample.adapters[i].cumulativePct,
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
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: ReadSampleRail(
          samples: _samples,
          index: _index,
          onSelected: (index) {
            Navigator.of(context).pop();
            _select(index);
          },
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
              visualDensity: VisualDensity.compact,
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
/// checkbox menu for more.
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
    if (samples.length > _maxCompareChips) {
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

/// A button that opens a checkbox list of every sample. The menu stays
/// open while samples are toggled.
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
        label: Text(
          'Compared: ${selected.length} of ${samples.length} samples',
        ),
      ),
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
