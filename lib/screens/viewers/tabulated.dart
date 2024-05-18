import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/services/viewers/csv.dart';
import 'package:segui/styles/decoration.dart';

class TabulatedFileView extends StatelessWidget {
  const TabulatedFileView({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(basename(file.path)),
        backgroundColor: getSEGULBackgroundColor(context),
        actions: [
          InfoButton(file: file),
        ],
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: Center(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    decoration: getContainerDecoration(context),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FileIcon(file: file),
                          const SizedBox(width: 8),
                          FileIOSubtitle(file: file),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: getContainerDecoration(context),
                    child: TabulatedFileViewBody(file: file),
                  ),
                ),
              ],
            )),
      ),
    );
  }
}

class TabulatedFileViewBody extends StatefulWidget {
  const TabulatedFileViewBody({super.key, required this.file});

  final File file;

  @override
  State<TabulatedFileViewBody> createState() => _TabulatedFileViewBodyState();
}

class _TabulatedFileViewBodyState extends State<TabulatedFileViewBody> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _parseContent(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final content = snapshot.data;
            if (snapshot.data!.isEmpty) {
              return const Center(child: Text('Failed to parse file.'));
            }
            return content != null
                ? PaginatedTable(content: content)
                : const EmptyScreen(
                    title: 'Table is empty.',
                    description: 'Try run the analysis again.');
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  Future<List<List<dynamic>>> _parseContent() async {
    try {
      final parser = CsvParser();
      return await parser.parse(widget.file);
    } catch (e) {
      return [];
    }
  }
}

class PaginatedTable extends StatefulWidget {
  const PaginatedTable({super.key, required this.content});

  final List<List<dynamic>> content;

  @override
  State<PaginatedTable> createState() => _PaginatedTableState();
}

class _PaginatedTableState extends State<PaginatedTable> {
  @override
  Widget build(BuildContext context) {
    int screenHeight = MediaQuery.of(context).size.height.toInt();
    return SingleChildScrollView(
        child: Theme(
      data: Theme.of(context).copyWith(
          cardTheme: const CardTheme(elevation: 0, color: Colors.transparent)),
      child: PaginatedDataTable(
        rowsPerPage: _rowCount(screenHeight),
        columns: widget.content[0]
            .map((e) => DataColumn(label: Text(e.toString())))
            .toList(),
        // We skip the first row, which is the header
        source: ContentSource(widget.content.sublist(1)),
      ),
    ));
  }

  int _rowCount(int screenHeight) {
    if (widget.content.length <= 50) {
      return widget.content.length;
    } else {
      // Estimate row number from screen height
      // 58 is the average row height
      return (screenHeight * .88) ~/ 56;
    }
  }
}

class ContentSource extends DataTableSource {
  ContentSource(this.content);

  final List<List<dynamic>> content;

  @override
  DataRow? getRow(int index) {
    if (index >= content.length) {
      return null;
    }
    return DataRow(
        cells: content[index]
            .map((e) => DataCell(Text(_formatDouble(e))))
            .toList());
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => content.length;

  @override
  int get selectedRowCount => 0;

  // Return two point decimal for double values
  String _formatDouble(dynamic value) {
    if (value is num) {
      // Use thousands separator and two decimal points
      // https://pub.dev/documentation/intl/latest/intl/NumberFormat-class.html
      return NumberFormat("#,###.##").format(value);
    }
    return value.toString();
  }
}
