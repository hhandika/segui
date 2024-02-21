import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:segui/providers/io.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/io/directory.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/io/metadata.dart';
import 'package:segui/services/types.dart';
import 'package:segui/styles/decoration.dart';

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
            final addNew = data.where((e) => e.type == type).toList().isEmpty;
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
                  ref.watch(fileInputProvider).when(
                      data: (data) {
                        return _isLoading
                            ? const SharedProgressIndicator()
                            : !widget.allowDirectorySelection
                                ? SingleInputButton(
                                    addNew: addNew,
                                    inputFiles: data,
                                    type: type,
                                    onFileSelected: !widget.allowMultiple &&
                                            !addNew
                                        ? null
                                        : () async {
                                            if (!widget.hasSecondaryPicker &&
                                                addNew) {
                                              await _addFiles(isDir: false);
                                            } else {
                                              await _addMoreFiles(data,
                                                  isDir: false);
                                            }
                                          },
                                  )
                                : InputSelector(
                                    addNew: addNew,
                                    onFileSelected: () async {
                                      if (!widget.hasSecondaryPicker &&
                                          addNew) {
                                        await _addFiles(isDir: true);
                                      } else {
                                        await _addMoreFiles(data, isDir: false);
                                      }
                                    },
                                    onDirectorySelected: () async {
                                      if (!widget.hasSecondaryPicker &&
                                          addNew) {
                                        await _addFiles(isDir: true);
                                      } else {
                                        await _addMoreFiles(data, isDir: true);
                                      }
                                    },
                                  );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (err, stack) {
                        return IconButton(
                          tooltip: 'Retry',
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            ref.invalidate(fileInputProvider);
                          },
                        );
                      }),
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

class SingleInputButton extends ConsumerWidget {
  const SingleInputButton({
    super.key,
    required this.addNew,
    required this.inputFiles,
    required this.type,
    required this.onFileSelected,
  });

  final bool addNew;
  final List<SegulInputFile> inputFiles;
  final SegulType type;
  final VoidCallback? onFileSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: addNew ? 'Select files' : 'Add more files',
      icon: _hasInputFile
          ? const Icon(Icons.clear_rounded)
          : const Icon(Icons.add_rounded),
      onPressed: _hasInputFile
          ? () {
              final file = inputFiles.firstWhere((e) => e.type == type);
              ref.read(fileInputProvider.notifier).removeFromList(file);
            }
          : onFileSelected,
    );
  }

  bool get _hasInputFile {
    if (inputFiles.isEmpty) {
      return false;
    }
    return inputFiles.any((element) => element.type == type);
  }
}

class InputSelector extends StatefulWidget {
  const InputSelector({
    super.key,
    required this.addNew,
    required this.onFileSelected,
    required this.onDirectorySelected,
  });

  final bool addNew;
  final VoidCallback onFileSelected;
  final VoidCallback onDirectorySelected;

  @override
  State<InputSelector> createState() => _InputSelectorState();
}

class _InputSelectorState extends State<InputSelector> {
  @override
  Widget build(BuildContext context) {
    final isSmallScreen = isPhoneScreen(context);
    final isMobile = Platform.isAndroid || Platform.isIOS;
    return isSmallScreen
        ? IconButton(
            tooltip: 'Select input method',
            icon: Icon(Icons.adaptive.more_rounded),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                barrierLabel: 'Select input method',
                showDragHandle: true,
                builder: (context) {
                  return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 32),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          SelectFileButton(
                            addNew: widget.addNew,
                            onFileSelected: widget.onFileSelected,
                          ),
                          if (!isMobile)
                            SelectDirectoryButton(
                              onDirectorySelected: widget.onDirectorySelected,
                            ),
                          if (!widget.addNew) const ClearAllButton(),
                        ],
                      ));
                },
              );
            },
          )
        : InputActionMenu(
            addNew: widget.addNew,
            onFileSelected: widget.onFileSelected,
            onDirectorySelected: widget.onDirectorySelected,
          );
  }
}

class InputActionMenu extends ConsumerWidget {
  const InputActionMenu({
    super.key,
    required this.addNew,
    required this.onFileSelected,
    required this.onDirectorySelected,
  });

  final bool addNew;
  final VoidCallback onFileSelected;
  final VoidCallback onDirectorySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = Platform.isAndroid || Platform.isIOS;
    return PopupMenuButton(
        elevation: 2,
        color: Theme.of(context).colorScheme.background,
        tooltip: 'Select input method',
        itemBuilder: (context) {
          return [
            PopupMenuItem(
                child: SelectFileButton(
              addNew: addNew,
              onFileSelected: onFileSelected,
            )),
            if (!isMobile)
              PopupMenuItem(
                  child: SelectDirectoryButton(
                onDirectorySelected: onDirectorySelected,
              )),
            if (!addNew)
              const PopupMenuItem(
                child: ClearAllButton(),
              ),
          ];
        });
  }
}

class SelectFileButton extends StatelessWidget {
  const SelectFileButton({
    super.key,
    required this.addNew,
    required this.onFileSelected,
  });

  final bool addNew;
  final VoidCallback onFileSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.add_rounded),
      title: Text(
        addNew ? 'Select files' : 'Add more files',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      onTap: () {
        Navigator.of(context).pop();
        onFileSelected();
      },
    );
  }
}

class SelectDirectoryButton extends StatelessWidget {
  const SelectDirectoryButton({
    super.key,
    required this.onDirectorySelected,
  });
  final VoidCallback onDirectorySelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.folder_outlined),
      title: Text(
        'From directory',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      onTap: () {
        Navigator.of(context).pop();
        onDirectorySelected();
      },
    );
  }
}

class ClearAllButton extends ConsumerWidget {
  const ClearAllButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.clear_rounded),
      title: Text(
        'Clear all',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      onTap: () {
        Navigator.of(context).pop();
        ref.read(fileInputProvider.notifier).clearAll();
      },
    );
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
    return runningPlatform == PlatformType.isMobile
        ? SharedTextField(
            label: 'Directory name',
            hint: 'Enter output directory name',
            controller: ctr,
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

  final File file;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: file.path,
      child: Text(
        path.basename(file.path),
        style: Theme.of(context).textTheme.labelLarge,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class FileIOSubtitle extends StatelessWidget {
  const FileIOSubtitle({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _metadata,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // We use interpunction to separate the size and last modified
          return Text(
            snapshot.data!,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Future<String> get _metadata async {
    return await FileMetadata(file: file).metadataText;
  }
}

class FileInfoScreen extends StatelessWidget {
  const FileInfoScreen({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getMetadata(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Container(
              padding: const EdgeInsets.all(16),
              width: isPhoneScreen(context) ? double.infinity : 480,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  PrimaryFileIcon(file: file, iconSize: 40),
                  const SizedBox(height: 4),
                  Text(
                    snapshot.data!.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    snapshot.data!.path,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const CommonDivider(),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      MetadataTile(
                        title: 'Size',
                        content: snapshot.data!.size,
                        icon: const Icon(Icons.file_copy_outlined),
                      ),
                      MetadataTile(
                        title: 'Last accessed',
                        content: snapshot.data!.accessed,
                        icon: const Icon(Icons.access_time_outlined),
                      ),
                      MetadataTile(
                        title: 'Last modified',
                        content: snapshot.data!.lastModified,
                        icon: const Icon(Icons.update_outlined),
                      ),
                    ],
                  )
                ],
              ));
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          return const Center(
            child: Text('Error loading file info'),
          );
        }
      },
    );
  }

  Future<CompleteFileMetadata> _getMetadata() async {
    return await FileMetadata(file: file).completeMetadata;
  }
}

class MetadataTile extends StatelessWidget {
  const MetadataTile({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
  });

  final String title;
  final String content;
  final Icon icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: icon,
      title: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium,
      ),
      subtitle: Text(content),
    );
  }
}
