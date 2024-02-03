import 'dart:io';

import 'package:flutter/material.dart';
import 'package:segui/screens/viewers/tabulated.dart';
import 'package:segui/screens/viewers/text.dart';
import 'package:segui/screens/viewers/unknown.dart';
import 'package:segui/services/io.dart';

class FileViewer extends StatelessWidget {
  const FileViewer({
    super.key,
    required this.file,
    required this.type,
  });

  final File file;
  final CommonFileType type;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case CommonFileType.plainText:
        return PlainTextViewer(file: file);
      case CommonFileType.tabulated:
        return TabulatedFileViewer(file: file);
      default:
        return UnknownFileViewer(file: file);
    }
  }
}
