import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:segui/services/io/file.dart';

/// A file in a [FileTree], flagged when a run created it.
typedef FileTreeFile = ({File file, bool isNew});

/// Whether SEGUI recognizes the format of the file at [path], so it can
/// list the file with a matching icon.
bool isSupportedFile(String path) {
  return FileIconType.fromFileName(p.basename(path)) != FileIconType.unknown;
}

/// Deepest directory that holds every file in [paths], or an empty string
/// when they share none, such as files on different Windows drives. Paths
/// follow [context], the host platform's by default.
String commonDirectory(Iterable<String> paths, {p.Context? context}) {
  final p.Context path = context ?? p.context;
  List<String>? common;
  for (final String file in paths) {
    final List<String> parts = path.split(path.dirname(file));
    if (common == null) {
      common = parts;
      continue;
    }
    int length = 0;
    while (length < common.length &&
        length < parts.length &&
        common[length] == parts[length]) {
      length++;
    }
    common = common.sublist(0, length);
  }
  return common == null || common.isEmpty ? '' : path.joinAll(common);
}

/// A folder in a [FileTree] with its subfolders and files, both sorted by
/// name.
class FileTreeFolder {
  const FileTreeFolder({
    required this.name,
    required this.path,
    required this.folders,
    required this.files,
  });

  /// Folder name shown in the tree. A chain of folders that only hold one
  /// folder each is shown as one, such as `loci/nexus`.
  final String name;
  final String path;
  final List<FileTreeFolder> folders;
  final List<FileTreeFile> files;

  /// Number of files in this folder and its subfolders.
  int get fileCount {
    return folders.fold(files.length, (sum, e) => sum + e.fileCount);
  }

  /// Whether this folder or a subfolder holds a new file.
  bool get hasNewFiles {
    return files.any((e) => e.isNew) || folders.any((e) => e.hasNewFiles);
  }

  /// Files in this folder and its subfolders.
  Iterable<FileTreeFile> get allFiles sync* {
    for (final FileTreeFolder folder in folders) {
      yield* folder.allFiles;
    }
    yield* files;
  }

  /// Paths of every subfolder, at any depth.
  Iterable<String> get folderPaths sync* {
    for (final FileTreeFolder folder in folders) {
      yield folder.path;
      yield* folder.folderPaths;
    }
  }
}

/// A row of a [FileTree] as it is listed on screen.
sealed class FileTreeRow {
  const FileTreeRow({required this.depth});

  /// Nesting level below the root, which is 0.
  final int depth;
}

class FileTreeFolderRow extends FileTreeRow {
  const FileTreeFolderRow({
    required super.depth,
    required this.folder,
    required this.isExpanded,
  });

  final FileTreeFolder folder;
  final bool isExpanded;
}

class FileTreeFileRow extends FileTreeRow {
  const FileTreeFileRow({required super.depth, required this.file});

  final FileTreeFile file;
}

/// Stands for the files of [folderPath] beyond those shown.
class FileTreeMoreRow extends FileTreeRow {
  const FileTreeMoreRow({
    required super.depth,
    required this.folderPath,
    required this.remaining,
  });

  final String folderPath;
  final int remaining;
}

/// Supported files arranged by the folders that hold them. Files SEGUI does
/// not recognize are left out and counted in [unsupportedCount], and hidden
/// files are left out entirely.
class FileTree {
  const FileTree._({required this.root, required this.unsupportedCount});

  /// Builds the tree under [rootPath], or under the deepest folder that
  /// holds every supported file when [rootPath] is null. When [query] is
  /// set, only files whose names contain it, ignoring case, are listed.
  factory FileTree.fromFiles(
    List<FileTreeFile> files, {
    String? rootPath,
    String query = '',
  }) {
    // Hidden files, such as `.DS_Store`, are neither listed nor counted.
    final List<FileTreeFile> visible =
        files.where((e) => !p.basename(e.file.path).startsWith('.')).toList();
    final List<FileTreeFile> supported =
        visible.where((e) => isSupportedFile(e.file.path)).toList();
    final String root =
        rootPath ?? commonDirectory(supported.map((e) => e.file.path));
    final String search = query.trim().toLowerCase();
    final List<FileTreeFile> matches = search.isEmpty
        ? supported
        : supported
            .where(
                (e) => p.basename(e.file.path).toLowerCase().contains(search))
            .toList();
    final _FolderBuilder builder = _FolderBuilder(
      name: root.isEmpty ? '' : p.basename(root),
      path: root,
    );
    for (final FileTreeFile file in matches) {
      builder.add(file, _folderParts(root, file.file.path));
    }
    return FileTree._(
      root: builder.build(isRoot: true),
      unsupportedCount: visible.length - supported.length,
    );
  }

  final FileTreeFolder root;
  final int unsupportedCount;

  bool get isEmpty => root.fileCount == 0;

  /// Rows to list, showing the contents of [expanded] folder paths. Each
  /// folder shows [pageSize] files, or the count in [shownCounts].
  List<FileTreeRow> rows({
    required Set<String> expanded,
    required Map<String, int> shownCounts,
    required int pageSize,
  }) {
    final List<FileTreeRow> rows = [];
    _addRows(rows, root, 0, expanded, shownCounts, pageSize);
    return rows;
  }

  void _addRows(
    List<FileTreeRow> rows,
    FileTreeFolder folder,
    int depth,
    Set<String> expanded,
    Map<String, int> shownCounts,
    int pageSize,
  ) {
    for (final FileTreeFolder child in folder.folders) {
      final bool isExpanded = expanded.contains(child.path);
      rows.add(FileTreeFolderRow(
        depth: depth,
        folder: child,
        isExpanded: isExpanded,
      ));
      if (isExpanded) {
        _addRows(rows, child, depth + 1, expanded, shownCounts, pageSize);
      }
    }
    final int shown = shownCounts[folder.path] ?? pageSize;
    for (final FileTreeFile file in folder.files.take(shown)) {
      rows.add(FileTreeFileRow(depth: depth, file: file));
    }
    final int remaining = folder.files.length - shown;
    if (remaining > 0) {
      rows.add(FileTreeMoreRow(
        depth: depth,
        folderPath: folder.path,
        remaining: remaining,
      ));
    }
  }

  // Folder names from [root] down to the folder holding [path]. Files
  // outside [root] go under a folder named by their full directory.
  static List<String> _folderParts(String root, String path) {
    final String dir = p.dirname(path);
    if (root.isEmpty || !(p.equals(dir, root) || p.isWithin(root, dir))) {
      return [dir];
    }
    final String relative = p.relative(dir, from: root);
    return relative == '.' ? [] : p.split(relative);
  }
}

class _FolderBuilder {
  _FolderBuilder({required this.name, required this.path});

  final String name;
  final String path;
  final Map<String, _FolderBuilder> folders = {};
  final List<FileTreeFile> files = [];

  void add(FileTreeFile file, List<String> parts) {
    if (parts.isEmpty) {
      files.add(file);
      return;
    }
    final String part = parts.first;
    folders
        .putIfAbsent(
          part,
          () => _FolderBuilder(
            name: part,
            path: path.isEmpty ? part : p.join(path, part),
          ),
        )
        .add(file, parts.sublist(1));
  }

  FileTreeFolder build({bool isRoot = false}) {
    // Show a chain of folders that only hold one folder each as one.
    if (!isRoot && files.isEmpty && folders.length == 1) {
      final FileTreeFolder child = folders.values.single.build();
      return FileTreeFolder(
        name: p.join(name, child.name),
        path: child.path,
        folders: child.folders,
        files: child.files,
      );
    }
    final List<_FolderBuilder> sortedFolders = folders.values.toList()
      ..sort((a, b) => _compareNames(a.name, b.name));
    final List<FileTreeFile> sortedFiles = [...files]..sort((a, b) =>
        _compareNames(p.basename(a.file.path), p.basename(b.file.path)));
    return FileTreeFolder(
      name: name,
      path: path,
      folders: sortedFolders.map((e) => e.build()).toList(),
      files: sortedFiles,
    );
  }

  static int _compareNames(String a, String b) {
    return a.toLowerCase().compareTo(b.toLowerCase());
  }
}
