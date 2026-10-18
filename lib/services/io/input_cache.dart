import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Folder in the app support directory that holds extracted archives,
/// folders copied on Android, and files shared to SEGUI.
const String inputCacheDirName = 'input-cache';

/// Copies of input files that SEGUI or the system pickers make on mobile.
///
/// Android's picker copies each file into `<cache>/file_picker`, the iOS
/// picker copies into `<tmp>/<bundle>-Inbox`, and SEGUI writes extracted
/// archives and copied folders into [inputCacheDirName]. Nothing else
/// deletes these copies, so they are pruned whenever the inputs change.
class InputCacheServices {
  const InputCacheServices({
    required this.tempDir,
    required this.supportDir,
    required this.includePickerCopies,
  });

  final Directory tempDir;
  final Directory supportDir;

  /// Whether to prune the copies mobile pickers make in [tempDir]. Desktop
  /// pickers do not copy, and a shared desktop temp folder is not ours.
  final bool includePickerCopies;

  /// Session folders still being written, which pruning leaves alone.
  static final Set<String> _busyDirs = {};

  static Future<InputCacheServices> create() async {
    return InputCacheServices(
      tempDir: await getTemporaryDirectory(),
      supportDir: await getApplicationSupportDirectory(),
      includePickerCopies: Platform.isAndroid || Platform.isIOS,
    );
  }

  /// Runs [work] on a new session folder named after [label], keeping
  /// the folder from being pruned until [work] completes.
  Future<T> withSessionDir<T>(
    String label,
    Future<T> Function(Directory dir) work,
  ) async {
    final Directory dir = await createSessionDir(label);
    _busyDirs.add(dir.path);
    try {
      return await work(dir);
    } finally {
      _busyDirs.remove(dir.path);
    }
  }

  Directory get inputCacheDir {
    return Directory(p.join(supportDir.path, inputCacheDirName));
  }

  /// A new, empty folder in the input cache named after [label] and the
  /// current time.
  Future<Directory> createSessionDir(String label) async {
    final String stamp = DateTime.now().microsecondsSinceEpoch.toString();
    final dir = Directory(p.join(inputCacheDir.path, '$label-$stamp'));
    return await dir.create(recursive: true);
  }

  /// Folders that may hold picker or SEGUI copies of input files.
  Future<List<Directory>> cacheRoots() async {
    final List<Directory> roots = [inputCacheDir];
    if (!includePickerCopies) {
      return roots;
    }
    roots.add(Directory(p.join(tempDir.path, 'file_picker')));
    if (await tempDir.exists()) {
      await for (final entity in tempDir.list(followLinks: false)) {
        if (entity is Directory && p.basename(entity.path).endsWith('-Inbox')) {
          roots.add(entity);
        }
      }
    }
    return roots;
  }

  /// Whether [path] is a copy inside one of the cache folders.
  Future<bool> isCached(String path) async {
    for (final Directory root in await cacheRoots()) {
      if (p.isWithin(root.path, path)) {
        return true;
      }
    }
    return false;
  }

  /// Deletes cached copies whose paths are not in [keep], then removes
  /// folders left empty. Returns the number of files deleted.
  Future<int> prune(Set<String> keep) async {
    int deleted = 0;
    for (final Directory root in await cacheRoots()) {
      if (!await root.exists()) {
        continue;
      }
      final files = await root
          .list(recursive: true, followLinks: false)
          .where((entity) => entity is File)
          .cast<File>()
          .toList();
      for (final File file in files) {
        if (!keep.contains(file.path) && !_isBusy(file.path)) {
          await _tryDelete(file);
          deleted++;
        }
      }
      await _removeEmptyDirs(root);
    }
    return deleted;
  }

  /// Deletes every cached copy.
  Future<int> clear() => prune(const {});

  Future<void> _removeEmptyDirs(Directory root) async {
    final dirs = await root
        .list(recursive: true, followLinks: false)
        .where((entity) => entity is Directory)
        .cast<Directory>()
        .toList();
    // Deepest folders first, so parents empty out before they are checked.
    dirs.sort((a, b) => b.path.length.compareTo(a.path.length));
    for (final Directory dir in dirs) {
      if (!_isBusy(dir.path) && await dir.list().isEmpty) {
        await _tryDelete(dir);
      }
    }
  }

  bool _isBusy(String path) {
    return _busyDirs.any((dir) => dir == path || p.isWithin(dir, path));
  }

  Future<void> _tryDelete(FileSystemEntity entity) async {
    try {
      await entity.delete();
    } on FileSystemException {
      // A file in use or already gone stays for the next prune.
    }
  }
}
