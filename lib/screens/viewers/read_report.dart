import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/screens/viewers/read_report/charts.dart';
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

/// The report tabs, with the sample they show.
class ReadReportContent extends StatefulWidget {
  const ReadReportContent({super.key, required this.report});

  final ReadReportData report;

  @override
  State<ReadReportContent> createState() => _ReadReportContentState();
}

class _ReadReportContentState extends State<ReadReportContent> {
  late List<ReadSampleData> _samples;
  int _focused = 0;
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
    final ReadSampleData sample = _samples[_focused];
    final List<ReadSampleData> compared = [
      for (int i = 0; i < _samples.length; i++)
        if (_compared.contains(i)) _samples[i],
    ];
    final SampleCompareChips chips = SampleCompareChips(
      samples: _samples,
      selected: _compared,
      onChanged: (selected) => setState(() => _compared = selected),
    );
    final List<ReportTab> tabs = [
      ReportTab(
        label: 'Overview',
        child: ReadOverview(
          samples: _samples,
          focused: _focused,
          onFocus: (i) => setState(() => _focused = i),
        ),
      ),
      ReportTab(
        label: 'Per-base quality',
        description: 'Median and mean quality at each position, with the '
            'middle half of bases and the 10th to 90th percentile shaded.',
        child: PositionQualityChart(positions: sample.positions),
      ),
      ReportTab(
        label: 'Per-read quality',
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
      ReportTab(
        label: 'GC content',
        description: 'Reads by GC content, with a normal distribution of the '
            'same mean and deviation. Peaks away from the curve can mean '
            'contamination.',
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
      ReportTab(
        label: 'Read length',
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
      ReportTab(
        label: 'Base composition',
        description: 'Share of each base at each position. Lines should be '
            'flat after the first few bases of most libraries.',
        child: BaseCompositionChart(positions: sample.positions),
      ),
      ReportTab(
        label: 'N content',
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
      ReportTab(
        label: 'Duplication',
        description: 'Copies of each sequence among the first reads of the '
            'file. Most reads of a diverse library appear once.',
        child: DuplicationChart(sample: sample),
      ),
      ReportTab(
        label: 'Adapters',
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
      ReportTab(
        label: 'Overrepresented',
        description: 'Sequences above 0.1% of the sampled reads.',
        child: OverrepresentedTable(sequences: sample.overrepresented),
      ),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SeguiSpacing.xl,
              SeguiSpacing.lg,
              SeguiSpacing.xl,
              0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SampleSelector(
                samples: _samples,
                focused: _focused,
                onChanged: (i) => setState(() => _focused = i),
              ),
            ),
          ),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final ReportTab tab in tabs) Tab(text: tab.label)],
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final ReportTab tab in tabs) ReportPanel(tab: tab)
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setSamples() {
    _samples = samplesWithReads(widget.report);
    _focused = 0;
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
}

/// A tab of the report.
class ReportTab {
  const ReportTab({
    required this.label,
    required this.child,
    this.description,
    this.header,
  });

  final String label;
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
    final TextTheme text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SeguiSpacing.xl),
      child: Container(
        padding: const EdgeInsets.all(SeguiSpacing.xl),
        decoration: getContainerDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tab.label, style: text.titleMedium),
            if (tab.description != null) ...[
              const SizedBox(height: SeguiSpacing.xs),
              Text(tab.description!, style: text.bodySmall),
            ],
            if (tab.header != null) ...[
              const SizedBox(height: SeguiSpacing.md),
              tab.header!,
            ],
            const SizedBox(height: SeguiSpacing.lg),
            tab.child,
          ],
        ),
      ),
    );
  }
}

/// Picks the sample shown on single-sample charts.
class SampleSelector extends StatelessWidget {
  const SampleSelector({
    super.key,
    required this.samples,
    required this.focused,
    required this.onChanged,
  });

  final List<ReadSampleData> samples;
  final int focused;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<int>(
      label: const Text('Sample'),
      initialSelection: focused,
      // A new focus from the overview table replaces the shown selection.
      key: ValueKey(focused),
      width: SeguiContentWidth.card,
      dropdownMenuEntries: [
        for (int i = 0; i < samples.length; i++)
          DropdownMenuEntry(value: i, label: samples[i].sample),
      ],
      onSelected: (value) {
        if (value != null) onChanged(value);
      },
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

/// Per-sample statistics with quality checks. Tapping a row shows that
/// sample on the other tabs.
class ReadOverview extends StatefulWidget {
  const ReadOverview({
    super.key,
    required this.samples,
    required this.focused,
    required this.onFocus,
  });

  final List<ReadSampleData> samples;
  final int focused;
  final ValueChanged<int> onFocus;

  @override
  State<ReadOverview> createState() => _ReadOverviewState();
}

class _ReadOverviewState extends State<ReadOverview> {
  int? _sortColumn;
  bool _ascending = true;

  @override
  Widget build(BuildContext context) {
    final List<_OverviewColumn> columns = _columns;
    final List<int> order = [for (int i = 0; i < widget.samples.length; i++) i];
    if (_sortColumn != null) {
      final _OverviewColumn column = columns[_sortColumn!];
      order.sort((a, b) {
        final int result = column
            .sortValue(widget.samples[a])
            .compareTo(column.sortValue(widget.samples[b]));
        return _ascending ? result : -result;
      });
    }
    final ReadSampleData focused = widget.samples[widget.focused];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            sortColumnIndex: _sortColumn,
            sortAscending: _ascending,
            showCheckboxColumn: false,
            columns: [
              for (int i = 0; i < columns.length; i++)
                DataColumn(
                  label: Text(columns[i].label),
                  numeric: columns[i].numeric,
                  onSort: (index, ascending) => setState(() {
                    _sortColumn = index;
                    _ascending = ascending;
                  }),
                ),
            ],
            rows: [
              for (final int i in order)
                DataRow(
                  selected: i == widget.focused,
                  onSelectChanged: (_) => widget.onFocus(i),
                  cells: [
                    for (final _OverviewColumn column in columns)
                      DataCell(
                        column.showsStatus
                            ? QcStatusChip(
                                status: overallStatus(
                                  readQcChecks(widget.samples[i]),
                                ),
                              )
                            : Text(column.text(widget.samples[i])),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: SeguiSpacing.xl),
        Text(
          'Checks for ${focused.sample}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: SeguiSpacing.md),
        Wrap(
          spacing: SeguiSpacing.sm,
          runSpacing: SeguiSpacing.sm,
          children: [
            for (final ReadQcCheck check in readQcChecks(focused))
              QcStatusChip(
                status: check.status,
                label: '${check.name}: ${check.value}',
              ),
          ],
        ),
      ],
    );
  }

  List<_OverviewColumn> get _columns => [
        _OverviewColumn(
          label: 'Sample',
          numeric: false,
          sortValue: (s) => s.sample,
          text: (s) => s.sample,
        ),
        _OverviewColumn(
          label: 'Status',
          numeric: false,
          sortValue: (s) => overallStatus(readQcChecks(s)).index,
          text: (s) => overallStatus(readQcChecks(s)).label,
          showsStatus: true,
        ),
        _numeric('Reads', (m) => m.readCount, _countFormat.format),
        _numeric('Bases', (m) => m.baseCount, _countFormat.format),
        _numeric('Mean length', (m) => m.meanReadLength, _decimal),
        _numeric('N50', (m) => m.n50ReadLength, _countFormat.format),
        _numeric('GC (%)', (m) => 100 * m.gcContent, _decimal),
        _numeric('Q30 (%)', (m) => m.q30Pct, _decimal),
        _numeric('Mean Q', (m) => m.meanQscore, _decimal),
        _numeric('Duplication (%)', (m) => m.duplicatePct ?? 0, _decimal),
        _numeric('Adapters (%)', (m) => m.adapterReadsPct ?? 0, _decimal),
      ];

  _OverviewColumn _numeric(
    String label,
    double Function(ReadMetricsData metrics) value,
    String Function(double value) format,
  ) {
    return _OverviewColumn(
      label: label,
      numeric: true,
      sortValue: (s) => value(s.metrics),
      text: (s) => format(value(s.metrics)),
    );
  }

  static String _decimal(double value) => value.toStringAsFixed(1);
}

class _OverviewColumn {
  const _OverviewColumn({
    required this.label,
    required this.numeric,
    required this.sortValue,
    required this.text,
    this.showsStatus = false,
  });

  final String label;
  final bool numeric;
  final Comparable Function(ReadSampleData sample) sortValue;
  final String Function(ReadSampleData sample) text;

  /// Whether cells show the sample status as a chip instead of [text].
  final bool showsStatus;
}

class QcStatusChip extends StatelessWidget {
  const QcStatusChip({super.key, required this.status, this.label});

  final ReadQcStatus status;

  /// Text in the chip. The status name by default.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      ReadQcStatus.pass => ChartPalette.pass,
      ReadQcStatus.warn => ChartPalette.warn,
      ReadQcStatus.fail => ChartPalette.fail,
    };
    return Chip(
      avatar: CircleAvatar(backgroundColor: color),
      label: Text(label ?? status.label),
      visualDensity: VisualDensity.compact,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${formatPercent(duplication.duplicatePct)} of '
          '${_countFormat.format(duplication.sampledReads)} sampled reads '
          'repeat an earlier read.',
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
                DataCell(Text(seq.percent.toStringAsFixed(2))),
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
