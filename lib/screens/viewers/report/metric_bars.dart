import 'package:material_ui/material_ui.dart';
import 'package:segui/styles/design_tokens.dart';

/// One horizontal bar per item for a metric, scaled to the largest value.
/// The open item is highlighted and kept in view, and a tap opens another.
/// Bars build only while visible, so long lists stay fast.
class MetricBars extends StatefulWidget {
  const MetricBars({
    super.key,
    required this.view,
    required this.open,
    required this.name,
    required this.value,
    required this.label,
    required this.format,
    required this.onSelected,
    this.exact,
    this.leading,
  });

  /// Items in list order.
  final List<int> view;

  /// The open item.
  final int open;
  final String Function(int item) name;
  final double Function(int item) value;

  /// Name of the metric, for tooltips and screen readers.
  final String label;

  /// The value beside a bar.
  final String Function(double value) format;
  final ValueChanged<int> onSelected;

  /// The value in a bar's tooltip. [format] by default.
  final String Function(double value)? exact;

  /// A marker before an item's name, such as its status.
  final Widget Function(int item)? leading;

  @override
  State<MetricBars> createState() => _MetricBarsState();
}

class _MetricBarsState extends State<MetricBars> {
  static const double _rowExtent =
      SeguiChartLayout.barRow + 2 * SeguiSpacing.xxs;

  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(covariant MetricBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open != widget.open) {
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
    final double largest =
        view.map(widget.value).fold(0, (a, b) => a > b ? a : b);
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
          final int item = view[position];
          final double value = widget.value(item);
          return MetricBar(
            name: widget.name(item),
            value: value,
            largest: largest,
            label: widget.label,
            text: widget.format(value),
            exact: (widget.exact ?? widget.format)(value),
            leading: widget.leading?.call(item),
            isOpen: item == widget.open,
            onTap: () => widget.onSelected(item),
          );
        },
      ),
    );
  }

  /// Scrolls the open item into view.
  void _showOpen() {
    final int position = widget.view.indexOf(widget.open);
    if (position < 0 || !_controller.hasClients) return;
    final ScrollPosition scroll = _controller.position;
    final double offset = position * _rowExtent;
    if (offset < scroll.pixels ||
        offset + _rowExtent > scroll.pixels + scroll.viewportDimension) {
      _controller.jumpTo(offset.clamp(0, scroll.maxScrollExtent));
    }
  }
}

class MetricBar extends StatelessWidget {
  const MetricBar({
    super.key,
    required this.name,
    required this.value,
    required this.largest,
    required this.label,
    required this.text,
    required this.exact,
    required this.isOpen,
    required this.onTap,
    this.leading,
  });

  final String name;
  final double value;
  final double largest;

  /// Name of the metric.
  final String label;

  /// The value beside the bar and in its tooltip.
  final String text;
  final String exact;
  final bool isOpen;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextStyle? nameStyle = theme.textTheme.bodySmall?.copyWith(
      color: isOpen ? colors.primary : null,
      fontWeight: isOpen ? FontWeight.w600 : null,
    );
    return Semantics(
      selected: isOpen,
      button: true,
      label: '$name, $label $text',
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
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: SeguiSpacing.sm),
                ],
                SizedBox(
                  width: SeguiChartLayout.barLabel,
                  child: Text(
                    name,
                    style: nameStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: SeguiSpacing.md),
                Expanded(
                  child: Tooltip(
                    message: '$label: $exact',
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
                    text,
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
}
