import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/io.dart';
import 'package:file_picker/file_picker.dart';

class DesktopIOScreen extends StatefulWidget {
  const DesktopIOScreen({super.key});

  @override
  State<DesktopIOScreen> createState() => _DesktopIOScreenState();
}

class _DesktopIOScreenState extends State<DesktopIOScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          child: const DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: TabBar(
                tabs: [
                  Tab(
                    icon: Icon(Icons.input),
                  ),
                  Tab(
                    icon: Icon(Icons.output),
                  ),
                ],
              ),
              body: TabBarView(
                children: [
                  InputScreen(),
                  OutputScreen(),
                ],
              ),
            ),
          ),
        ));
  }
}

class InputScreen extends ConsumerWidget {
  const InputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: double.infinity,
      child: ref.watch(fileInputProvider).when(
            data: (data) => IOList(title: 'Input Files', files: data),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (err, stack) => Text(err.toString()),
          ),
    );
  }
}

class OutputScreen extends ConsumerWidget {
  const OutputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: double.infinity,
      child: ref.watch(fileOutputProvider).when(
            data: (data) => IOList(title: 'Output Files', files: data),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (err, stack) => Text(err.toString()),
          ),
    );
  }
}

class IOList extends ConsumerWidget {
  const IOList({
    super.key,
    required this.title,
    required this.files,
  });

  final String title;
  final List<XFile> files;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Flexible(
            child: ListView.separated(
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            indent: 36,
            endIndent: 40,
          ),
          shrinkWrap: true,
          itemCount: files.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final file = files[index];
            return ListTile(
              minVerticalPadding: 2,
              leading: const Icon(Icons.attach_file_outlined),
              title: Text(file.name),
              subtitle: FutureBuilder<String>(
                future: getFileSize(file),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(snapshot.data!);
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  ref.read(fileInputProvider.notifier).removeFile(file);
                },
              ),
            );
          },
        ))
      ],
    );
  }
}

class SelectDirField extends StatelessWidget {
  const SelectDirField({
    super.key,
    required this.label,
    required this.dirPath,
    required this.onChanged,
  });

  final String label;
  final TextEditingController dirPath;
  final void Function() onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            dirPath.text.isEmpty ? '$label: ' : dirPath.text,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: dirPath.text.isEmpty
              ? const Icon(Icons.folder)
              : const Icon(Icons.folder_open),
          onPressed: () async {
            final dir = await _selectDir();
            if (dir != null) {
              dirPath.text = dir.path;
              onChanged();
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

class SharedMultiFilePicker extends ConsumerStatefulWidget {
  const SharedMultiFilePicker({
    super.key,
    required this.label,
    required this.paths,
    required this.xTypeGroup,
    required this.onPressed,
  });

  final String label;
  final List<String> paths;
  final List<XTypeGroup> xTypeGroup;
  final Function(List<String>) onPressed;

  @override
  SharedMultiFilePickerState createState() => SharedMultiFilePickerState();
}

class SharedMultiFilePickerState extends ConsumerState<SharedMultiFilePicker> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.paths.isEmpty
                ? '${widget.label}: '
                : '${widget.paths.length} files selected',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        _isLoading
            ? const SizedBox(
                height: 10,
                width: 10,
                child: CircularProgressIndicator(),
              )
            : IconButton(
                icon: widget.paths.isEmpty
                    ? const Icon(Icons.folder)
                    : const Icon(Icons.folder_open),
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  try {
                    final paths = await _selectFiles();
                    if (paths.isNotEmpty) {
                      widget.onPressed(paths);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        showSharedSnackBar(context, e.toString()),
                      );
                    }
                  }
                  setState(() {
                    _isLoading = false;
                  });
                },
              ),
      ],
    );
  }

  Future<List<String>> _selectFiles() async {
    List<XFile> result = await IOServices().selectMultiFiles(widget.xTypeGroup);
    if (result.isNotEmpty) {
      ref.read(fileInputProvider.notifier).addFiles(result);
      return result.map((e) => e.path).toList();
    } else {
      return [];
    }
  }
}

class SharedSingleFilePicker extends StatelessWidget {
  const SharedSingleFilePicker(
      {super.key,
      required this.label,
      required this.path,
      required this.xTypeGroup,
      required this.onPressed,
      s});

  final String label;
  final String? path;
  final List<XTypeGroup> xTypeGroup;
  final Function(String) onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            path == null ? '$label: ' : path!,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: path == null
              ? const Icon(Icons.folder)
              : const Icon(Icons.folder_open),
          onPressed: () async {
            final path = await _selectFile();
            if (path != null) {
              onPressed(path);
            }
          },
        ),
      ],
    );
  }

  Future<String?> _selectFile() async {
    final result = await IOServices().selectFile(xTypeGroup);
    if (result != null) {
      return result.path;
    }
    return null;
  }
}

class InputSelectorForm extends StatelessWidget {
  const InputSelectorForm({
    super.key,
    required this.ctr,
    required this.xTypeGroup,
    required this.onFilePressed,
  });

  final IOController ctr;
  final List<XTypeGroup> xTypeGroup;
  final void Function(List<String>) onFilePressed;

  @override
  Widget build(BuildContext context) {
    return SharedMultiFilePicker(
      label: 'Select input files',
      paths: ctr.files,
      xTypeGroup: xTypeGroup,
      onPressed: onFilePressed,
    );
  }
}

class SharedOutputDirField extends StatelessWidget {
  const SharedOutputDirField({
    super.key,
    required this.ctr,
    required this.onChanged,
  });

  final TextEditingController ctr;
  final void Function() onChanged;

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? SharedTextField(
            label: 'Directory name',
            hint: 'Enter output directory name',
            controller: ctr,
          )
        : SelectDirField(
            label: 'Select output directory',
            dirPath: ctr,
            onChanged: onChanged,
          );
  }
}
