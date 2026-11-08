import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/styles/design_tokens.dart';

/// One option of a [ChoiceSheetButton].
typedef SheetChoice<T> = ({T value, String label});

/// A button that shows its current choice and opens [showChoiceSheet] to
/// change it. For phones, in place of a dropdown menu.
class ChoiceSheetButton<T> extends StatelessWidget {
  const ChoiceSheetButton({
    super.key,
    required this.title,
    required this.value,
    required this.choices,
    required this.onSelected,
    this.label,
    this.isSearchable = false,
    this.isDense = false,
  });

  /// Title of the sheet.
  final String title;
  final T value;
  final List<SheetChoice<T>> choices;
  final ValueChanged<T> onSelected;

  /// Text before the choice on the button, such as "Sample".
  final String? label;

  /// Whether the sheet has a filter, for long lists.
  final bool isSearchable;

  /// A text button for tight spots, such as a table pager.
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    final String current = [
          for (final SheetChoice<T> c in choices)
            if (c.value == value) c.label,
        ].firstOrNull ??
        '';
    final Widget text = Text(
      label == null ? current : '$label: $current',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    const Widget arrow = Icon(Icons.arrow_drop_down_rounded);
    if (isDense) {
      return TextButton.icon(
        onPressed: () => _open(context),
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
        icon: arrow,
        iconAlignment: IconAlignment.end,
        label: text,
      );
    }
    return OutlinedButton.icon(
      onPressed: () => _open(context),
      icon: arrow,
      iconAlignment: IconAlignment.end,
      label: text,
    );
  }

  Future<void> _open(BuildContext context) async {
    final T? picked = await showChoiceSheet<T>(
      context: context,
      title: title,
      choices: choices,
      selected: value,
      isSearchable: isSearchable,
    );
    if (picked != null && picked != value) onSelected(picked);
  }
}

/// Shows [choices] in a bottom sheet and returns the one picked, or null
/// when the sheet closes without a pick.
Future<T?> showChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required List<SheetChoice<T>> choices,
  required T selected,
  bool isSearchable = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => ChoiceSheet<T>(
      title: title,
      choices: choices,
      selected: selected,
      isSearchable: isSearchable,
    ),
  );
}

/// Title and options of [showChoiceSheet]. Picking an option closes the
/// sheet with it.
class ChoiceSheet<T> extends StatefulWidget {
  const ChoiceSheet({
    super.key,
    required this.title,
    required this.choices,
    required this.selected,
    this.isSearchable = false,
  });

  final String title;
  final List<SheetChoice<T>> choices;
  final T selected;
  final bool isSearchable;

  @override
  State<ChoiceSheet<T>> createState() => _ChoiceSheetState<T>();
}

class _ChoiceSheetState<T> extends State<ChoiceSheet<T>> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String query = _query.text.trim().toLowerCase();
    final List<SheetChoice<T>> shown = [
      for (final SheetChoice<T> c in widget.choices)
        if (query.isEmpty || c.label.toLowerCase().contains(query)) c,
    ];
    final Widget list = shown.isEmpty
        ? const ListTile(title: Text('No matches.'))
        : ListView.builder(
            shrinkWrap: !widget.isSearchable,
            itemCount: shown.length,
            itemBuilder: (context, i) {
              final SheetChoice<T> choice = shown[i];
              final bool isSelected = choice.value == widget.selected;
              return ListTile(
                title: Text(choice.label),
                selected: isSelected,
                trailing: isSelected ? const Icon(Icons.check_rounded) : null,
                onTap: () => Navigator.of(context).pop(choice.value),
              );
            },
          );
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          // Lines up with the list tiles below.
          padding: const EdgeInsets.symmetric(horizontal: SeguiSpacing.xl),
          child: Text(widget.title, style: theme.textTheme.titleMedium),
        ),
        if (widget.isSearchable)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SeguiSpacing.xl,
              SeguiSpacing.lg,
              SeguiSpacing.xl,
              0,
            ),
            child: TextField(
              controller: _query,
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Filter',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        const SizedBox(height: SeguiSpacing.md),
        if (widget.isSearchable)
          Expanded(child: list)
        else
          Flexible(child: list),
        const SizedBox(height: SeguiSpacing.md),
      ],
    );
    // Long lists get a tall sheet so the filter stays above the keyboard.
    if (widget.isSearchable) {
      return FractionallySizedBox(
        heightFactor: SeguiSheetLayout.listHeight,
        child: content,
      );
    }
    return SafeArea(child: content);
  }
}

/// A plain icon button that opens a viewer's view settings, like the
/// other header buttons.
class ReportSettingsButton extends StatelessWidget {
  const ReportSettingsButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'View settings',
      onPressed: onPressed,
      icon: const Icon(Icons.tune_rounded),
    );
  }
}

/// Shows view settings in a bottom sheet on phones, or a dialog on larger
/// screens. [builder] runs again after each [refresh], so the sheet shows
/// changes the owner makes to its own state.
Future<void> showReportSettings({
  required BuildContext context,
  required Widget Function(BuildContext context, VoidCallback refresh) builder,
  String title = 'View settings',
}) {
  return showResponsiveSheet<void>(
    context: context,
    builder: (context) => SheetContent(
      title: title,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
      child: StatefulBuilder(
        builder: (context, setSheetState) =>
            builder(context, () => setSheetState(() {})),
      ),
    ),
  );
}
