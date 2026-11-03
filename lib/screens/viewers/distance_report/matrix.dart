import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/read_report/charts.dart';
import 'package:segui/screens/viewers/report/heatmap_cell.dart';
import 'package:segui/screens/viewers/report/metric_bars.dart';
import 'package:segui/screens/viewers/report/paged_table.dart';
import 'package:segui/services/viewers/distance_report.dart';
import 'package:segui/services/viewers/natural_sort.dart';
import 'package:segui/src/rust/api/distance_report.dart';
import 'package:segui/styles/design_tokens.dart';

/// Matrices with more items than this show no heatmap, since every row
/// would hold every item.
const int maxHeatmapItems = 100;

/// How a matrix panel shows its values.
enum MatrixView {
  nearest('Nearest', Icons.bar_chart_rounded),
  heatmap('Heatmap', Icons.grid_on_rounded);

  const MatrixView(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// A square distance matrix: the distances from one chosen item to every
/// other, nearest first, or the whole matrix as a heatmap.
class DistanceMatrixPanel extends StatefulWidget {
  const DistanceMatrixPanel({
    super.key,
    required this.matrix,
    required this.itemLabel,
  });

  final DistanceMatrixData matrix;

  /// Name of one item, such as "Sample".
  final String itemLabel;

  @override
  State<DistanceMatrixPanel> createState() => _DistanceMatrixPanelState();
}

class _DistanceMatrixPanelState extends State<DistanceMatrixPanel> {
  MatrixView _mode = MatrixView.nearest;
  int _open = 0;

  @override
  void didUpdateWidget(covariant DistanceMatrixPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matrix != widget.matrix) _open = 0;
  }

  @override
  Widget build(BuildContext context) {
    final DistanceMatrixData matrix = widget.matrix;
    final List<String> names = matrix.names;
    if (names.length < 2) {
      return const ChartPlaceholder(message: 'Needs at least two items.');
    }
    final int open = _open.clamp(0, names.length - 1);
    final bool hasHeatmap = names.length <= maxHeatmapItems;
    final MatrixView mode = hasHeatmap ? _mode : MatrixView.nearest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: SeguiSpacing.md,
          runSpacing: SeguiSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (hasHeatmap)
              SegmentedButton<MatrixView>(
                showSelectedIcon: false,
                segments: [
                  for (final MatrixView view in MatrixView.values)
                    ButtonSegment(
                      value: view,
                      label: Text(view.label),
                      icon: Icon(view.icon),
                    ),
                ],
                selected: {mode},
                onSelectionChanged: (views) =>
                    setState(() => _mode = views.first),
              ),
            DropdownMenu<int>(
              key: ValueKey(open),
              initialSelection: open,
              width: SeguiContentWidth.searchBar,
              label: Text(widget.itemLabel),
              enableFilter: true,
              requestFocusOnTap: true,
              dropdownMenuEntries: [
                for (int i = 0; i < names.length; i++)
                  DropdownMenuEntry(value: i, label: names[i]),
              ],
              onSelected: (i) {
                if (i != null) setState(() => _open = i);
              },
            ),
          ],
        ),
        const SizedBox(height: SeguiSpacing.md),
        Expanded(
          child: switch (mode) {
            MatrixView.nearest => _NearestBars(
                matrix: matrix,
                open: open,
                onSelected: (i) => setState(() => _open = i),
              ),
            MatrixView.heatmap => _MatrixHeatmap(
                matrix: matrix,
                itemLabel: widget.itemLabel,
                open: open,
                onSelected: (i) => setState(() => _open = i),
              ),
          },
        ),
      ],
    );
  }
}

/// Distances from the open item to every other, nearest first.
class _NearestBars extends StatelessWidget {
  const _NearestBars({
    required this.matrix,
    required this.open,
    required this.onSelected,
  });

  final DistanceMatrixData matrix;
  final int open;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final List<int> view = [
      for (int i = 0; i < matrix.names.length; i++)
        if (i != open) i,
    ]..sort(
        (a, b) => matrixValue(matrix, open, a)
            .compareTo(matrixValue(matrix, open, b)),
      );
    return MetricBars(
      view: view,
      open: open,
      name: (i) => matrix.names[i],
      value: (i) => matrixValue(matrix, open, i),
      label: 'Distance to ${matrix.names[open]}',
      format: formatDistance,
      onSelected: onSelected,
    );
  }
}

/// Every pair of items, colored from the lowest to the highest distance.
class _MatrixHeatmap extends StatelessWidget {
  const _MatrixHeatmap({
    required this.matrix,
    required this.itemLabel,
    required this.open,
    required this.onSelected,
  });

  final DistanceMatrixData matrix;
  final String itemLabel;
  final int open;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final List<String> names = matrix.names;
    final (double, double)? range = matrixRange(matrix);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: PagedTable<int>(
            rows: [for (int i = 0; i < names.length; i++) i],
            selected: open,
            onTap: onSelected,
            columns: [
              PagedTableColumn(
                label: itemLabel,
                width: 220,
                sortValue: (i) => NaturalText(names[i]),
                resizable: true,
                cell: (i) => Text(names[i], overflow: TextOverflow.ellipsis),
              ),
              for (int j = 0; j < names.length; j++)
                PagedTableColumn(
                  label: names[j],
                  width: SeguiTableLayout.matrixColumn,
                  numeric: true,
                  sortValue: (i) => matrixValue(matrix, i, j),
                  cell: (i) {
                    final double value = matrixValue(matrix, i, j);
                    if (i == j || range == null || !value.isFinite) {
                      return Text(formatDistance(value));
                    }
                    final (double low, double high) = range;
                    return HeatmapCell(
                      fraction: high > low ? (value - low) / (high - low) : 0.5,
                      text: formatDistance(value),
                      selected: i == open,
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: SeguiSpacing.sm),
        const HeatmapLegend(
          text: 'Colors run from the lowest to the highest distance.',
        ),
      ],
    );
  }
}
