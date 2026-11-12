import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:segui/services/io/directory.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/input_cache.dart';
import 'package:segui/services/io/mobile_io.dart';
import 'package:segui/src/rust/api/archive.dart';
import 'package:segui/src/rust/api/progress.dart';

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

/// Whether files of [type] can come from an archive. SEGUL reads gzipped
/// raw reads as they are, so a `.gz` read file must not be mistaken for an
/// archive; raw reads are added as regular files instead.
bool acceptsArchiveInput(XTypeGroup type) {
  return type != genomicRawReadTypeGroup;
}

/// Extracts archives into the input cache, so one picked file can carry a
/// whole dataset. Mobile pickers copy every picked file, which is slow and
/// fails for thousands of files; an archive is copied once.
class ArchiveInputServices {
  const ArchiveInputServices(this.cache);

  final InputCacheServices cache;

  /// Extracts [archive] and returns the files that match [type]. A copy
  /// of the archive made by a picker is deleted afterwards.
  ///
  /// [onProgress] receives extraction progress with a way to stop. A
  /// stopped extraction keeps and returns the files extracted so far.
  Future<List<File>> extract(
    File archive,
    XTypeGroup type, {
    void Function(InputCopyProgress progress)? onProgress,
  }) async {
    if (!isArchivePath(archive.path)) {
      throw ArgumentError('Unsupported archive. Use .zip or .tar.gz');
    }
    return await cache.withSessionDir('archive', (output) async {
      final services = ExtractServices(
        inputPath: archive.path,
        outputDir: output.path,
      );
      try {
        if (onProgress == null) {
          await services.extract();
        } else {
          await _extractWithProgress(services, onProgress);
        }
      } finally {
        if (await cache.isCached(archive.path) && await archive.exists()) {
          await archive.delete();
        }
      }
      return DirectoryCrawler(output).crawlByType(type);
    });
  }

  Future<void> _extractWithProgress(
    ExtractServices services,
    void Function(InputCopyProgress progress) onProgress,
  ) async {
    final RunMonitor monitor = RunMonitor();
    final subscription = monitor.subscribe().listen((TaskProgress progress) {
      onProgress(extractProgress(progress, onCancel: monitor.cancel));
    });
    try {
      await services.extractWithMonitor(monitor: monitor);
    } catch (_) {
      if (!monitor.isCancelled()) {
        rethrow;
      }
    } finally {
      monitor.close();
      await subscription.cancel();
    }
  }
}

/// Maps Rust extraction progress to input copy progress.
InputCopyProgress extractProgress(
  TaskProgress progress, {
  VoidCallback? onCancel,
}) {
  return InputCopyProgress(
    copied: progress.done,
    total: progress.total,
    bytesCopied: progress.bytesDone.toInt(),
    bytesTotal: progress.bytesTotal.toInt(),
    stage: InputCopyStage.extracting,
    onCancel: onCancel,
  );
}
