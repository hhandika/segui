import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/services/io/directory.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';

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
                  child: PickerLabel(
                addNew: data.directory == null,
                isDir: true,
                unselectedLabel: label,
                selectedLabel: PathTextWithOverflow(
                  path: data.directory?.path ?? '',
                ),
              )),
              const SizedBox(width: 2),
              IconButton(
                tooltip: data.directory == null
                    ? 'Select directory'
                    : 'Clear directory',
                icon: data.directory == null
                    ? const Icon(Icons.add_rounded)
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
            final addNew = data.where((e) => e.type == type).toList().isEmpty;
            final newInput = addNew && !widget.hasSecondaryPicker;
            return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PickerLabel(
                    addNew: addNew,
                    isDir: false,
                    unselectedLabel: '${widget.label} ',
                    selectedLabel: Text(
                      _getFileCountLabel(data.length),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(width: 2),
                  _isLoading
                      ? const SharedProgressIndicator()
                      : !widget.allowDirectorySelection
                          ? SingleInputButton(
                              addNew: addNew,
                              inputFiles: data,
                              type: type,
                              onFileSelected: !widget.allowMultiple && !addNew
                                  ? null
                                  : () async {
                                      if (newInput) {
                                        await _addFiles(isDir: false);
                                      } else {
                                        await _addMoreFiles(data, isDir: false);
                                      }
                                    },
                            )
                          : InputSelector(
                              addNew: addNew,
                              onFileSelected: () async {
                                if (newInput) {
                                  await _addFiles(isDir: false);
                                } else {
                                  await _addMoreFiles(data, isDir: false);
                                }
                              },
                              onDirectorySelected: () async {
                                if (newInput) {
                                  await _addFiles(isDir: true);
                                } else {
                                  await _addMoreFiles(data, isDir: true);
                                }
                              },
                            ),
                ]);
          },
          loading: () => const SharedProgressIndicator(),
          error: (err, stack) => Text(err.toString()),
        );
  }

  Future<void> _addFiles({required bool isDir}) async {
    _startLoading();
    try {
      final selection = _getFileSelection();
      if (isDir) {
        await selection.addDirectory();
      } else {
        await selection.selectFiles();
      }
    } catch (e) {
      _showError(e.toString());
    }

    _stopLoading();
  }

  Future<void> _addMoreFiles(List<SegulInputFile> currentFiles,
      {required bool isDir}) async {
    _startLoading();
    final selection = _getFileSelection();
    final files = currentFiles.map((e) => e.file).toList();
    try {
      int duplicates = 0;
      if (isDir) {
        duplicates = await selection.addMoreDirectory(files);
      } else {
        duplicates = await selection.addMoreFiles(files);
      }
      if (duplicates > 0) {
        _showError(
            'Skipping $duplicates duplicate file${duplicates > 1 ? 's' : ''}. 🙈');
      }
    } catch (e) {
      _showError(e.toString());
    }
    _stopLoading();
  }

  FileInputServices _getFileSelection() {
    final selection = FileInputServices(
      ref,
      allowedExtension: widget.xTypeGroup,
      allowMultiple: widget.allowMultiple,
    );
    return selection;
  }

  String _getFileCountLabel(int count) {
    return count == 1 ? '1 file selected' : '$count files selected';
  }

  void _startLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      showSharedSnackBar(context, error),
    );
  }

  void _stopLoading() {
    setState(() {
      _isLoading = false;
    });
  }
}

class PickerLabel extends StatelessWidget {
  const PickerLabel({
    super.key,
    required this.addNew,
    required this.isDir,
    required this.unselectedLabel,
    required this.selectedLabel,
  });

  final bool addNew;
  final bool isDir;
  final String unselectedLabel;
  final Widget selectedLabel;

  @override
  Widget build(BuildContext context) {
    return RichText(
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.start,
        text: TextSpan(children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              _icon,
            ),
          ),
          const WidgetSpan(
            child: SizedBox(width: 4),
          ),
          WidgetSpan(
            child: addNew
                ? Text(
                    unselectedLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  )
                : selectedLabel,
          ),
        ]));
  }

  IconData get _icon {
    if (isDir) {
      return addNew ? Icons.folder_outlined : Icons.folder_open_outlined;
    } else {
      return addNew ? Icons.file_copy_outlined : Icons.file_present_outlined;
    }
  }
}
