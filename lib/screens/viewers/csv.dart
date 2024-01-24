import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:segui/screens/shared/components.dart';
import 'package:segui/services/viewers/csv.dart';
import 'package:segui/styles/decoration.dart';

class TabulatedFileViewer extends StatelessWidget {
  const TabulatedFileViewer({super.key, required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CSV Viewer'),
        backgroundColor: getSEGULBackgroundColor(context),
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: Center(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
                decoration: getContainerDecoration(context),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        file.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const TopDivider(),
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TabulatedFileViewerBody(file: file),
                    )),
                  ],
                ))),
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
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columns: content![0]
                        .map((e) => DataColumn(label: Text(e.toString())))
                        .toList(),
                    rows: content
                        .sublist(1)
                        .map((e) => DataRow(
                            cells: e
                                .map((e) => DataCell(Text(e.toString())))
                                .toList()))
                        .toList(),
                  )),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  Future<List<List<dynamic>>> _parseContent() async {
    return await CsvParser(file: file).parse();
  }
}
