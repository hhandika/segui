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

/// Sequence files that receive sequences in the sequence addition task.
/// Same extensions as [sequenceTypeGroup], but a separate group so
/// destination files stay apart from the files that supply sequences.
const XTypeGroup destinationSequenceTypeGroup = XTypeGroup(
  label: 'Destination sequence',
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

/// MAF files, plain or gzipped. The picker accepts any `.gz` file, so use
/// [isMafPath] to check the full extension.
const XTypeGroup mafTypeGroup = XTypeGroup(
  label: 'MAF',
  extensions: [...mafExtensions, ...gunzipExtensions],
  uniformTypeIdentifiers: [
    'public.plain-text',
    'org.gnu.gnu-zip-archive',
  ],
);

/// BED files, plain or gzipped. Use [isBedPath] to check the full extension.
const XTypeGroup bedTypeGroup = XTypeGroup(
  label: 'BED',
  extensions: [...bedExtensions, ...gunzipExtensions],
  uniformTypeIdentifiers: [
    'public.plain-text',
    'org.gnu.gnu-zip-archive',
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

const List<String> mafExtensions = [
  'maf',
];

const List<String> bedExtensions = [
  'bed',
];

/// Whether [path] is a MAF file, such as `genome.maf` or `genome.maf.gz`.
bool isMafPath(String path) => _hasExtension(path, mafExtensions);

/// Whether [path] is a BED file, such as `loci.bed` or `loci.bed.gz`.
bool isBedPath(String path) => _hasExtension(path, bedExtensions);

/// Whether [file] belongs to [type]. MAF and BED files match by their full
/// extension, so gzipped reads are not mistaken for gzipped MAF files.
bool matchesTypeGroup(File file, XTypeGroup type) {
  if (type == mafTypeGroup) {
    return isMafPath(file.path);
  }
  if (type == bedTypeGroup) {
    return isBedPath(file.path);
  }
  return type.extensions?.contains(file.fileExtension) ?? false;
}

// Matches [extensions] case-insensitively, ignoring a gzip extension.
bool _hasExtension(String path, List<String> extensions) {
  String name = p.basename(path).toLowerCase();
  if (gunzipExtensions.contains(p.extension(name).replaceFirst('.', ''))) {
    name = p.withoutExtension(name);
  }
  final String ext = p.extension(name);
  return ext.length > 1 && extensions.contains(ext.substring(1));
}

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
  ...mafExtensions,
  ...bedExtensions,
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

/// Partition-only file extensions. Partitions saved as `.txt` or `.nex`
/// show the text or NEXUS icon instead.
const List<String> partitionExtensions = [
  'part',
  'partition',
];

/// File formats drawn with their own icon in file lists.
enum FileIconType {
  fasta('fasta', 'FASTA'),
  nexus('nexus', 'NEXUS'),
  phylip('phylip', 'PHYLIP'),
  fastq('fastq', 'FASTQ'),
  gzip('gzip', 'Gzip'),
  csv('csv', 'CSV'),
  text('text', 'Text'),
  partition('partition', 'Partition'),
  log('log', 'Log'),
  zip('zip', 'Archive'),
  unknown('unknown', 'Other');

  const FileIconType(this._name, this.label);

  final String _name;

  /// Format name shown in file summaries.
  final String label;

  /// SVG asset of the icon. Asset keys always use POSIX separators.
  String get assetPath => 'assets/images/files/$_name.svg';

  /// Icon type for a file named [fileName], matched by extension. Gzip
  /// files show the format they compress when it is FASTQ.
  static FileIconType fromFileName(String fileName) {
    final String name = fileName.toLowerCase();
    final String ext = p.extension(name).replaceFirst('.', '');
    if (gunzipExtensions.contains(ext)) {
      final String innerExt =
          p.extension(p.withoutExtension(name)).replaceFirst('.', '');
      return fastqExtensions.contains(innerExt)
          ? FileIconType.fastq
          : FileIconType.gzip;
    }
    if (fastaExtensions.contains(ext)) return FileIconType.fasta;
    if (nexusExtensions.contains(ext)) return FileIconType.nexus;
    if (phylipExtensions.contains(ext)) return FileIconType.phylip;
    if (fastqExtensions.contains(ext)) return FileIconType.fastq;
    if (tabularExtensions.contains(ext)) return FileIconType.csv;
    if (partitionExtensions.contains(ext)) return FileIconType.partition;
    if (ext == 'log') return FileIconType.log;
    if (plainTextExtensions.contains(ext)) return FileIconType.text;
    if (compressionExtensions.contains(ext)) return FileIconType.zip;
    return FileIconType.unknown;
  }
}

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
    return FileIconType.fromFileName(p.basename(file.path)).assetPath;
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
