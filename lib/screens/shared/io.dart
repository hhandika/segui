import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:segui/providers/io.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/io.dart';
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
                          ? SingleInputButton(
                              isAddNew: isAddNew,
                              inputFiles: data,
                              type: type,
                              onFileSelected: !widget.allowMultiple && !isAddNew
                                  ? null
                                  : () async {
                                      await _selectFiles(
                                          isAddNew &&
                                              !widget.hasSecondaryPicker,
                                          isFileSelection: true);
                                    },
                            )
                          : InputSelector(
                              isAddNew: isAddNew,
                              onFileSelected: () async {
                                await _selectFiles(
                                    isAddNew && !widget.hasSecondaryPicker,
                                    isFileSelection: true);
                              },
                              onDirectorySelected: () async {
                                await _selectFiles(
                                    isAddNew && !widget.hasSecondaryPicker,
                                    isFileSelection: false);
                              },
                            ),
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

class SingleInputButton extends ConsumerWidget {
  const SingleInputButton({
    super.key,
    required this.isAddNew,
    required this.inputFiles,
    required this.type,
    required this.onFileSelected,
  });

  final bool isAddNew;
  final List<SegulInputFile> inputFiles;
  final SegulType type;
  final VoidCallback? onFileSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: isAddNew ? 'Select files' : 'Add more files',
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
    required this.isAddNew,
    required this.onFileSelected,
    required this.onDirectorySelected,
  });

  final bool isAddNew;
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
                            isAddNew: widget.isAddNew,
                            onFileSelected: widget.onFileSelected,
                          ),
                          if (!isMobile)
                            SelectDirectoryButton(
                              onDirectorySelected: widget.onDirectorySelected,
                            ),
                          if (!widget.isAddNew) const ClearAllButton(),
                        ],
                      ));
                },
              );
            },
          )
        : InputActionMenu(
            isAddNew: widget.isAddNew,
            onFileSelected: widget.onFileSelected,
            onDirectorySelected: widget.onDirectorySelected,
          );
  }
}

class InputActionMenu extends ConsumerWidget {
  const InputActionMenu({
    super.key,
    required this.isAddNew,
    required this.onFileSelected,
    required this.onDirectorySelected,
  });

  final bool isAddNew;
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
              isAddNew: isAddNew,
              onFileSelected: onFileSelected,
            )),
            if (!isMobile)
              PopupMenuItem(
                  child: SelectDirectoryButton(
                onDirectorySelected: onDirectorySelected,
              )),
            if (!isAddNew)
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
    required this.isAddNew,
    required this.onFileSelected,
  });

  final bool isAddNew;
  final VoidCallback onFileSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.add_rounded),
      title: Text(
        isAddNew ? 'Select files' : 'Add more files',
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
                  const SizedBox(height: 4),
                  const CommonDivider(),
                  const MetadataSubtitle(subtitle: 'Size'),
                  MetadataContent(
                    content: snapshot.data!.size,
                  ),
                  const MetadataSubtitle(subtitle: 'Last accessed'),
                  MetadataContent(
                    content: snapshot.data!.accessed,
                  ),
                  const MetadataSubtitle(subtitle: 'Last modified'),
                  MetadataContent(
                    content: snapshot.data!.lastModified,
                  ),
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

class MetadataSubtitle extends StatelessWidget {
  const MetadataSubtitle({super.key, required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
          overflow: TextOverflow.ellipsis,
        ));
  }
}

class MetadataContent extends StatelessWidget {
  const MetadataContent({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      style: Theme.of(context).textTheme.bodySmall,
      overflow: TextOverflow.ellipsis,
    );
  }
}
