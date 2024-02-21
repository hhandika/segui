import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/shared/io/output_view.dart';
import 'package:segui/services/io/io.dart';
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
      body: const Center(
        child: DataUsageView(),
      ),
    );
  }
}

class DataUsageView extends ConsumerWidget {
  const DataUsageView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppDataStats(),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: getContainerDecoration(context),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ref.watch(fileOutputProvider).when(
                    data: (outputFile) {
                      final files = outputFile.files;
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
                                  file: file.file,
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
          const Center(
            child: ClearAppDataButton(),
          ),
        ],
      ),
    );
  }
}

class AppDataStats extends StatelessWidget {
  const AppDataStats({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = isPhoneScreen(context);
    return FutureBuilder(
      future: DataUsageServices().calculateUsage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else {
          return isSmallScreen
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FileCountTile(count: snapshot.data!.count),
                    FileSizeTile(totalSize: snapshot.data!.size),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FileCountTile(count: snapshot.data!.count),
                    FileSizeTile(totalSize: snapshot.data!.size),
                  ],
                );
        }
      },
    );
  }
}

class FileCountTile extends StatelessWidget {
  const FileCountTile({super.key, required this.count});

  final String count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: ListTile(
        leading: Icon(
          Icons.file_copy_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          'File count',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        subtitle: Text(count),
      ),
    );
  }
}

class FileSizeTile extends StatelessWidget {
  const FileSizeTile({super.key, required this.totalSize});

  final String totalSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 200,
        child: ListTile(
          leading: Icon(
            Icons.data_usage_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            'Total size',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          subtitle: Text(totalSize),
        ));
  }
}

class ClearAppDataButton extends ConsumerWidget {
  const ClearAppDataButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextButton(
            onPressed: () {
              // Show dialog to confirm the action
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Clear all data'),
                    content: const Text(
                      'Delete all data except the latest log file.',
                    ),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel')),
                      TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () {
                            ref
                                .read(fileOutputProvider.notifier)
                                .removeAllFiles();
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.delete_forever_outlined),
                          label: const Text('Clear all data'))
                    ],
                  );
                },
              );
            },
            child: const Text('Clear app data')));
  }
}
