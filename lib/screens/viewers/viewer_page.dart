import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/io/inspector_view.dart';
import 'package:segui/screens/shared/io/picker_widget.dart';
import 'package:segui/screens/viewers/common.dart';
import 'package:segui/services/io/directory.dart';
import 'package:segui/services/io/drop.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/providers/viewer.dart';
import 'package:segui/services/utils.dart';
import 'package:segui/services/viewers/viewer_files.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

/// Fewest files that show the filter field.
const int _filterMin = 9;

/// Opens files and folders just to view them, like `segul view`.
class ViewerPage extends ConsumerWidget {
  const ViewerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<File> files = ref.watch(viewerFilesProvider);
    final Color? background = getSEGULBackgroundColor(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viewer'),
        backgroundColor: background,
        actions: const [OpenViewerFileButton(), OpenViewerFolderButton()],
      ),
      backgroundColor: background,
      body: SafeArea(
        child: FileDropTarget(
          onDropped: (items) => _addDropped(context, ref, items),
          builder: (context, isDragging, _) => Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: SeguiContentWidth.reading),
              child: Padding(
                padding: EdgeInsets.all(
                  isPhoneScreen(context) ? SeguiSpacing.lg : SeguiSpacing.xxl,
                ),
                child: files.isEmpty
                    ? ViewerEmptyState(isDragging: isDragging)
                    : ViewerFileList(files: files),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addDropped(
    BuildContext context,
    WidgetRef ref,
    List<DropItem> items,
  ) async {
    final List<String> paths = await openDroppedItems(items);
    final int added =
        await ref.read(viewerFilesProvider.notifier).addPaths(paths);
    if (added == 0 && context.mounted) {
      showViewerMessage(context, 'No files to view');
    }
  }
}

/// Opens files picked by the user.
class OpenViewerFileButton extends ConsumerWidget {
  const OpenViewerFileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Open file',
      icon: const Icon(Icons.file_open_outlined),
      onPressed: () => openViewerFiles(context, ref),
    );
  }
}

/// Opens the viewable files in a folder picked by the user.
class OpenViewerFolderButton extends ConsumerWidget {
  const OpenViewerFolderButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Open folder',
      icon: const Icon(Icons.folder_open_outlined),
      onPressed: () => openViewerFolder(context, ref),
    );
  }
}

/// Lets the user pick files and lists them. A single file opens right
/// away.
Future<void> openViewerFiles(BuildContext context, WidgetRef ref) async {
  final List<File> picked = await pickViewerFiles();
  if (picked.isEmpty || !context.mounted) return;
  ref.read(viewerFilesProvider.notifier).addFiles(picked);
  if (picked.length == 1) {
    await openFileView(
      context,
      picked.first,
      siblings: ref.read(viewerFilesProvider),
    );
  }
}

/// Lets the user pick a folder and lists its viewable files.
Future<void> openViewerFolder(BuildContext context, WidgetRef ref) async {
  final Directory? dir = await pickDirectory();
  if (dir == null || !context.mounted) return;
  final int added = await ref.read(viewerFilesProvider.notifier).addFolder(dir);
  if (added == 0 && context.mounted) {
    showViewerMessage(context, 'No files to view in ${p.basename(dir.path)}');
  }
}

void showViewerMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Asks for files or a folder, and lists recent ones.
class ViewerEmptyState extends ConsumerWidget {
  const ViewerEmptyState({super.key, this.isDragging = false});

  final bool isDragging;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ViewerRecent> recents = ref.watch(viewerRecentsProvider);
    return ListView(
      children: [
        PickerDropZone(
          icon: Icons.visibility_outlined,
          title: 'Open a file or folder to view',
          hint: isFileDropSupported
              ? 'Or drop them here'
              : 'Alignments, tables, reports, and text',
          isDragging: isDragging,
          actions: [
            PickerAction(
              label: 'Open file',
              icon: Icons.file_open_outlined,
              onSelected: () => openViewerFiles(context, ref),
            ),
            PickerAction(
              label: 'Open folder',
              icon: Icons.folder_open_outlined,
              onSelected: () => openViewerFolder(context, ref),
            ),
          ],
        ),
        if (recents.isNotEmpty) ...[
          const SizedBox(height: SeguiSpacing.xl),
          ViewerSectionHeader(
            title: 'Recent',
            action: TextButton(
              onPressed: ref.read(viewerRecentsProvider.notifier).clear,
              child: const Text('Clear'),
            ),
          ),
          for (final ViewerRecent recent in recents)
            ViewerRecentTile(recent: recent),
        ],
      ],
    );
  }
}

/// Muted section title with an optional action at the end.
class ViewerSectionHeader extends StatelessWidget {
  const ViewerSectionHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

/// A recent file or folder. Tapping it opens it again.
class ViewerRecentTile extends ConsumerWidget {
  const ViewerRecentTile({super.key, required this.recent});

  final ViewerRecent recent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: recent.isFolder
          ? Icon(Icons.folder_outlined, color: getIconColor(context))
          : CostumFileIcon(
              file: File(recent.path),
              iconColor: getIconColor(context),
            ),
      title: Text(recent.name, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        p.dirname(recent.path),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        tooltip: 'Remove from recent',
        icon: const Icon(Icons.close_rounded),
        onPressed: () =>
            ref.read(viewerRecentsProvider.notifier).remove(recent),
      ),
      onTap: () => _reopen(context, ref),
    );
  }

  Future<void> _reopen(BuildContext context, WidgetRef ref) async {
    if (!recent.exists) {
      ref.read(viewerRecentsProvider.notifier).remove(recent);
      showViewerMessage(context, 'Open ${recent.name} again to view it');
      return;
    }
    final ViewerFiles files = ref.read(viewerFilesProvider.notifier);
    if (recent.isFolder) {
      await files.addFolder(Directory(recent.path));
      return;
    }
    final File file = File(recent.path);
    files.addFiles([file]);
    await openFileView(context, file, siblings: ref.read(viewerFilesProvider));
  }
}

/// Opened files with a filter, a button to step through every alignment,
/// and a tile per file that opens its viewer.
class ViewerFileList extends ConsumerStatefulWidget {
  const ViewerFileList({super.key, required this.files});

  final List<File> files;

  @override
  ConsumerState<ViewerFileList> createState() => _ViewerFileListState();
}

class _ViewerFileListState extends ConsumerState<ViewerFileList> {
  final TextEditingController _filter = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<File> files = widget.files;
    final String query = _filter.text.trim().toLowerCase();
    final List<File> shown = query.isEmpty
        ? files
        : files
            .where((f) => p.basename(f.path).toLowerCase().contains(query))
            .toList();
    final int count = files.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ViewerSectionHeader(
          title: '${formatCount(count)} ${count == 1 ? 'file' : 'files'}',
          action: TextButton(
            onPressed: () {
              _filter.clear();
              ref.read(viewerFilesProvider.notifier).clear();
            },
            child: const Text('Clear'),
          ),
        ),
        if (count >= _filterMin) ...[
          const SizedBox(height: SeguiSpacing.sm),
          TextField(
            controller: _filter,
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Filter by name',
            ),
          ),
        ],
        if (files.any(isAlignmentViewable)) ...[
          const SizedBox(height: SeguiSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: ViewAllSequencesButton(files: files),
          ),
        ],
        const SizedBox(height: SeguiSpacing.sm),
        Expanded(
          child: shown.isEmpty
              ? const Center(child: Text('No matching files'))
              : ListView.builder(
                  itemCount: shown.length,
                  itemBuilder: (context, index) =>
                      ViewerFileTile(file: shown[index], siblings: files),
                ),
        ),
      ],
    );
  }
}

/// An opened file. Tapping it opens its viewer; the info button shows what
/// it holds.
class ViewerFileTile extends ConsumerWidget {
  const ViewerFileTile({
    super.key,
    required this.file,
    required this.siblings,
  });

  final File file;
  final List<File> siblings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FileIconType format = FileIconType.fromFileName(file.path);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CostumFileIcon(file: file, iconColor: getIconColor(context)),
      title: Text(p.basename(file.path), overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${format.label} · ${p.basename(p.dirname(file.path))}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Details',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => showResponsiveSheet<void>(
              context: context,
              builder: (context) => SheetContent(
                title: p.basename(file.path),
                child: FileInspectionDetails(file: file, siblings: siblings),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.close_rounded),
            onPressed: () =>
                ref.read(viewerFilesProvider.notifier).remove(file),
          ),
        ],
      ),
      onTap: () => openFileView(context, file, siblings: siblings),
    );
  }
}
