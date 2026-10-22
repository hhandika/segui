import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/styles/design_tokens.dart';

/// Tells users that files shared from another app are waiting for a tool.
/// Each tool's file picker offers them with "Use shared files".
class SharedFilesBanner extends ConsumerWidget {
  const SharedFilesBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count = ref.watch(sharedInputProvider);
    if (count == 0) {
      return const SizedBox.shrink();
    }
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: SeguiSpacing.xl),
      child: Card.filled(
        color: theme.colorScheme.secondaryContainer,
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(
            Icons.move_to_inbox_outlined,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          title: Text(
              count == 1 ? '1 shared file ready' : '$count shared files ready'),
          subtitle: const Text(
              'Choose a tool, then tap Use shared files in its input picker.'),
          trailing: IconButton(
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => ref.read(sharedInputProvider.notifier).clear(),
          ),
        ),
      ),
    );
  }
}
