import 'package:material_ui/material_ui.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

/// Space around a report's tabs: tighter on phones, where width is short.
EdgeInsets reportPadding(BuildContext context) {
  return EdgeInsets.all(
    isPhoneScreen(context) ? SeguiSpacing.md : SeguiSpacing.xl,
  );
}

/// Space inside a report tab: tighter on phones.
EdgeInsets reportPanelPadding(BuildContext context) {
  return EdgeInsets.all(
    isPhoneScreen(context) ? SeguiSpacing.lg : SeguiSpacing.xl,
  );
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
    this.fill = false,
  });

  final String title;
  final Widget child;
  final String? description;

  /// Controls shown above the chart, such as sample toggles.
  final Widget? header;

  /// Whether [child] fills the rest of the tab and scrolls on its own,
  /// keeping the title and controls in place. Only for a tab's sole
  /// section. In a tab too small for that, the child gets an unbounded
  /// height and sizes itself.
  final bool fill;
}

/// Tab bar and panels of a report, inside a [DefaultTabController].
///
/// Tabs change only on tap, so sideways drags reach charts and tables.
class ReportTabView extends StatelessWidget {
  const ReportTabView({super.key, required this.tabs});

  final List<ReportTab> tabs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [for (final ReportTab tab in tabs) Tab(text: tab.label)],
        ),
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [for (final ReportTab tab in tabs) ReportPanel(tab: tab)],
          ),
        ),
      ],
    );
  }
}

class ReportPanel extends StatelessWidget {
  const ReportPanel({super.key, required this.tab});

  final ReportTab tab;

  @override
  Widget build(BuildContext context) {
    if (tab.sections case [final ReportSection section] when section.fill) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final bool isSticky =
              constraints.maxHeight >= SeguiTableLayout.stickyMinHeight &&
                  !isPhoneScreen(context);
          if (isSticky) {
            return Padding(
              padding: reportPanelPadding(context),
              child: ReportSectionView(section: section, isSticky: true),
            );
          }
          // Too small to keep the controls in place, so the whole tab
          // scrolls and the section sizes its own list.
          return ListView(
            padding: reportPanelPadding(context),
            children: [ReportSectionView(section: section)],
          );
        },
      );
    }
    return ListView(
      padding: reportPanelPadding(context),
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
  const ReportSectionView({
    super.key,
    required this.section,
    this.isSticky = false,
  });

  final ReportSection section;

  /// Whether the section fills its tab, so its child takes the space left.
  final bool isSticky;

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
        if (isSticky) Expanded(child: section.child) else section.child,
      ],
    );
  }
}

/// Scrolls [child] sideways when the space is narrower than [minWidth], so
/// charts keep their ticks, labels, and bars apart on small screens.
class MinWidthScroll extends StatefulWidget {
  const MinWidthScroll({
    super.key,
    required this.minWidth,
    required this.child,
  });

  final double minWidth;
  final Widget child;

  @override
  State<MinWidthScroll> createState() => _MinWidthScrollState();
}

class _MinWidthScrollState extends State<MinWidthScroll> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth ||
            constraints.maxWidth >= widget.minWidth) {
          return widget.child;
        }
        // A visible thumb keeps the chart scrollable where its zoom takes
        // the drag. Without the screen insets, the thumb sits in the gutter
        // below the chart instead of over it.
        return MediaQuery.removePadding(
          context: context,
          removeLeft: true,
          removeTop: true,
          removeRight: true,
          removeBottom: true,
          child: Scrollbar(
            controller: _controller,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(
                bottom: SeguiControlSize.scrollbarGutter,
              ),
              child: SizedBox(width: widget.minWidth, child: widget.child),
            ),
          ),
        );
      },
    );
  }
}
