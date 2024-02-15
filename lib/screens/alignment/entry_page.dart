import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/providers/navigation.dart';
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
    return SharedOperationPage(
        child: AlignmentOptions(
      analysis: ref.watch(alignmentOperationSelectionProvider),
    ));
  }
}

class AlignmentTaskSelection extends ConsumerWidget {
  const AlignmentTaskSelection({super.key, required this.infoContent});

  final Widget infoContent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FormView(children: [
      DropdownButton(
          value: ref.watch(alignmentOperationSelectionProvider),
          isExpanded: true,
          items: alignmentOperationMap.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
          onChanged: (AlignmentOperationType? value) {
            if (value != null) {
              ref
                  .read(alignmentOperationSelectionProvider.notifier)
                  .setOperation(value);
            }
            ref.invalidate(fileInputProvider);
            ref.invalidate(fileOutputProvider);
          }),
      infoContent,
    ]);
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
      default:
        return const SizedBox();
    }
  }
}
