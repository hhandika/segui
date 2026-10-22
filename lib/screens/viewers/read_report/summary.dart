import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/read_report/charts.dart';
import 'package:segui/screens/viewers/read_report/sample_list.dart';
import 'package:segui/services/viewers/read_report.dart';
import 'package:segui/src/rust/api/reads.dart';
import 'package:segui/styles/design_tokens.dart';

final NumberFormat _countFormat = NumberFormat('#,##0');

/// How the summary tab shows the samples.
enum SummaryView {
  bars('Bars', Icons.bar_chart_rounded),
  table('Table', Icons.table_rows_outlined);

  const SummaryView(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Every sample at a glance: one metric as bars, or all metrics as a
/// table, followed by the checks of the open sample. Samples follow the
/// order of the sample list, and picking one opens it.
class ReadSummaryPanel extends StatefulWidget {
  const ReadSummaryPanel({
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
  State<ReadSummaryPanel> createState() => _ReadSummaryPanelState();
}

class _ReadSummaryPanelState extends State<ReadSummaryPanel> {
  ReadMetric _metric = ReadMetric.reads;
  SummaryView _mode = SummaryView.bars;

  @override
  Widget build(BuildContext context) {
    final List<ReadMetric> metrics = ReadMetric.availableFor(widget.samples);
    final ReadMetric metric =
        metrics.contains(_metric) ? _metric : metrics.first;
    final ReadSampleData open = widget.samples[widget.index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: SeguiSpacing.md,
          runSpacing: SeguiSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<SummaryView>(
              showSelectedIcon: false,
              segments: [
                for (final SummaryView mode in SummaryView.values)
                  ButtonSegment(
                    value: mode,
                    label: Text(mode.label),
                    icon: Icon(mode.icon),
                  ),
              ],
              selected: {_mode},
              onSelectionChanged: (modes) =>
                  setState(() => _mode = modes.first),
            ),
            if (_mode == SummaryView.bars)
              for (final ReadMetric option in metrics)
                ChoiceChip(
                  // Without a check mark, chips keep their width.
                  showCheckmark: false,
                  label: Text(option.label),
                  selected: option == metric,
                  onSelected: (_) => setState(() => _metric = option),
                ),
          ],
        ),
        const SizedBox(height: SeguiSpacing.lg),
        if (widget.view.isEmpty)
          const ChartPlaceholder(message: 'No samples match the filter.')
        else if (_mode == SummaryView.bars)
          SampleMetricBars(
            samples: widget.samples,
            view: widget.view,
            index: widget.index,
            metric: metric,
            onSelected: widget.onSelected,
          )
        else
          ReadOverviewTable(
            samples: widget.samples,
            view: widget.view,
            index: widget.index,
            onSelected: widget.onSelected,
          ),
        const SizedBox(height: SeguiSpacing.xl),
        Text(
          'Checks for ${open.sample}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: SeguiSpacing.md),
        Wrap(
          spacing: SeguiSpacing.sm,
          runSpacing: SeguiSpacing.sm,
          children: [
            for (final ReadQcCheck check in readQcChecks(open))
              QcStatusChip(
                status: check.status,
                label: '${check.name}: ${check.value}',
              ),
          ],
        ),
      ],
    );
  }
}

/// One horizontal bar per sample for [metric], scaled to the largest
/// value. The open sample is highlighted, and a tap opens another.
class SampleMetricBars extends StatelessWidget {
  const SampleMetricBars({
    super.key,
    required this.samples,
    required this.view,
    required this.index,
    required this.metric,
    required this.onSelected,
  });

  final List<ReadSampleData> samples;
  final List<int> view;
  final int index;
  final ReadMetric metric;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final double largest = view
        .map((i) => metric.valueOf(samples[i].metrics) ?? 0)
        .fold(0, (a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final int i in view)
          SampleMetricBar(
            sample: samples[i],
            value: metric.valueOf(samples[i].metrics) ?? 0,
            largest: largest,
            metric: metric,
            isOpen: i == index,
            onTap: () => onSelected(i),
          ),
      ],
    );
  }
}

class SampleMetricBar extends StatelessWidget {
  const SampleMetricBar({
    super.key,
    required this.sample,
    required this.value,
    required this.largest,
    required this.metric,
    required this.isOpen,
    required this.onTap,
  });

  final ReadSampleData sample;
  final double value;
  final double largest;
  final ReadMetric metric;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextStyle? name = theme.textTheme.bodySmall?.copyWith(
      color: isOpen ? colors.primary : null,
      fontWeight: isOpen ? FontWeight.w600 : null,
    );
    return Semantics(
      selected: isOpen,
      button: true,
      label: '${sample.sample}, ${metric.label} ${metric.format(value)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SeguiRadius.xs),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SeguiSpacing.xs,
            vertical: SeguiSpacing.xxs,
          ),
          child: SizedBox(
            height: SeguiChartLayout.barRow,
            child: Row(
              children: [
                SampleStatusDot(sample: sample),
                const SizedBox(width: SeguiSpacing.sm),
                SizedBox(
                  width: SeguiChartLayout.barLabel,
                  child: Text(
                    sample.sample,
                    style: name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: SeguiSpacing.md),
                Expanded(
                  child: Tooltip(
                    message: '${metric.label}: ${_exact(value)}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(SeguiRadius.xs),
                      child: Container(
                        height: SeguiChartLayout.barThickness,
                        color: colors.surfaceContainerHighest,
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor:
                              largest > 0 ? (value / largest).clamp(0, 1) : 0,
                          heightFactor: 1,
                          child: ColoredBox(
                            color: isOpen
                                ? colors.primary
                                : colors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: SeguiChartLayout.barValue,
                  child: Text(
                    metric.format(value),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _exact(double value) {
    return switch (metric) {
      ReadMetric.reads || ReadMetric.bases => _countFormat.format(value),
      _ => metric.format(value),
    };
  }
}

/// Every metric of every sample, sortable by column. Tapping a row opens
/// the sample.
class ReadOverviewTable extends StatefulWidget {
  const ReadOverviewTable({
    super.key,
    required this.samples,
    required this.view,
    required this.index,
    required this.onSelected,
  });

  final List<ReadSampleData> samples;
  final List<int> view;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  State<ReadOverviewTable> createState() => _ReadOverviewTableState();
}

class _ReadOverviewTableState extends State<ReadOverviewTable> {
  int? _sortColumn;
  bool _ascending = true;

  @override
  Widget build(BuildContext context) {
    final List<_OverviewColumn> columns = _columns;
    final List<int> order = List<int>.of(widget.view);
    if (_sortColumn != null) {
      final _OverviewColumn column = columns[_sortColumn!];
      order.sort((a, b) {
        final int result = column
            .sortValue(widget.samples[a])
            .compareTo(column.sortValue(widget.samples[b]));
        return _ascending ? result : -result;
      });
    }
    return SingleChildScrollView(
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
              selected: i == widget.index,
              onSelectChanged: (_) => widget.onSelected(i),
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
    return Chip(
      avatar: CircleAvatar(backgroundColor: statusColor(status)),
      label: Text(label ?? status.label),
      visualDensity: VisualDensity.compact,
    );
  }
}
