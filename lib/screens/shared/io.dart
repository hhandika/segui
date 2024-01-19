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
            data: (data) => InputFileList(
              files: data,
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (err, stack) => Text(err.toString()),
          ),
    );
  }
}

class InputFileList extends ConsumerWidget {
  const InputFileList({super.key, required this.files});

  final List<SegulFile> files;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IOListContainer(
        title: 'Input Files',
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
            final data = files[index];
            return ListTile(
              minVerticalPadding: 2,
              leading: const Icon(Icons.attach_file_outlined),
              title: Text(data.file.name),
              subtitle: FutureBuilder<String>(
                future: getFileSize(data.file),
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
                  ref.read(fileInputProvider.notifier).removeFile(data);
                },
              ),
            );
          },
        ));
  }
}

class OutputScreen extends ConsumerWidget {
  const OutputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: double.infinity,
      child: ref.watch(fileOutputProvider).when(
            data: (data) => OutputFileList(files: data),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (err, stack) => Text(err.toString()),
          ),
    );
  }
}

class OutputFileList extends StatelessWidget {
  const OutputFileList({
    super.key,
    required this.files,
  });

  final List<XFile> files;

  @override
  Widget build(BuildContext context) {
    return IOListContainer(
        title: 'Output Files',
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
            final data = files[index];
            return ListTile(
              minVerticalPadding: 2,
              leading: const Icon(Icons.attach_file_outlined),
              title: Text(data.name),
              subtitle: FutureBuilder<String>(
                future: getFileSize(data),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(snapshot.data!);
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
              trailing: IconButton(
                icon: Icon(Icons.adaptive.share_outlined),
                onPressed: () {
                  IOServices().shareFile(context, data);
                },
              ),
            );
          },
        ));
  }
}

class IOListContainer extends StatelessWidget {
  const IOListContainer({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Flexible(
          child: child,
        )
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
    required this.hasSecondaryPicker,
  });

  final IOController ctr;
  final bool allowMultiple;
  final XTypeGroup xTypeGroup;
  final bool hasSecondaryPicker;

  @override
  Widget build(BuildContext context) {
    return SharedFilePicker(
      label: 'Select input files',
      allowMultiple: allowMultiple,
      xTypeGroup: xTypeGroup,
      hasSecondaryPicker: hasSecondaryPicker,
    );
  }
}

class SharedFilePicker extends ConsumerStatefulWidget {
  const SharedFilePicker({
    super.key,
    required this.label,
    required this.allowMultiple,
    required this.xTypeGroup,
    required this.hasSecondaryPicker,
  });

  final String label;
  final bool allowMultiple;
  final XTypeGroup xTypeGroup;
  final bool hasSecondaryPicker;

  @override
  SharedMultiFilePickerState createState() => SharedMultiFilePickerState();
}

class SharedMultiFilePickerState extends ConsumerState<SharedFilePicker> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final type = matchTypeByXTypeGroup(widget.xTypeGroup);
    return ref.watch(fileInputProvider).when(
          data: (data) {
            final isAddNew = data.where((e) => e.type == type).toList().isEmpty;
            return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  data.isEmpty
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
                  const SizedBox(width: 8),
                  _isLoading
                      ? const SizedBox(
                          height: 8,
                          width: 8,
                          child: CircularProgressIndicator(),
                        )
                      : IconButton(
                          icon: isAddNew
                              ? const Icon(Icons.folder)
                              : const Icon(Icons.add_rounded),
                          onPressed: !isAddNew && !widget.allowMultiple
                              ? null
                              : () async {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  try {
                                    await _selectFiles(
                                        isAddNew && !widget.hasSecondaryPicker);
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        showSharedSnackBar(
                                            context, e.toString()),
                                      );
                                    }
                                  }
                                  setState(() {
                                    _isLoading = false;
                                  });
                                },
                        ),
                ]);
          },
          loading: () => const SizedBox.shrink(),
          error: (err, stack) => Text(err.toString()),
        );
  }

  Future<void> _selectFiles(bool isAddNew) async {
    List<SegulFile> result = await FileSelectionServices(ref)
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
