import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/screens/viewers/common.dart';
import 'package:segui/services/io/file.dart';
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
        infoText: 'List of input files. '
            'Click on a file to view its content. '
            'Click on the delete icon to remove a file. '
            'Removing a file will not delete the file from the system.',
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: files.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final data = files[index];
            final association = FileAssociation(file: data.file);
            return ListTile(
              minVerticalPadding: 2,
              leading: FileIcon(file: data.file),
              title: FileIOTitle(file: data.file),
              subtitle: FileIOSubtitle(file: data.file),
              trailing: IconButton(
                tooltip: 'Remove file',
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  ref.read(fileInputProvider.notifier).removeFromList(data);
                },
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FileView(
                      file: data.file,
                      type: association.commonFileTYpe,
                    ),
                  ),
                );
              },
            );
          },
        ));
  }
}
