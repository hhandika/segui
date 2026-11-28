import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/src/rust/api/progress.dart';
import 'package:segui/src/rust/api/tree.dart';

/// Tree files from [inputFiles]. Throws if a selected file is not a tree file.
List<String> treePaths(List<SegulInputFile> inputFiles) {
  final List<String> paths =
      IOServices().convertPathsToString(inputFiles, SegulType.phylogeneticTree);
  if (paths.isEmpty) {
    throw 'No input files';
  }
  for (final String path in paths) {
    if (!isTreePath(path)) {
      throw 'Not a tree file: ${p.basename(path)}';
    }
  }
  return paths;
}

class TreeConversionRunner {
  const TreeConversionRunner({
    required this.inputFiles,
    required this.outputDir,
    required this.inputFormat,
    required this.outputFormat,
    this.isTranslateSkipped = false,
    this.isAnnotationStripped = false,
    this.isGzipped = false,
    this.monitor,
  });

  final List<SegulInputFile> inputFiles;
  final Directory outputDir;

  /// A key of [treeInputFormat].
  final String inputFormat;

  /// A key of [treeOutputFormat].
  final String outputFormat;

  /// Write NEXUS trees without a TRANSLATE block.
  final bool isTranslateSkipped;
  final bool isAnnotationStripped;
  final bool isGzipped;

  /// Reports file progress and cancels the run. Null runs untracked.
  final RunMonitor? monitor;

  Future<void> run() async {
    await TreeConversionServices(
      inputFiles: treePaths(inputFiles),
      inputFmt: inputFormat,
      outputDir: outputDir.path,
      outputFmt: outputFormat,
      noTranslate: isTranslateSkipped,
      stripAnnotations: isAnnotationStripped,
      gzip: isGzipped,
    ).convert(monitor: monitor ?? RunMonitor());
  }
}
