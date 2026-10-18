import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/io/file_browser.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/screens/viewers/common.dart';
import 'package:segui/services/io/input.dart';

class InputScreen extends ConsumerWidget {
  const InputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: double.infinity,
      child: ref.watch(fileInputProvider).when(
            data: (data) => data.isEmpty
                ? const EmptyScreen(
                    title: 'No input files selected.',
                    description: 'Select one or more input files. '
                        'The selected files will be shown here.',
                  )
                : InputFileList(files: data),
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

  final List<SegulInputFile> files;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IOListContainer(
      title: 'Input Files',
      infoText: 'Input files by folder. '
          'Click on a folder to show or hide its files. '
          'Click on a file to view its content. '
          'Select files to remove them from the list. '
          'Removing a file will not delete the file from the system.',
      child: FileBrowser(
        files: [
          for (final SegulInputFile file in files)
            (file: file.file, isNew: false),
        ],
        emptyChild: const EmptyScreen(
          title: 'No input files selected.',
          description: 'Select one or more input files. '
              'The selected files will be shown here.',
        ),
        onFileTap: (file) => openFileView(
          context,
          file.file,
          siblings: files.map((input) => input.file),
        ),
        actions: [
          FileBrowserAction(
            label: 'Remove',
            icon: Icons.playlist_remove_rounded,
            isDestructive: true,
            onSelected: (context, selected) async {
              final bool? isConfirmed = await showResponsiveSheet<bool>(
                context: context,
                builder: (context) =>
                    RemoveInputFilesAlert(count: selected.length),
              );
              if (isConfirmed != true) {
                return false;
              }
              await ref
                  .read(fileInputProvider.notifier)
                  .removeFiles(selected.map((e) => e.path).toSet());
              return true;
            },
          ),
        ],
      ),
    );
  }
}

/// Asks before removing [count] selected files from the input list.
class RemoveInputFilesAlert extends StatelessWidget {
  const RemoveInputFilesAlert({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final String files = count == 1 ? '1 file' : '$count files';
    return SheetContent(
      title: 'Remove $files?',
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Remove',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
      child: Text('This removes $files from the input list. '
          'The files stay on your computer.'),
    );
  }
}
