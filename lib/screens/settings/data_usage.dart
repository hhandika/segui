import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/styles/decoration.dart';

class DataUsageScreen extends ConsumerStatefulWidget {
  const DataUsageScreen({super.key});

  @override
  DataUsageScreenState createState() => DataUsageScreenState();
}

class DataUsageScreenState extends ConsumerState<DataUsageScreen> {
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
                  child: ref.watch(fileOutputProvider).when(
                        data: (outputFile) {
                          final files = outputFile.oldFiles;
                          return files.isEmpty
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
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stackTrace) => Text(
                          'Error: $error',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                  onPressed: () {
                    // Show dialog to confirm the action
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Clear all data'),
                          content: const Text(
                            'Permanently delete all data except the latest log file. '
                            'Continue?',
                          ),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () {
                                  ref
                                      .read(fileOutputProvider.notifier)
                                      .removeAllFiles();
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Clear all data'))
                          ],
                        );
                      },
                    );
                  },
                  child: const Text('Clear all data'))
            ],
          ),
        ),
      ),
    );
  }
}
