import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/settings/settings_layout.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/screens/shared/io/output_view.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

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
      body: const SafeArea(
        child: Center(
          child: DataUsageView(),
        ),
      ),
    );
  }
}

class DataUsageView extends ConsumerWidget {
  const DataUsageView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(SeguiSpacing.xxl),
      child: ref.watch(fileOutputProvider).when(
            data: (outputFile) {
              final stats = DataUsageServices().calculateUsage(outputFile);
              // Newest first.
              final List<File> files = [
                for (final output in outputFile.files) output.file,
              ]..sort(
                  (a, b) =>
                      b.lastModifiedSync().compareTo(a.lastModifiedSync()),
                );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsPageHeader(
                    title: 'Data usage',
                    detail: '${stats.count} · ${stats.size}',
                    actions: const [ClearAppDataButton()],
                  ),
                  const SizedBox(height: SeguiSpacing.xl),
                  Expanded(
                    child: files.isEmpty
                        ? const Center(child: Text('No data found'))
                        : SettingsListCard(
                            itemCount: files.length,
                            itemBuilder: (context, index) => OutputFileTiles(
                              isOldFile: true,
                              file: files[index],
                            ),
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text(
              'Error: $error',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
    );
  }
}

class ClearAppDataButton extends ConsumerStatefulWidget {
  const ClearAppDataButton({super.key});

  @override
  ClearAppDataButtonState createState() => ClearAppDataButtonState();
}

class ClearAppDataButtonState extends ConsumerState<ClearAppDataButton> {
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        // Show dialog to confirm the action
        showResponsiveSheet(
          context: context,
          builder: (context) {
            return SheetContent(
              title: 'Clear all data',
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel')),
                TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () async {
                      await ref.read(fileOutputProvider.notifier).clearAll();
                      ref.invalidate(fileOutputProvider);
                      ref.read(fileOutputProvider.notifier).addFromAppDir();
                      _popDialog();
                    },
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: const Text('Clear all data'))
              ],
              child: const Text(
                'Delete all data except the latest log file.',
              ),
            );
          },
        );
      },
      icon: const Icon(Icons.delete_outline),
      label: const Text('Clear app data'),
    );
  }

  void _popDialog() {
    Navigator.of(context).pop();
  }
}
