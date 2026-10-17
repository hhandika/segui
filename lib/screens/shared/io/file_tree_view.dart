import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/screens/shared/io/file_list.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/services/io/file_tree.dart';
import 'package:segui/styles/design_tokens.dart';

/// Indent of each nesting level in a [FileTreeView].
const double fileTreeIndent = 16;

/// Lists a [FileTree] by folder. Folders open and close on tap, and each
/// lists [fileListPageSize] files at a time. Small trees, and trees of
/// search results for [query], open every folder.
///
/// While [isSelecting], rows show checkboxes for the [selected] file paths
/// and report changes to [onSelectionChanged].
class FileTreeView extends StatefulWidget {
  const FileTreeView({
    super.key,
    required this.tree,
    required this.onFileTap,
    this.onFileLongPress,
    this.isSelecting = false,
    this.selected = const {},
    this.onSelectionChanged,
    this.query = '',
    this.trailingBuilder,
    this.bottomPadding = 8,
  });

  final FileTree tree;
  final ValueChanged<FileTreeFile> onFileTap;
  final ValueChanged<FileTreeFile>? onFileLongPress;
  final bool isSelecting;
  final Set<String> selected;

  /// Called with file paths and whether they are now selected.
  final void Function(Iterable<String> paths, bool isSelected)?
      onSelectionChanged;

  /// Search the [tree] was filtered by, if any.
  final String query;

  /// Builds the trailing widget of a file row outside selection.
  final Widget Function(BuildContext context, FileTreeFile file)?
      trailingBuilder;

  /// Space below the last row, such as room for a floating toolbar.
  final double bottomPadding;

  @override
  State<FileTreeView> createState() => _FileTreeViewState();
}

class _FileTreeViewState extends State<FileTreeView> {
  late Set<String> _expanded = _initialExpanded;
  final Map<String, int> _shownCounts = {};

  @override
  void didUpdateWidget(FileTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tree.root.path != widget.tree.root.path) {
      _expanded = _initialExpanded;
      _shownCounts.clear();
    } else if (oldWidget.query != widget.query) {
      // Search results open every folder that holds a match.
      _expanded = _initialExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<FileTreeRow> rows = widget.tree.rows(
      expanded: _expanded,
      shownCounts: _shownCounts,
      pageSize: fileListPageSize,
    );
    final int unsupported = widget.tree.unsupportedCount;
    final int leading = unsupported > 0 ? 1 : 0;
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
          SeguiSpacing.md, 0, SeguiSpacing.md, widget.bottomPadding),
      itemCount: rows.length + leading,
      itemBuilder: (context, index) {
        if (index < leading) {
          return UnsupportedFilesNote(count: unsupported);
        }
        final FileTreeRow row = rows[index - leading];
        return FileTreeGuides(
          depth: row.depth,
          child: switch (row) {
            FileTreeFolderRow() => FileTreeFolderHeader(
                folder: row.folder,
                isExpanded: row.isExpanded,
                isSelecting: widget.isSelecting,
                selection: _folderSelection(row.folder),
                onTap: () => _toggle(row.folder.path),
                onSelected: (isSelected) => widget.onSelectionChanged?.call(
                  row.folder.allFiles.map((e) => e.file.path),
                  isSelected,
                ),
              ),
            FileTreeFileRow() => FileBrowserTile(
                file: row.file,
                isSelecting: widget.isSelecting,
                isSelected: widget.selected.contains(row.file.file.path),
                trailing: widget.trailingBuilder?.call(context, row.file),
                onTap: () => widget.isSelecting
                    ? _toggleFile(row.file)
                    : widget.onFileTap(row.file),
                onLongPress: widget.isSelecting
                    ? null
                    : () => widget.onFileLongPress?.call(row.file),
                onSelected: (_) => _toggleFile(row.file),
              ),
            FileTreeMoreRow() => ShowMoreFilesButtons(
                remaining: row.remaining,
                onShowMore: () => _showMore(row.folderPath, row.remaining),
                onShowAll: () => _showMore(row.folderPath, row.remaining,
                    isShowingAll: true),
              ),
          },
        );
      },
    );
  }

  Set<String> get _initialExpanded {
    final FileTree tree = widget.tree;
    return widget.query.isNotEmpty || tree.root.fileCount <= fileListPageSize
        ? tree.root.folderPaths.toSet()
        : <String>{};
  }

  // Checked when every file is selected, empty when none is, and mixed
  // otherwise.
  bool? _folderSelection(FileTreeFolder folder) {
    int count = 0;
    int selected = 0;
    for (final FileTreeFile file in folder.allFiles) {
      count++;
      if (widget.selected.contains(file.file.path)) {
        selected++;
      }
    }
    if (selected == 0) {
      return false;
    }
    return selected == count ? true : null;
  }

  void _toggle(String path) {
    setState(() {
      if (!_expanded.remove(path)) {
        _expanded.add(path);
      }
    });
  }

  void _toggleFile(FileTreeFile file) {
    final String path = file.file.path;
    widget.onSelectionChanged?.call([path], !widget.selected.contains(path));
  }

  void _showMore(String path, int remaining, {bool isShowingAll = false}) {
    setState(() {
      final int shown = _shownCounts[path] ?? fileListPageSize;
      _shownCounts[path] =
          shown + (isShowingAll ? remaining : fileListPageSize);
    });
  }
}

/// Indents [child] by [depth] levels and draws a guide line for each, so
/// the files of a folder line up under it.
class FileTreeGuides extends StatelessWidget {
  const FileTreeGuides({super.key, required this.depth, required this.child});

  final int depth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (depth == 0) {
      return child;
    }
    return CustomPaint(
      painter: FileTreeGuidePainter(
        depth: depth,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      child: Padding(
        padding: EdgeInsets.only(left: depth * fileTreeIndent),
        child: child,
      ),
    );
  }
}

class FileTreeGuidePainter extends CustomPainter {
  const FileTreeGuidePainter({required this.depth, required this.color});

  final int depth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (int i = 0; i < depth; i++) {
      // Lines up with the chevron of the parent folder.
      final double x = i * fileTreeIndent + 20;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(FileTreeGuidePainter oldDelegate) {
    return oldDelegate.depth != depth || oldDelegate.color != color;
  }
}

/// Folder section header of a [FileTreeView] with its file count.
class FileTreeFolderHeader extends StatelessWidget {
  const FileTreeFolderHeader({
    super.key,
    required this.folder,
    required this.isExpanded,
    required this.isSelecting,
    required this.selection,
    required this.onTap,
    required this.onSelected,
  });

  final FileTreeFolder folder;
  final bool isExpanded;
  final bool isSelecting;

  /// Whether all, some (null), or none of the folder's files are selected.
  final bool? selection;
  final VoidCallback onTap;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int count = folder.fileCount;
    return InkWell(
      borderRadius: BorderRadius.circular(SeguiRadius.sm),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            SeguiSpacing.lg, SeguiSpacing.md, SeguiSpacing.md, SeguiSpacing.xs),
        child: Row(
          children: [
            Icon(
              isExpanded
                  ? Icons.expand_more_rounded
                  : Icons.chevron_right_rounded,
              size: SeguiControlSize.iconSmall,
            ),
            const SizedBox(width: SeguiSpacing.xs),
            Icon(
              isExpanded ? Icons.folder_open_outlined : Icons.folder_outlined,
              size: SeguiControlSize.iconSmall,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: SeguiSpacing.md),
            Flexible(
              child: Tooltip(
                message: folder.path,
                child: Text(
                  folder.name,
                  style: theme.textTheme.labelLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (folder.hasNewFiles) const NewFileBadge(),
            const SizedBox(width: SeguiSpacing.md),
            Text(
              count == 1 ? '1 file' : '$count files',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (isSelecting)
              Checkbox(
                tristate: true,
                value: selection,
                onChanged: (_) => onSelected(selection != true),
              )
            else
              const SizedBox(height: kMinInteractiveDimension),
          ],
        ),
      ),
    );
  }
}

/// File row of a [FileTreeView]: an icon tile, the name with its size and
/// date, and a checkbox while selecting.
class FileBrowserTile extends StatelessWidget {
  const FileBrowserTile({
    super.key,
    required this.file,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    required this.onSelected,
    this.onLongPress,
    this.trailing,
  });

  final FileTreeFile file;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool?> onSelected;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ListTile(
      minVerticalPadding: SeguiSpacing.xxs,
      selected: isSelecting && isSelected,
      selectedTileColor: colors.secondaryContainer,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SeguiRadius.md)),
      leading: FileIconTile(icon: FileIcon(file: file.file)),
      title: Row(
        children: [
          Flexible(child: FileIOTitle(file: file.file)),
          if (file.isNew) const NewFileBadge(),
        ],
      ),
      subtitle: FileIOSubtitle(file: file.file),
      trailing: isSelecting
          ? Checkbox(value: isSelected, onChanged: onSelected)
          : trailing,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

/// Marks a file, or a folder holding one, that a run created.
class NewFileBadge extends StatelessWidget {
  const NewFileBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'New',
      child: Icon(
        Icons.fiber_new_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// Note of the files left out of a [FileTreeView] because SEGUI does not
/// recognize their format.
class UnsupportedFilesNote extends StatelessWidget {
  const UnsupportedFilesNote({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          SeguiSpacing.xl, SeguiSpacing.xs, SeguiSpacing.xl, SeguiSpacing.md),
      child: Row(
        children: [
          Icon(Icons.visibility_off_outlined,
              size: SeguiControlSize.iconSmall, color: color),
          const SizedBox(width: SeguiSpacing.md),
          Expanded(
            child: Text(
              '$count unsupported ${count == 1 ? 'file' : 'files'} '
              'not shown',
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Folder that holds the files of a [FileTreeView].
class FileTreeRootHeader extends StatelessWidget {
  const FileTreeRootHeader({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.folder_outlined,
          size: SeguiControlSize.iconSmall,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: SeguiSpacing.md),
        Flexible(child: PathTextWithOverflow(path: path)),
      ],
    );
  }
}

/// Shown in place of a [FileTreeView] when a search matches no file.
class NoMatchingFiles extends StatelessWidget {
  const NoMatchingFiles({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return EmptyScreen(
      title: 'No matching files',
      description: 'No file name contains "$query".',
    );
  }
}
