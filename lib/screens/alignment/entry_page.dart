import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/screens/alignment/concat.dart';
import 'package:segui/screens/alignment/convert.dart';
import 'package:segui/screens/alignment/filter.dart';
import 'package:segui/screens/alignment/partition.dart';
import 'package:segui/screens/alignment/split.dart';
import 'package:segui/screens/alignment/summary.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/services/types.dart';

class AlignmentPage extends ConsumerWidget {
  const AlignmentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operation = ref.watch(alignmentOperationSelectionProvider);
    return SharedOperationPage(
        operation: operation,
        child: AlignmentOptions(
          analysis: operation,
        ));
  }
}

class AlignmentOptions extends ConsumerWidget {
  const AlignmentOptions({super.key, required this.analysis});

  final AlignmentOperationType analysis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (analysis) {
      case AlignmentOperationType.concatenation:
        return const ConcatView();
      case AlignmentOperationType.conversion:
        return const ConvertView();
      case AlignmentOperationType.filter:
        return const AlignmentFilteringView();
      case AlignmentOperationType.partition:
        return const PartitionConversionView();
      case AlignmentOperationType.split:
        return const SplitAlignmentView();
      case AlignmentOperationType.summary:
        return const AlignmentSummaryView();
    }
  }
}
