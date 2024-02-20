import 'dart:io';

import 'package:flutter/material.dart';
import 'package:segui/screens/viewers/tabulated.dart';
import 'package:segui/screens/viewers/text.dart';
import 'package:segui/screens/viewers/unknown.dart';
import 'package:segui/services/io/file.dart';

class FileView extends StatelessWidget {
  const FileView({
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
        return PlainTextView(file: file);
      case CommonFileType.tabulated:
        return TabulatedFileView(file: file);
      default:
        return UnknownFileView(file: file);
    }
  }
}
