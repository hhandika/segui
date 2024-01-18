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

class IOCompactScreen extends StatefulWidget {
  const IOCompactScreen({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<IOCompactScreen> createState() => _IOCompactScreenState();
}

class _IOCompactScreenState extends State<IOCompactScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 3,
        child: Scaffold(
            appBar: const TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.play_circle_outline),
                ),
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
                widget.child,
                const InputScreen(),
                const OutputScreen(),
              ],
            )));
  }
}

class IOExpandedScreen extends StatefulWidget {
  const IOExpandedScreen({super.key});

  @override
  State<IOExpandedScreen> createState() => _IOExpandedScreenState();
}

class _IOExpandedScreenState extends State<IOExpandedScreen> {
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

class SelectDirField extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
              ref.read(fileOutputProvider.notifier).addFiles(dir);
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

class InputSelectorForm extends StatelessWidget {
  const InputSelectorForm({
    super.key,
    required this.ctr,
    required this.allowMultiple,
    required this.xTypeGroup,
  });

  final IOController ctr;
  final bool allowMultiple;
  final XTypeGroup xTypeGroup;

  @override
  Widget build(BuildContext context) {
    return SharedFilePicker(
      label: 'Select input files',
      allowMultiple: allowMultiple,
      xTypeGroup: xTypeGroup,
    );
  }
}

class SharedFilePicker extends ConsumerStatefulWidget {
  const SharedFilePicker({
    super.key,
    required this.label,
    required this.allowMultiple,
    required this.xTypeGroup,
  });

  final String label;
  final bool allowMultiple;
  final XTypeGroup xTypeGroup;

  @override
  SharedMultiFilePickerState createState() => SharedMultiFilePickerState();
}

class SharedMultiFilePickerState extends ConsumerState<SharedFilePicker> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final type = matchTypeByXTypeGroup(widget.xTypeGroup);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ref.watch(fileInputProvider).when(
              data: (data) => data.isEmpty
                  ? Text(
                      '${widget.label}: ',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  : RichText(
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      text: TextSpan(children: [
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(Icons.folder_open),
                        ),
                        const WidgetSpan(
                          child: SizedBox(width: 4),
                        ),
                        TextSpan(
                          text:
                              '${IOServices().countFiles(data, type)} selected files',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ])),
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => Text(err.toString()),
            ),
        const SizedBox(width: 8),
        _isLoading
            ? const SizedBox(
                height: 8,
                width: 8,
                child: CircularProgressIndicator(),
              )
            : ref.watch(fileInputProvider).when(
                  data: (data) => IconButton(
                    icon: data.isEmpty
                        ? const Icon(Icons.folder)
                        : const Icon(Icons.add_rounded),
                    onPressed: data.isNotEmpty && !widget.allowMultiple
                        ? null
                        : () async {
                            setState(() {
                              _isLoading = true;
                            });
                            try {
                              await _selectFiles(data.isEmpty);
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
                  loading: () => const Icon(Icons.folder),
                  error: (err, stack) => const Icon(Icons.folder),
                ),
      ],
    );
  }

  Future<void> _selectFiles(bool isAddNew) async {
    List<XFile> result = await FileSelectionServices(ref)
        .selectFiles(widget.xTypeGroup, widget.allowMultiple);
    final notifier = ref.read(fileInputProvider.notifier);
    if (result.isNotEmpty) {
      isAddNew ? notifier.addFiles(result) : notifier.addMoreFiles(result);
    }
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
