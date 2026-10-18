import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/alignment/alignment_view.dart';
import 'package:segui/screens/viewers/tabulated.dart';
import 'package:segui/screens/viewers/text.dart';
import 'package:segui/screens/viewers/unknown.dart';
import 'package:segui/services/viewers/alignment_files.dart';
import 'package:segui/services/viewers/inspector.dart';
import 'package:segui/src/rust/api/file_sort.dart';

class FileView extends StatelessWidget {
  const FileView({
    super.key,
    required this.file,
    required this.kind,
    this.siblings = const [],
  });

  final File file;
  final FileContentKind kind;

  /// Files listed beside [file], which viewers that can switch files step
  /// through.
  final Iterable<File> siblings;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case FileContentKind.alignment:
        return AlignmentFileView(file: file, siblings: siblings);
      // Partitions are text, so NEXUS sets blocks are not read as sequences.
      case FileContentKind.partition:
      case FileContentKind.text:
        return PlainTextView(file: file);
      case FileContentKind.table:
        return TabulatedFileView(file: file);
      case FileContentKind.other:
        return UnknownFileView(file: file);
    }
  }
}

/// Opens [file] in the viewer that matches its content. [siblings] are the
/// files listed with it, so the viewer can switch between them; partitions
/// among them are left out of the alignment viewer.
Future<void> openFileView(
  BuildContext context,
  File file, {
  Iterable<File> siblings = const [],
}) async {
  final NavigatorState navigator = Navigator.of(context);
  final FileContentKind kind = await contentKindOf(file);
  final List<File> alignments = kind == FileContentKind.alignment
      ? await alignmentFilesOf(siblings)
      : const [];
  await navigator.push(
    MaterialPageRoute(
      builder: (context) => FileView(
        file: file,
        kind: kind,
        siblings: alignments,
      ),
    ),
  );
}

/// Opens the alignment viewer on every sequence file in [files], starting
/// with the first in [order], so the viewer can step through them all.
/// Returns false when [files] hold no sequences, leaving partitions out.
Future<bool> openAllSequences(
  BuildContext context,
  Iterable<File> files, {
  required FileOrder order,
}) async {
  final NavigatorState navigator = Navigator.of(context);
  final List<File> alignments = await alignmentFilesOf(files);
  if (alignments.isEmpty) {
    return false;
  }
  final List<int> sorted = order(
    [for (final file in alignments) file.path],
    FileSortKey.path,
    ascending: true,
  );
  await navigator.push(
    MaterialPageRoute(
      builder: (context) => FileView(
        file: alignments[sorted.first],
        kind: FileContentKind.alignment,
        siblings: alignments,
      ),
    ),
  );
  return true;
}
