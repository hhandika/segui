import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/viewers/csv.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/services/viewers/read_report.dart';

/// Bytes read from the start of a NEXUS file to tell its blocks apart.
const int _nexusHeaderBytes = 16 * 1024;

/// Largest file the inspector reads in full for its counts. FASTA
/// alignments are indexed rather than read, so any size is counted.
const int inspectorContentLimitBytes = 64 * 1024 * 1024;

/// Counts shown with thousands separators, such as 12,345.
final NumberFormat _countFormat = NumberFormat('#,##0');

/// NEXUS blocks that hold sequences.
const Set<String> _nexusSequenceBlocks = {'data', 'characters', 'unaligned'};

/// What a file holds, which decides the viewer that opens it.
enum FileContentKind {
  alignment('Sequences'),
  partition('Partition'),
  table('Table'),
  readReport('Read report'),
  text('Text'),
  other('Other');

  const FileContentKind(this.label);

  final String label;
}

/// Whether the start of a NEXUS file, [header], has a sets block and no
/// sequence block, as in a partition written by SEGUL.
bool isNexusPartitionHeader(String header) {
  final String text =
      header.replaceAll(RegExp(r'\[[^\]]*\]'), ' ').toLowerCase();
  final Iterable<String> blocks = RegExp(r'\bbegin\s+(\w+)\s*;')
      .allMatches(text)
      .map((match) => match.group(1)!);
  if (blocks.any(_nexusSequenceBlocks.contains) ||
      RegExp(r'\bmatrix\b').hasMatch(text)) {
    return false;
  }
  return blocks.contains('sets') || RegExp(r'\bcharset\b').hasMatch(text);
}

/// Whether [file] is a NEXUS partition rather than a NEXUS alignment.
Future<bool> isNexusPartition(File file) async {
  if (!nexusExtensions.contains(file.fileExtension.toLowerCase())) {
    return false;
  }
  try {
    final List<int> bytes = await file
        .openRead(0, _nexusHeaderBytes)
        .fold<List<int>>([], (all, chunk) => all..addAll(chunk));
    return isNexusPartitionHeader(
      utf8.decode(bytes, allowMalformed: true),
    );
  } on FileSystemException {
    return false;
  }
}

/// What [file] holds, read from its extension and, for NEXUS and text
/// files, the start of its content.
Future<FileContentKind> contentKindOf(File file) async {
  final String ext = file.fileExtension.toLowerCase();
  if (partitionExtensions.contains(ext)) {
    return FileContentKind.partition;
  }
  if (isAlignmentViewable(file)) {
    return await isNexusPartition(file)
        ? FileContentKind.partition
        : FileContentKind.alignment;
  }
  if (tabularExtensions.contains(ext)) {
    return FileContentKind.table;
  }
  if (isReadReport(file)) {
    return FileContentKind.readReport;
  }
  if (plainTextExtensions.contains(ext)) {
    if (p.basenameWithoutExtension(file.path).endsWith('_partition')) {
      return FileContentKind.partition;
    }
    return FileContentKind.text;
  }
  return FileContentKind.other;
}

/// Files in [files] the alignment viewer can open, leaving out NEXUS
/// partitions.
Future<List<File>> alignmentFilesOf(Iterable<File> files) async {
  final List<File> alignments = [];
  for (final File file in files) {
    if (isAlignmentViewable(file) && !await isNexusPartition(file)) {
      alignments.add(file);
    }
  }
  return alignments;
}

/// One partition: its name and the sites it spans.
class PartitionEntry {
  const PartitionEntry({required this.name, required this.lastSite});

  final String name;

  /// Last one-based site in the partition's ranges.
  final int lastSite;
}

/// Partitions in a NEXUS sets block (`charset name = 1-100;`) or a
/// RAxML partition file (`DNA, name = 1-100`).
List<PartitionEntry> parsePartitions(String text) {
  final String content = text.replaceAll(RegExp(r'\[[^\]]*\]'), ' ');
  final Iterable<RegExpMatch> nexus = RegExp(
    r'\bcharset\s+([^=;]+?)\s*=\s*([^;]+);',
    caseSensitive: false,
  ).allMatches(content);
  if (nexus.isNotEmpty) {
    return [
      for (final match in nexus) _entry(match.group(1)!, match.group(2)!),
    ];
  }
  final RegExp raxml =
      RegExp(r'^(?:[^,=]+,)?\s*([^,=]+?)\s*=\s*([\d\s\-\\,]+)$');
  return [
    for (final line in const LineSplitter().convert(content))
      if (raxml.firstMatch(line.trim()) case final RegExpMatch match)
        _entry(match.group(1)!, match.group(2)!),
  ];
}

// Codon strides such as `\3` are not sites.
PartitionEntry _entry(String name, String ranges) {
  final Iterable<int> sites = RegExp(r'\d+')
      .allMatches(ranges.replaceAll(RegExp(r'\\\d+'), ''))
      .map((match) => int.parse(match.group(0)!));
  return PartitionEntry(
    name: name.trim(),
    lastSite: sites.isEmpty ? 0 : sites.reduce((a, b) => a > b ? a : b),
  );
}

/// A fact about an inspected file, as a label and its value.
class InspectionDetail {
  const InspectionDetail(this.label, this.value);

  final String label;
  final String value;
}

/// What the workbench inspector shows about one file.
class FileInspection {
  const FileInspection({
    required this.file,
    required this.kind,
    required this.format,
    required this.details,
    this.note,
  });

  final File file;
  final FileContentKind kind;
  final FileIconType format;

  /// Size and content counts, such as sequences and sites.
  final List<InspectionDetail> details;

  /// Why counts are missing, such as a file too large to read here.
  final String? note;
}

/// Loads the sequences of an alignment file.
typedef AlignmentLoader = Future<AlignmentViewData> Function(String path);

/// Reads a file's kind, size, and content counts for the inspector.
class FileInspector {
  const FileInspector({required this.loadAlignment});

  final AlignmentLoader loadAlignment;

  Future<FileInspection> inspect(File file) async {
    final FileIconType format =
        FileIconType.fromFileName(p.basename(file.path));
    if (!await file.exists()) {
      return FileInspection(
        file: file,
        kind: FileContentKind.other,
        format: format,
        details: const [],
        note: 'The file no longer exists.',
      );
    }
    final FileContentKind kind = await contentKindOf(file);
    final int bytes = await file.length();
    final List<InspectionDetail> details = [
      InspectionDetail('Format', format.label),
      InspectionDetail('Content', kind.label),
      InspectionDetail('Size', FileUtils().formatSize(bytes)),
    ];
    if (kind == FileContentKind.other) {
      return FileInspection(
        file: file,
        kind: kind,
        format: format,
        details: details,
      );
    }
    final bool isIndexed =
        kind == FileContentKind.alignment && format == FileIconType.fasta;
    if (bytes > inspectorContentLimitBytes && !isIndexed) {
      return FileInspection(
        file: file,
        kind: kind,
        format: format,
        details: details,
        note: 'Too large to count here. Open it to see its content.',
      );
    }
    try {
      details.addAll(await _contentDetails(file, kind));
    } catch (_) {
      return FileInspection(
        file: file,
        kind: kind,
        format: format,
        details: details,
        note: 'Could not read the file content.',
      );
    }
    return FileInspection(
      file: file,
      kind: kind,
      format: format,
      details: details,
    );
  }

  Future<List<InspectionDetail>> _contentDetails(
    File file,
    FileContentKind kind,
  ) async {
    switch (kind) {
      case FileContentKind.alignment:
        final AlignmentViewData data = await loadAlignment(file.path);
        data.dispose();
        return [
          InspectionDetail('Sequences', _countFormat.format(data.names.length)),
          InspectionDetail(
            data.isAligned ? 'Sites' : 'Longest sequence',
            _countFormat.format(data.length),
          ),
          InspectionDetail('Data type', data.isDna ? 'DNA' : 'Amino acid'),
          InspectionDetail('Aligned', data.isAligned ? 'Yes' : 'No'),
        ];
      case FileContentKind.partition:
        final List<PartitionEntry> partitions =
            parsePartitions(await file.readAsString());
        final int sites = partitions.fold(
          0,
          (last, entry) => entry.lastSite > last ? entry.lastSite : last,
        );
        return [
          InspectionDetail(
              'Partitions', _countFormat.format(partitions.length)),
          if (sites > 0) InspectionDetail('Sites', _countFormat.format(sites)),
        ];
      case FileContentKind.table:
        final List<List<dynamic>> rows = await CsvParser().parse(file);
        return [
          InspectionDetail(
            'Rows',
            _countFormat.format(rows.isEmpty ? 0 : rows.length - 1),
          ),
          InspectionDetail(
            'Columns',
            _countFormat.format(rows.isEmpty ? 0 : rows.first.length),
          ),
        ];
      case FileContentKind.readReport:
        final Object? report = jsonDecode(await file.readAsString());
        final List<dynamic> samples = report is Map<String, dynamic>
            ? report['samples'] as List<dynamic>? ?? const []
            : const [];
        return [
          InspectionDetail('Samples', _countFormat.format(samples.length)),
        ];
      case FileContentKind.text:
        final int lines = await file
            .openRead()
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .length;
        return [InspectionDetail('Lines', _countFormat.format(lines))];
      case FileContentKind.other:
        return const [];
    }
  }
}
