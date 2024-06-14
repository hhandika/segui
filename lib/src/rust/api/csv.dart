// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0-dev.39.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

// These functions are ignored because they are not marked as `pub`: `is_id_column_names`, `match_type_id_column`, `select_columns`
// These functions are ignored (category: IgnoreBecauseExplicitAttribute): `get_dataframe`, `get_dataframe`

enum CsvSegulType {
  /// Locus summary from alignment summary
  locusSummary,

  /// Taxon summary from alignment summary
  taxonSummary,

  /// Whole read summary from raw read summary
  /// Add default settings
  wholeReadSummary,

  /// Per read summary from raw read summary
  /// When the complete setting is used.
  perReadSummary,

  /// Contig summary from assembly summary
  contigSummary,
  ;
}

class CsvSummaryServices {
  final String inputPath;
  final CsvSegulType segulType;

  const CsvSummaryServices({
    required this.inputPath,
    required this.segulType,
  });

  Future<List<String>> getColumnNames() =>
      RustLib.instance.api.crateApiCsvCsvSummaryServicesGetColumnNames(
        that: this,
      );

  Future<BigInt> getLine() =>
      RustLib.instance.api.crateApiCsvCsvSummaryServicesGetLine(
        that: this,
      );

  // HINT: Make it `#[frb(sync)]` to let it become the default constructor of Dart class.
  static Future<CsvSummaryServices> newInstance(
          {required String inputPath, required CsvSegulType segulType}) =>
      RustLib.instance.api.crateApiCsvCsvSummaryServicesNew(
          inputPath: inputPath, segulType: segulType);

  Future<Map<String, String>> parseColumns({required String colName}) => RustLib
      .instance.api
      .crateApiCsvCsvSummaryServicesParseColumns(that: this, colName: colName);

  @override
  int get hashCode => inputPath.hashCode ^ segulType.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CsvSummaryServices &&
          runtimeType == other.runtimeType &&
          inputPath == other.inputPath &&
          segulType == other.segulType;
}
