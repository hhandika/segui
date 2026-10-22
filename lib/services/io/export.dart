import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:segui/services/io/file_tree.dart';
import 'package:segui/src/rust/api/archive.dart';

/// Whether the platform has a share sheet. Linux has none, so SEGUI only
/// exports there.
bool get canShareFiles => !Platform.isLinux;

/// Names and file details of each [ExportFormat].
extension ExportFormatDetails on ExportFormat {
  String get label => switch (this) {
        ExportFormat.zip => 'ZIP',
        ExportFormat.tarGz => 'Gzip',
      };

  String get description => switch (this) {
        ExportFormat.zip => 'A .zip archive that opens on any computer',
        ExportFormat.tarGz =>
          'A .tar.gz archive, common on Linux and computing clusters',
      };

  String get extension => switch (this) {
        ExportFormat.zip => '.zip',
        ExportFormat.tarGz => '.tar.gz',
      };

  String get mimeType => switch (this) {
        ExportFormat.zip => 'application/zip',
        ExportFormat.tarGz => 'application/gzip',
      };

  /// Save dialog filter. Platforms match on the last extension only.
  XTypeGroup get typeGroup => XTypeGroup(
        label: '$label archive',
        extensions: [
          switch (this) {
            ExportFormat.zip => 'zip',
            ExportFormat.tarGz => 'gz',
          }
        ],
      );
}

/// Bundles [files] into one [format] archive to save or share. Files keep
/// their folders relative to the folder they share.
class FileExportServices {
  const FileExportServices({required this.files, required this.format});

  /// Archive name when the files share no named folder.
  static const String defaultName = 'segui-export';

  final List<File> files;
  final ExportFormat format;

  /// Archive file name after the folder the files share, such as
  /// `loci.zip`.
  String get suggestedName {
    final String folder = files.length == 1
        ? p.basenameWithoutExtension(files.single.path)
        : p.basename(commonDirectory(files.map((e) => e.path)));
    final String name = folder.isEmpty ? defaultName : folder;
    return '$name${format.extension}';
  }

  /// Adds the format extension to [path] when the save dialog left it out.
  String withExtension(String path) {
    return path.toLowerCase().endsWith(format.extension)
        ? path
        : '$path${format.extension}';
  }

  /// Writes the archive to [path].
  Future<File> writeTo(String path) async {
    await ExportServices(
      outputPath: path,
      inputFiles: files.map((e) => e.path).toList(),
      format: format,
    ).write();
    return File(path);
  }

  /// Writes the archive to a new temporary folder, for sharing.
  Future<File> writeTemp() async {
    final Directory dir =
        await Directory.systemTemp.createTemp('segui-export-');
    return writeTo(p.join(dir.path, suggestedName));
  }

  /// Asks where to save the archive and writes it there. Returns where it
  /// was saved, or null when the user cancels.
  Future<String?> save() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return _saveOnMobile();
    }
    final FileSaveLocation? location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: [format.typeGroup],
    );
    if (location == null) {
      return null;
    }
    final String path = withExtension(location.path);
    await writeTo(path);
    return path;
  }

  // Mobile save dialogs take the archive bytes, so it is built in a
  // temporary folder first.
  Future<String?> _saveOnMobile() async {
    final File archive = await writeTemp();
    try {
      final Uri? uri = await FilePicker.saveFile(
        fileName: suggestedName,
        bytes: await archive.readAsBytes(),
        mimeType: format.mimeType,
      );
      if (uri == null) {
        return null;
      }
      return uri.scheme == 'file' ? uri.toFilePath() : suggestedName;
    } finally {
      await archive.parent.delete(recursive: true);
    }
  }
}
