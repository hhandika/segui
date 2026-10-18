import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/io/file_list.dart';
import 'package:segui/screens/shared/io/file_tree_view.dart';
import 'package:segui/services/io/file_tree.dart';
import 'package:segui/styles/design_tokens.dart';

/// Action on the files selected in a [FileBrowser].
@immutable
class FileBrowserAction {
  const FileBrowserAction({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.isDestructive = false,
    this.isSingleFile = false,
  });

  final String label;
  final IconData icon;

  /// Runs the action on the selected files. Returns whether the selection
  /// is done, so the browser leaves selection.
  final Future<bool> Function(BuildContext context, List<File> files)
      onSelected;
  final bool isDestructive;

  /// Whether the action takes one file, so it shows only then.
  final bool isSingleFile;
}

/// Files listed by folder with a selection mode, and a search field once
/// there are more than [fileListPageSize] files.
///
/// Above the tree, Select switches to selection, where Select all and
/// Clear all sit on the left and Done on the right. While selecting, a
/// toolbar docked under the tree runs [actions] on the selected files, so
/// it never covers a row.
class FileBrowser extends StatefulWidget {
  const FileBrowser({
    super.key,
    required this.files,
    required this.actions,
    required this.onFileTap,
    required this.emptyChild,
    this.rootPath,
    this.header,
    this.trailingBuilder,
  });

  final List<FileTreeFile> files;
  final List<FileBrowserAction> actions;
  final ValueChanged<FileTreeFile> onFileTap;

  /// Shown when there are no files to list.
  final Widget emptyChild;

  /// Folder the tree starts from. Defaults to the folder all files share.
  final String? rootPath;

  /// Shown between the toolbar and the tree.
  final Widget? header;

  /// Builds the trailing widget of a file row outside selection.
  final Widget Function(BuildContext context, FileTreeFile file)?
      trailingBuilder;

  @override
  State<FileBrowser> createState() => _FileBrowserState();
}

class _FileBrowserState extends State<FileBrowser> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  bool _isSelecting = false;
  final Set<String> _selected = {};

  @override
  void didUpdateWidget(FileBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Files removed elsewhere leave the selection.
    final Set<String> paths = widget.files.map((e) => e.file.path).toSet();
    _selected.retainAll(paths);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The root stays put while searching, so folders keep their place.
    final String rootPath = widget.rootPath ??
        commonDirectory(widget.files
            .where((e) => isSupportedFile(e.file.path))
            .map((e) => e.file.path));
    final FileTree allFiles =
        FileTree.fromFiles(widget.files, rootPath: rootPath);
    // Short lists fit on screen, so search shows only past one page.
    final bool canSearch = allFiles.root.fileCount > fileListPageSize;
    final String query = canSearch ? _query : '';
    final FileTree tree = query.isEmpty
        ? allFiles
        : FileTree.fromFiles(widget.files, rootPath: rootPath, query: query);
    final bool hasFiles = !allFiles.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canSearch) ...[
          FileSearchField(
            controller: _search,
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
          const SizedBox(height: SeguiSpacing.xs),
        ],
        FileSelectionBar(
          isSelecting: _isSelecting,
          rootPath: rootPath,
          canSelect: hasFiles,
          onSelect: () => setState(() => _isSelecting = true),
          onDone: _endSelection,
          onSelectAll: () => setState(() {
            _selected.addAll(tree.root.allFiles.map((e) => e.file.path));
          }),
          onClearAll: () => setState(_selected.clear),
        ),
        if (widget.header != null) widget.header!,
        Expanded(
          child: _hasNoRows(tree, hasFiles)
              ? (hasFiles && query.isNotEmpty
                  ? NoMatchingFiles(query: query)
                  : widget.emptyChild)
              : FileTreeView(
                  tree: tree,
                  query: query,
                  isSelecting: _isSelecting,
                  selected: _selected,
                  trailingBuilder: widget.trailingBuilder,
                  onFileTap: widget.onFileTap,
                  onFileLongPress: (file) => setState(() {
                    _isSelecting = true;
                    _selected.add(file.file.path);
                  }),
                  onSelectionChanged: _changeSelection,
                ),
        ),
        if (_isSelecting)
          FileActionToolbar(
            count: _selected.length,
            actions: widget.actions,
            onSelected: _runAction,
          ),
      ],
    );
  }

  // An empty tree still shows its note of unsupported files.
  bool _hasNoRows(FileTree tree, bool hasFiles) {
    return tree.isEmpty && (tree.unsupportedCount == 0 || !hasFiles);
  }

  void _changeSelection(Iterable<String> paths, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selected.addAll(paths);
      } else {
        _selected.removeAll(paths);
      }
    });
  }

  void _endSelection() {
    setState(() {
      _isSelecting = false;
      _selected.clear();
    });
  }

  Future<void> _runAction(FileBrowserAction action) async {
    final List<File> files = _selected.map(File.new).toList();
    final bool isDone = await action.onSelected(context, files);
    if (isDone && mounted) {
      _endSelection();
    }
  }
}

/// Rounded search field that filters files by name.
class FileSearchField extends StatelessWidget {
  const FileSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search files',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
            filled: true,
            fillColor: colors.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SeguiRadius.full),
              borderSide: BorderSide.none,
            ),
          ),
        );
      },
    );
  }
}

/// Row under the search field. Outside selection it shows the root folder
/// and Select. While selecting it shows Select all and Clear all on the
/// left and Done on the right.
class FileSelectionBar extends StatelessWidget {
  const FileSelectionBar({
    super.key,
    required this.isSelecting,
    required this.rootPath,
    required this.canSelect,
    required this.onSelect,
    required this.onDone,
    required this.onSelectAll,
    required this.onClearAll,
  });

  final bool isSelecting;
  final String? rootPath;
  final bool canSelect;
  final VoidCallback onSelect;
  final VoidCallback onDone;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final String? root = rootPath;
    // Compact buttons keep the bar one short row.
    const VisualDensity density = VisualDensity.compact;
    return SizedBox(
      height: SeguiControlSize.control,
      child: Row(
        children: [
          if (isSelecting) ...[
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(visualDensity: density),
                      onPressed: onSelectAll,
                      child: const Text('Select all'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(visualDensity: density),
                      onPressed: onClearAll,
                      child: const Text('Clear all'),
                    ),
                  ],
                ),
              ),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(visualDensity: density),
              onPressed: onDone,
              child: const Text('Done'),
            ),
          ] else ...[
            Expanded(
              child: root == null || root.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(left: SeguiSpacing.md),
                      child: FileTreeRootHeader(path: root),
                    ),
            ),
            if (canSelect)
              TextButton(
                style: TextButton.styleFrom(visualDensity: density),
                onPressed: onSelect,
                child: const Text('Select'),
              ),
          ],
        ],
      ),
    );
  }
}

/// Flat, compact toolbar centered under the file tree. Actions sit on the
/// left, destructive actions alone on the right, and the selection count
/// between them behind dividers, so a destructive action is hard to tap by
/// accident.
class FileActionToolbar extends StatelessWidget {
  const FileActionToolbar({
    super.key,
    required this.count,
    required this.actions,
    required this.onSelected,
  });

  /// Narrowest toolbar that shows labels on the non-destructive actions.
  static const double labelWidth = 420;

  /// Narrowest toolbar that shows the label on destructive actions.
  static const double destructiveLabelWidth = 300;

  final int count;
  final List<FileBrowserAction> actions;
  final ValueChanged<FileBrowserAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final List<FileBrowserAction> available = count == 0
        ? const []
        : actions.where((e) => !e.isSingleFile || count == 1).toList();
    final List<FileBrowserAction> actionsStart =
        available.where((e) => !e.isDestructive).toList();
    final List<FileBrowserAction> actionsEnd =
        available.where((e) => e.isDestructive).toList();
    // Labels show only when the panel has room, and the toolbar shrinks to
    // its buttons instead of spanning the panel.
    return LayoutBuilder(builder: (context, constraints) {
      final bool showLabels = constraints.maxWidth >= labelWidth;
      return Padding(
        padding: const EdgeInsets.only(top: SeguiSpacing.xs),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(SeguiRadius.full),
            ),
            child: Padding(
              padding: const EdgeInsets.all(SeguiSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final FileBrowserAction action in actionsStart)
                    FileActionButton(
                      action: action,
                      showLabel: showLabels,
                      onPressed: () => onSelected(action),
                    ),
                  if (actionsStart.isNotEmpty) const FileActionDivider(),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SeguiSpacing.lg,
                      ),
                      child: Text(
                        count == 0 ? 'Select files' : '$count selected',
                        style: theme.textTheme.labelLarge,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (actionsEnd.isNotEmpty) const FileActionDivider(),
                  for (final FileBrowserAction action in actionsEnd)
                    FileActionButton(
                      action: action,
                      showLabel: constraints.maxWidth >= destructiveLabelWidth,
                      onPressed: () => onSelected(action),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Short vertical line between the groups of a [FileActionToolbar].
class FileActionDivider extends StatelessWidget {
  const FileActionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: SeguiControlSize.iconMedium,
      child: VerticalDivider(
        width: SeguiSpacing.xs,
        thickness: SeguiStroke.thin,
      ),
    );
  }
}

/// Flat toolbar button for a [FileBrowserAction], in the error color when
/// destructive, kept as narrow as its content. Without a label it shows the
/// icon with a tooltip.
class FileActionButton extends StatelessWidget {
  const FileActionButton({
    super.key,
    required this.action,
    required this.showLabel,
    required this.onPressed,
  });

  final FileBrowserAction action;
  final bool showLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color? color = action.isDestructive ? colors.error : null;
    if (!showLabel) {
      return IconButton(
        tooltip: action.label,
        color: color,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(action.icon),
      );
    }
    // Sized to its label, so the button never stretches.
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: color,
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(0, SeguiControlSize.control),
        padding: const EdgeInsets.symmetric(horizontal: SeguiSpacing.md),
      ),
      onPressed: onPressed,
      icon: Icon(action.icon),
      label: Text(action.label),
    );
  }
}
