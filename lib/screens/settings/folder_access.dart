import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/settings/settings_layout.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/providers/folder_access.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

class FolderAccessScreen extends StatelessWidget {
  const FolderAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folder access'),
        backgroundColor: getSEGULBackgroundColor(context),
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: const FolderAccessView(),
    );
  }
}

/// Folders SEGUI opens without asking, with buttons to add and remove them.
class FolderAccessView extends ConsumerWidget {
  const FolderAccessView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(SeguiSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SettingsPageHeader(
            title: 'Folder access',
            detail: 'Folders SEGUI opens without asking',
            actions: [AddFolderAccessButton()],
          ),
          const SizedBox(height: SeguiSpacing.xl),
          Expanded(
            child: ref.watch(folderAccessProvider).when(
                  data: (folders) => folders.isEmpty
                      ? const Center(child: Text('No folders yet'))
                      : SettingsListCard(
                          itemCount: folders.length,
                          itemBuilder: (context, index) =>
                              FolderAccessTile(path: folders[index]),
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Text('Error: $error'),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class AddFolderAccessButton extends ConsumerWidget {
  const AddFolderAccessButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () => _addFolder(context, ref),
      icon: const Icon(Icons.create_new_folder_outlined),
      label: const Text('Add folder'),
    );
  }

  Future<void> _addFolder(BuildContext context, WidgetRef ref) async {
    final String? path = await ref.read(folderAccessProvider.notifier).grant();
    if (path != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(showSharedSnackBar(context, 'Folder added'));
    }
  }
}

class FolderAccessTile extends ConsumerWidget {
  const FolderAccessTile({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.folder_outlined),
      title: Text(path, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        tooltip: 'Remove access',
        icon: const Icon(Icons.close_rounded),
        onPressed: () => ref.read(folderAccessProvider.notifier).forget(path),
      ),
    );
  }
}
