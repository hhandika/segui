import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/screens/viewers/common.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/io/output.dart';
import 'package:segui/services/types.dart';
import 'package:segui/styles/decoration.dart';

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

class OutputFileList extends StatelessWidget {
  const OutputFileList({
    super.key,
    required this.data,
  });

  final SegulOutputFile data;

  @override
  Widget build(BuildContext context) {
    return IOListContainer(
      title: 'Output Files',
      infoText: 'List of files in the output directory. '
          'Newly created files are marked with a new icon. '
          'Click on a file to view its content. '
          'Select menu to share or delete a file. '
          'Deleting a file will remove it from the system.',
      child: data.files.isEmpty
          ? const Center(
              child: EmptyScreen(
              title: 'No output files found. ',
              description: 'Run an analysis to generate output files.',
            ))
          : ListView.builder(
              itemCount: data.files.length,
              itemBuilder: (context, index) {
                final file = data.files[index].file;
                return OutputFileTiles(
                  isOldFile: !data.files[index].isNew,
                  file: file,
                );
              },
            ),
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
      minVerticalPadding: 2,
      leading: FileIcon(file: file),
      title: isOldFile
          ? FileIOTitle(file: file)
          : Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FileIOTitle(file: file),
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
  const OutputActionMenu({super.key, required this.file});

  final File file;

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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CommonShareTile(file: file),
                        const SizedBox(height: 2),
                        ExternalAppLauncher(
                          file: file,
                          fromPopUp: true,
                        ),
                        const SizedBox(height: 2),
                        FileInfoTile(file: file),
                        const SizedBox(height: 8),
                        const CommonDivider(),
                        CommonDeleteTile(file: file),
                        const SizedBox(height: 4),
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
                const PopupMenuDivider(),
                PopupMenuItem(
                  child: CommonDeleteTile(file: file),
                ),
              ];
            },
          );
  }
}
