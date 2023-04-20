import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/types.dart';
import 'package:segui/services/io.dart';

class SharedInputForms extends StatefulWidget {
  const SharedInputForms({super.key, required this.ctr});

  final IOController ctr;

  @override
  State<SharedInputForms> createState() => _SharedInputFormsState();
}

class _SharedInputFormsState extends State<SharedInputForms> {
  @override
  Widget build(BuildContext context) {
    return FormCard(
      children: [
        runningPlatform == PlatformType.isDesktop
            ? SelectDirField(
                label: 'Select input directory',
                dirPath: widget.ctr.dirPath,
                onPressed: (value) {
                  setState(() {
                    widget.ctr.dirPath = value;
                  });
                })
            : const SizedBox.shrink(),
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
        SharedDropdownField(
          value: widget.ctr.dataTypeController,
          label: 'Data Type',
          items: dataType,
          onChanged: (String? value) {
            setState(() {
              if (value != null) {
                widget.ctr.dataTypeController = value;
              }
            });
          },
        ),
        runningPlatform == PlatformType.isMobile
            ? SharedFilePicker(
                label: 'Select Files',
                onPressed: (value) {
                  setState(() {
                    widget.ctr.files = value;
                  });
                },
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}

class FormView extends StatelessWidget {
  const FormView({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 25, 10, 15),
          child: ListView(
            shrinkWrap: false,
            children: children,
          ),
        ),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Color.lerp(Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.surface, 0.95),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
        child: Column(
          children: children,
        ),
      ),
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
      ),
      onChanged: (value) {},
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
  });

  final String? value;
  final String label;
  final List<String> items;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
      ),
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class SelectDirField extends StatelessWidget {
  const SelectDirField({
    super.key,
    required this.label,
    required this.dirPath,
    required this.onPressed,
  });

  final String label;
  final String? dirPath;
  final void Function(String?) onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label: ${dirPath ?? ''}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.folder),
          onPressed: () async {
            final dir = await _selectDir();
            if (dir != null) {
              onPressed(dir.path);
            }
          },
        ),
      ],
    );
  }

  Future<Directory?> _selectDir() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      if (kDebugMode) {
        print('Selected directory: $result');
      }
      return Directory(result);
    }
    return null;
  }
}

class SharedFilePicker extends StatelessWidget {
  const SharedFilePicker({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final Function(List<String?>) onPressed;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 50,
        width: 120,
        child: FittedBox(
            child: SecondaryButton(
                text: label,
                onPressed: () {
                  _selectFile();
                })),
      ),
    );
  }

  Future<List<File?>> _selectFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      if (kDebugMode) {
        print('Selected file: ${result.files.single.path}');
      }
      return result.paths
          .map((file) => file != null ? File(file) : null)
          .toList();
    }
    return [];
  }
}

SnackBar showSharedSnackBar(BuildContext context, String text) {
  return SnackBar(
    content: Text(text),
    duration: const Duration(seconds: 8),
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
