//! File association and file type matching.
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:segui/services/io/io.dart';
import 'package:path/path.dart' as p;

/// File type group. Used by the file_selector package
/// to filter file types.
/// [label] is the label to display in the file picker.
/// [extensions] is a list of file extensions to filter.
/// [uniformTypeIdentifiers] is a list of uniform type identifiers to filter.
/// It is used by Apple's devices.
const XTypeGroup plainTextTypeGroup = XTypeGroup(
  label: 'Text',
  extensions: ['txt', 'text'],
  uniformTypeIdentifiers: [
    'public.plain-text',
  ],
);

/// 'com.segui.fastq' is a custom uniform type identifier
/// for fastq files. Registered in the info.plist file
/// as UTExportedTypeDeclarations and UTImportedTypeDeclarations.
const XTypeGroup genomicRawReadTypeGroup = XTypeGroup(
  label: 'Sequence Read',
  extensions: [
    ...fastqExtensions,
    ...gunzipExtensions,
  ],
  uniformTypeIdentifiers: [
    'com.segui.fastq',
    'org.gnu.gnu-zip-archive',
  ],
);

const XTypeGroup sequenceTypeGroup = XTypeGroup(
  label: 'Sequence',
  extensions: [
    ...fastaExtensions,
    ...nexusExtensions,
    ...phylipExtensions,
  ],
  uniformTypeIdentifiers: [
    'com.segui.fasta',
    'com.segui.nexus',
    'com.segui.phylip',
  ],
);

const XTypeGroup partitionTypeGroup = XTypeGroup(
  label: 'Partition',
  extensions: [
    ...nexusExtensions,
    'txt',
    'part',
    'partition',
  ],
  uniformTypeIdentifiers: [
    'com.segui.partition',
    'public.plain-text',
    'com.segui.nexus',
  ],
);

const XTypeGroup genomicContigTypeGroup = XTypeGroup(
  label: 'Contig',
  extensions: fastaExtensions,
  uniformTypeIdentifiers: [
    'com.segui.fasta',
  ],
);

const List<String> fastaExtensions = [
  'fasta',
  'fa',
  'fas',
  'fsa',
  'fna',
];

const List<String> nexusExtensions = [
  'nexus',
  'nex',
  'nxs',
];

const List<String> phylipExtensions = [
  'phylip',
  'phy',
  'ph',
];

const List<String> fastqExtensions = [
  'fastq',
  'fq',
];

const List<String> gunzipExtensions = [
  'gz',
  'gzip',
];

const List<String> sequenceExtensions = [
  ...fastaExtensions,
  ...nexusExtensions,
  ...phylipExtensions,
  ...fastqExtensions,
  ...gunzipExtensions,
];

const List<String> tabularExtensions = [
  'csv',
];

/// Supported text file extensions.
/// Used to determine if a file is
/// a text file.
/// Allow segui to open text files
const List<String> plainTextExtensions = [
  'txt',
  'text',
  'log',
  'conf',
  'toml',
  'yaml',
  'nex',
];

const List<String> compressionExtensions = [
  'zip',
  'tar',
  'gz',
  'gzip',
  'bz2',
  'bzip2',
  'xz',
  'zst',
  '7zip',
];

const Map<CommonFileType, String> commonFileIcons = {
  CommonFileType.sequence: 'assets/images/dna.svg',
  CommonFileType.plainText: 'assets/images/text.svg',
  CommonFileType.tabulated: 'assets/images/table.svg',
  CommonFileType.zip: 'assets/images/zip.svg',
  CommonFileType.other: 'assets/images/unknown.svg',
};

/// Common file type to match
/// file type with icons.
enum CommonFileType {
  sequence,
  plainText,
  tabulated,
  zip,
  other,
}

class FileAssociation extends FileUtils {
  FileAssociation({required this.file});

  final File file;

  bool get isSupportedViewExtension {
    final fileType = commonFileTYpe;
    return fileType == CommonFileType.plainText ||
        fileType == CommonFileType.tabulated;
  }

  CommonFileType get commonFileTYpe {
    return file.fileType;
  }

  String get matchingIconPath {
    final fileType = commonFileTYpe;
    return commonFileIcons[fileType]!;
  }

  bool get isSequenceFile {
    return sequenceExtensions.contains(file.fileExtension);
  }

  bool get isTabularFile {
    return tabularExtensions.contains(file.fileExtension);
  }
}

extension FileMatching on File {
  CommonFileType get fileType {
    String ext = fileExtension;
    if (sequenceExtensions.any((element) => element == ext)) {
      return CommonFileType.sequence;
    } else if (plainTextExtensions.any((element) => element == ext)) {
      return CommonFileType.plainText;
    } else if (tabularExtensions.any((element) => element == ext)) {
      return CommonFileType.tabulated;
    } else if (compressionExtensions.any((element) => element == ext)) {
      return CommonFileType.zip;
    } else {
      return CommonFileType.other;
    }
  }
}

extension FileExtension on File {
  // Get file extension without the dot.
  String get fileExtension {
    String ext = p.extension(path);
    if (ext.isNotEmpty) {
      return ext.substring(1);
    }
    return '';
  }
}
