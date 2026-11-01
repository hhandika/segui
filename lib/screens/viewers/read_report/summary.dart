import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/read_report/charts.dart';
import 'package:segui/screens/viewers/read_report/paged_table.dart';
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
/// order of the sample list, and picking one opens it. The controls and
/// the checks stay in place while the samples scroll between them.
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
    return LayoutBuilder(
      builder: (context, constraints) => _content(
        context,
        metrics: metrics,
        metric: metric,
        open: open,
        fills: constraints.hasBoundedHeight,
      ),
    );
  }

  /// The controls, samples, and checks. When the panel [fills] its space,
  /// the samples take what the controls and checks leave.
  Widget _content(
    BuildContext context, {
    required List<ReadMetric> metrics,
    required ReadMetric metric,
    required ReadSampleData open,
    required bool fills,
  }) {
    final Widget samples = widget.view.isEmpty
        ? const Align(
            alignment: Alignment.topCenter,
            child: ChartPlaceholder(message: 'No samples match the filter.'),
          )
        : _mode == SummaryView.bars
            ? SampleMetricBars(
                samples: widget.samples,
                view: widget.view,
                index: widget.index,
                metric: metric,
                onSelected: widget.onSelected,
              )
            : ReadOverviewTable(
                samples: widget.samples,
                view: widget.view,
                index: widget.index,
                onSelected: widget.onSelected,
              );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: fills ? MainAxisSize.max : MainAxisSize.min,
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
        if (fills)
          Expanded(child: samples)
        else
          SizedBox(height: SeguiTableLayout.scrollingHeight, child: samples),
        const Divider(height: SeguiSpacing.xl),
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
/// value. The open sample is highlighted and kept in view, and a tap opens
/// another. Bars build only while visible, so long lists stay fast.
class SampleMetricBars extends StatefulWidget {
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
  State<SampleMetricBars> createState() => _SampleMetricBarsState();
}

class _SampleMetricBarsState extends State<SampleMetricBars> {
  static const double _rowExtent =
      SeguiChartLayout.barRow + 2 * SeguiSpacing.xxs;

  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(covariant SampleMetricBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showOpen());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<int> view = widget.view;
    final double largest = view
        .map((i) => widget.metric.valueOf(widget.samples[i].metrics) ?? 0)
        .fold(0, (a, b) => a > b ? a : b);
    return Scrollbar(
      controller: _controller,
      child: ListView.builder(
        controller: _controller,
        padding: const EdgeInsets.only(
          right: SeguiControlSize.scrollbarGutter,
        ),
        itemExtent: _rowExtent,
        itemCount: view.length,
        itemBuilder: (context, position) {
          final int i = view[position];
          return SampleMetricBar(
            sample: widget.samples[i],
            value: widget.metric.valueOf(widget.samples[i].metrics) ?? 0,
            largest: largest,
            metric: widget.metric,
            isOpen: i == widget.index,
            onTap: () => widget.onSelected(i),
          );
        },
      ),
    );
  }

  /// Scrolls the open sample into view.
  void _showOpen() {
    final int position = widget.view.indexOf(widget.index);
    if (position < 0 || !_controller.hasClients) return;
    final ScrollPosition scroll = _controller.position;
    final double offset = position * _rowExtent;
    if (offset < scroll.pixels ||
        offset + _rowExtent > scroll.pixels + scroll.viewportDimension) {
      _controller.jumpTo(offset.clamp(0, scroll.maxScrollExtent));
    }
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

/// Every metric of every sample, sortable by column and shown a page at a
/// time. Tapping a row opens the sample.
class ReadOverviewTable extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return PagedTable<int>(
      rows: view,
      selected: index,
      onTap: onSelected,
      columns: [
        PagedTableColumn(
          label: 'Sample',
          width: 200,
          sortValue: (i) => samples[i].sample,
          cell: (i) => Text(
            samples[i].sample,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        PagedTableColumn(
          label: 'Status',
          width: 140,
          sortValue: (i) => overallStatus(readQcChecks(samples[i])).index,
          cell: (i) => QcStatusChip(
            status: overallStatus(readQcChecks(samples[i])),
          ),
        ),
        _numeric('Reads', 130, (m) => m.readCount, _countFormat.format),
        _numeric('Bases', 160, (m) => m.baseCount, _countFormat.format),
        _numeric('Mean length', 140, (m) => m.meanReadLength, _decimal),
        _numeric('N50', 100, (m) => m.n50ReadLength, _countFormat.format),
        _numeric('GC (%)', 110, (m) => 100 * m.gcContent, _decimal),
        _numeric('Q30 (%)', 110, (m) => m.q30Pct, _decimal),
        _numeric('Mean Q', 110, (m) => m.meanQscore, _decimal),
        _numeric(
          'Duplication (%)',
          160,
          (m) => m.duplicatePct ?? 0,
          _decimal,
        ),
        _numeric(
          'Adapters (%)',
          140,
          (m) => m.adapterReadsPct ?? 0,
          _decimal,
        ),
      ],
    );
  }

  PagedTableColumn<int> _numeric(
    String label,
    double width,
    double Function(ReadMetricsData metrics) value,
    String Function(double value) format,
  ) {
    return PagedTableColumn(
      label: label,
      width: width,
      numeric: true,
      sortValue: (i) => value(samples[i].metrics),
      cell: (i) => Text(format(value(samples[i].metrics))),
    );
  }

  static String _decimal(double value) => value.toStringAsFixed(1);
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
