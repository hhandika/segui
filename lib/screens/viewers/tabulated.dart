import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/io/io.dart';
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
            child: Container(
                decoration: getContainerDecoration(context),
                child: Column(
                  children: [
                    Padding(
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
                    const TopDivider(),
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TabulatedFileViewBody(file: file),
                    )),
                  ],
                ))),
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
            return content!.length > 300
                ? BigFileErrors(file: widget.file)
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        clipBehavior: Clip.antiAlias,
                        child: DataTable(
                          columns: content[0]
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
    try {
      final parser = CsvParser();
      return await parser.parse(widget.file);
    } catch (e) {
      return [];
    }
  }
}

class BigFileErrors extends StatelessWidget {
  const BigFileErrors({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FileErrorIcon(),
          const Text('File too large to display.'),
          ExternalAppLauncher(file: file, fromPopUp: false)
        ],
      ),
    );
  }
}
