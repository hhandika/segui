import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/services/io.dart';
import 'package:segui/styles/decoration.dart';

class DataUsageScreen extends StatefulWidget {
  const DataUsageScreen({super.key});

  @override
  State<DataUsageScreen> createState() => _DataUsageScreenState();
}

class _DataUsageScreenState extends State<DataUsageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data usage'),
        backgroundColor: getSEGULBackgroundColor(context),
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Container(
                  decoration: getContainerDecoration(context),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: FutureBuilder(
                    future: _findAllFiles(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final files = snapshot.data;
                        return files!.isEmpty
                            ? const Center(
                                child: Text('No data found'),
                              )
                            : ListView.builder(
                                itemCount: files.length,
                                itemBuilder: (context, index) {
                                  final file = files[index];
                                  return OutputFileTiles(
                                    isOldFile: true,
                                    file: file,
                                  );
                                });
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      return const CircularProgressIndicator();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                  onPressed: () {
                    setState(() {
                      _clearAllData();
                    });
                  },
                  child: const Text('Clear all data'))
            ],
          ),
        ),
      ),
    );
  }

  Future<List<File>> _findAllFiles() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();

    return DirectoryCrawler(appDocDir).crawl(recursive: true);
  }

  void _clearAllData() async {
    FileCleaningService().deleteAllFilesInAppDocDir();
  }
}
