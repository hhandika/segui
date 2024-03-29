// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0-dev.24.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

class ArchiveServices {
  final String outputPath;
  final List<String> inputFiles;

  const ArchiveServices({
    required this.outputPath,
    required this.inputFiles,
  });

  static Future<ArchiveServices> newArchiveServices({dynamic hint}) =>
      RustLib.instance.api.archiveServicesNew(hint: hint);

  Future<void> zip({dynamic hint}) => RustLib.instance.api.archiveServicesZip(
        that: this,
      );

  @override
  int get hashCode => outputPath.hashCode ^ inputFiles.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArchiveServices &&
          runtimeType == other.runtimeType &&
          outputPath == other.outputPath &&
          inputFiles == other.inputFiles;
}
