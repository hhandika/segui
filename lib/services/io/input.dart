import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/io/archive_input.dart';
import 'package:segui/services/io/input_cache.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/io/mobile_io.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/directory.dart';

/// Match all file extensions,
/// Use mostly for determining file
/// input.
enum SegulType {
  genomicReads,
  genomicContig,
  standardSequence,
  alignmentPartition,
  plainText,
  destinationSequence,
  multipleAlignment,
  bed,
  sampleGroup,
}

class SegulInputFile {
  SegulInputFile({
    required this.file,
    required this.type,
  });

  final SegulType type;
  final File file;

  factory SegulInputFile.fromXFile(XFile file, XTypeGroup xTypeGroup) {
    return SegulInputFile(
      file: File(file.path),
      type: matchTypeByXTypeGroup(xTypeGroup),
    );
  }

  factory SegulInputFile.addMoreFiles(SegulInputFile oldFile, XFile file) {
    return SegulInputFile(
      file: File(file.path),
      type: oldFile.type,
    );
  }
}

SegulType matchTypeByXTypeGroup(XTypeGroup xTypeGroup) {
  switch (xTypeGroup) {
    case genomicRawReadTypeGroup:
      return SegulType.genomicReads;
    case genomicContigTypeGroup:
      return SegulType.genomicContig;
    case sequenceTypeGroup:
      return SegulType.standardSequence;
    case partitionTypeGroup:
      return SegulType.alignmentPartition;
    case plainTextTypeGroup:
      return SegulType.plainText;
    case destinationSequenceTypeGroup:
      return SegulType.destinationSequence;
    case mafTypeGroup:
      return SegulType.multipleAlignment;
    case bedTypeGroup:
      return SegulType.bed;
    case sampleGroupTypeGroup:
      return SegulType.sampleGroup;
    default:
      return SegulType.standardSequence;
  }
}

/// Counts of files left out when adding input files.
typedef InputAddResult = ({int duplicates, int skipped});

const InputAddResult _nothingSkipped = (duplicates: 0, skipped: 0);

/// A picker failure explained in words users can act on.
class InputPickException implements Exception {
  const InputPickException(this.message);

  final String message;

  /// Maps picker plugin errors, such as running out of memory while the
  /// Android picker copies many files, to a suggestion.
  factory InputPickException.fromPlatform(PlatformException error) {
    if (error.code == 'out_of_memory') {
      return const InputPickException(
        'Too many files for the system picker. '
        'Use Browse folder or Open archive instead.',
      );
    }
    return InputPickException(
      'Could not load the files (${error.message ?? error.code}). '
      'For many files, use Browse folder or Open archive.',
    );
  }

  @override
  String toString() => message;
}

class FileInputServices {
  const FileInputServices(
    this.ref, {
    required this.allowedExtension,
    required this.allowMultiple,
    this.onProgress,
  });

  final WidgetRef ref;
  final XTypeGroup allowedExtension;
  final bool allowMultiple;

  /// Reports progress while files are copied into the app on mobile.
  final void Function(InputCopyProgress progress)? onProgress;

  Future<InputAddResult> selectFiles() async {
    final picked = await _pickFiles();
    await _updateProvider(picked.files);
    return (duplicates: 0, skipped: picked.skipped);
  }

  Future<InputAddResult> addMoreFiles(List<File> currentFiles) async {
    final picked = await _pickFiles();
    final newFiles = _checkDuplicateFiles(currentFiles, picked.files);
    await _addMoreToProvider(newFiles.files);
    return (duplicates: newFiles.duplicate, skipped: picked.skipped);
  }

  Future<InputAddResult> addDirectory() async {
    final List<XFile>? files = await _pickDirectoryFiles();
    if (files == null) {
      return _nothingSkipped;
    }
    await _updateProvider(_requireMatches(files));
    return _nothingSkipped;
  }

  Future<InputAddResult> addMoreDirectory(List<File> currentFiles) async {
    final List<XFile>? files = await _pickDirectoryFiles();
    if (files == null) {
      return _nothingSkipped;
    }
    return await _addMatches(_requireMatches(files), currentFiles);
  }

  /// Extracts a picked zip or tar.gz archive and adds its matching files.
  Future<InputAddResult> addArchive(List<File> currentFiles) async {
    final List<XFile>? files = await _pickArchive();
    if (files == null) {
      return _nothingSkipped;
    }
    if (files.isEmpty) {
      throw InputPickException(
          'No ${allowedExtension.label} files found in the archive.');
    }
    return await _addMatches(files, currentFiles);
  }

  /// Adds the matching files in SEGUI's own `inputs` folder, which iOS
  /// users fill through the Files app or Finder.
  Future<InputAddResult> addSeguiFolder(List<File> currentFiles) async {
    final Directory dir = await getSeguiInputDirectory();
    final List<XFile> files = _crawl(dir);
    if (files.isEmpty) {
      throw InputPickException(
        'No ${allowedExtension.label} files in the SEGUI inputs folder. '
        'Copy them into On My iPhone › SEGUI › inputs with the Files app.',
      );
    }
    return await _addMatches(files, currentFiles);
  }

  /// Takes the files shared to SEGUI and adds the matching ones,
  /// extracting archives among them.
  Future<InputAddResult> addSharedFiles(List<File> currentFiles) async {
    final cache = await InputCacheServices.create();
    onProgress?.call(const InputCopyProgress.preparing());
    return await cache.withSessionDir('shared', (destination) async {
      final List<String> paths =
          await MobileIoChannel.instance.takeSharedFiles(destination);
      final List<XFile> matches = [];
      int skipped = 0;
      for (final String path in paths) {
        if (isArchivePath(path)) {
          final files = await ArchiveInputServices(cache)
              .extract(File(path), allowedExtension);
          matches.addAll(files.map((e) => XFile(e.path)));
        } else if (matchesTypeGroup(File(path), allowedExtension)) {
          matches.add(XFile(path));
        } else {
          skipped++;
        }
      }
      final result = await _addMatches(matches, currentFiles);
      return (
        duplicates: result.duplicates,
        skipped: result.skipped + skipped,
      );
    });
  }

  /// Select a file in place of the current file of this type.
  Future<void> replaceFile() async {
    final picked = await _pickFiles(multiple: false);
    if (picked.files.isNotEmpty) {
      await ref
          .read(fileInputProvider.notifier)
          .replaceType(picked.files, allowedExtension);
    }
  }

  /// Add dropped [paths], searching dropped directories when
  /// [allowDirectory] is true. Files that do not match the allowed
  /// extensions are skipped. A new selection replaces the files of this
  /// type, and a single-file picker keeps only the first matching file.
  Future<({int duplicates, int skipped})> addDropped(
    List<String> paths, {
    required List<File> currentFiles,
    required bool allowDirectory,
  }) async {
    final List<XFile> matches = [];
    int skipped = 0;
    for (final String path in paths) {
      if (FileSystemEntity.isDirectorySync(path)) {
        if (!allowDirectory) {
          skipped++;
          continue;
        }
        final files =
            DirectoryCrawler(Directory(path)).crawlByType(allowedExtension);
        matches.addAll(files.map((e) => XFile(e.path)));
      } else if (matchesTypeGroup(File(path), allowedExtension)) {
        matches.add(XFile(path));
      } else {
        skipped++;
      }
    }
    final result = await _addMatches(matches, currentFiles);
    return (duplicates: result.duplicates, skipped: result.skipped + skipped);
  }

  /// Adds [matches] to the inputs. When nothing of this type is selected
  /// yet, the matches replace the files of this type, and a single-file
  /// picker keeps only the first match.
  Future<InputAddResult> _addMatches(
    List<XFile> matches,
    List<File> currentFiles,
  ) async {
    final notifier = ref.read(fileInputProvider.notifier);
    if (!allowMultiple) {
      if (matches.isNotEmpty) {
        await notifier.replaceType([matches.first], allowedExtension);
      }
      return (duplicates: 0, skipped: _extraCount(matches));
    }
    final newFiles = _checkDuplicateFiles(currentFiles, matches);
    if (currentFiles.isEmpty) {
      await notifier.replaceType(newFiles.files, allowedExtension);
    } else {
      await _addMoreToProvider(newFiles.files);
    }
    return (duplicates: newFiles.duplicate, skipped: 0);
  }

  List<XFile> _requireMatches(List<XFile> files) {
    if (files.isEmpty) {
      throw InputPickException(
          'No ${allowedExtension.label} files found in the folder.');
    }
    return files;
  }

  int _extraCount(List<XFile> matches) {
    return matches.isEmpty ? 0 : matches.length - 1;
  }

  List<XFile> _crawl(Directory dir) {
    return DirectoryCrawler(dir)
        .crawlByType(allowedExtension)
        .map((e) => XFile(e.path))
        .toList();
  }

  Future<({List<XFile> files, int skipped})> _pickFiles({
    bool? multiple,
  }) async {
    final bool pickMany = multiple ?? allowMultiple;
    try {
      if (Platform.isAndroid) {
        final List<XFile> picked = pickMany
            ? await _selectMultiUsingFilePicker()
            : await _selectUsingFilePicker();
        return filterPickedFiles(picked, allowedExtension);
      }
      final List<XFile> picked = pickMany
          ? await _selectMultiFiles(allowedExtension)
          : await _selectSingleFile(allowedExtension);
      return (files: picked, skipped: 0);
    } on PlatformException catch (e) {
      throw InputPickException.fromPlatform(e);
    }
  }

  /// Picks a folder and finds its matching files. On mobile the native
  /// channel opens it in place on iOS and copies its matching files into
  /// the input cache on Android.
  Future<List<XFile>?> _pickDirectoryFiles() async {
    if (!MobileIoChannel.isSupported) {
      final Directory? dir =
          await DirectorySelectionServices(ref).selectDirectoryAdaptive();
      return dir == null ? null : _crawl(dir);
    }
    final cache = await InputCacheServices.create();
    final channel = MobileIoChannel.instance;
    final subscription =
        onProgress == null ? null : channel.progress.listen(onProgress);
    try {
      return await cache.withSessionDir('folder', (destination) async {
        final Directory? dir = await channel.pickFolder(
          extensions: allowedExtension.extensions ?? const [],
          destination: destination,
        );
        // Crawl while the copied folder is still protected from pruning.
        return dir == null ? null : _crawl(dir);
      });
    } on PlatformException catch (e) {
      throw InputPickException.fromPlatform(e);
    } finally {
      await subscription?.cancel();
    }
  }

  /// Picks and extracts an archive. Returns null when the picker is
  /// dismissed.
  Future<List<XFile>?> _pickArchive() async {
    final XFile? archive;
    try {
      archive = await _selectArchiveFile();
    } on PlatformException catch (e) {
      throw InputPickException.fromPlatform(e);
    }
    if (archive == null) {
      return null;
    }
    if (!isArchivePath(archive.path)) {
      throw const InputPickException(
        'Choose a .zip, .tar.gz, or .tgz archive.',
      );
    }
    onProgress?.call(const InputCopyProgress.preparing());
    final cache = await InputCacheServices.create();
    final files = await ArchiveInputServices(cache)
        .extract(File(archive.path), allowedExtension);
    return files.map((e) => XFile(e.path)).toList();
  }

  Future<XFile?> _selectArchiveFile() async {
    if (Platform.isAndroid) {
      final picked = await _selectUsingFilePicker();
      return picked.isEmpty ? null : picked.first;
    }
    return await openFile(acceptedTypeGroups: [archiveTypeGroup]);
  }

  ({List<XFile> files, int duplicate}) _checkDuplicateFiles(
      List<File> current, List<XFile> results) {
    if (results.isEmpty) {
      return (files: [], duplicate: 0);
    }
    final files = current.map((e) => e.path).toSet();
    final newFiles = results
        .where((e) => !files.contains(e.path))
        .map((e) => XFile(e.path))
        .toList();
    final diff = results.length - newFiles.length;
    return (files: newFiles, duplicate: diff);
  }

  Future<void> _addMoreToProvider(List<XFile> result) async {
    final notifier = ref.read(fileInputProvider.notifier);
    if (result.isNotEmpty) {
      await notifier.addMoreFiles(result, allowedExtension);
    }
  }

  Future<void> _updateProvider(List<XFile> result) async {
    final notifier = ref.read(fileInputProvider.notifier);

    if (result.isNotEmpty) {
      await notifier.addFiles(result, allowedExtension);
    }
  }

  Future<List<XFile>> _selectMultiFiles(XTypeGroup allowedExtension) async {
    final fileList = await openFiles(
      acceptedTypeGroups: [allowedExtension],
    );
    return fileList;
  }

  List<SegulInputFile> mapFilesToSegulInputFile(
      List<XFile> files, XTypeGroup xTypeGroup) {
    return files.map((e) {
      return SegulInputFile(
        file: File(e.path),
        type: matchTypeByXTypeGroup(xTypeGroup),
      );
    }).toList();
  }

  Future<List<XFile>> _selectSingleFile(XTypeGroup allowedExtension) async {
    final result = await openFile(
      acceptedTypeGroups: [allowedExtension],
    );
    return result == null ? [] : [result];
  }

  // Do selection without data. The Android picker copies the file into
  // the app cache before returning.
  Future<List<XFile>> _selectUsingFilePicker() async {
    final result = await FilePicker.pickFile(
      type: FileType.any,
      onFileLoading: _onPickerStatus,
    );
    final path = result?.path;
    if (path == null) {
      return [];
    }
    return [XFile(path)];
  }

  // Do selection without data. The Android picker copies every file into
  // the app cache before returning, which takes a while for many files.
  Future<List<XFile>> _selectMultiUsingFilePicker() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      onFileLoading: _onPickerStatus,
    );
    return result
        .map((e) => e.path)
        .whereType<String>()
        .map((path) => XFile(path))
        .toList();
  }

  void _onPickerStatus(FilePickerStatus status) {
    if (status == FilePickerStatus.picking) {
      onProgress?.call(const InputCopyProgress.preparing());
    }
  }
}

/// Keeps the [picked] files that match [type]. The Android picker cannot
/// filter by extension, so other files are counted as skipped.
({List<XFile> files, int skipped}) filterPickedFiles(
  List<XFile> picked,
  XTypeGroup type,
) {
  final files =
      picked.where((e) => matchesTypeGroup(File(e.path), type)).toList();
  return (files: files, skipped: picked.length - files.length);
}
