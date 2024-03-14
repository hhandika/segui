import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:segui/services/providers/io.dart';
import 'package:segui/screens/shared/io/picker_widget.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/io/metadata.dart';
import 'package:segui/services/types.dart';
import 'package:segui/styles/decoration.dart';

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
      label: 'Select files',
      allowMultiple: allowMultiple,
      xTypeGroup: xTypeGroup,
      hasSecondaryPicker: hasSecondaryPicker,
      allowDirectorySelection: allowDirectorySelection,
      task: task,
    );
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
      child: Text(
        // Substring the last 40 characters
        path.length > 40 ? '...${path.substring(path.length - 40)}' : path,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
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
