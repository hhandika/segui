import 'package:material_ui/material_ui.dart';
import 'package:segui/styles/design_tokens.dart';

/// Marks a selected list row with a bar along its left edge, leaving the
/// row's background and text colors unchanged.
class SelectedRowMark extends StatelessWidget {
  const SelectedRowMark({
    super.key,
    required this.isSelected,
    required this.child,
  });

  final bool isSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      child: Stack(
        children: [
          child,
          if (isSelected)
            Positioned(
              left: 0,
              top: SeguiSpacing.sm,
              bottom: SeguiSpacing.sm,
              width: SeguiStroke.thick,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(SeguiRadius.full),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
