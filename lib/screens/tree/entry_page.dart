import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/screens/tree/convert.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/services/types.dart';

class TreePage extends ConsumerWidget {
  const TreePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operation = ref.watch(treeOperationSelectionProvider);
    return SharedOperationPage(
      operation: operation,
      child: TreeOptions(analysis: operation),
    );
  }
}

class TreeOptions extends StatelessWidget {
  const TreeOptions({super.key, required this.analysis});

  final TreeOperationType analysis;

  @override
  Widget build(BuildContext context) {
    switch (analysis) {
      case TreeOperationType.conversion:
        return const TreeConversionView();
    }
  }
}
