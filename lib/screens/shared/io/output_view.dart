import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/io/file_list.dart';
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

/// Files in the output directory. Shows only the files new since the
/// directory was selected, with a button to show the rest.
class OutputFileList extends StatefulWidget {
  const OutputFileList({
    super.key,
    required this.data,
  });

  final SegulOutputFile data;

  @override
  State<OutputFileList> createState() => _OutputFileListState();
}

class _OutputFileListState extends State<OutputFileList> {
  bool _isShowingAll = false;

  @override
  Widget build(BuildContext context) {
    final List<({File file, bool isNew})> allFiles = widget.data.files;
    final List<({File file, bool isNew})> files = _isShowingAll
        ? allFiles
        : allFiles.where((file) => file.isNew).toList();
    final int otherCount = allFiles.length -
        allFiles.where((file) {
          return file.isNew;
        }).length;
    return IOListContainer(
      title: 'Output Files',
      infoText: 'New files in the output directory. '
          'Show other files to see everything in the directory. '
          'Click on a file to view its content. '
          'Select menu to share or delete a file. '
          'Deleting a file will remove it from the system.',
      child: Column(
        children: [
          if (otherCount > 0)
            TextButton(
              onPressed: () => setState(() => _isShowingAll = !_isShowingAll),
              child: Text(_isShowingAll
                  ? 'Show new files only'
                  : 'Show $otherCount other '
                      '${otherCount == 1 ? 'file' : 'files'} in the folder'),
            ),
          Expanded(
            child: files.isEmpty
                ? EmptyScreen(
                    title: allFiles.isEmpty
                        ? 'No output files found.'
                        : 'No new output files yet.',
                    description: 'Run an analysis to generate output files.',
                  )
                : PagedFileList(
                    key: ValueKey(_isShowingAll),
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      return OutputFileTiles(
                        isOldFile: !files[index].isNew,
                        file: files[index].file,
                      );
                    },
                  ),
          ),
        ],
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
