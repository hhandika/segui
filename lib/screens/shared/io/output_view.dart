import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/io/file_browser.dart';
import 'package:segui/screens/shared/io/file_list.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/screens/viewers/common.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/file_tree.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/io/output.dart';
import 'package:segui/services/types.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

class OutputScreen extends ConsumerWidget {
  const OutputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: double.infinity,
      child: ref.watch(fileOutputProvider).when(
            data: (data) {
              return data.directory == null
                  ? const EmptyScreen(
                      title: 'No output directory selected.',
                      description: 'Select an output directory. '
                          'Files in the output directory will be shown here.',
                    )
                  : OutputFileList(data: data);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (err, stack) => Text(err.toString()),
          ),
    );
  }
}

/// Files in the output directory by folder. Shows only the files new since
/// the directory was selected, with a button to show the rest.
class OutputFileList extends ConsumerStatefulWidget {
  const OutputFileList({
    super.key,
    required this.data,
  });

  final SegulOutputFile data;

  @override
  ConsumerState<OutputFileList> createState() => _OutputFileListState();
}

class _OutputFileListState extends ConsumerState<OutputFileList> {
  bool _isShowingAll = false;

  @override
  Widget build(BuildContext context) {
    final List<({File file, bool isNew})> allFiles = widget.data.files;
    final List<({File file, bool isNew})> files = _isShowingAll
        ? allFiles
        : allFiles.where((file) => file.isNew).toList();
    // Other files the toggle would reveal, leaving out unsupported files.
    final int otherCount = allFiles
        .where((file) => !file.isNew && isSupportedFile(file.file.path))
        .length;
    final bool isDesktop = runningPlatform == PlatformType.isDesktop;
    return IOListContainer(
      title: 'Output Files',
      infoText: 'New files in the output directory, by folder. '
          'Show other files to see everything in the directory. '
          'Files SEGUI does not recognize are not shown. '
          'Click on a file to view its content. '
          'Select files to share or delete them. '
          'Deleting a file will remove it from the system.',
      child: FileBrowser(
        files: files,
        rootPath: widget.data.directory?.path,
        header: otherCount > 0
            ? TextButton(
                onPressed: () => setState(() => _isShowingAll = !_isShowingAll),
                child: Text(_isShowingAll
                    ? 'Show new files only'
                    : 'Show $otherCount other '
                        '${otherCount == 1 ? 'file' : 'files'} in the folder'),
              )
            : null,
        emptyChild: EmptyScreen(
          title: allFiles.isEmpty
              ? 'No output files found.'
              : 'No new output files yet.',
          description: 'Run an analysis to generate output files.',
        ),
        onFileTap: (file) => openFileView(context, file.file),
        trailingBuilder: (context, file) {
          return OutputActionMenu(file: file.file, showDelete: false);
        },
        actions: [
          FileBrowserAction(
            label: 'Share',
            icon: Icons.adaptive.share_rounded,
            onSelected: (context, files) async {
              await IOServices().shareFiles(context, files);
              return false;
            },
          ),
          if (isDesktop)
            FileBrowserAction(
              label: 'Open',
              icon: Icons.open_in_new_rounded,
              isSingleFile: true,
              onSelected: (context, files) async {
                await _openInApp(context, files.single);
                return false;
              },
            ),
          FileBrowserAction(
            label: 'Delete',
            icon: Icons.delete_outline_rounded,
            isDestructive: true,
            onSelected: _confirmDelete,
          ),
        ],
      ),
    );
  }

  Future<void> _openInApp(BuildContext context, File file) async {
    final launcher = UrlLauncherServices(file: file);
    final bool canLaunch = await launcher.canLaunch();
    try {
      if (canLaunch) {
        await launcher.launchExternalApp();
        return;
      }
    } catch (_) {
      // Shown below like a file no app can open.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, 'No app found to open this file.'),
      );
    }
  }

  Future<bool> _confirmDelete(BuildContext context, List<File> files) async {
    final bool? isConfirmed = await showResponsiveSheet<bool>(
      context: context,
      builder: (context) => DeleteFilesAlert(count: files.length),
    );
    if (isConfirmed != true) {
      return false;
    }
    await ref.read(fileOutputProvider.notifier).deleteFiles(files);
    return true;
  }
}

/// Asks before deleting [count] selected files from disk.
class DeleteFilesAlert extends StatelessWidget {
  const DeleteFilesAlert({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final String files = count == 1 ? '1 file' : '$count files';
    return SheetContent(
      title: 'Delete $files?',
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Delete',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
      child: Text('Deleting removes $files from your computer permanently.'),
    );
  }
}

class OutputFileTiles extends StatelessWidget {
  const OutputFileTiles({
    super.key,
    required this.isOldFile,
    required this.file,
  });

  final bool isOldFile;
  final File file;

  @override
  Widget build(BuildContext context) {
    final FileAssociation association = FileAssociation(file: file);
    return ListTile(
      minVerticalPadding: SeguiSpacing.xxs,
      leading: FileIconTile(icon: FileIcon(file: file)),
      title: isOldFile
          ? FileIOTitle(file: file)
          : Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: FileIOTitle(file: file),
                ),
                Icon(
                  Icons.fiber_new_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
      subtitle: FileIOSubtitle(file: file),
      trailing: OutputActionMenu(file: file),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FileView(
              file: file,
              type: association.commonFileTYpe,
            ),
          ),
        );
      },
    );
  }
}

class OutputActionMenu extends StatelessWidget {
  const OutputActionMenu({
    super.key,
    required this.file,
    this.showDelete = true,
  });

  final File file;

  /// Whether the menu offers Delete. The file panel deletes through
  /// selection instead.
  final bool showDelete;

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = isPhoneScreen(context);
    return isSmallScreen
        ? IconButton(
            icon: Icon(Icons.adaptive.more_rounded),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Container(
                    padding: const EdgeInsets.all(SeguiSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CommonShareTile(file: file),
                        const SizedBox(height: SeguiSpacing.xxs),
                        ExternalAppLauncher(
                          file: file,
                          fromPopUp: true,
                        ),
                        const SizedBox(height: SeguiSpacing.xxs),
                        FileInfoTile(file: file),
                        if (showDelete) ...[
                          const SizedBox(height: SeguiSpacing.md),
                          const CommonDivider(),
                          CommonDeleteTile(file: file),
                        ],
                        const SizedBox(height: SeguiSpacing.xs),
                      ],
                    ),
                  );
                },
              );
            },
          )
        : PopupMenuButton<PopupMenuItem>(
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  child: CommonShareTile(file: file),
                ),
                if (runningPlatform == PlatformType.isDesktop)
                  PopupMenuItem(
                    child: ExternalAppLauncher(
                      file: file,
                      fromPopUp: true,
                    ),
                  ),
                PopupMenuItem(child: FileInfoTile(file: file)),
                if (showDelete) ...[
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    child: CommonDeleteTile(file: file),
                  ),
                ],
              ];
            },
          );
  }
}
