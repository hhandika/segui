import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

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

class SelectDirField extends StatefulWidget {
  const SelectDirField({
    super.key,
    required this.dirPath,
    required this.onChanged,
  });

  final String? dirPath;
  final void Function(String?) onChanged;

  @override
  State<SelectDirField> createState() => _SelectDirFieldState();
}

class _SelectDirFieldState extends State<SelectDirField> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Choose a directory: ${widget.dirPath ?? ''}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.folder),
          onPressed: () async {
            final dir = await _selectDir();
            if (dir != null) {
              widget.onChanged(dir.path);
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
