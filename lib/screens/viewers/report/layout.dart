import 'package:material_ui/material_ui.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

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
              padding: const EdgeInsets.all(SeguiSpacing.xl),
              child: ReportSectionView(section: section, isSticky: true),
            );
          }
          // Too small to keep the controls in place, so the whole tab
          // scrolls and the section sizes its own list.
          return ListView(
            padding: const EdgeInsets.all(SeguiSpacing.xl),
            children: [ReportSectionView(section: section)],
          );
        },
      );
    }
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
