import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/read_report/charts.dart';
import 'package:segui/screens/viewers/report/data_bar.dart';
import 'package:segui/screens/viewers/report/metric_bars.dart';
import 'package:segui/screens/viewers/report/paged_table.dart';
import 'package:segui/services/viewers/alignment_report.dart';
import 'package:segui/styles/design_tokens.dart';

/// How a report item panel shows its loci or taxa.
enum ItemView {
  bars('Bars', Icons.bar_chart_rounded),
  table('Table', Icons.table_rows_outlined);

  const ItemView(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Every locus or taxon of an alignment report: one metric as bars, or
/// all metrics as a table, with the open item's values below. The
/// controls and the values stay in place while the items scroll between
/// them. A name filter narrows both views.
class ReportItemPanel extends StatefulWidget {
  const ReportItemPanel({
    super.key,
    required this.names,
    required this.metrics,
    required this.nameLabel,
    required this.open,
    required this.onSelected,
  });

  final List<String> names;
  final List<ReportMetric> metrics;

  /// Heading of the name column, such as "Locus".
  final String nameLabel;

  /// The open item, as a position in [names].
  final int open;
  final ValueChanged<int> onSelected;

  @override
  State<ReportItemPanel> createState() => _ReportItemPanelState();
}

class _ReportItemPanelState extends State<ReportItemPanel> {
  final TextEditingController _query = TextEditingController();
  ItemView _mode = ItemView.bars;
  int _metric = 0;
  bool _highestFirst = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ReportMetric metric =
        widget.metrics[_metric.clamp(0, widget.metrics.length - 1)];
    final List<int> view = reportItemView(
      widget.names,
      query: _query.text,
      metric: metric,
      highestFirst: _mode == ItemView.bars && _highestFirst,
    );
    return LayoutBuilder(
      builder: (context, constraints) => _content(
        context,
        metric: metric,
        view: view,
        fills: constraints.hasBoundedHeight,
      ),
    );
  }

  /// The controls, items, and open item's values. When the panel [fills]
  /// its space, the items take what the controls and values leave.
  Widget _content(
    BuildContext context, {
    required ReportMetric metric,
    required List<int> view,
    required bool fills,
  }) {
    final Widget items = view.isEmpty
        ? const Align(
            alignment: Alignment.topCenter,
            child: ChartPlaceholder(message: 'No names match the filter.'),
          )
        : switch (_mode) {
            ItemView.bars => MetricBars(
                view: view,
                open: widget.open,
                name: (i) => widget.names[i],
                value: (i) => metric.values[i],
                label: metric.label,
                format: metric.format,
                onSelected: widget.onSelected,
              ),
            ItemView.table => _table(context, view),
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
            SegmentedButton<ItemView>(
              showSelectedIcon: false,
              segments: [
                for (final ItemView mode in ItemView.values)
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
            SizedBox(
              width: SeguiContentWidth.searchBar,
              child: TextField(
                controller: _query,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Filter by name',
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear filter',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(_query.clear),
                        ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (_mode == ItemView.bars) ...[
              FilterChip(
                label: const Text('Highest first'),
                selected: _highestFirst,
                onSelected: (on) => setState(() => _highestFirst = on),
              ),
              for (final (int i, ReportMetric option) in widget.metrics.indexed)
                ChoiceChip(
                  // Without a check mark, chips keep their width.
                  showCheckmark: false,
                  label: Text(option.label),
                  selected: option == metric,
                  onSelected: (_) => setState(() => _metric = i),
                ),
            ],
          ],
        ),
        const SizedBox(height: SeguiSpacing.lg),
        if (fills)
          Expanded(child: items)
        else
          SizedBox(height: SeguiTableLayout.scrollingHeight, child: items),
        const Divider(height: SeguiSpacing.xl),
        _OpenItemValues(
          name: widget.names[widget.open],
          nameLabel: widget.nameLabel,
          values: [
            for (final ReportMetric m in widget.metrics)
              (m.label, m.format(m.values[widget.open])),
          ],
        ),
      ],
    );
  }

  Widget _table(BuildContext context, List<int> view) {
    final Color neutral = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DataBarLegend(),
        const SizedBox(height: SeguiSpacing.sm),
        Expanded(
          child: PagedTable<int>(
            rows: view,
            selected: widget.open,
            onTap: widget.onSelected,
            columns: [
              PagedTableColumn(
                label: widget.nameLabel,
                width: 220,
                sortValue: (i) => widget.names[i],
                cell: (i) => Text(
                  widget.names[i],
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              for (final ReportMetric metric in widget.metrics)
                _numeric(metric, view, neutral),
            ],
          ),
        ),
      ],
    );
  }

  /// A column of [metric] with a data bar behind each value, scaled to
  /// the listed items.
  PagedTableColumn<int> _numeric(
    ReportMetric metric,
    List<int> view,
    Color neutral,
  ) {
    double low = double.infinity;
    double high = double.negativeInfinity;
    for (final int i in view) {
      final double v = metric.values[i];
      if (v < low) low = v;
      if (v > high) high = v;
    }
    return PagedTableColumn(
      label: metric.label,
      width: metric.width,
      numeric: true,
      sortValue: (i) => metric.values[i],
      cell: (i) {
        final double value = metric.values[i];
        final Text text = Text(
          metric.format(value),
          maxLines: 1,
          softWrap: false,
        );
        // Bars say nothing when every listed item has the same value.
        if (high <= low) return text;
        return DataBarCell(
          fraction: (value - low) / (high - low),
          color: neutral,
          child: text,
        );
      },
    );
  }
}

/// The values of the open locus or taxon, below its list.
class _OpenItemValues extends StatelessWidget {
  const _OpenItemValues({
    required this.name,
    required this.nameLabel,
    required this.values,
  });

  final String name;
  final String nameLabel;
  final List<(String, String)> values;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$nameLabel: $name', style: theme.textTheme.titleSmall),
        const SizedBox(height: SeguiSpacing.md),
        Wrap(
          spacing: SeguiSpacing.sm,
          runSpacing: SeguiSpacing.sm,
          children: [
            for (final (String label, String value) in values)
              Chip(
                label: Text('$label: $value'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }
}
