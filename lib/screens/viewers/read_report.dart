import 'dart:io';

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
import 'package:segui/screens/viewers/read_report/summary.dart';
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
    final List<ReadSampleData> compared = [
      for (int i = 0; i < _samples.length; i++)
        if (_compared.contains(i)) _samples[i],
    ];
    final SampleCompareChips chips = SampleCompareChips(
      samples: _samples,
      selected: _compared,
      onChanged: (selected) => setState(() => _compared = selected),
    );
    return [
      ReportTab(label: 'Summary', sections: [
        ReportSection(
          title: 'Samples',
          description: 'Every sample in the order of the sample list. '
              'Select one to open it.',
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
        ReportSection(
          title: 'Per-read quality',
          description: 'Reads by their mean quality score.',
          header: chips,
          child: ReadLineChart(
            xLabel: 'Mean quality score',
            yLabel: 'Reads',
            lines: _overlay(
              compared,
              (s) => indexedPoints(s.sample, s.readQualityCounts),
            ),
          ),
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
                color: ChartPalette.seriesAt(0),
              ),
              ChartLine(
                points: indexedPoints('Theoretical', sample.gcTheoretical),
                color: ChartPalette.seriesAt(1),
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
        ReportSection(
          title: 'N content',
          header: chips,
          child: ReadLineChart(
            xLabel: 'Position (bp)',
            yLabel: 'N (%)',
            minY: 0,
            lines: _overlay(
              compared,
              (s) => ChartPoints(
                name: s.sample,
                x: s.positions.start,
                y: s.positions.nPct,
              ),
            ),
          ),
        ),
      ]),
      ReportTab(label: 'Length', sections: [
        ReportSection(
          title: 'Read length',
          header: chips,
          child: ReadLineChart(
            xLabel: 'Read length (bp)',
            yLabel: 'Reads',
            lines: _overlay(
              compared,
              (s) => ChartPoints(
                name: s.sample,
                x: s.lengthValues,
                y: s.lengthCounts,
              ),
            ),
          ),
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
                  color: ChartPalette.seriesAt(i),
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
          child: OverrepresentedTable(sequences: sample.overrepresented),
        ),
      ]),
    ];
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
          color: ChartPalette.seriesAt(_samples.indexOf(sample)),
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

/// A tab of the report, made of one or more sections.
class ReportTab {
  const ReportTab({required this.label, required this.sections});

  final String label;
  final List<ReportSection> sections;
}

/// A titled chart or table in a report tab.
class ReportSection {
  const ReportSection({
    required this.title,
    required this.child,
    this.description,
    this.header,
  });

  final String title;
  final Widget child;
  final String? description;

  /// Controls shown above the chart, such as sample toggles.
  final Widget? header;
}

class ReportPanel extends StatelessWidget {
  const ReportPanel({super.key, required this.tab});

  final ReportTab tab;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(SeguiSpacing.xl),
      children: [
        for (final (int i, ReportSection section) in tab.sections.indexed) ...[
          if (i > 0) const Divider(height: SeguiSpacing.xxxl * 2),
          ReportSectionView(section: section),
        ],
      ],
    );
  }
}

class ReportSectionView extends StatelessWidget {
  const ReportSectionView({super.key, required this.section});

  final ReportSection section;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(section.title, style: text.titleMedium),
        if (section.description != null) ...[
          const SizedBox(height: SeguiSpacing.xs),
          Text(section.description!, style: text.bodySmall),
        ],
        if (section.header != null) ...[
          const SizedBox(height: SeguiSpacing.md),
          section.header!,
        ],
        const SizedBox(height: SeguiSpacing.lg),
        section.child,
      ],
    );
  }
}

/// Toggles the samples compared on a chart.
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
    return Wrap(
      spacing: SeguiSpacing.sm,
      runSpacing: SeguiSpacing.xs,
      children: [
        for (int i = 0; i < samples.length; i++)
          FilterChip(
            label: Text(samples[i].sample),
            selected: selected.contains(i),
            avatar: CircleAvatar(backgroundColor: ChartPalette.seriesAt(i)),
            showCheckmark: false,
            onSelected: (on) => onChanged(
              on ? {...selected, i} : ({...selected}..remove(i)),
            ),
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
    // Darker residue colors read better as lines on a light background.
    final ResiduePalette palette = ResiduePalette.nucleotide(
      theme.brightness == Brightness.light ? Brightness.dark : Brightness.light,
    );
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
              color: ChartPalette.seriesAt(0),
            ),
            BarSeries(
              name: 'Reads',
              values: duplication.readsPct,
              color: ChartPalette.seriesAt(1),
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
      return const ChartPlaceholder(message: 'No overrepresented sequences.');
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Sequence')),
          DataColumn(label: Text('Count'), numeric: true),
          DataColumn(label: Text('Reads (%)'), numeric: true),
          DataColumn(label: Text('Possible source')),
          DataColumn(label: Text('')),
        ],
        rows: [
          for (final OverrepresentedData seq in sequences)
            DataRow(
              cells: [
                DataCell(SelectableText(seq.sequence)),
                DataCell(Text(_countFormat.format(seq.count))),
                DataCell(Text(
                  seq.maxErrorPct > 0
                      ? '${seq.percent.toStringAsFixed(2)} '
                          '(+${seq.maxErrorPct.toStringAsFixed(3)})'
                      : seq.percent.toStringAsFixed(2),
                )),
                DataCell(Text(seq.source)),
                DataCell(CopySequenceButton(sequence: seq.sequence)),
              ],
            ),
        ],
      ),
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
