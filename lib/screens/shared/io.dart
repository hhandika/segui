import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/io.dart';

class SelectDirField extends ConsumerWidget {
  const SelectDirField({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(fileOutputProvider).when(
        data: (data) {
          return Row(
            children: [
              Expanded(
                child: data.directory == null
                    ? Text(
                        '$label: ',
                        overflow: TextOverflow.ellipsis,
                      )
                    : PathTextWithOverflow(
                        path: data.directory!.path,
                      ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: data.directory == null
                    ? 'Select directory'
                    : 'Clear directory',
                icon: data.directory == null
                    ? const Icon(Icons.folder_outlined)
                    : const Icon(Icons.clear),
                onPressed: data.directory == null
                    ? () async {
                        await DirectorySelectionServices(ref).addOutputDir();
                      }
                    : () {
                        ref.invalidate(fileOutputProvider);
                      },
              ),
            ],
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (err, stack) {
          return Column(
            children: [
              Text(
                err.toString(),
              ),
              IconButton(
                tooltip: 'Retry',
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.invalidate(fileOutputProvider);
                },
              ),
            ],
          );
        });
  }
}

class InputSelectorForm extends StatelessWidget {
  const InputSelectorForm({
    super.key,
    required this.ctr,
    required this.allowMultiple,
    required this.xTypeGroup,
    required this.hasSecondaryPicker,
    required this.allowDirectorySelection,
    required this.task,
  });

  final IOController ctr;
  final bool allowMultiple;
  final XTypeGroup xTypeGroup;
  final bool hasSecondaryPicker;
  final SupportedTask task;
  final bool allowDirectorySelection;

  @override
  Widget build(BuildContext context) {
    return SharedFilePicker(
      label: 'Add files',
      allowMultiple: allowMultiple,
      xTypeGroup: xTypeGroup,
      hasSecondaryPicker: hasSecondaryPicker,
      allowDirectorySelection: allowDirectorySelection,
      task: task,
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
    required this.task,
    required this.allowDirectorySelection,
  });

  final String label;
  final bool allowMultiple;
  final XTypeGroup xTypeGroup;
  final bool hasSecondaryPicker;
  final SupportedTask task;
  final bool allowDirectorySelection;

  @override
  SharedFilePickerState createState() => SharedFilePickerState();
}

class SharedFilePickerState extends ConsumerState<SharedFilePicker> {
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
                      ? const SharedProgressIndicator()
                      : !widget.allowDirectorySelection
                          ? IconButton(
                              tooltip: 'Add file',
                              icon: const Icon(Icons.add_rounded),
                              onPressed: !isAddNew && !widget.allowMultiple
                                  ? null
                                  : () async {
                                      await _selectFiles(
                                          isAddNew &&
                                              !widget.hasSecondaryPicker,
                                          isFileSelection: true);
                                    },
                            )
                          : PopupMenuButton(
                              elevation: 2,
                              color: Theme.of(context).colorScheme.background,
                              tooltip: 'Select input method',
                              itemBuilder: (context) {
                                return [
                                  PopupMenuItem(
                                    child: ListTile(
                                      leading: const Icon(Icons.add_rounded),
                                      title: Text(isAddNew
                                          ? 'Select files'
                                          : 'Add more files'),
                                    ),
                                    onTap: () async {
                                      await _selectFiles(
                                          isAddNew &&
                                              !widget.hasSecondaryPicker,
                                          isFileSelection: true);
                                    },
                                  ),
                                  PopupMenuItem(
                                    child: ListTile(
                                      leading: Icon(
                                        isAddNew
                                            ? Icons.folder_outlined
                                            : Icons.folder_open_outlined,
                                      ),
                                      title: Text(isAddNew
                                          ? 'Add from directory'
                                          : 'More from directory'),
                                    ),
                                    onTap: () async {
                                      await _selectFiles(
                                          isAddNew &&
                                              !widget.hasSecondaryPicker,
                                          isFileSelection: false);
                                    },
                                  ),
                                  if (!isAddNew)
                                    PopupMenuItem(
                                      child: const ListTile(
                                        leading: Icon(Icons.delete_outline),
                                        title: Text('Clear input files'),
                                      ),
                                      onTap: () {
                                        ref.invalidate(fileInputProvider);
                                      },
                                    ),
                                ];
                              },
                              onSelected: (value) async {}),
                ]);
          },
          loading: () => const SizedBox.shrink(),
          error: (err, stack) => Text(err.toString()),
        );
  }

  Future<void> _selectFiles(bool isAddNew,
      {required bool isFileSelection}) async {
    final selection = FileInputServices(
      ref,
      allowedExtension: widget.xTypeGroup,
      isAddNew: isAddNew,
      allowMultiple: widget.allowMultiple,
    );
    setState(() {
      _isLoading = true;
    });

    try {
      if (isFileSelection) {
        await selection.selectFiles();
      } else {
        await selection.addDirectory();
      }

      // On mobile, user cannot select the output directory
      // we add it automatically when they select the input files
      if (Platform.isAndroid || Platform.isIOS) {
        ref.read(fileOutputProvider.notifier).addMobile(null, widget.task);
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
  }
}

class SharedOutputDirField extends ConsumerWidget {
  const SharedOutputDirField({
    super.key,
    required this.ctr,
  });

  final TextEditingController ctr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Platform.isIOS || Platform.isAndroid
        ? SharedTextField(
            label: 'Directory name',
            hint: 'Enter output directory name',
            controller: ctr,
            onSubmitted: () {
              updateOutputDir(
                  ref, ctr.text, SupportedTask.alignmentConcatenation);
            },
          )
        : const SelectDirField(
            label: 'Select output directory',
          );
  }
}

/// Display a path full when it is short
/// Display a path with overflow when it is long
/// The overflowed path is displayed in a tooltip
class PathTextWithOverflow extends StatelessWidget {
  const PathTextWithOverflow({
    super.key,
    required this.path,
  });

  final String path;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
        message: path,
        child: Row(
          children: [
            const Icon(Icons.folder_open),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                // Substring the last 40 characters
                path.length > 40
                    ? '...${path.substring(path.length - 40)}'
                    : path,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ));
  }
}

class FileIOTitle extends StatelessWidget {
  const FileIOTitle({super.key, required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: file.path,
      child: Text(
        file.name,
        style: Theme.of(context).textTheme.labelLarge,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class FileIOSubtitle extends StatelessWidget {
  const FileIOSubtitle({super.key, required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({String size, String lastModified})>(
      future: _metadata,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // We use interpunction to separate the size and last modified
          return Text(
            '${snapshot.data!.size} · modified ${snapshot.data!.lastModified}',
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Future<({String size, String lastModified})> get _metadata async {
    return FileMetadata(file: file).metadata;
  }
}
