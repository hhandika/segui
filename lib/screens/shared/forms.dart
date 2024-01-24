// ignore: unused_import
import 'dart:ffi';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/screens/genomics/read_summary.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/io.dart';
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
  });

  final IOController ctr;
  final bool allowMultiple;
  final XTypeGroup xTypeGroup;
  final bool isDatatypeEnabled;
  final bool hasSecondaryPicker;
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

class CardTitle extends StatelessWidget {
  const CardTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class FormCard extends StatelessWidget {
  const FormCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: children,
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
    this.onSubmitted,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
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
      onSubmitted: (value) {
        controller.text = value;
        if (onSubmitted != null) {
          onSubmitted!();
        }
      },
    );
  }
}

class SharedDropdownField extends StatelessWidget {
  const SharedDropdownField({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  final String? value;
  final String label;
  final List<String> items;
  final void Function(String?) onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      isExpanded: true,
      value: value,
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
    );
  }
}

SnackBar showSharedSnackBar(BuildContext context, String text) {
  return SnackBar(
    content: Text(text),
    duration: const Duration(seconds: 10),
    showCloseIcon: true,
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
        Text(label),
        Switch(
          value: value,
          onChanged: onPressed,
        ),
      ],
    );
  }
}
