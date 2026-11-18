import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io/export_view.dart';
import 'package:segui/screens/shared/io/file_list.dart';
import 'package:segui/screens/shared/io/file_tree_view.dart';
import 'package:segui/screens/shared/io/info.dart';
import 'package:segui/screens/viewers/common.dart';
import 'package:segui/services/io/data_usage.dart';
import 'package:segui/services/io/export.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/providers/data_usage.dart';
import 'package:segui/services/types.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

/// Lists the [rows] of a [DataUsageTree] in a card no taller than its
/// rows. Folders open and close through [onToggle]. While [selection] is
/// set, rows show checkboxes; a long press on any row picks it.
class DataUsageTreeCard extends StatelessWidget {
  const DataUsageTreeCard({
    super.key,
    required this.rows,
    required this.onToggle,
    required this.onSelectFolder,
    required this.onSelectFile,
    this.selection,
  });

  final List<DataUsageRow> rows;
  final ValueChanged<String> onToggle;
  final ValueChanged<DataUsageFolder> onSelectFolder;
  final ValueChanged<DataUsageFile> onSelectFile;

  /// Picked folders and files, or null outside selection.
  final DataUsageSelection? selection;

  @override
  Widget build(BuildContext context) {
    return DataUsageCard(
      child: ListView.builder(
        // Sized to the rows, so a short list leaves no empty card below.
        shrinkWrap: true,
        padding: const EdgeInsets.all(SeguiSpacing.xs),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final DataUsageRow row = rows[index];
          final DataUsageSelection? selection = this.selection;
          return FileTreeGuides(
            depth: row.depth,
            child: switch (row) {
              DataUsageFolderRow() => DataUsageFolderTile(
                  folder: row.folder,
                  isExpanded: row.isExpanded,
                  selection: selection?.folderState(row.folder),
                  isSelecting: selection != null,
                  onTap: () => onToggle(row.folder.path),
                  onSelected: () => onSelectFolder(row.folder),
                ),
              DataUsageFileRow() => DataUsageFileTile(
                  file: row.file,
                  isSelecting: selection != null,
                  isSelected: selection?.isFileSelected(row.file) ?? false,
                  onSelected: () => onSelectFile(row.file),
                ),
              DataUsageEmptyRow() => const DataUsageEmptyTile(),
            },
          );
        },
      ),
    );
  }
}

/// Outlined card shared by the data usage summary and tree.
class DataUsageCard extends StatelessWidget {
  const DataUsageCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(SeguiFormLayout.cardRadius),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

/// Folder row with its item count, last change, and total size. Ends in an
/// action menu, or a checkbox while selecting.
class DataUsageFolderTile extends StatelessWidget {
  const DataUsageFolderTile({
    super.key,
    required this.folder,
    required this.isExpanded,
    required this.onTap,
    required this.onSelected,
    this.isSelecting = false,
    this.selection = false,
  });

  final DataUsageFolder folder;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onSelected;
  final bool isSelecting;

  /// Whether all, some (null), or none of the folder is picked.
  final bool? selection;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color muted = colors.onSurfaceVariant;
    return Material(
      color: isSelecting && selection == true
          ? colors.secondaryContainer
          : Colors.transparent,
      borderRadius: BorderRadius.circular(SeguiRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(SeguiRadius.md),
        onTap: onTap,
        onLongPress: onSelected,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              SeguiSpacing.md, SeguiSpacing.sm, 0, SeguiSpacing.sm),
          child: Row(
            children: [
              Icon(
                isExpanded
                    ? Icons.expand_more_rounded
                    : Icons.chevron_right_rounded,
                size: SeguiControlSize.iconSmall,
                color: muted,
              ),
              const SizedBox(width: SeguiSpacing.sm),
              Icon(
                isExpanded ? Icons.folder_open_outlined : Icons.folder_outlined,
                size: SeguiControlSize.iconMedium,
                color: folder.isEmpty ? muted : colors.primary,
              ),
              const SizedBox(width: SeguiSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      style: theme.textTheme.labelLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _details,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: SeguiSpacing.md),
              DataUsageSizeLabel(size: folder.size, isEmpty: folder.isEmpty),
              if (isSelecting)
                Checkbox(
                  tristate: true,
                  value: selection,
                  onChanged: (_) => onSelected(),
                )
              else
                DataUsageActionMenu(
                  entity: folder.directory,
                  name: folder.name,
                  files: [for (final file in folder.allFiles) file.file],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String get _details {
    if (folder.isEmpty) {
      return 'Empty';
    }
    final int count = folder.itemCount;
    final String items = count == 1 ? '1 item' : '$count items';
    return '$items · ${DateFormat.yMMMd().format(folder.modified)}';
  }
}

/// File row with its last change and size. Opens the file on tap, or picks
/// it while selecting.
class DataUsageFileTile extends StatelessWidget {
  const DataUsageFileTile({
    super.key,
    required this.file,
    required this.onSelected,
    this.isSelecting = false,
    this.isSelected = false,
  });

  final DataUsageFile file;
  final VoidCallback onSelected;
  final bool isSelecting;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      minVerticalPadding: SeguiSpacing.xs,
      contentPadding: const EdgeInsets.only(left: SeguiSpacing.xs),
      horizontalTitleGap: SeguiSpacing.lg,
      selected: isSelecting && isSelected,
      selectedTileColor: theme.colorScheme.secondaryContainer,
      selectedColor: theme.colorScheme.onSecondaryContainer,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SeguiRadius.md)),
      leading: FileIconTile(icon: FileIcon(file: file.file)),
      title: Text(
        file.name,
        style: theme.textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        DateFormat.yMMMd().add_jm().format(file.modified),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DataUsageSizeLabel(size: file.size),
          if (isSelecting)
            Checkbox(value: isSelected, onChanged: (_) => onSelected())
          else
            DataUsageActionMenu(
              entity: file.file,
              name: file.name,
              files: [file.file],
            ),
        ],
      ),
      onTap: isSelecting ? onSelected : () => openFileView(context, file.file),
      onLongPress: onSelected,
    );
  }
}

/// Contents of an open folder that holds nothing.
class DataUsageEmptyTile extends StatelessWidget {
  const DataUsageEmptyTile({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SeguiSpacing.md,
        vertical: SeguiSpacing.md,
      ),
      child: Text(
        'No files',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

/// Size of a folder or file, lined up at the end of its row.
class DataUsageSizeLabel extends StatelessWidget {
  const DataUsageSizeLabel({
    super.key,
    required this.size,
    this.isEmpty = false,
  });

  final int size;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      _label,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  // Sizes under 1 KB show in bytes rather than as 0.00 Kb.
  String get _label {
    if (isEmpty) {
      return '—';
    }
    return size < 1024 ? '$size B' : FileUtils().formatSize(size);
  }
}

/// What a [DataUsageActionMenu] can do with a folder or file.
enum DataUsageAction {
  share('Share', Icons.share_outlined),
  export('Export', Icons.archive_outlined),
  openInApp('Open in app', Icons.open_in_new),
  details('Details', Icons.info_outline_rounded),
  delete('Delete', Icons.delete_outline_rounded);

  const DataUsageAction(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Actions for a folder or file of the data usage tree: a bottom sheet on
/// phones and a pop-up menu elsewhere.
class DataUsageActionMenu extends ConsumerWidget {
  const DataUsageActionMenu({
    super.key,
    required this.entity,
    required this.name,
    required this.files,
  });

  /// The folder or file the actions apply to.
  final FileSystemEntity entity;
  final String name;

  /// Every file in [entity], or the file itself.
  final List<File> files;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<DataUsageAction> actions = _actions;
    if (isPhoneScreen(context)) {
      return IconButton(
        tooltip: 'Actions',
        icon: Icon(Icons.adaptive.more_rounded),
        onPressed: () async {
          final DataUsageAction? action =
              await showModalBottomSheet<DataUsageAction>(
            context: context,
            builder: (context) => DataUsageActionSheet(
              title: name,
              actions: actions,
            ),
          );
          if (action != null && context.mounted) {
            await _run(context, ref, action);
          }
        },
      );
    }
    return PopupMenuButton<DataUsageAction>(
      tooltip: 'Actions',
      onSelected: (action) => _run(context, ref, action),
      itemBuilder: (context) => [
        for (final DataUsageAction action in actions) ...[
          if (action == DataUsageAction.delete && action != actions.first)
            const PopupMenuDivider(),
          PopupMenuItem(
            value: action,
            child: DataUsageActionLabel(action: action),
          ),
        ],
      ],
    );
  }

  bool get _isFolder => entity is Directory;

  List<DataUsageAction> get _actions {
    final bool isDesktop = runningPlatform == PlatformType.isDesktop;
    return [
      if (_isFolder && files.isNotEmpty) DataUsageAction.export,
      if (!_isFolder && canShareFiles) DataUsageAction.share,
      if (!_isFolder && isDesktop) DataUsageAction.openInApp,
      if (!_isFolder) DataUsageAction.details,
      DataUsageAction.delete,
    ];
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    DataUsageAction action,
  ) async {
    // Read before any await, since a delete removes this row.
    final DataUsage usage = ref.read(dataUsageProvider.notifier);
    switch (action) {
      case DataUsageAction.share:
        await IOServices().shareFile(context, files.single);
      case DataUsageAction.export:
        await exportDataUsageFiles(context, files);
      case DataUsageAction.openInApp:
        await _openInApp(context);
      case DataUsageAction.details:
        await showResponsiveSheet(
          context: context,
          builder: (context) => FileInfoScreen(file: files.single),
        );
      case DataUsageAction.delete:
        final bool? isConfirmed = await showResponsiveSheet<bool>(
          context: context,
          builder: (context) => DataUsageDeleteAlert.entry(
            name: name,
            isFolder: _isFolder,
            fileCount: files.length,
          ),
        );
        if (isConfirmed == true) {
          await usage.delete([entity], files);
        }
    }
  }

  Future<void> _openInApp(BuildContext context) async {
    final UrlLauncherServices launcher =
        UrlLauncherServices(file: files.single);
    try {
      if (await launcher.canLaunch()) {
        await launcher.launchExternalApp();
        return;
      }
    } catch (_) {
      // Shown below like a file no app can open.
    }
    if (context.mounted) {
      _showMessage(context, 'No app found to open this file.');
    }
  }

  void _showMessage(BuildContext context, String message) {
    showDataUsageMessage(context, message);
  }
}

/// Bottom sheet listing the [actions] for [title]. Pops with the chosen
/// action.
class DataUsageActionSheet extends StatelessWidget {
  const DataUsageActionSheet({
    super.key,
    required this.title,
    required this.actions,
  });

  final String title;
  final List<DataUsageAction> actions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(SeguiSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  SeguiSpacing.xl, 0, SeguiSpacing.xl, SeguiSpacing.md),
              child: Text(
                title,
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            for (final DataUsageAction action in actions) ...[
              if (action == DataUsageAction.delete && action != actions.first)
                const CommonDivider(),
              ListTile(
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.all(Radius.circular(SeguiRadius.lg)),
                ),
                title: DataUsageActionLabel(action: action),
                onTap: () => Navigator.of(context).pop(action),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Icon and label of a [DataUsageAction], in the error color for Delete.
class DataUsageActionLabel extends StatelessWidget {
  const DataUsageActionLabel({super.key, required this.action});

  final DataUsageAction action;

  @override
  Widget build(BuildContext context) {
    final Color? color = action == DataUsageAction.delete
        ? Theme.of(context).colorScheme.error
        : null;
    return Row(
      children: [
        Icon(action.icon, color: color),
        const SizedBox(width: SeguiSpacing.lg),
        Text(action.label, style: TextStyle(color: color)),
      ],
    );
  }
}

/// Asks before deleting folders and files from the app data.
class DataUsageDeleteAlert extends StatelessWidget {
  const DataUsageDeleteAlert({
    super.key,
    required this.title,
    required this.message,
  });

  /// Asks before deleting one folder with its files, or one file.
  factory DataUsageDeleteAlert.entry({
    Key? key,
    required String name,
    required bool isFolder,
    required int fileCount,
  }) {
    final String files = fileCount == 1 ? '1 file' : '$fileCount files';
    return DataUsageDeleteAlert(
      key: key,
      title: isFolder ? 'Delete folder?' : 'Delete file?',
      message: switch ((isFolder, fileCount)) {
        (false, _) => 'Deletes $name permanently.',
        (true, 0) => 'Deletes the empty folder $name.',
        _ => 'Deletes $name and its $files permanently.',
      },
    );
  }

  /// Asks before deleting [count] picked folders and files.
  factory DataUsageDeleteAlert.selection({
    Key? key,
    required int count,
    required int fileCount,
  }) {
    final String items = count == 1 ? '1 item' : '$count items';
    final String files = fileCount == 1 ? '1 file' : '$fileCount files';
    return DataUsageDeleteAlert(
      key: key,
      title: 'Delete $items?',
      message: 'Deletes the selected folders and $files permanently.',
    );
  }

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SheetContent(
      title: title,
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
      child: Text(message),
    );
  }
}

/// Asks for an archive format, then saves or shares [files] as one
/// compressed archive that keeps their folders.
Future<void> exportDataUsageFiles(
  BuildContext context,
  List<File> files,
) async {
  final ExportRequest? request = await showResponsiveSheet<ExportRequest>(
    context: context,
    builder: (context) => ExportFilesSheet(
      count: files.length,
      canShare: canShareFiles,
    ),
  );
  if (request == null) {
    return;
  }
  final FileExportServices exporter =
      FileExportServices(files: files, format: request.format);
  try {
    if (request.isSharing) {
      final File archive = await exporter.writeTemp();
      if (context.mounted) {
        await IOServices().shareFile(context, archive);
      }
      return;
    }
    final String? savedPath = await exporter.save();
    if (savedPath != null && context.mounted) {
      showDataUsageMessage(context, 'Exported to $savedPath');
    }
  } catch (e) {
    if (context.mounted) {
      showDataUsageMessage(context, 'Export failed: $e');
    }
  }
}

void showDataUsageMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
      .showSnackBar(showSharedSnackBar(context, message));
}
