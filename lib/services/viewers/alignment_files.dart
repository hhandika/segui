import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:segui/services/io/file.dart';
import 'package:segui/src/rust/api/file_sort.dart';

/// How the file list in the alignment viewer is ordered.
enum AlignmentFileSort {
  name(
    'Name',
    FileSortKey.name,
    ascending: 'A to Z',
    descending: 'Z to A',
  ),
  size(
    'Size',
    FileSortKey.size,
    ascending: 'Smallest first',
    descending: 'Largest first',
  );

  const AlignmentFileSort(
    this.label,
    this.key, {
    required this.ascending,
    required this.descending,
  });

  final String label;

  /// The matching sort in the Rust file list service.
  final FileSortKey key;

  /// Names of the two directions for this sort.
  final String ascending;
  final String descending;
}

/// Positions of [paths] ordered by [key], reading [sizes] when sorting by
/// size. [rustFileOrder] does this in Rust; tests can supply their own.
typedef FileOrder = List<int> Function(
  List<String> paths,
  FileSortKey key, {
  required bool ascending,
  List<int?> sizes,
});

/// Orders file paths with SEGUL's Rust side: names sort naturally, so
/// `uce-2` comes before `uce-10`, and files without a size go last.
List<int> rustFileOrder(
  List<String> paths,
  FileSortKey key, {
  required bool ascending,
  List<int?> sizes = const [],
}) {
  return FileListServices.raw(paths: paths)
      .order(key: key, ascending: ascending, sizes: sizes);
}

/// Alignment files the viewer can step through: [file] and the files it
/// was opened beside that the viewer can read, in natural path order.
class AlignmentFileList {
  AlignmentFileList(
    File file,
    Iterable<File> siblings, {
    required FileOrder order,
  })  : _order = order,
        files = _collect(file, siblings, order);

  final List<File> files;
  final FileOrder _order;

  int get length => files.length;

  /// Position of [file], matched by path.
  int indexOf(File file) => files.indexWhere((f) => f.path == file.path);

  /// Position [delta] steps from [index], wrapping at both ends.
  int step(int index, int delta) {
    if (files.isEmpty) return 0;
    return (index + delta) % files.length;
  }

  /// Positions of files whose name contains [query], ignoring case,
  /// ordered by [sort] in the given direction. Names sort naturally, so
  /// `uce-2` comes before `uce-10`. [sizes] maps paths to bytes; files
  /// without a size go last either way.
  List<int> view({
    String query = '',
    AlignmentFileSort sort = AlignmentFileSort.name,
    bool ascending = true,
    Map<String, int> sizes = const {},
  }) {
    final String needle = query.trim().toLowerCase();
    final List<int> matches = [
      for (int i = 0; i < files.length; i++)
        if (p.basename(files[i].path).toLowerCase().contains(needle)) i,
    ];
    final List<int> order = _order(
      [for (final int i in matches) files[i].path],
      sort.key,
      ascending: ascending,
      sizes: sort == AlignmentFileSort.size
          ? [for (final int i in matches) sizes[files[i].path]]
          : const [],
    );
    return [for (final int i in order) matches[i]];
  }

  @override
  bool operator ==(Object other) {
    if (other is! AlignmentFileList || other.length != length) return false;
    for (int i = 0; i < length; i++) {
      if (other.files[i].path != files[i].path) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(files.map((f) => f.path));

  static List<File> _collect(
    File file,
    Iterable<File> siblings,
    FileOrder order,
  ) {
    final Map<String, File> byPath = {
      for (final File f in siblings)
        if (isAlignmentViewable(f)) f.path: f,
      file.path: file,
    };
    final List<File> files = byPath.values.toList();
    final List<int> sorted = order(
      [for (final File f in files) f.path],
      FileSortKey.path,
      ascending: true,
    );
    return [for (final int i in sorted) files[i]];
  }
}

/// Size in bytes of each file in [files] that still exists, read in Rust.
Future<Map<String, int>> alignmentFileSizes(AlignmentFileList files) async {
  final List<String> paths = [for (final File f in files.files) f.path];
  final List<int?> sizes = await FileListServices.raw(paths: paths).sizes();
  return {
    for (int i = 0; i < paths.length; i++)
      if (sizes[i] != null) paths[i]: sizes[i]!,
  };
}
