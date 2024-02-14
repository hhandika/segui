import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/services/io.dart';
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
              Container(
                width: double.infinity,
                decoration: getContainerDecoration(context),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: const Column(
                  children: [
                    AppDataStats(),
                    CacheDataStats(),
                    SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        ClearCacheButton(),
                        ClearAppDataButton(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
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
            ],
          ),
        ),
      ),
    );
  }
}

class AppDataStats extends StatelessWidget {
  const AppDataStats({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: DataUsageServices().calculateUsage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('File count:'),
                  Text(
                    snapshot.data!.count,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('App data:'),
                  Text(
                    snapshot.data!.size,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }
}

class CacheDataStats extends StatelessWidget {
  const CacheDataStats({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: TempDataServices().calculateAppTempDirUsage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cache:'),
                Text(
                  snapshot.data!,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            );
          }
        });
  }
}

class ClearCacheButton extends StatelessWidget {
  const ClearCacheButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).disabledColor,
      ),
      onPressed: () {},
      child: const Text(
        'Clear cache',
      ),
    );
  }
}

class ClearAppDataButton extends ConsumerWidget {
  const ClearAppDataButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).disabledColor,
        ),
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
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).disabledColor,
                      ),
                      onPressed: () {
                        ref.read(fileOutputProvider.notifier).removeAllFiles();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Clear all data'))
                ],
              );
            },
          );
        },
        child: const Text('Clear app data'));
  }
}
