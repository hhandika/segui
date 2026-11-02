import 'dart:math';

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/styles/design_tokens.dart';

final NumberFormat _countFormat = NumberFormat('#,##0');

/// A column of a [PagedTable].
class PagedTableColumn<T> {
  const PagedTableColumn({
    required this.label,
    required this.width,
    required this.cell,
    this.numeric = false,
    this.sortValue,
    this.resizable = false,
  });

  final String label;

  /// Starting width. A [resizable] column can be dragged wider or narrower.
  final double width;
  final Widget Function(T row) cell;

  /// Whether cells align to the end, like numbers.
  final bool numeric;

  /// Value the column sorts by. Columns without one do not sort. Wrap
  /// names in `NaturalText` so `locus_2` sorts before `locus_10`.
  final Comparable Function(T row)? sortValue;

  /// Whether a handle at the column's right edge resizes it, such as for
  /// long sample or locus names. A double tap on the handle resets it.
  final bool resizable;
}

/// A table that shows one page of rows at a time, so large reports stay
/// fast. Light lines separate the columns. The column header and the pager stay in place while the rows
/// scroll. The page follows the [selected] row when it changes. In a
/// scrolling parent, the table takes a fixed height.
class PagedTable<T> extends StatefulWidget {
  const PagedTable({
    super.key,
    required this.rows,
    required this.columns,
    this.selected,
    this.onTap,
  });

  final List<T> rows;
  final List<PagedTableColumn<T>> columns;
  final T? selected;
  final ValueChanged<T>? onTap;

  @override
  State<PagedTable<T>> createState() => _PagedTableState<T>();
}

class _PagedTableState<T> extends State<PagedTable<T>> {
  final ScrollController _vertical = ScrollController();
  final ScrollController _horizontal = ScrollController();
  int? _sortColumn;
  bool _ascending = true;
  int _page = 0;
  int _pageSize = SeguiTableLayout.pageSizes.first;
  late List<T> _order;

  /// Widths set by dragging, by column position.
  final Map<int, double> _widths = {};

  @override
  void initState() {
    super.initState();
    _sort();
    _showSelected();
  }

  @override
  void didUpdateWidget(covariant PagedTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sort();
    _page = _page.clamp(0, _pageCount - 1);
    if (oldWidget.selected != widget.selected) {
      _showSelected();
    }
  }

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  int get _pageCount => max(1, (_order.length / _pageSize).ceil());

  @override
  Widget build(BuildContext context) {
    final int start = _page * _pageSize;
    final int end = (start + _pageSize).clamp(0, _order.length);
    final double tableWidth = [
      for (int i = 0; i < widget.columns.length; i++) _widthOf(i),
    ].fold(0, (a, b) => a + b);
    final bool hasPager = _order.length > SeguiTableLayout.pageSizes.first;
    final Widget table = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: MediaQuery(
            // Starts the row scrollbar below the column header.
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(
                top: SeguiTableLayout.heading + SeguiStroke.thin,
              ),
            ),
            // Outside the sideways scroll, so the row scrollbar stays at
            // the panel's edge however wide the table is.
            child: Scrollbar(
              controller: _vertical,
              notificationPredicate: (notification) => notification.depth == 1,
              child: Padding(
                // A lane for the row scrollbar beside the last column.
                padding: const EdgeInsets.only(
                  right: SeguiControlSize.scrollbarGutter,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double width = tableWidth > constraints.maxWidth
                        ? tableWidth
                        : constraints.maxWidth;
                    return Scrollbar(
                      controller: _horizontal,
                      // The rows get no scrollbar of their own on desktop,
                      // which would sit at the table's far edge.
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context)
                            .copyWith(scrollbars: false),
                        child: SingleChildScrollView(
                          controller: _horizontal,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: width,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _header(context),
                                const Divider(height: SeguiStroke.thin),
                                Expanded(
                                  child: ListView.builder(
                                    controller: _vertical,
                                    // Keeps the sideways scrollbar off the
                                    // last row.
                                    padding: const EdgeInsets.only(
                                      bottom: SeguiControlSize.scrollbarGutter,
                                    ),
                                    itemExtent: SeguiTableLayout.row,
                                    itemCount: end - start,
                                    itemBuilder: (context, i) =>
                                        _row(context, _order[start + i]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (hasPager) ...[
          const Divider(height: SeguiStroke.thin),
          _pager(context, start, end),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.hasBoundedHeight
          ? table
          : SizedBox(height: SeguiTableLayout.scrollingHeight, child: table),
    );
  }

  Widget _header(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      height: SeguiTableLayout.heading,
      child: Row(
        children: [
          for (final (int i, PagedTableColumn<T> column)
              in widget.columns.indexed)
            _HeaderCell(
              label: column.label,
              divider: _hasDivider(i),
              width: _widthOf(i),
              numeric: column.numeric,
              style: theme.textTheme.titleSmall,
              sortedAscending: _sortColumn == i ? _ascending : null,
              onSort: column.sortValue == null ? null : () => _sortBy(i),
              onResize: column.resizable
                  ? (delta) => setState(() {
                        _widths[i] = (_widthOf(i) + delta).clamp(
                          SeguiTableLayout.minColumn,
                          SeguiTableLayout.maxResizedColumn,
                        );
                      })
                  : null,
              onResetWidth: column.resizable
                  ? () => setState(() => _widths.remove(i))
                  : null,
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, T row) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isSelected = widget.selected != null && row == widget.selected;
    return Semantics(
      selected: isSelected,
      button: widget.onTap != null,
      child: Material(
        color: isSelected
            ? colors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        child: InkWell(
          onTap: widget.onTap == null ? null : () => widget.onTap!(row),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.outlineVariant, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                for (final (int i, PagedTableColumn<T> column)
                    in widget.columns.indexed)
                  Container(
                    width: _widthOf(i),
                    padding: const EdgeInsets.symmetric(
                      horizontal: SeguiTableLayout.cellPadding,
                    ),
                    decoration: _hasDivider(i)
                        ? BoxDecoration(border: _columnDivider(colors))
                        : null,
                    alignment: column.numeric
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: column.cell(row),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pager(BuildContext context, int start, int end) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall;
    final bool hasPrevious = _page > 0;
    final bool hasNext = _page < _pageCount - 1;
    return Padding(
      padding: const EdgeInsets.only(top: SeguiSpacing.xs),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: SeguiSpacing.md,
        children: [
          Text('Rows per page', style: style),
          DropdownButton<int>(
            value: _pageSize,
            isDense: true,
            underline: const SizedBox.shrink(),
            style: style,
            items: [
              for (final int size in SeguiTableLayout.pageSizes)
                DropdownMenuItem(value: size, child: Text('$size')),
            ],
            onChanged: (size) {
              if (size == null) return;
              setState(() {
                _pageSize = size;
                _page = 0;
                _showSelected();
              });
              _scrollToTop();
            },
          ),
          Text(
            '${_countFormat.format(start + 1)}–${_countFormat.format(end)} '
            'of ${_countFormat.format(_order.length)}',
            style: style,
          ),
          IconButton(
            tooltip: 'First page',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.first_page_rounded),
            onPressed: hasPrevious ? () => _goTo(0) : null,
          ),
          IconButton(
            tooltip: 'Previous page',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: hasPrevious ? () => _goTo(_page - 1) : null,
          ),
          IconButton(
            tooltip: 'Next page',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: hasNext ? () => _goTo(_page + 1) : null,
          ),
          IconButton(
            tooltip: 'Last page',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.last_page_rounded),
            onPressed: hasNext ? () => _goTo(_pageCount - 1) : null,
          ),
        ],
      ),
    );
  }

  // A new order starts at its first page, even when the selected row
  // moves to another.
  bool _hasDivider(int column) => column < widget.columns.length - 1;

  double _widthOf(int column) =>
      _widths[column] ?? widget.columns[column].width;

  void _sortBy(int column) {
    setState(() {
      _ascending = _sortColumn == column ? !_ascending : true;
      _sortColumn = column;
      _sort();
      _page = 0;
    });
    _scrollToTop();
  }

  void _sort() {
    _order = List<T>.of(widget.rows);
    final Comparable Function(T row)? value =
        _sortColumn == null ? null : widget.columns[_sortColumn!].sortValue;
    if (value == null) return;
    _order.sort((a, b) {
      final int result = value(a).compareTo(value(b));
      return _ascending ? result : -result;
    });
  }

  void _goTo(int page) {
    setState(() => _page = page);
    _scrollToTop();
  }

  /// Turns to the page of the selected row and scrolls it into view after
  /// the next frame. Callers rebuild the table.
  void _showSelected() {
    if (widget.selected == null) return;
    final int position = _order.indexOf(widget.selected as T);
    if (position < 0) return;
    _page = position ~/ _pageSize;
    final double offset = (position % _pageSize) * SeguiTableLayout.row;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_vertical.hasClients) return;
      final ScrollPosition scroll = _vertical.position;
      if (offset < scroll.pixels ||
          offset + SeguiTableLayout.row >
              scroll.pixels + scroll.viewportDimension) {
        _vertical.jumpTo(offset.clamp(0, scroll.maxScrollExtent));
      }
    });
  }

  void _scrollToTop() {
    if (_vertical.hasClients) _vertical.jumpTo(0);
  }
}

/// The light line at the right edge of every column but the last.
Border _columnDivider(ColorScheme colors) => Border(
      right: BorderSide(
        color: colors.outlineVariant,
        width: SeguiTableLayout.columnDivider,
      ),
    );

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.divider,
    required this.width,
    required this.numeric,
    required this.style,
    required this.sortedAscending,
    required this.onSort,
    required this.onResize,
    required this.onResetWidth,
  });

  final String label;
  final double width;
  final bool numeric;
  final TextStyle? style;

  /// Whether a line separates this column from the next.
  final bool divider;

  /// Sort direction when the table sorts by this column, otherwise null.
  final bool? sortedAscending;
  final VoidCallback? onSort;

  /// Called with the drag distance on the resize handle. Columns without
  /// it have no handle.
  final ValueChanged<double>? onResize;
  final VoidCallback? onResetWidth;

  @override
  Widget build(BuildContext context) {
    final Widget arrow = Icon(
      sortedAscending == false
          ? Icons.arrow_downward_rounded
          : Icons.arrow_upward_rounded,
      size: SeguiControlSize.iconSmall,
      color: sortedAscending == null ? Colors.transparent : null,
    );
    final Widget text = Flexible(
      child: Text(label, style: style, overflow: TextOverflow.ellipsis),
    );
    final Widget cell = InkWell(
      onTap: onSort,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SeguiTableLayout.cellPadding,
        ),
        child: Row(
          mainAxisAlignment:
              numeric ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (numeric && onSort != null) arrow,
            text,
            if (!numeric && onSort != null) arrow,
          ],
        ),
      ),
    );
    final ValueChanged<double>? resize = onResize;
    return Container(
      width: width,
      decoration: divider
          ? BoxDecoration(
              border: _columnDivider(Theme.of(context).colorScheme),
            )
          : null,
      child: resize == null
          ? cell
          : Stack(
              children: [
                Positioned.fill(child: cell),
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: SeguiTableLayout.resizeHandle,
                  child: _ResizeHandle(
                    label: label,
                    onResize: resize,
                    onReset: onResetWidth,
                  ),
                ),
              ],
            ),
    );
  }
}

/// A grab area at a column's right edge, beside the column line. Dragging
/// it resizes the column, and a double tap resets the width.
class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.label,
    required this.onResize,
    required this.onReset,
  });

  final String label;
  final ValueChanged<double> onResize;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Resize $label column',
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) => onResize(details.delta.dx),
          onDoubleTap: onReset,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
