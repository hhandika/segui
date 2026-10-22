import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/src/rust/api/contig.dart';
import 'package:segui/src/rust/api/maf.dart';
import 'package:segui/src/rust/api/reads.dart';

class ContigSummaryRunner {
  const ContigSummaryRunner({
    required this.inputFiles,
    required this.inputFmt,
    required this.outputDir,
    required this.prefix,
  });

  final List<SegulInputFile> inputFiles;
  final String inputFmt;
  final String prefix;
  final Directory outputDir;

  Future<void> run() async {
    List<String> finalInputFiles =
        IOServices().convertPathsToString(inputFiles, SegulType.genomicContig);
    if (finalInputFiles.isEmpty) {
      throw 'No input files';
    }

    await ContigServices(
      files: finalInputFiles,
      fileFmt: inputFmt,
      outputDir: outputDir.path,
    ).summarize(prefix: prefix.isEmpty ? null : prefix);
  }
}

class ReadSummaryRunner {
  const ReadSummaryRunner({
    required this.inputFiles,
    required this.inputFmt,
    required this.outputDir,
    required this.prefix,
    required this.mode,
    this.phred = 'Auto',
  });

  final List<SegulInputFile> inputFiles;
  final String inputFmt;
  final Directory outputDir;
  final String prefix;
  final String mode;

  /// Quality score offset: Auto, 33, or 64.
  final String phred;

  /// Runs the summary and returns the files it wrote.
  Future<ReadSummaryOutput> run() async {
    List<String> finalInputFiles =
        IOServices().convertPathsToString(inputFiles, SegulType.genomicReads);
    if (finalInputFiles.isEmpty) {
      throw 'No input files';
    }
    return await RawReadServices(
      files: finalInputFiles,
      fileFmt: inputFmt,
      outputDir: outputDir.path,
    ).summarize(
      mode: mode,
      prefix: prefix.isEmpty ? null : prefix,
      phred: phred.toLowerCase(),
    );
  }
}

/// Species names from a comma-separated list, ignoring blank entries.
List<String> parseSpeciesList(String text) {
  return text
      .split(',')
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .toList();
}

/// Whether [text] is empty or a whole number of zero or more.
bool isValidOptionalCount(String text) {
  final String value = text.trim();
  return value.isEmpty || (int.tryParse(value) ?? -1) >= 0;
}

/// Whether [text] is empty or a number, which may be negative.
bool isValidOptionalNumber(String text) {
  final String value = text.trim();
  return value.isEmpty || double.tryParse(value) != null;
}

BigInt? _optionalCount(String text) {
  final String value = text.trim();
  return value.isEmpty ? null : BigInt.parse(value);
}

String? _optionalText(String text) {
  final String value = text.trim();
  return value.isEmpty ? null : value;
}

/// MAF files from [inputFiles]. Throws if a selected file is not a MAF file.
List<String> _mafPaths(List<SegulInputFile> inputFiles) {
  final List<String> paths = IOServices()
      .convertPathsToString(inputFiles, SegulType.multipleAlignment);
  if (paths.isEmpty) {
    throw 'No input files';
  }
  for (final String path in paths) {
    if (!isMafPath(path)) {
      throw 'Not a MAF file: ${p.basename(path)}';
    }
  }
  return paths;
}

class MafConversionRunner {
  const MafConversionRunner({
    required this.inputFiles,
    required this.outputDir,
    required this.outputFormat,
    required this.isInterleave,
    this.groupBy = 'block',
    this.isClipped = true,
    this.isStrandAware = false,
    this.refSpecies = '',
    this.minBlockLength = '',
    this.minSpecies = '',
    this.minScore = '',
    this.species = '',
  });

  /// MAF files, plus an optional BED file of loci.
  final List<SegulInputFile> inputFiles;
  final Directory outputDir;
  final String outputFormat;
  final bool isInterleave;

  /// A key of [mafGroupingOptions]. Used only without a BED file.
  final String groupBy;

  /// Clip blocks to each BED locus. Used only with a BED file.
  final bool isClipped;

  /// Reverse complement minus-strand BED loci.
  final bool isStrandAware;

  /// Optional text fields from the form. Empty means not set.
  final String refSpecies;
  final String minBlockLength;
  final String minSpecies;
  final String minScore;

  /// Comma-separated species to write. Empty writes every species.
  final String species;

  Future<void> run() async {
    final List<String> mafFiles = _mafPaths(inputFiles);
    final List<String> bedFiles =
        IOServices().convertPathsToString(inputFiles, SegulType.bed);
    if (bedFiles.length > 1) {
      throw 'Select at most one BED file.';
    }
    if (bedFiles.isNotEmpty && !isBedPath(bedFiles.first)) {
      throw 'Not a BED file: ${p.basename(bedFiles.first)}';
    }
    await MafConversionServices(
      inputFiles: mafFiles,
      bedFile: bedFiles.isEmpty ? null : bedFiles.first,
      outputDir: outputDir.path,
      outputFmt: getOutputFmt(outputFormat, isInterleave),
      groupBy: groupBy,
      clip: isClipped,
      strandAware: isStrandAware,
      refSpecies: _optionalText(refSpecies),
      minBlockLen: _optionalCount(minBlockLength),
      minSpecies: _optionalCount(minSpecies),
      minScore: double.tryParse(minScore.trim()),
      species: parseSpeciesList(species),
    ).convert();
  }
}

class MafSummaryRunner {
  const MafSummaryRunner({
    required this.inputFiles,
    required this.outputDir,
    this.prefix = '',
    this.refSpecies = '',
    this.species = '',
  });

  final List<SegulInputFile> inputFiles;
  final Directory outputDir;
  final String prefix;
  final String refSpecies;

  /// Comma-separated species to report. Empty reports every species.
  final String species;

  Future<void> run() async {
    await MafSummaryServices(
      inputFiles: _mafPaths(inputFiles),
      outputDir: outputDir.path,
      prefix: _optionalText(prefix),
      refSpecies: _optionalText(refSpecies),
      species: parseSpeciesList(species),
    ).summarize();
  }
}
