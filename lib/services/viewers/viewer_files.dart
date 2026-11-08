import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:segui/services/io/file.dart';

/// Most recent files and folders the viewer keeps.
const int viewerRecentLimit = 10;

/// Whether the viewer lists [file]: a format SEGUI has a viewer for, and
/// not a hidden file. Archives and compressed files are left out.
bool isViewerFile(File file) {
  final String name = p.basename(file.path);
  if (name.startsWith('.')) return false;
  // Compressed files, such as gzipped reads, have no viewer.
  final String ext = p.extension(name).toLowerCase().replaceFirst('.', '');
  if (gunzipExtensions.contains(ext)) return false;
  return switch (FileIconType.fromFileName(name)) {
    FileIconType.unknown || FileIconType.zip || FileIconType.gzip => false,
    _ => true,
  };
}

/// Viewable files directly inside [dir], like `segul view align --dir`.
/// Subfolders are not searched.
Future<List<File>> listViewerFiles(Directory dir) async {
  final List<File> files = [];
  await for (final FileSystemEntity entity in dir.list(followLinks: false)) {
    if (entity is File && isViewerFile(entity)) files.add(entity);
  }
  return files;
}

/// Lets the user pick files to view. Android uses its own picker, which
/// copies the files into the app cache first.
Future<List<File>> pickViewerFiles() async {
  if (Platform.isAndroid) {
    final List<PlatformFile> picked =
        await FilePicker.pickFiles(type: FileType.any);
    return picked
        .map((file) => file.path)
        .whereType<String>()
        .map(File.new)
        .toList();
  }
  final List<XFile> picked = await openFiles();
  return picked.map((file) => File(file.path)).toList();
}

/// A file or folder opened in the viewer before.
class ViewerRecent {
  const ViewerRecent({required this.path, required this.isFolder});

  factory ViewerRecent.fromJson(String source) {
    final Map<String, dynamic> json =
        jsonDecode(source) as Map<String, dynamic>;
    return ViewerRecent(
      path: json['path'] as String,
      isFolder: json['isFolder'] as bool? ?? false,
    );
  }

  final String path;
  final bool isFolder;

  String get name => p.basename(path);

  /// Whether the file or folder is still there.
  bool get exists =>
      isFolder ? Directory(path).existsSync() : File(path).existsSync();

  String toJson() => jsonEncode({'path': path, 'isFolder': isFolder});

  @override
  bool operator ==(Object other) =>
      other is ViewerRecent && other.path == path && other.isFolder == isFolder;

  @override
  int get hashCode => Object.hash(path, isFolder);
}

/// [recents] with [entry] moved to the front, capped at
/// [viewerRecentLimit].
List<ViewerRecent> addRecent(List<ViewerRecent> recents, ViewerRecent entry) {
  return [
    entry,
    ...recents.where((recent) => recent.path != entry.path),
  ].take(viewerRecentLimit).toList();
}
