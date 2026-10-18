import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/alignment/alignment_view.dart';
import 'package:segui/screens/viewers/tabulated.dart';
import 'package:segui/screens/viewers/text.dart';
import 'package:segui/screens/viewers/unknown.dart';
import 'package:segui/services/io/file.dart';

class FileView extends StatelessWidget {
  const FileView({
    super.key,
    required this.file,
    required this.type,
    this.siblings = const [],
  });

  final File file;
  final CommonFileType type;

  /// Files listed beside [file], which viewers that can switch files step
  /// through.
  final Iterable<File> siblings;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case CommonFileType.sequence when isAlignmentViewable(file):
        return AlignmentFileView(file: file, siblings: siblings);
      case CommonFileType.plainText:
        return PlainTextView(file: file);
      case CommonFileType.tabulated:
        return TabulatedFileView(file: file);
      default:
        return UnknownFileView(file: file);
    }
  }
}

/// Opens [file] in the viewer that matches its type. [siblings] are the
/// files listed with it, so the viewer can switch between them.
Future<void> openFileView(
  BuildContext context,
  File file, {
  Iterable<File> siblings = const [],
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => FileView(
        file: file,
        type: FileAssociation(file: file).commonFileTYpe,
        siblings: siblings,
      ),
    ),
  );
}
