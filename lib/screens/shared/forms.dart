import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/io.dart';

class SharedSequenceInputForm extends StatefulWidget {
  const SharedSequenceInputForm({
    super.key,
    required this.ctr,
    this.isDatatypeEnabled = true,
  });

  final IOController ctr;
  final bool isDatatypeEnabled;

  @override
  State<SharedSequenceInputForm> createState() =>
      _SharedSequenceInputFormState();
}

class _SharedSequenceInputFormState extends State<SharedSequenceInputForm> {
  @override
  Widget build(BuildContext context) {
    return FormCard(
      children: [
        InputSelectorForm(
          ctr: widget.ctr,
          onDirPressed: (value) {
            setState(() {
              widget.ctr.dirPath = value;
            });
          },
          onFilePressed: (value) {
            setState(() {
              widget.ctr.files = value;
            });
          },
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

class InputSelectorForm extends StatelessWidget {
  const InputSelectorForm({
    super.key,
    required this.onDirPressed,
    required this.onFilePressed,
    required this.ctr,
  });

  final void Function(String?) onDirPressed;
  final void Function(List<String>) onFilePressed;
  final IOController ctr;

  @override
  Widget build(BuildContext context) {
    return runningPlatform == PlatformType.isDesktop
        ? SelectDirField(
            label: 'Select input directory',
            dirPath: ctr.dirPath,
            onPressed: onDirPressed,
          )
        : SharedFilePicker(
            label: 'Select input files',
            paths: ctr.files,
            onPressed: onFilePressed,
          );
  }
}

class FormView extends StatelessWidget {
  const FormView({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppPageView(
      child: ListView(
        shrinkWrap: true,
        children: children,
      ),
    );
  }
}

class AppPageView extends StatelessWidget {
  const AppPageView({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          constraints: const BoxConstraints(maxWidth: 500),
          child: child),
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
  const CommonCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color.lerp(Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.surface, 0.95),
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

class SharedOutputDirField extends StatelessWidget {
  const SharedOutputDirField({
    super.key,
    required this.ctr,
    required this.onPressed,
  });

  final String? ctr;
  final void Function(String?) onPressed;

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? const SizedBox.shrink()
        : SelectDirField(
            label: 'Select output directory',
            dirPath: ctr,
            onPressed: onPressed);
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
            dirPath ?? '$label: ',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: dirPath == null
              ? const Icon(Icons.folder)
              : const Icon(Icons.folder_open),
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
    required this.paths,
    required this.onPressed,
  });

  final String label;
  final List<String> paths;
  final Function(List<String>) onPressed;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            paths.isEmpty ? '$label: ' : '${paths.length} files selected',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: paths.isEmpty
              ? const Icon(Icons.folder)
              : const Icon(Icons.folder_open),
          onPressed: () async {
            final paths = await _selectFile();
            if (paths.isNotEmpty) {
              onPressed(paths);
            }
          },
        ),
      ],
    );
  }

  Future<List<String>> _selectFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      return result.paths.map((e) => e ?? '').toList();
    } else {
      return [];
    }
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
