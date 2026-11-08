import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/alignment_view.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/viewers/viewer_files.dart';
import 'package:segui/src/rust/api/file_sort.dart';

/// Files open in the viewer page, in natural path order.
final viewerFilesProvider =
    NotifierProvider<ViewerFiles, List<File>>(ViewerFiles.new);

class ViewerFiles extends Notifier<List<File>> {
  @override
  List<File> build() => const [];

  /// Adds [files], skipping ones already listed, and records them as
  /// recent. Returns how many were new.
  int addFiles(Iterable<File> files) {
    final int added = _add(files);
    final ViewerRecents recents = ref.read(viewerRecentsProvider.notifier);
    for (final File file in files) {
      recents.record(ViewerRecent(path: file.path, isFolder: false));
    }
    return added;
  }

  /// Adds the viewable files directly inside [dir] and records [dir] as
  /// recent. Returns how many were new.
  Future<int> addFolder(Directory dir) async {
    final List<File> files = await listViewerFiles(dir);
    ref
        .read(viewerRecentsProvider.notifier)
        .record(ViewerRecent(path: dir.path, isFolder: true));
    return _add(files);
  }

  /// Adds dropped [paths]: folders add their files, other paths are
  /// added as files. Returns how many were new.
  Future<int> addPaths(Iterable<String> paths) async {
    int added = 0;
    final List<File> files = [];
    for (final String path in paths) {
      if (FileSystemEntity.isDirectorySync(path)) {
        added += await addFolder(Directory(path));
      } else {
        files.add(File(path));
      }
    }
    return added + addFiles(files.where(isViewerFile));
  }

  void remove(File file) {
    state = [
      for (final File f in state)
        if (f.path != file.path) f
    ];
  }

  void clear() => state = const [];

  int _add(Iterable<File> files) {
    final Set<String> known = {for (final File f in state) f.path};
    final List<File> merged = [...state];
    for (final File file in files) {
      if (known.add(file.path)) merged.add(file);
    }
    final int added = merged.length - state.length;
    if (added == 0) return 0;
    final List<int> order = ref.read(fileOrderProvider)(
      [for (final File f in merged) f.path],
      FileSortKey.path,
      ascending: true,
    );
    state = [for (final int i in order) merged[i]];
    return added;
  }
}

/// Files and folders opened in the viewer before, newest first. Kept
/// across restarts.
final viewerRecentsProvider =
    NotifierProvider<ViewerRecents, List<ViewerRecent>>(ViewerRecents.new);

class ViewerRecents extends Notifier<List<ViewerRecent>> {
  static const String _key = 'viewerRecents';

  @override
  List<ViewerRecent> build() {
    try {
      final List<String> saved =
          ref.watch(settingProvider).getStringList(_key) ?? const [];
      return [
        for (final String entry in saved) ViewerRecent.fromJson(entry),
      ];
    } catch (_) {
      // No saved preferences, as in widget tests, or an unreadable entry.
      return const [];
    }
  }

  void record(ViewerRecent entry) => _save(addRecent(state, entry));

  void remove(ViewerRecent entry) {
    _save([
      for (final ViewerRecent recent in state)
        if (recent != entry) recent
    ]);
  }

  void clear() => _save(const []);

  void _save(List<ViewerRecent> recents) {
    state = recents;
    try {
      ref.read(settingProvider).setStringList(
        _key,
        [for (final ViewerRecent recent in recents) recent.toJson()],
      );
    } catch (_) {
      // No saved preferences, as in widget tests.
    }
  }
}
