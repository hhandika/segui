// ignore: unused_import
import 'dart:isolate';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/types.dart';

class SharedSequenceInputForm extends ConsumerStatefulWidget {
  const SharedSequenceInputForm({
    super.key,
    required this.ctr,
    required this.xTypeGroup,
    this.allowMultiple = true,
    this.isDatatypeEnabled = true,
    this.hasSecondaryPicker = false,
  });

  final IOController ctr;
  final bool allowMultiple;
  final XTypeGroup xTypeGroup;
  final bool isDatatypeEnabled;
  final bool hasSecondaryPicker;

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

class SharedInfoForm extends StatelessWidget {
  const SharedInfoForm({
    super.key,
    required this.description,
    required this.onClosed,
    required this.onExpanded,
    required this.isShowingInfo,
  });

  final VoidCallback onExpanded;
  final VoidCallback onClosed;
  final String? description;
  final bool isShowingInfo;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Visibility(
              visible: isShowingInfo,
              child: CommonCard(
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const Icon(Icons.info_outline_rounded),
                    const SizedBox(height: 4),
                    Text(
                      description ?? '',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 2),
            Center(
              child: IconButton(
                tooltip: isShowingInfo ? 'Hide info' : 'Show info',
                icon: Icon(
                  isShowingInfo
                      ? Icons.expand_less_outlined
                      : Icons.expand_more_outlined,
                ),
                onPressed: () {
                  if (isShowingInfo) {
                    onClosed();
                  } else {
                    onExpanded();
                  }
                },
              ),
            )
          ],
        ));
  }
}

class FormView extends StatelessWidget {
  const FormView({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppPageView(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}

class AppPageView extends StatelessWidget {
  const AppPageView({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final windowWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
        ),
        constraints: BoxConstraints(maxWidth: windowWidth > 1500 ? 500 : 500),
        padding: const EdgeInsets.all(16),
        child: child,
      ),
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
  });

  final String label;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffix: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                },
              )
            : null,
      ),
      onSubmitted: (value) {
        controller.text = value;
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
