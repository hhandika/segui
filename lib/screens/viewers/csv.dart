import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:segui/services/viewers/csv.dart';
import 'package:segui/styles/decoration.dart';

class TabulatedFileViewer extends StatelessWidget {
  const TabulatedFileViewer({super.key, required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(file.name),
        backgroundColor: getSEGULBackgroundColor(context),
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: Center(
        child: TabulatedFileViewerBody(file: file),
      ),
    );
  }
}

class TabulatedFileViewerBody extends StatelessWidget {
  const TabulatedFileViewerBody({super.key, required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _parseContent(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final content = snapshot.data;
            return InteractiveViewer(
                child: DataTable(
              columns:
                  content![0].map((e) => DataColumn(label: Text(e))).toList(),
              rows: content
                  .sublist(1)
                  .map((e) =>
                      DataRow(cells: e.map((e) => DataCell(Text(e))).toList()))
                  .toList(),
            ));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  Future<List<List<String>>> _parseContent() async {
    return await CsvParser(file: file).parse();
  }
}
