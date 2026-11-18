import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/logging.dart';

/// Order of the folders and files in a [DataUsageTree]. Folders always come
/// before files.
enum DataUsageSort {
  size('Size'),
  name('Name'),
  recent('Recent');

  const DataUsageSort(this.label);

  final String label;
}

/// A file in a [DataUsageTree] with its size and last change, read once
/// when the tree is built.
class DataUsageFile {
  const DataUsageFile({
    required this.file,
    required this.size,
    required this.modified,
  });

  final File file;
  final int size;
  final DateTime modified;

  String get name => p.basename(file.path);
}

/// A folder in a [DataUsageTree], including empty ones, with the total
/// size and file count of everything inside it.
class DataUsageFolder {
  const DataUsageFolder({
    required this.directory,
    required this.folders,
    required this.files,
    required this.size,
    required this.fileCount,
    required this.modified,
  });

  final Directory directory;
  final List<DataUsageFolder> folders;
  final List<DataUsageFile> files;

  /// Bytes in this folder and its subfolders.
  final int size;

  /// Files in this folder and its subfolders.
  final int fileCount;

  /// Latest change to the folder or anything inside it.
  final DateTime modified;

  String get name => p.basename(directory.path);
  String get path => directory.path;

  bool get isEmpty => folders.isEmpty && files.isEmpty;

  /// Folders and files directly inside this folder.
  int get itemCount => folders.length + files.length;

  /// Files in this folder and its subfolders.
  Iterable<DataUsageFile> get allFiles sync* {
    for (final DataUsageFolder folder in folders) {
      yield* folder.allFiles;
    }
    yield* files;
  }

  /// Paths of every subfolder, at any depth.
  Iterable<String> get folderPaths sync* {
    for (final DataUsageFolder folder in folders) {
      yield folder.path;
      yield* folder.folderPaths;
    }
  }

  /// Number of subfolders, at any depth.
  int get folderCount {
    return folders.fold(folders.length, (sum, e) => sum + e.folderCount);
  }
}

/// Bytes held by one file format, or by every format grouped as Other.
class DataUsageTypeShare {
  const DataUsageTypeShare({
    required this.label,
    required this.size,
    this.isOther = false,
  });

  final String label;
  final int size;
  final bool isOther;
}

/// A row of a [DataUsageTree] as it is listed on screen.
sealed class DataUsageRow {
  const DataUsageRow({required this.depth});

  /// Nesting level below the root, which is 0.
  final int depth;
}

class DataUsageFolderRow extends DataUsageRow {
  const DataUsageFolderRow({
    required super.depth,
    required this.folder,
    required this.isExpanded,
  });

  final DataUsageFolder folder;
  final bool isExpanded;
}

class DataUsageFileRow extends DataUsageRow {
  const DataUsageFileRow({required super.depth, required this.file});

  final DataUsageFile file;
}

/// Stands for the contents of an open folder that holds nothing.
class DataUsageEmptyRow extends DataUsageRow {
  const DataUsageEmptyRow({required super.depth});
}

/// The folders and files in SEGUI's data folder. Hidden entries, such as
/// `.DS_Store`, are left out, and links are not followed.
class DataUsageTree {
  const DataUsageTree({required this.root});

  factory DataUsageTree.fromDirectory(Directory dir) {
    return DataUsageTree(root: _readFolder(dir));
  }

  final DataUsageFolder root;

  int get size => root.size;
  int get fileCount => root.fileCount;
  int get folderCount => root.folderCount;
  bool get isEmpty => root.isEmpty;

  /// Bytes per file format, largest first: the [top] largest formats, then
  /// one Other share for the rest, including unrecognized files.
  List<DataUsageTypeShare> typeShares({int top = 3}) {
    final Map<FileIconType, int> sizes = {};
    for (final DataUsageFile file in root.allFiles) {
      final FileIconType type = FileIconType.fromFileName(file.name);
      sizes[type] = (sizes[type] ?? 0) + file.size;
    }
    final List<MapEntry<FileIconType, int>> named =
        sizes.entries.where((e) => e.key != FileIconType.unknown).toList()
          ..sort((a, b) {
            final int order = b.value.compareTo(a.value);
            return order != 0 ? order : a.key.label.compareTo(b.key.label);
          });
    final List<DataUsageTypeShare> shares = [
      for (final MapEntry<FileIconType, int> entry in named.take(top))
        DataUsageTypeShare(label: entry.key.label, size: entry.value),
    ];
    final bool hasRest =
        named.length > top || sizes.containsKey(FileIconType.unknown);
    if (hasRest) {
      final int shown = shares.fold(0, (sum, e) => sum + e.size);
      shares.add(DataUsageTypeShare(
        label: FileIconType.unknown.label,
        size: size - shown,
        isOther: true,
      ));
    }
    return shares;
  }

  /// Rows to list in [sort] order, showing the contents of [expanded]
  /// folder paths.
  List<DataUsageRow> rows({
    required Set<String> expanded,
    required DataUsageSort sort,
  }) {
    final List<DataUsageRow> rows = [];
    _addRows(rows, root, 0, expanded, sort);
    return rows;
  }

  void _addRows(
    List<DataUsageRow> rows,
    DataUsageFolder folder,
    int depth,
    Set<String> expanded,
    DataUsageSort sort,
  ) {
    for (final DataUsageFolder child in _sortFolders(folder.folders, sort)) {
      final bool isExpanded = expanded.contains(child.path);
      rows.add(DataUsageFolderRow(
        depth: depth,
        folder: child,
        isExpanded: isExpanded,
      ));
      if (!isExpanded) {
        continue;
      }
      if (child.isEmpty) {
        rows.add(DataUsageEmptyRow(depth: depth + 1));
      } else {
        _addRows(rows, child, depth + 1, expanded, sort);
      }
    }
    for (final DataUsageFile file in _sortFiles(folder.files, sort)) {
      rows.add(DataUsageFileRow(depth: depth, file: file));
    }
  }

  static List<DataUsageFolder> _sortFolders(
    List<DataUsageFolder> folders,
    DataUsageSort sort,
  ) {
    return [...folders]..sort((a, b) => switch (sort) {
          DataUsageSort.size => _thenName(b.size.compareTo(a.size), a, b),
          DataUsageSort.name => _compareNames(a.name, b.name),
          DataUsageSort.recent =>
            _thenName(b.modified.compareTo(a.modified), a, b),
        });
  }

  static List<DataUsageFile> _sortFiles(
    List<DataUsageFile> files,
    DataUsageSort sort,
  ) {
    return [...files]..sort((a, b) {
        final int order = switch (sort) {
          DataUsageSort.size => b.size.compareTo(a.size),
          DataUsageSort.name => 0,
          DataUsageSort.recent => b.modified.compareTo(a.modified),
        };
        return order != 0 ? order : _compareNames(a.name, b.name);
      });
  }

  static int _thenName(int order, DataUsageFolder a, DataUsageFolder b) {
    return order != 0 ? order : _compareNames(a.name, b.name);
  }

  static int _compareNames(String a, String b) {
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  static DataUsageFolder _readFolder(Directory dir) {
    final List<DataUsageFolder> folders = [];
    final List<DataUsageFile> files = [];
    DateTime modified = _modifiedOf(dir);
    final List<FileSystemEntity> entities = _list(dir);
    for (final FileSystemEntity entity in entities) {
      if (p.basename(entity.path).startsWith('.')) {
        continue;
      }
      if (entity is Directory) {
        folders.add(_readFolder(entity));
      } else if (entity is File) {
        final FileStat stat = entity.statSync();
        files.add(DataUsageFile(
          file: entity,
          size: stat.size,
          modified: stat.modified,
        ));
      }
    }
    int size = 0;
    int fileCount = files.length;
    for (final DataUsageFile file in files) {
      size += file.size;
      if (file.modified.isAfter(modified)) {
        modified = file.modified;
      }
    }
    for (final DataUsageFolder folder in folders) {
      size += folder.size;
      fileCount += folder.fileCount;
      if (folder.modified.isAfter(modified)) {
        modified = folder.modified;
      }
    }
    return DataUsageFolder(
      directory: dir,
      folders: folders,
      files: files,
      size: size,
      fileCount: fileCount,
      modified: modified,
    );
  }

  // A folder that cannot be read, such as one removed while listing, is
  // shown as empty.
  static List<FileSystemEntity> _list(Directory dir) {
    try {
      return dir.listSync(followLinks: false);
    } on FileSystemException {
      return const [];
    }
  }

  static DateTime _modifiedOf(FileSystemEntity entity) {
    return entity.statSync().modified;
  }
}

/// Folders and files picked in a [DataUsageTree]. Picking a folder picks
/// everything inside it, and a folder counts as picked once everything
/// inside it is.
class DataUsageSelection {
  const DataUsageSelection([this.paths = const {}]);

  /// Paths of the picked folders and files.
  final Set<String> paths;

  bool get isEmpty => paths.isEmpty;

  bool isFileSelected(DataUsageFile file) => paths.contains(file.file.path);

  /// Whether all (true), some (null), or none (false) of [folder] is
  /// picked.
  bool? folderState(DataUsageFolder folder) {
    if (paths.contains(folder.path)) {
      return true;
    }
    final bool hasPicked = paths.any((path) => p.isWithin(folder.path, path));
    return hasPicked ? null : false;
  }

  DataUsageSelection toggleFolder(DataUsageTree tree, DataUsageFolder folder) {
    final Set<String> inside = {folder.path, ..._pathsIn(folder)};
    final Set<String> next = folderState(folder) == true
        ? paths.difference(inside)
        : paths.union(inside);
    return DataUsageSelection(_complete(tree, next));
  }

  DataUsageSelection toggleFile(DataUsageTree tree, DataUsageFile file) {
    final String path = file.file.path;
    final Set<String> next =
        paths.contains(path) ? ({...paths}..remove(path)) : {...paths, path};
    return DataUsageSelection(_complete(tree, next));
  }

  /// Picks every folder and file in [tree].
  static DataUsageSelection all(DataUsageTree tree) {
    return DataUsageSelection(_pathsIn(tree.root).toSet());
  }

  /// Keeps only paths still in [tree], such as after a delete.
  DataUsageSelection prune(DataUsageTree tree) {
    return DataUsageSelection(_complete(tree, paths));
  }

  /// Picked folders and files, leaving out those inside a picked folder.
  List<FileSystemEntity> entities(DataUsageTree tree) {
    final List<FileSystemEntity> entities = [];
    _addEntities(tree.root, entities);
    return entities;
  }

  /// Every picked file, including files inside picked folders.
  List<File> files(DataUsageTree tree) {
    return [
      for (final DataUsageFile file in tree.root.allFiles)
        if (paths.contains(file.file.path)) file.file,
    ];
  }

  void _addEntities(DataUsageFolder folder, List<FileSystemEntity> out) {
    for (final DataUsageFolder child in folder.folders) {
      if (paths.contains(child.path)) {
        out.add(child.directory);
      } else {
        _addEntities(child, out);
      }
    }
    for (final DataUsageFile file in folder.files) {
      if (paths.contains(file.file.path)) {
        out.add(file.file);
      }
    }
  }

  // Rebuilds [picked] from the tree, so a folder is picked exactly when
  // everything inside it is, and paths no longer in the tree drop out.
  static Set<String> _complete(DataUsageTree tree, Set<String> picked) {
    final Set<String> result = {};
    for (final DataUsageFolder folder in tree.root.folders) {
      _completeFolder(folder, picked, result);
    }
    for (final DataUsageFile file in tree.root.files) {
      if (picked.contains(file.file.path)) {
        result.add(file.file.path);
      }
    }
    return result;
  }

  static bool _completeFolder(
    DataUsageFolder folder,
    Set<String> picked,
    Set<String> result,
  ) {
    bool isFull = true;
    for (final DataUsageFolder child in folder.folders) {
      isFull = _completeFolder(child, picked, result) && isFull;
    }
    for (final DataUsageFile file in folder.files) {
      if (picked.contains(file.file.path)) {
        result.add(file.file.path);
      } else {
        isFull = false;
      }
    }
    if (folder.isEmpty) {
      isFull = picked.contains(folder.path);
    }
    if (isFull) {
      result.add(folder.path);
    }
    return isFull;
  }

  static Iterable<String> _pathsIn(DataUsageFolder folder) sync* {
    for (final DataUsageFolder child in folder.folders) {
      yield child.path;
      yield* _pathsIn(child);
    }
    for (final DataUsageFile file in folder.files) {
      yield file.file.path;
    }
  }
}

/// Deletes folders and files in SEGUI's data folder.
class DataUsageCleaner {
  const DataUsageCleaner({required this.root});

  /// SEGUI's data folder. Nothing outside it is deleted.
  final Directory root;

  /// Deletes [entity], with everything inside it when it is a folder.
  Future<void> delete(FileSystemEntity entity) async {
    if (!p.isWithin(root.path, entity.path)) {
      throw ArgumentError.value(
          entity.path, 'entity', 'Not inside the SEGUI data folder');
    }
    if (await entity.exists()) {
      await entity.delete(recursive: true);
    }
  }

  /// Deletes everything in [root] except the latest log file, which the
  /// running app still writes to.
  Future<void> clearAll() async {
    final List<File> files = root
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .toList();
    final File? log = FileLoggingService().findLatestLog(files);
    await _clear(root, log);
  }

  Future<void> _clear(Directory dir, File? keep) async {
    for (final FileSystemEntity entity in dir.listSync(followLinks: false)) {
      if (keep != null && p.equals(entity.path, keep.path)) {
        continue;
      }
      if (entity is Directory &&
          keep != null &&
          p.isWithin(entity.path, keep.path)) {
        await _clear(entity, keep);
        continue;
      }
      await entity.delete(recursive: true);
    }
  }
}
