// ignore: unused_import
import 'dart:ffi';

import 'package:file_selector/file_selector.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/screens/genomics/read_summary.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/types.dart';

class SharedSequenceInputForm extends ConsumerStatefulWidget {
  const SharedSequenceInputForm({
    super.key,
    required this.ctr,
    required this.xTypeGroup,
    required this.task,
    this.allowMultiple = true,
    this.isDatatypeEnabled = true,
    this.hasSecondaryPicker = false,
    this.allowDirectorySelection = true,
  });

  final IOController ctr;
  final bool allowMultiple;
  final XTypeGroup xTypeGroup;
  final bool isDatatypeEnabled;
  final bool hasSecondaryPicker;
  final bool allowDirectorySelection;
  final SupportedTask task;

  @override
  SharedSequenceInputFormState createState() => SharedSequenceInputFormState();
}

class SharedSequenceInputFormState
    extends ConsumerState<SharedSequenceInputForm> {
  @override
  Widget build(BuildContext context) {
    return FormCard(
      children: [
        InputSelectorForm(
          ctr: widget.ctr,
          allowMultiple: widget.allowMultiple,
          xTypeGroup: widget.xTypeGroup,
          hasSecondaryPicker: widget.isDatatypeEnabled,
          allowDirectorySelection: widget.allowDirectorySelection,
          task: task,
        ),
        SharedDropdownField(
          value: widget.ctr.inputFormatController,
          label: 'Format',
          items: inputFormat,
          onChanged: (String? value) {
            setState(() {
              widget.ctr.inputFormatController = value;
            });
          },
        ),
        Visibility(
            visible: widget.ctr.inputFormatController == 'Auto',
            child: Text('Auto-detect format based on file extension.',
                style: Theme.of(context).textTheme.labelSmall)),
        SharedDropdownField(
          value: widget.ctr.dataTypeController,
          label: 'Data Type',
          items: dataType,
          enabled: widget.isDatatypeEnabled,
          onChanged: (String? value) {
            setState(() {
              if (value != null) {
                widget.ctr.dataTypeController = value;
              }
            });
          },
        ),
      ],
    );
  }
}

/// Section title in a tool form, numbered when [step] is set.
class CardTitle extends StatelessWidget {
  const CardTitle({super.key, required this.title, this.step});

  final String title;
  final int? step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 0, 10),
      child: Row(
        children: [
          if (step != null) ...[
            StepBadge(step: step!),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class StepBadge extends StatelessWidget {
  const StepBadge({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$step',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// Card that groups the fields of one tool form section.
class FormCard extends StatelessWidget {
  const FormCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.outlineVariant),
    );
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: colors.primary, width: 2),
          ),
          filled: true,
          fillColor: colors.surfaceContainerLowest,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: colors.surfaceContainerLowest,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: children,
        ),
      ),
    );
  }
}

class CommonCard extends StatelessWidget {
  const CommonCard({
    super.key,
    required this.child,
    required this.backgroundColor,
  });
  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color.lerp(
            backgroundColor, Theme.of(context).colorScheme.surface, 0.9),
      ),
      child: child,
    );
  }
}

class SharedTextField extends StatelessWidget {
  const SharedTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
  });

  final String label;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffix: controller.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                  },
                )
              : null,
        ),
      ),
    );
  }
}

/// Picks one of [items], as segmented buttons when the options are few and
/// short, or as a dropdown otherwise.
class SharedDropdownField extends StatelessWidget {
  const SharedDropdownField({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  static const int maxSegments = 4;
  static const int maxSegmentLabelLength = 10;

  final String? value;
  final String label;
  final List<String> items;
  final void Function(String?) onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _isSegmented
          ? SegmentedField(
              value: value,
              label: label,
              items: items,
              onChanged: enabled ? onChanged : null,
            )
          : DropdownButtonFormField<String?>(
              isExpanded: true,
              initialValue: value,
              decoration: InputDecoration(
                labelText: label,
              ),
              items: items
                  .map((item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          overflow: TextOverflow.clip,
                        ),
                      ))
                  .toList(),
              onChanged: enabled ? onChanged : null,
            ),
    );
  }

  bool get _isSegmented {
    return items.length <= maxSegments &&
        items.every((item) => item.length <= maxSegmentLabelLength);
  }
}

/// Dropdown whose [items] map each option value to its display label.
class SharedMapDropdownField extends StatelessWidget {
  const SharedMapDropdownField({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final String label;
  final Map<String, String> items;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
        ),
        items: items.entries
            .map((entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    overflow: TextOverflow.clip,
                  ),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class SegmentedField extends StatelessWidget {
  const SegmentedField({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final String label;
  final List<String> items;
  final void Function(String?)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            emptySelectionAllowed: value == null,
            segments: items
                .map((item) => ButtonSegment<String>(
                      value: item,
                      label: Text(item, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            selected: {if (value != null) value!},
            onSelectionChanged: onChanged == null
                ? null
                : (selection) {
                    if (selection.isNotEmpty) {
                      onChanged!(selection.first);
                    }
                  },
          ),
        ),
      ],
    );
  }
}

SnackBar showSharedSnackBar(BuildContext context, String text) {
  return SnackBar(
    content: Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
    ),
    duration: const Duration(seconds: 10),
    showCloseIcon: true,
    closeIconColor: Theme.of(context).colorScheme.onTertiaryContainer,
    backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
  );
}

class SwitchForm extends StatelessWidget {
  const SwitchForm({
    super.key,
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final bool value;
  final void Function(bool) onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Switch(
          value: value,
          onChanged: onPressed,
        ),
      ],
    );
  }
}
