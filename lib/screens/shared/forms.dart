import 'package:file_selector/file_selector.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/screens/genomics/read_summary.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/styles/design_tokens.dart';

/// Tells the enclosing tool form that the user changed a field.
///
/// Fields that are not [FormField]s dispatch this from their change handler.
/// [FormField]s, such as dropdowns, are tracked by the enclosing [Form].
class FormEditedNotification extends Notification {
  const FormEditedNotification();
}

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
          helper: widget.ctr.inputFormatController == 'Auto'
              ? 'Detects the format from each file extension.'
              : null,
          onChanged: (String? value) {
            setState(() {
              widget.ctr.inputFormatController = value;
            });
          },
        ),
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
      padding: const EdgeInsets.fromLTRB(
        SeguiSpacing.xs,
        SeguiFormLayout.sectionTitleTop,
        0,
        SeguiFormLayout.sectionTitleBottom,
      ),
      child: Row(
        children: [
          if (step != null) ...[
            StepBadge(step: step!),
            const SizedBox(width: SeguiSpacing.lg),
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
      width: SeguiControlSize.badge,
      height: SeguiControlSize.badge,
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
///
/// Spaces its [children] [SeguiFormLayout.fieldGap] apart, so fields carry
/// no vertical padding of their own. Leave hidden fields out of [children]
/// with collection `if` rather than [Visibility], which would still take a
/// gap.
class FormCard extends StatelessWidget {
  const FormCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(SeguiFormLayout.fieldRadius),
      borderSide: BorderSide(color: colors.outlineVariant),
    );
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(
              color: colors.primary,
              width: SeguiStroke.regular,
            ),
          ),
          filled: true,
          fillColor: colors.surfaceContainerLowest,
          helperMaxLines: 3,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(SeguiFormLayout.cardPadding),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SeguiFormLayout.cardRadius),
          color: colors.surfaceContainerLowest,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          spacing: SeguiFormLayout.fieldGap,
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
      padding: const EdgeInsets.fromLTRB(
        SeguiSpacing.xl,
        SeguiSpacing.md,
        SeguiSpacing.xl,
        SeguiSpacing.xl,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SeguiRadius.lg),
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
    this.helper,
    this.keyboardType,
    this.onChanged,
  });

  final String label;

  /// Example value shown inside the empty field.
  final String hint;

  /// Explanation shown below the field at all times.
  final String? helper;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (String value) {
        const FormEditedNotification().dispatch(context);
        onChanged?.call(value);
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        suffix: controller.text.isNotEmpty
            ? IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  const FormEditedNotification().dispatch(context);
                },
              )
            : null,
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
    this.helper,
    this.enabled = true,
  });

  static const int maxSegments = 4;
  static const int maxSegmentLabelLength = 10;

  final String? value;
  final String label;
  final List<String> items;
  final void Function(String?) onChanged;

  /// Explanation shown below the field.
  final String? helper;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return _isSegmented
        ? SegmentedField(
            value: value,
            label: label,
            items: items,
            helper: helper,
            onChanged: enabled ? onChanged : null,
          )
        : DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: value,
            decoration: InputDecoration(
              labelText: label,
              helperText: helper,
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
    this.helper,
  });

  final String? value;
  final String label;
  final Map<String, String> items;
  final void Function(String?) onChanged;

  /// Explanation shown below the field.
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
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
    this.helper,
  });

  final String? value;
  final String label;
  final List<String> items;
  final void Function(String?)? onChanged;

  /// Explanation shown below the buttons.
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return FieldWithHelper(
      helper: helper,
      child: _buildField(context),
    );
  }

  Widget _buildField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: SeguiSpacing.md),
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
                      const FormEditedNotification().dispatch(context);
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
    this.helper,
  });

  final String label;
  final bool value;
  final void Function(bool) onPressed;

  /// Explanation shown below the label.
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SeguiFormLayout.helperGap,
            children: [
              Text(label),
              if (helper != null) FieldHelperText(text: helper!),
            ],
          ),
        ),
        const SizedBox(width: SeguiSpacing.lg),
        Switch(
          value: value,
          onChanged: (bool value) {
            const FormEditedNotification().dispatch(context);
            onPressed(value);
          },
        ),
      ],
    );
  }
}

/// Shows [helper] directly below [child], the field it explains.
///
/// For fields without a built-in helper, such as file pickers. Text fields
/// and dropdowns take a `helper` of their own.
class FieldWithHelper extends StatelessWidget {
  const FieldWithHelper({
    super.key,
    required this.helper,
    required this.child,
  });

  final String? helper;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (helper == null) {
      return child;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SeguiFormLayout.helperGap,
      children: [
        child,
        FieldHelperText(text: helper!),
      ],
    );
  }
}

/// Supporting text for a form field, styled like [InputDecoration]'s
/// helper text.
class FieldHelperText extends StatelessWidget {
  const FieldHelperText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
