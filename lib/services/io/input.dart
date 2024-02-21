import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
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
    default:
      return SegulType.standardSequence;
  }
}

class FileInputServices {
  const FileInputServices(
    this.ref, {
    required this.allowedExtension,
    required this.allowMultiple,
  });

  final WidgetRef ref;
  final XTypeGroup allowedExtension;
  final bool allowMultiple;

  Future<void> selectFiles() async {
    List<XFile> results = [];
    if (allowMultiple) {
      results = await _selectMultiFileAdaptive();
    } else {
      results = await _selectFileAdaptive();
    }
    await _updateProvider(results);
  }

  Future<int> addMoreFiles(List<File> currentFiles) async {
    List<XFile> results = [];
    if (allowMultiple) {
      results = await _selectMultiFileAdaptive();
    } else {
      results = await _selectFileAdaptive();
    }
    final newFiles = _checkDuplicateFiles(currentFiles, results);
    await _addMoreToProvider(newFiles.files);
    return newFiles.duplicate;
  }

  Future<void> addDirectory() async {
    final result = await _selectDirectoryAdaptive();

    if (result != null) {
      final files = DirectoryCrawler(result).crawlByType(allowedExtension);
      await _updateProvider(files.map((e) => XFile(e.path)).toList());
    }
  }

  Future<int> addMoreDirectory(List<File> currentFiles) async {
    final result = await _selectDirectoryAdaptive();
    if (result != null) {
      final files = DirectoryCrawler(result).crawlByType(allowedExtension);
      final newFiles = _checkDuplicateFiles(
          currentFiles, files.map((e) => XFile(e.path)).toList());
      await _addMoreToProvider(newFiles.files);
      return newFiles.duplicate;
    }
    return 0;
  }

  Future<List<XFile>> _selectMultiFileAdaptive() async {
    if (Platform.isAndroid) {
      return await _selectMultiUsingFilePicker(allowedExtension);
    } else {
      return await _selectMultiFiles(allowedExtension);
    }
  }

  Future<List<XFile>> _selectFileAdaptive() async {
    if (Platform.isAndroid) {
      return await _selectUsingFilePicker(allowedExtension);
    } else {
      return await _selectSingleFile(allowedExtension);
    }
  }

  Future<Directory?> _selectDirectoryAdaptive() async {
    if (Platform.isAndroid) {
      return await _selectDirectoryFilePicker();
    } else {
      return await _selectDirectory();
    }
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

  Future<Directory?> _selectDirectory() async {
    final result = await getDirectoryPath();
    if (result != null) {
      return Directory(result);
    }
    return null;
  }

  Future<Directory?> _selectDirectoryFilePicker() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      return Directory(result);
    }
    return null;
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

// Do selection without data.
  Future<List<XFile>> _selectUsingFilePicker(
      XTypeGroup allowedExtension) async {
    final result = await FilePicker.platform
        .pickFiles(allowMultiple: false, type: FileType.any);

    if (result == null) {
      return [];
    }
    return [XFile(result.files.first.path!)];
  }

// Do selection without data.
  Future<List<XFile>> _selectMultiUsingFilePicker(
      XTypeGroup allowedExtension) async {
    final result = await FilePicker.platform
        .pickFiles(allowMultiple: true, type: FileType.any);

    if (result == null) {
      return [];
    }
    return result.files.map((e) => XFile(e.path!)).toList();
  }
}
