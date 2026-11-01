import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/viewers/read_report/charts.dart';
import 'package:segui/screens/viewers/read_report/sample_list.dart';
import 'package:segui/screens/viewers/report/data_bar.dart';
import 'package:segui/screens/viewers/report/metric_bars.dart';
import 'package:segui/screens/viewers/report/paged_table.dart';
import 'package:segui/services/viewers/natural_sort.dart';
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

/// Every sample at a glance: one metric as bars, or all
/// metrics as a table, followed by the checks of the open sample. Samples follow the
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
        : switch (_mode) {
            SummaryView.bars => MetricBars(
                view: widget.view,
                open: widget.index,
                name: (i) => widget.samples[i].sample,
                value: (i) => metric.valueOf(widget.samples[i].metrics) ?? 0,
                label: metric.label,
                format: metric.format,
                exact: switch (metric) {
                  ReadMetric.reads || ReadMetric.bases => _countFormat.format,
                  _ => metric.format,
                },
                leading: (i) => SampleStatusDot(sample: widget.samples[i]),
                onSelected: widget.onSelected,
              ),
            SummaryView.table => ReadOverviewTable(
                samples: widget.samples,
                view: widget.view,
                index: widget.index,
                onSelected: widget.onSelected,
              ),
          };
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
                tooltip: 'Show ${check.name.toLowerCase()} ranges',
                onPressed: () => showQcCheckRanges(
                  context,
                  check: check,
                  sample: open.sample,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Every metric of every sample, sortable by column and shown a page at a
/// time. A bar behind each number shows where it sits between the lowest
/// and highest value of its column among the listed samples, colored by
/// status in columns with a quality check. Tapping a row opens the sample.
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
    final Color neutral = Theme.of(context).colorScheme.primary;
    PagedTableColumn<int> numeric(
      String label,
      double width,
      ReadMetric metric,
      String Function(double value) format,
    ) {
      return _numeric(label, width, metric, format, neutral);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DataBarLegend(
          swatches: [
            for (final ReadQcStatus status in ReadQcStatus.values)
              (statusColor(status), status.label),
            (neutral, 'No check'),
          ],
        ),
        const SizedBox(height: SeguiSpacing.sm),
        Expanded(
          child: PagedTable<int>(
            rows: view,
            selected: index,
            onTap: onSelected,
            columns: [
              PagedTableColumn(
                label: 'Sample',
                width: 200,
                sortValue: (i) => NaturalText(samples[i].sample),
                resizable: true,
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
              numeric('Reads', 130, ReadMetric.reads, _countFormat.format),
              numeric('Bases', 160, ReadMetric.bases, _countFormat.format),
              numeric('Mean length', 140, ReadMetric.meanLength, _decimal),
              numeric('N50', 100, ReadMetric.n50, _countFormat.format),
              numeric('GC (%)', 110, ReadMetric.gc, _decimal),
              numeric('Q30 (%)', 110, ReadMetric.q30, _decimal),
              numeric('Mean Q', 110, ReadMetric.meanQuality, _decimal),
              numeric(
                'Duplication (%)',
                160,
                ReadMetric.duplication,
                _decimal,
              ),
              numeric('Adapters (%)', 140, ReadMetric.adapters, _decimal),
            ],
          ),
        ),
      ],
    );
  }

  /// A column of [metric] with a data bar behind each value. Samples
  /// without the metric show a dash and no bar.
  PagedTableColumn<int> _numeric(
    String label,
    double width,
    ReadMetric metric,
    String Function(double value) format,
    Color neutral,
  ) {
    final List<double> listed = [
      for (final int i in view)
        if (metric.valueOf(samples[i].metrics) case final double value) value,
    ];
    final double low = listed.fold(double.infinity, math.min);
    final double high = listed.fold(double.negativeInfinity, math.max);
    final ReadQcRule? rule = metric.rule;
    return PagedTableColumn(
      label: label,
      width: width,
      numeric: true,
      sortValue: (i) =>
          metric.valueOf(samples[i].metrics) ?? double.negativeInfinity,
      cell: (i) {
        final double? value = metric.valueOf(samples[i].metrics);
        if (value == null) return const Text('-');
        final Text text = Text(format(value), maxLines: 1, softWrap: false);
        // Bars say nothing when every listed sample has the same value.
        if (high <= low) return text;
        return DataBarCell(
          fraction: (value - low) / (high - low),
          color: rule == null ? neutral : statusColor(rule.statusOf(value)),
          child: text,
        );
      },
    );
  }

  static String _decimal(double value) => value.toStringAsFixed(1);
}

class QcStatusChip extends StatelessWidget {
  const QcStatusChip({
    super.key,
    required this.status,
    this.label,
    this.tooltip,
    this.onPressed,
  });

  final ReadQcStatus status;

  /// Text in the chip. The status name by default.
  final String? label;
  final String? tooltip;

  /// Called on a tap. Without it, the chip only shows the status.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Widget avatar = CircleAvatar(backgroundColor: statusColor(status));
    final Widget text = Text(label ?? status.label);
    if (onPressed == null) {
      return Chip(
        avatar: avatar,
        label: text,
        visualDensity: VisualDensity.compact,
      );
    }
    return ActionChip(
      avatar: avatar,
      label: text,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}

/// Shows what [check] measures and the values that pass, warn, or fail,
/// as a dialog or, on phones, a bottom sheet.
Future<void> showQcCheckRanges(
  BuildContext context, {
  required ReadQcCheck check,
  required String sample,
}) {
  return showResponsiveSheet<void>(
    context: context,
    builder: (context) => SheetContent(
      title: check.name,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
      child: QcCheckRanges(check: check, sample: sample),
    ),
  );
}

/// The description of a check, the sample's value, and the range of each
/// status with the sample's status highlighted.
class QcCheckRanges extends StatelessWidget {
  const QcCheckRanges({super.key, required this.check, required this.sample});

  final ReadQcCheck check;
  final String sample;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(check.rule.description, style: theme.textTheme.bodyMedium),
        const SizedBox(height: SeguiSpacing.lg),
        Text(
          '$sample: ${check.value} (${check.status.label.toLowerCase()})',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: SeguiSpacing.md),
        for (final (ReadQcStatus status, String range) in check.rule.ranges)
          Semantics(
            selected: status == check.status,
            child: Container(
              margin: const EdgeInsets.only(bottom: SeguiSpacing.xs),
              padding: const EdgeInsets.symmetric(
                horizontal: SeguiSpacing.lg,
                vertical: SeguiSpacing.md,
              ),
              decoration: BoxDecoration(
                color: status == check.status
                    ? colors.secondaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(SeguiRadius.sm),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: SeguiControlSize.indicator / 2,
                    backgroundColor: statusColor(status),
                  ),
                  const SizedBox(width: SeguiSpacing.md),
                  SizedBox(
                    width: SeguiControlSize.illustration,
                    child:
                        Text(status.label, style: theme.textTheme.labelLarge),
                  ),
                  Expanded(
                    child: Text(range, style: theme.textTheme.bodyMedium),
                  ),
                  if (status == check.status)
                    Icon(
                      Icons.check_rounded,
                      size: SeguiControlSize.iconSmall,
                      color: colors.onSecondaryContainer,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
