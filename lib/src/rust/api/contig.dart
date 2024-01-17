// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0-dev.19.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

class ContigServices {
  final String? dirPath;
  final List<String> files;
  final String fileFmt;
  final String outputDir;

  const ContigServices({
    this.dirPath,
    required this.files,
    required this.fileFmt,
    required this.outputDir,
  });

  static Future<ContigServices> newContigServices({dynamic hint}) =>
      RustLib.instance.api.contigServicesNew(hint: hint);

  Future<void> summarize({dynamic hint}) =>
      RustLib.instance.api.contigServicesSummarize(
        that: this,
      );

  @override
  int get hashCode =>
      dirPath.hashCode ^ files.hashCode ^ fileFmt.hashCode ^ outputDir.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContigServices &&
          runtimeType == other.runtimeType &&
          dirPath == other.dirPath &&
          files == other.files &&
          fileFmt == other.fileFmt &&
          outputDir == other.outputDir;
}
