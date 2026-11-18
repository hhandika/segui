import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/settings/data_usage_tree.dart';
import 'package:segui/screens/settings/settings_layout.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/services/io/data_usage.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/providers/data_usage.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

class DataUsageScreen extends StatelessWidget {
  const DataUsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data usage'),
        backgroundColor: getSEGULBackgroundColor(context),
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: const SafeArea(child: DataUsageView()),
    );
  }
}

/// Folders and files in SEGUI's data folder as a tree that opens and
/// closes, with their total size. In select mode, picked folders and files
/// can be exported as one archive or deleted together.
class DataUsageView extends ConsumerStatefulWidget {
  const DataUsageView({super.key});

  @override
  ConsumerState<DataUsageView> createState() => _DataUsageViewState();
}

class _DataUsageViewState extends ConsumerState<DataUsageView> {
  DataUsageSort _sort = DataUsageSort.size;
  Set<String> _expanded = {};

  /// Picked folders and files, or null outside select mode.
  DataUsageSelection? _selection;

  @override
  Widget build(BuildContext context) {
    final bool isPhone = isPhoneScreen(context);
    // The app bar names the page on phones.
    return Padding(
      padding: EdgeInsets.all(
        isPhone ? SeguiPageMargin.compact : SeguiPageMargin.regular,
      ),
      child: ref.watch(dataUsageProvider).when(
            skipLoadingOnReload: true,
            data: (tree) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isPhone) ...[
                  const SettingsPageHeader(title: 'Data usage'),
                  const SizedBox(height: SeguiSpacing.xl),
                ],
                DataUsageSummary(tree: tree),
                const SizedBox(height: SeguiSpacing.lg),
                if (tree.isEmpty)
                  const DataUsageEmpty()
                else ...[
                  if (_selection case final DataUsageSelection selection)
                    DataUsageSelectionBar(
                      count: selection.entities(tree).length,
                      isAllSelected: _isAllSelected(tree, selection),
                      onClose: _endSelection,
                      onSelectAll: () => _toggleSelectAll(tree, selection),
                    )
                  else
                    DataUsageToolbar(
                      sort: _sort,
                      hasFolders: tree.folderCount > 0,
                      isAllExpanded: _isAllExpanded(tree),
                      onSort: (sort) => setState(() => _sort = sort),
                      onToggleAll: () => _toggleAll(tree),
                      onSelect: () => setState(
                        () => _selection = const DataUsageSelection(),
                      ),
                    ),
                  const SizedBox(height: SeguiSpacing.md),
                  Expanded(
                    // Top aligned, so the card ends after its last row and
                    // the select mode actions stay at the bottom.
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: DataUsageTreeCard(
                        rows: tree.rows(expanded: _expanded, sort: _sort),
                        selection: _selection,
                        onToggle: _toggle,
                        onSelectFolder: (folder) =>
                            _pick((s) => s.toggleFolder(tree, folder)),
                        onSelectFile: (file) =>
                            _pick((s) => s.toggleFile(tree, file)),
                      ),
                    ),
                  ),
                  if (_selection case final DataUsageSelection selection) ...[
                    const SizedBox(height: SeguiSpacing.md),
                    DataUsageSelectionActions(
                      onExport: selection.isEmpty
                          ? null
                          : () => _export(selection.files(tree)),
                      onDelete: selection.isEmpty
                          ? null
                          : () => _delete(tree, selection),
                    ),
                  ],
                ],
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Text(
                'Could not read app data: $error',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
    );
  }

  bool _isAllExpanded(DataUsageTree tree) {
    final Iterable<String> paths = tree.root.folderPaths;
    return paths.isNotEmpty && paths.every(_expanded.contains);
  }

  bool _isAllSelected(DataUsageTree tree, DataUsageSelection selection) {
    return selection.paths.length == DataUsageSelection.all(tree).paths.length;
  }

  void _toggle(String path) {
    setState(() {
      if (!_expanded.remove(path)) {
        _expanded.add(path);
      }
    });
  }

  void _toggleAll(DataUsageTree tree) {
    setState(() {
      _expanded =
          _isAllExpanded(tree) ? <String>{} : tree.root.folderPaths.toSet();
    });
  }

  // Picking a row outside select mode, by a long press, starts it.
  void _pick(DataUsageSelection Function(DataUsageSelection) change) {
    setState(() {
      _selection = change(_selection ?? const DataUsageSelection());
    });
  }

  void _toggleSelectAll(DataUsageTree tree, DataUsageSelection selection) {
    setState(() {
      _selection = _isAllSelected(tree, selection)
          ? const DataUsageSelection()
          : DataUsageSelection.all(tree);
    });
  }

  void _endSelection() {
    setState(() => _selection = null);
  }

  Future<void> _export(List<File> files) async {
    if (files.isEmpty) {
      showDataUsageMessage(context, 'The selected folders are empty.');
      return;
    }
    await exportDataUsageFiles(context, files);
  }

  Future<void> _delete(
    DataUsageTree tree,
    DataUsageSelection selection,
  ) async {
    final DataUsage usage = ref.read(dataUsageProvider.notifier);
    final List<FileSystemEntity> entities = selection.entities(tree);
    final List<File> files = selection.files(tree);
    final bool? isConfirmed = await showResponsiveSheet<bool>(
      context: context,
      builder: (context) => DataUsageDeleteAlert.selection(
        count: entities.length,
        fileCount: files.length,
      ),
    );
    if (isConfirmed != true) {
      return;
    }
    await usage.delete(entities, files);
    if (mounted) {
      _endSelection();
    }
  }
}

/// Total size, folder count, and file count of the app data, with the
/// action to clear it.
class DataUsageSummary extends StatelessWidget {
  const DataUsageSummary({super.key, required this.tree});

  final DataUsageTree tree;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int folders = tree.folderCount;
    final int files = tree.fileCount;
    return DataUsageCard(
      padding: const EdgeInsets.fromLTRB(
          SeguiSpacing.xl, SeguiSpacing.lg, SeguiSpacing.md, SeguiSpacing.lg),
      child: Row(
        children: [
          Container(
            width: SeguiControlSize.touchTarget,
            height: SeguiControlSize.touchTarget,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(SeguiRadius.md),
            ),
            child: Icon(
              Icons.data_usage_rounded,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: SeguiSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FileUtils().formatSize(tree.size),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${folders == 1 ? '1 folder' : '$folders folders'} · '
                  '${files == 1 ? '1 file' : '$files files'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const ClearAppDataButton(),
        ],
      ),
    );
  }
}

/// Current sort order with icon buttons to sort, open or close every
/// folder, and start select mode.
class DataUsageToolbar extends StatelessWidget {
  const DataUsageToolbar({
    super.key,
    required this.sort,
    required this.hasFolders,
    required this.isAllExpanded,
    required this.onSort,
    required this.onToggleAll,
    required this.onSelect,
  });

  final DataUsageSort sort;
  final bool hasFolders;
  final bool isAllExpanded;
  final ValueChanged<DataUsageSort> onSort;
  final VoidCallback onToggleAll;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      height: SeguiControlSize.touchTarget,
      child: Row(
        children: [
          const SizedBox(width: SeguiSpacing.xs),
          Expanded(
            child: Text(
              'Sorted by ${sort.label.toLowerCase()}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          DataUsageSortButton(sort: sort, onSort: onSort),
          if (hasFolders)
            IconButton(
              tooltip: isAllExpanded ? 'Collapse all' : 'Expand all',
              onPressed: onToggleAll,
              icon: Icon(isAllExpanded
                  ? Icons.unfold_less_rounded
                  : Icons.unfold_more_rounded),
            ),
          IconButton(
            tooltip: 'Select',
            onPressed: onSelect,
            icon: const Icon(Icons.checklist_rounded),
          ),
        ],
      ),
    );
  }
}

/// Replaces the toolbar in select mode: the picked count and select all.
class DataUsageSelectionBar extends StatelessWidget {
  const DataUsageSelectionBar({
    super.key,
    required this.count,
    required this.isAllSelected,
    required this.onClose,
    required this.onSelectAll,
  });

  final int count;
  final bool isAllSelected;
  final VoidCallback onClose;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Container(
      height: SeguiControlSize.touchTarget,
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(SeguiRadius.full),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Done',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: colors.onSecondaryContainer,
          ),
          Expanded(
            child: Text(
              count == 0 ? 'Select items' : '$count selected',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.onSecondaryContainer,
              ),
            ),
          ),
          IconButton(
            tooltip: isAllSelected ? 'Select none' : 'Select all',
            onPressed: onSelectAll,
            icon: Icon(
              isAllSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
            ),
            color: colors.onSecondaryContainer,
          ),
          const SizedBox(width: SeguiSpacing.xs),
        ],
      ),
    );
  }
}

/// Export and Delete for the picked folders and files, at opposite ends of
/// the bottom of the page in select mode.
class DataUsageSelectionActions extends StatelessWidget {
  const DataUsageSelectionActions({
    super.key,
    required this.onExport,
    required this.onDelete,
  });

  /// Null while nothing is picked.
  final VoidCallback? onExport;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    // Export and Delete sit at opposite ends, so a tap meant for one does
    // not land on the other.
    return Row(
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, SeguiControlSize.touchTarget),
          ),
          onPressed: onExport,
          icon: const Icon(Icons.archive_outlined),
          label: const Text('Export'),
        ),
        const Spacer(),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, SeguiControlSize.touchTarget),
            foregroundColor: colors.error,
            side: BorderSide(
              color: onDelete == null
                  ? colors.onSurface.withValues(alpha: 0.12)
                  : colors.error,
            ),
          ),
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Delete'),
        ),
      ],
    );
  }
}

/// Sort order picker: a bottom sheet on phones and a pop-up menu elsewhere.
class DataUsageSortButton extends StatelessWidget {
  const DataUsageSortButton({
    super.key,
    required this.sort,
    required this.onSort,
  });

  final DataUsageSort sort;
  final ValueChanged<DataUsageSort> onSort;

  @override
  Widget build(BuildContext context) {
    const Icon icon = Icon(Icons.sort_rounded);
    if (isPhoneScreen(context)) {
      return IconButton(
        tooltip: 'Sort',
        icon: icon,
        onPressed: () async {
          final DataUsageSort? choice =
              await showModalBottomSheet<DataUsageSort>(
            context: context,
            builder: (context) => DataUsageSortSheet(sort: sort),
          );
          if (choice != null) {
            onSort(choice);
          }
        },
      );
    }
    return PopupMenuButton<DataUsageSort>(
      tooltip: 'Sort',
      icon: icon,
      initialValue: sort,
      onSelected: onSort,
      itemBuilder: (context) => [
        for (final DataUsageSort option in DataUsageSort.values)
          CheckedPopupMenuItem(
            value: option,
            checked: option == sort,
            child: Text(option.label),
          ),
      ],
    );
  }
}

/// Bottom sheet of the sort orders. Pops with the chosen one.
class DataUsageSortSheet extends StatelessWidget {
  const DataUsageSortSheet({super.key, required this.sort});

  final DataUsageSort sort;

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
              child: Text('Sort by', style: theme.textTheme.titleMedium),
            ),
            for (final DataUsageSort option in DataUsageSort.values)
              ListTile(
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.all(Radius.circular(SeguiRadius.lg)),
                ),
                selected: option == sort,
                selectedTileColor: theme.colorScheme.secondaryContainer,
                selectedColor: theme.colorScheme.onSecondaryContainer,
                leading: Icon(_iconOf(option)),
                title: Text(option.label),
                trailing:
                    option == sort ? const Icon(Icons.check_rounded) : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
  }

  static IconData _iconOf(DataUsageSort option) {
    return switch (option) {
      DataUsageSort.size => Icons.storage_rounded,
      DataUsageSort.name => Icons.sort_by_alpha_rounded,
      DataUsageSort.recent => Icons.schedule_rounded,
    };
  }
}

/// Shown in place of the tree when the app data folder is empty.
class DataUsageEmpty extends StatelessWidget {
  const DataUsageEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color muted = theme.colorScheme.onSurfaceVariant;
    return DataUsageCard(
      padding: const EdgeInsets.all(SeguiSpacing.xxl),
      child: Column(
        children: [
          Icon(Icons.folder_off_outlined,
              size: SeguiControlSize.iconLarge, color: muted),
          const SizedBox(height: SeguiSpacing.md),
          Text('No app data', style: theme.textTheme.titleMedium),
          const SizedBox(height: SeguiSpacing.xs),
          Text(
            'Folders and files from your runs appear here.',
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ClearAppDataButton extends ConsumerWidget {
  const ClearAppDataButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return TextButton.icon(
      style: TextButton.styleFrom(foregroundColor: colors.error),
      onPressed: () async {
        final DataUsage usage = ref.read(dataUsageProvider.notifier);
        final bool? isConfirmed = await showResponsiveSheet<bool>(
          context: context,
          builder: (context) => const ClearAppDataAlert(),
        );
        if (isConfirmed == true) {
          await usage.clearAll();
        }
      },
      icon: const Icon(Icons.delete_sweep_outlined),
      label: const Text('Clear'),
    );
  }
}

/// Asks before deleting all app data.
class ClearAppDataAlert extends StatelessWidget {
  const ClearAppDataAlert({super.key});

  @override
  Widget build(BuildContext context) {
    return SheetContent(
      title: 'Clear all data',
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text('Clear all data'),
        ),
      ],
      child: const Text(
        'Delete all folders and files except the latest log file.',
      ),
    );
  }
}
