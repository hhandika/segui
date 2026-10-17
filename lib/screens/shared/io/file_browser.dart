import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/io/file_tree_view.dart';
import 'package:segui/services/io/file_tree.dart';

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

/// Files listed by folder with a search field and a selection mode.
///
/// Above the tree, Select switches to selection, where Select all and
/// Clear all sit on the left and Done on the right. While selecting, a
/// floating toolbar at the bottom runs [actions] on the selected files.
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
    final FileTree tree = _query.isEmpty
        ? allFiles
        : FileTree.fromFiles(widget.files, rootPath: rootPath, query: _query);
    final bool hasFiles = !allFiles.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: FileSearchField(
            controller: _search,
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
        ),
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
          child: Stack(
            children: [
              Positioned.fill(
                child: _hasNoRows(tree, hasFiles)
                    ? (hasFiles && _query.isNotEmpty
                        ? NoMatchingFiles(query: _query)
                        : widget.emptyChild)
                    : FileTreeView(
                        tree: tree,
                        query: _query,
                        isSelecting: _isSelecting,
                        selected: _selected,
                        trailingBuilder: widget.trailingBuilder,
                        bottomPadding: _isSelecting ? 88 : 8,
                        onFileTap: widget.onFileTap,
                        onFileLongPress: (file) => setState(() {
                          _isSelecting = true;
                          _selected.add(file.file.path);
                        }),
                        onSelectionChanged: _changeSelection,
                      ),
              ),
              if (_isSelecting)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FileActionToolbar(
                    count: _selected.length,
                    actions: widget.actions,
                    onSelected: _runAction,
                  ),
                ),
            ],
          ),
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
              borderRadius: BorderRadius.circular(28),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (isSelecting) ...[
            TextButton(onPressed: onSelectAll, child: const Text('Select all')),
            TextButton(onPressed: onClearAll, child: const Text('Clear all')),
            const Spacer(),
            FilledButton.tonal(onPressed: onDone, child: const Text('Done')),
          ] else ...[
            Expanded(
              child: root == null || root.isEmpty
                  ? const SizedBox.shrink()
                  : FileTreeRootHeader(path: root),
            ),
            if (canSelect)
              TextButton(onPressed: onSelect, child: const Text('Select'))
            else
              const SizedBox(height: kMinInteractiveDimension),
          ],
        ],
      ),
    );
  }
}

/// Floating toolbar with the selection count and the actions for it.
class FileActionToolbar extends StatelessWidget {
  const FileActionToolbar({
    super.key,
    required this.count,
    required this.actions,
    required this.onSelected,
  });

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Material(
        color: colors.surfaceContainerHighest,
        elevation: 3,
        shape: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  count == 0 ? 'Select files' : '$count selected',
                  style: theme.textTheme.labelLarge,
                ),
              ),
              for (final FileBrowserAction action in available)
                action.isDestructive
                    ? FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.errorContainer,
                          foregroundColor: colors.onErrorContainer,
                        ),
                        onPressed: () => onSelected(action),
                        icon: Icon(action.icon),
                        label: Text(action.label),
                      )
                    : TextButton.icon(
                        onPressed: () => onSelected(action),
                        icon: Icon(action.icon),
                        label: Text(action.label),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}
