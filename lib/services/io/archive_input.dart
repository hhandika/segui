import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:segui/services/io/directory.dart';
import 'package:segui/services/io/input_cache.dart';
import 'package:segui/src/rust/api/archive.dart';

/// Zip and gzip-compressed tar archives SEGUI can open as input.
const XTypeGroup archiveTypeGroup = XTypeGroup(
  label: 'Archive',
  extensions: ['zip', 'gz', 'tgz'],
  uniformTypeIdentifiers: [
    'public.zip-archive',
    'org.gnu.gnu-zip-archive',
    'org.gnu.gnu-zip-tar-archive',
  ],
);

/// Whether [path] names an archive SEGUI can extract.
bool isArchivePath(String path) {
  final String name = path.toLowerCase();
  return name.endsWith('.zip') ||
      name.endsWith('.tar.gz') ||
      name.endsWith('.tgz');
}

/// Extracts archives into the input cache, so one picked file can carry a
/// whole dataset. Mobile pickers copy every picked file, which is slow and
/// fails for thousands of files; an archive is copied once.
class ArchiveInputServices {
  const ArchiveInputServices(this.cache);

  final InputCacheServices cache;

  /// Extracts [archive] and returns the files that match [type]. A copy
  /// of the archive made by a picker is deleted afterwards.
  Future<List<File>> extract(File archive, XTypeGroup type) async {
    if (!isArchivePath(archive.path)) {
      throw ArgumentError('Unsupported archive. Use .zip or .tar.gz');
    }
    return await cache.withSessionDir('archive', (output) async {
      try {
        await ExtractServices(
          inputPath: archive.path,
          outputDir: output.path,
        ).extract();
      } finally {
        if (await cache.isCached(archive.path) && await archive.exists()) {
          await archive.delete();
        }
      }
      return DirectoryCrawler(output).crawlByType(type);
    });
  }
}
