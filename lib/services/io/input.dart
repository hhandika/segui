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
    required this.isAddNew,
  });

  final WidgetRef ref;
  final XTypeGroup allowedExtension;
  final bool allowMultiple;
  final bool isAddNew;

  Future<void> selectFiles() async {
    if (allowMultiple) {
      if (Platform.isAndroid) {
        var results = _selectMultiUsingFilePicker(allowedExtension);
        _updateProvider(await results);
      } else {
        var results = _selectMultiFiles(allowedExtension);
        _updateProvider(await results);
      }
    } else {
      if (Platform.isAndroid) {
        final results = await _selectUsingFilePicker(allowedExtension);
        if (results != null) {
          _updateProvider([results]);
        }
      } else {
        final results = await _selectSingleFile(allowedExtension);
        if (results != null) {
          _updateProvider([XFile(results.file.path)]);
        }
      }
    }
  }

  Future<void> addDirectory() async {
    final result = Platform.isAndroid
        ? await _pickDirectoryFilePicker()
        : await _pickDirectory();

    if (result != null) {
      final files = DirectoryCrawler(result).crawlByType(allowedExtension);
      _updateProvider(files.map((e) => XFile(e.path)).toList());
    }
  }

  void _updateProvider(List<XFile> result) {
    final notifier = ref.read(fileInputProvider.notifier);
    if (result.isNotEmpty) {
      if (isAddNew) {
        notifier.addFiles(result, allowedExtension);
      } else {
        notifier.addMoreFiles(result, allowedExtension);
      }
    }
  }

  Future<Directory?> _pickDirectory() async {
    final result = await getDirectoryPath();
    if (result != null) {
      return Directory(result);
    }
    return null;
  }

  Future<Directory?> _pickDirectoryFilePicker() async {
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

  Future<SegulInputFile?> _selectSingleFile(XTypeGroup allowedExtension) async {
    final result = await openFile(
      acceptedTypeGroups: [allowedExtension],
    );
    return result == null
        ? null
        : SegulInputFile(
            file: File(result.path),
            type: matchTypeByXTypeGroup(allowedExtension),
          );
  }

  // Do selection without data.
  Future<XFile?> _selectUsingFilePicker(XTypeGroup allowedExtension) async {
    final result = await FilePicker.platform
        .pickFiles(allowMultiple: false, type: FileType.any);

    if (result == null) {
      return null;
    }
    return XFile(result.files.first.path!);
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
