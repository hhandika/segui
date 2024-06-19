// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0-dev.39.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:freezed_annotation/freezed_annotation.dart' hide protected;
part 'sequence.freezed.dart';

// These functions are ignored because they are not marked as `pub`: `count_min_tax`, `create_final_output_path`, `extract_partition_fname`, `generate_input_partition_path`, `log_info`, `match_parameters`, `match_params`, `match_params`, `match_removal_type`, `match_translation_table`, `parse_file`
// These functions are ignored (category: IgnoreBecauseExplicitAttribute): `check_file_count`, `check_file_count`, `check_file_count`, `check_file_count`, `check_file_count`, `check_file_count`, `check_file_count`, `check_file_count`, `check_file_count`, `check_file_count`, `check_file_count`, `find_input_input_files`, `find_input_input_files`, `find_input_input_files`, `find_input_input_files`, `find_input_input_files`, `find_input_input_files`, `find_input_input_files`, `find_input_input_files`, `find_input_input_files`, `find_input_input_files`, `find_input_input_files`, `match_datatype`, `match_datatype`, `match_datatype`, `match_datatype`, `match_datatype`, `match_datatype`, `match_datatype`, `match_datatype`, `match_datatype`, `match_datatype`, `match_datatype`, `match_input_fmt`, `match_input_fmt`, `match_input_fmt`, `match_input_fmt`, `match_input_fmt`, `match_input_fmt`, `match_input_fmt`, `match_input_fmt`, `match_input_fmt`, `match_input_fmt`, `match_input_fmt`, `match_output_fmt`, `match_output_fmt`, `match_output_fmt`, `match_output_fmt`, `match_output_fmt`, `match_output_fmt`, `match_output_fmt`, `match_output_fmt`, `match_output_fmt`, `match_output_fmt`, `match_output_fmt`, `match_partition_fmt`, `match_partition_fmt`, `match_partition_fmt`, `match_partition_fmt`, `match_partition_fmt`

Future<String> showDnaUppercase() =>
    RustLib.instance.api.crateApiSequenceShowDnaUppercase();

class AlignmentServices {
  final List<String> inputFiles;
  final String inputFmt;
  final String datatype;
  final String outputDir;

  const AlignmentServices({
    required this.inputFiles,
    required this.inputFmt,
    required this.datatype,
    required this.outputDir,
  });

  Future<void> concatAlignment(
          {required String outFname,
          required String outFmtStr,
          required String partitionFmt}) =>
      RustLib.instance.api.crateApiSequenceAlignmentServicesConcatAlignment(
          that: this,
          outFname: outFname,
          outFmtStr: outFmtStr,
          partitionFmt: partitionFmt);

  // HINT: Make it `#[frb(sync)]` to let it become the default constructor of Dart class.
  static Future<AlignmentServices> newInstance() =>
      RustLib.instance.api.crateApiSequenceAlignmentServicesNew();

  Future<void> summarizeAlignment(
          {required String outputPrefix, required BigInt interval}) =>
      RustLib.instance.api.crateApiSequenceAlignmentServicesSummarizeAlignment(
          that: this, outputPrefix: outputPrefix, interval: interval);

  @override
  int get hashCode =>
      inputFiles.hashCode ^
      inputFmt.hashCode ^
      datatype.hashCode ^
      outputDir.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlignmentServices &&
          runtimeType == other.runtimeType &&
          inputFiles == other.inputFiles &&
          inputFmt == other.inputFmt &&
          datatype == other.datatype &&
          outputDir == other.outputDir;
}

@freezed
sealed class FilteringParams with _$FilteringParams {
  const FilteringParams._();

  const factory FilteringParams.minTax(
    double field0,
  ) = FilteringParams_MinTax;
  const factory FilteringParams.alnLen(
    BigInt field0,
  ) = FilteringParams_AlnLen;
  const factory FilteringParams.parsInf(
    BigInt field0,
  ) = FilteringParams_ParsInf;
  const factory FilteringParams.percInf(
    double field0,
  ) = FilteringParams_PercInf;
  const factory FilteringParams.taxonAll(
    List<String> field0,
  ) = FilteringParams_TaxonAll;
  const factory FilteringParams.none() = FilteringParams_None;
}

class FilteringServices {
  final List<String> inputFiles;
  final String inputFmt;
  final String datatype;
  final String outputDir;
  final bool isConcat;
  final FilteringParams params;
  final String? outputFmt;
  final String? prefix;
  final String? partitionFmt;

  const FilteringServices({
    required this.inputFiles,
    required this.inputFmt,
    required this.datatype,
    required this.outputDir,
    required this.isConcat,
    required this.params,
    this.outputFmt,
    this.prefix,
    this.partitionFmt,
  });

  Future<void> filter() =>
      RustLib.instance.api.crateApiSequenceFilteringServicesFilter(
        that: this,
      );

  // HINT: Make it `#[frb(sync)]` to let it become the default constructor of Dart class.
  static Future<FilteringServices> newInstance() =>
      RustLib.instance.api.crateApiSequenceFilteringServicesNew();

  @override
  int get hashCode =>
      inputFiles.hashCode ^
      inputFmt.hashCode ^
      datatype.hashCode ^
      outputDir.hashCode ^
      isConcat.hashCode ^
      params.hashCode ^
      outputFmt.hashCode ^
      prefix.hashCode ^
      partitionFmt.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilteringServices &&
          runtimeType == other.runtimeType &&
          inputFiles == other.inputFiles &&
          inputFmt == other.inputFmt &&
          datatype == other.datatype &&
          outputDir == other.outputDir &&
          isConcat == other.isConcat &&
          params == other.params &&
          outputFmt == other.outputFmt &&
          prefix == other.prefix &&
          partitionFmt == other.partitionFmt;
}

class IDExtractionServices {
  final List<String> inputFiles;
  final String inputFmt;
  final String datatype;
  final String outputDir;
  final String? prefix;
  final bool isMap;

  const IDExtractionServices({
    required this.inputFiles,
    required this.inputFmt,
    required this.datatype,
    required this.outputDir,
    this.prefix,
    required this.isMap,
  });

  Future<void> extractId() =>
      RustLib.instance.api.crateApiSequenceIdExtractionServicesExtractId(
        that: this,
      );

  // HINT: Make it `#[frb(sync)]` to let it become the default constructor of Dart class.
  static Future<IDExtractionServices> newInstance() =>
      RustLib.instance.api.crateApiSequenceIdExtractionServicesNew();

  @override
  int get hashCode =>
      inputFiles.hashCode ^
      inputFmt.hashCode ^
      datatype.hashCode ^
      outputDir.hashCode ^
      prefix.hashCode ^
      isMap.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IDExtractionServices &&
          runtimeType == other.runtimeType &&
          inputFiles == other.inputFiles &&
          inputFmt == other.inputFmt &&
          datatype == other.datatype &&
          outputDir == other.outputDir &&
          prefix == other.prefix &&
          isMap == other.isMap;
}

class PartitionServices {
  final List<String> inputFiles;
  final String inputPartFmt;
  final String output;
  final String outputPartFmt;
  final String datatype;
  final bool isUncheck;

  const PartitionServices({
    required this.inputFiles,
    required this.inputPartFmt,
    required this.output,
    required this.outputPartFmt,
    required this.datatype,
    required this.isUncheck,
  });

  Future<void> convertPartition() =>
      RustLib.instance.api.crateApiSequencePartitionServicesConvertPartition(
        that: this,
      );

  // HINT: Make it `#[frb(sync)]` to let it become the default constructor of Dart class.
  static Future<PartitionServices> newInstance() =>
      RustLib.instance.api.crateApiSequencePartitionServicesNew();

  @override
  int get hashCode =>
      inputFiles.hashCode ^
      inputPartFmt.hashCode ^
      output.hashCode ^
      outputPartFmt.hashCode ^
      datatype.hashCode ^
      isUncheck.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartitionServices &&
          runtimeType == other.runtimeType &&
          inputFiles == other.inputFiles &&
          inputPartFmt == other.inputPartFmt &&
          output == other.output &&
          outputPartFmt == other.outputPartFmt &&
          datatype == other.datatype &&
          isUncheck == other.isUncheck;
}

class SequenceConversionServices {
  final List<String> inputFiles;
  final String inputFmt;
  final String datatype;
  final String outputDir;
  final String outputFmt;
  final bool sort;

  const SequenceConversionServices({
    required this.inputFiles,
    required this.inputFmt,
    required this.datatype,
    required this.outputDir,
    required this.outputFmt,
    required this.sort,
  });

  Future<void> convertSequence() => RustLib.instance.api
          .crateApiSequenceSequenceConversionServicesConvertSequence(
        that: this,
      );

  // HINT: Make it `#[frb(sync)]` to let it become the default constructor of Dart class.
  static Future<SequenceConversionServices> newInstance() =>
      RustLib.instance.api.crateApiSequenceSequenceConversionServicesNew();

  @override
  int get hashCode =>
      inputFiles.hashCode ^
      inputFmt.hashCode ^
      datatype.hashCode ^
      outputDir.hashCode ^
      outputFmt.hashCode ^
      sort.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SequenceConversionServices &&
          runtimeType == other.runtimeType &&
          inputFiles == other.inputFiles &&
          inputFmt == other.inputFmt &&
          datatype == other.datatype &&
          outputDir == other.outputDir &&
          outputFmt == other.outputFmt &&
          sort == other.sort;
}

class SequenceExtraction {
  final List<String> inputFiles;
  final String inputFmt;
  final String datatype;
  final String outputDir;
  final String outputFmt;
  final SequenceExtractionParams params;

  const SequenceExtraction({
    required this.inputFiles,
    required this.inputFmt,
    required this.datatype,
    required this.outputDir,
    required this.outputFmt,
    required this.params,
  });

  Future<void> extract() =>
      RustLib.instance.api.crateApiSequenceSequenceExtractionExtract(
        that: this,
      );

  // HINT: Make it `#[frb(sync)]` to let it become the default constructor of Dart class.
  static Future<SequenceExtraction> newInstance() =>
      RustLib.instance.api.crateApiSequenceSequenceExtractionNew();

  @override
  int get hashCode =>
      inputFiles.hashCode ^
      inputFmt.hashCode ^
      datatype.hashCode ^
      outputDir.hashCode ^
      outputFmt.hashCode ^
      params.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SequenceExtraction &&
          runtimeType == other.runtimeType &&
          inputFiles == other.inputFiles &&
          inputFmt == other.inputFmt &&
          datatype == other.datatype &&
          outputDir == other.outputDir &&
          outputFmt == other.outputFmt &&
          params == other.params;
}

@freezed
sealed class SequenceExtractionParams with _$SequenceExtractionParams {
  const SequenceExtractionParams._();

  const factory SequenceExtractionParams.id(
    List<String> field0,
  ) = SequenceExtractionParams_Id;
  const factory SequenceExtractionParams.file(
    String field0,
  ) = SequenceExtractionParams_File;
  const factory SequenceExtractionParams.regex(
    String field0,
  ) = SequenceExtractionParams_Regex;
  const factory SequenceExtractionParams.none() = SequenceExtractionParams_None;
}

class SequenceRemoval {
  final List<String> inputFiles;
  final String inputFmt;
  final String datatype;
  final String outputDir;
  final String outputFmt;
  final String? removeRegex;
  final List<String>? removeList;

  const SequenceRemoval({
    required this.inputFiles,
    required this.inputFmt,
    required this.datatype,
    required this.outputDir,
    required this.outputFmt,
    this.removeRegex,
    this.removeList,
  });

  // HINT: Make it `#[frb(sync)]` to let it become the default constructor of Dart class.
  static Future<SequenceRemoval> newInstance() =>
      RustLib.instance.api.crateApiSequenceSequenceRemovalNew();

  Future<void> removeSequence() =>
      RustLib.instance.api.crateApiSequenceSequenceRemovalRemoveSequence(
        that: this,
      );

  @override
  int get hashCode =>
      inputFiles.hashCode ^
      inputFmt.hashCode ^
      datatype.hashCode ^
      outputDir.hashCode ^
      outputFmt.hashCode ^
      removeRegex.hashCode ^
      removeList.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SequenceRemoval &&
          runtimeType == other.runtimeType &&
          inputFiles == other.inputFiles &&
          inputFmt == other.inputFmt &&
          datatype == other.datatype &&
          outputDir == other.outputDir &&
          outputFmt == other.outputFmt &&
          removeRegex == other.removeRegex &&
          removeList == other.removeList;
}

class SequenceRenaming {
  final List<String> inputFiles;
  final String inputFmt;
  final String datatype;
  final String outputDir;
  final String outputFmt;
  final SequenceRenamingParams params;

  const SequenceRenaming({
    required this.inputFiles,
    required this.inputFmt,
    required this.datatype,
    required this.outputDir,
    required this.outputFmt,
    required this.params,
  });

  // HINT: Make it `#[frb(sync)]` to let it become the default constructor of Dart class.
  static Future<SequenceRenaming> newInstance() =>
      RustLib.instance.api.crateApiSequenceSequenceRenamingNew();

  Future<void> renameSequence() =>
      RustLib.instance.api.crateApiSequenceSequenceRenamingRenameSequence(
        that: this,
      );

  @override
  int get hashCode =>
      inputFiles.hashCode ^
      inputFmt.hashCode ^
      datatype.hashCode ^
      outputDir.hashCode ^
      outputFmt.hashCode ^
      params.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SequenceRenaming &&
          runtimeType == other.runtimeType &&
          inputFiles == other.inputFiles &&
          inputFmt == other.inputFmt &&
          datatype == other.datatype &&
          outputDir == other.outputDir &&
          outputFmt == other.outputFmt &&
          params == other.params;
}

@freezed
sealed class SequenceRenamingParams with _$SequenceRenamingParams {
  const SequenceRenamingParams._();

  const factory SequenceRenamingParams.renameId(
    String field0,
  ) = SequenceRenamingParams_RenameId;
  const factory SequenceRenamingParams.removeStr(
    String field0,
  ) = SequenceRenamingParams_RemoveStr;
  const factory SequenceRenamingParams.removeRegex(
    String field0,
    bool field1,
  ) = SequenceRenamingParams_RemoveRegex;
  const factory SequenceRenamingParams.replaceStr(
    String field0,
    String field1,
  ) = SequenceRenamingParams_ReplaceStr;
  const factory SequenceRenamingParams.replaceRegex(
    String field0,
    String field1,
    bool field2,
  ) = SequenceRenamingParams_ReplaceRegex;
  const factory SequenceRenamingParams.none() = SequenceRenamingParams_None;
}

class SplitAlignmentServices {
  final String inputFile;
  final String inputFmt;
  final String datatype;
  final String? inputPartition;
  final String inputPartitionFmt;
  final String outputDir;
  final String? prefix;
  final String outputFmt;
  final bool isUncheck;

  const SplitAlignmentServices({
    required this.inputFile,
    required this.inputFmt,
    required this.datatype,
    this.inputPartition,
    required this.inputPartitionFmt,
    required this.outputDir,
    this.prefix,
    required this.outputFmt,
    required this.isUncheck,
  });

  // HINT: Make it `#[frb(sync)]` to let it become the default constructor of Dart class.
  static Future<SplitAlignmentServices> newInstance() =>
      RustLib.instance.api.crateApiSequenceSplitAlignmentServicesNew();

  Future<void> splitAlignment() =>
      RustLib.instance.api.crateApiSequenceSplitAlignmentServicesSplitAlignment(
        that: this,
      );

  @override
  int get hashCode =>
      inputFile.hashCode ^
      inputFmt.hashCode ^
      datatype.hashCode ^
      inputPartition.hashCode ^
      inputPartitionFmt.hashCode ^
      outputDir.hashCode ^
      prefix.hashCode ^
      outputFmt.hashCode ^
      isUncheck.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitAlignmentServices &&
          runtimeType == other.runtimeType &&
          inputFile == other.inputFile &&
          inputFmt == other.inputFmt &&
          datatype == other.datatype &&
          inputPartition == other.inputPartition &&
          inputPartitionFmt == other.inputPartitionFmt &&
          outputDir == other.outputDir &&
          prefix == other.prefix &&
          outputFmt == other.outputFmt &&
          isUncheck == other.isUncheck;
}

class TranslationServices {
  final List<String> inputFiles;
  final String inputFmt;
  final String datatype;
  final String outputDir;
  final String outputFmt;
  final String table;
  final BigInt readingFrame;

  const TranslationServices({
    required this.inputFiles,
    required this.inputFmt,
    required this.datatype,
    required this.outputDir,
    required this.outputFmt,
    required this.table,
    required this.readingFrame,
  });

  // HINT: Make it `#[frb(sync)]` to let it become the default constructor of Dart class.
  static Future<TranslationServices> newInstance() =>
      RustLib.instance.api.crateApiSequenceTranslationServicesNew();

  Future<void> translateSequence() =>
      RustLib.instance.api.crateApiSequenceTranslationServicesTranslateSequence(
        that: this,
      );

  @override
  int get hashCode =>
      inputFiles.hashCode ^
      inputFmt.hashCode ^
      datatype.hashCode ^
      outputDir.hashCode ^
      outputFmt.hashCode ^
      table.hashCode ^
      readingFrame.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationServices &&
          runtimeType == other.runtimeType &&
          inputFiles == other.inputFiles &&
          inputFmt == other.inputFmt &&
          datatype == other.datatype &&
          outputDir == other.outputDir &&
          outputFmt == other.outputFmt &&
          table == other.table &&
          readingFrame == other.readingFrame;
}
