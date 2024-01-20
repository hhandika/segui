import 'dart:io';

import 'package:segui/services/io.dart';
import 'package:segui/src/rust/api/sequence.dart';

class ConcatRunnerServices {
  const ConcatRunnerServices({
    required this.inputFiles,
    required this.inputFormat,
    required this.datatype,
    required this.outputDir,
    required this.outputPrefix,
    required this.outputFormat,
    required this.partitionFormat,
    required this.isCodonModel,
    required this.isInterleave,
  });

  final List<SegulInputFile> inputFiles;
  final String inputFormat;
  final String datatype;
  final Directory outputDir;
  final String outputPrefix;
  final String outputFormat;
  final bool isInterleave;
  final String partitionFormat;
  final bool isCodonModel;

  Future<void> run() async {
    String outputFmt = getOutputFmt(outputFormat, isInterleave);
    String partitionFmt = getPartitionFmt(partitionFormat, isCodonModel);
    List<String> finalInputFiles = IOServices()
        .convertPathsToString(inputFiles, SegulType.standardSequence);
    await AlignmentServices(
      inputFiles: finalInputFiles,
      inputFmt: inputFormat,
      datatype: datatype,
      outputDir: outputDir.path,
    ).concatAlignment(
      outFname: outputPrefix,
      outFmtStr: outputFmt,
      partitionFmt: partitionFmt,
    );
  }
}
