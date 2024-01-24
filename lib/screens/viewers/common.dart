import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:segui/screens/viewers/tabulated.dart';
import 'package:segui/screens/viewers/text.dart';
import 'package:segui/services/io.dart';

class OpenViewerButton extends StatelessWidget {
  const OpenViewerButton({
    super.key,
    required this.file,
    required this.type,
  });

  final XFile file;
  final CommonFileType type;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Open in viewer',
      icon: const Icon(Icons.open_in_new),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              switch (type) {
                case CommonFileType.plainText:
                  return PlainTextViewer(file: file);
                case CommonFileType.tabulated:
                  return TabulatedFileViewer(file: file);
                default:
                  return const SizedBox();
              }
            },
          ),
        );
      },
    );
  }
}
