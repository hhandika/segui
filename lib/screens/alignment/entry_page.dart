import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/providers/navigation.dart';
import 'package:segui/screens/alignment/concat.dart';
import 'package:segui/screens/alignment/convert.dart';
import 'package:segui/screens/alignment/partition.dart';
import 'package:segui/screens/alignment/split.dart';
import 'package:segui/screens/alignment/summary.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/services/types.dart';

class AlignmentPage extends StatefulWidget {
  const AlignmentPage({super.key});

  @override
  State<AlignmentPage> createState() => _AlignmentPageState();
}

class _AlignmentPageState extends State<AlignmentPage> {
  @override
  Widget build(BuildContext context) {
    return const SharedOperationPage(
      child: AlignmentContentPage(),
    );
  }
}

class AlignmentContentPage extends ConsumerWidget {
  const AlignmentContentPage({super.key});

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
      const SizedBox(height: 8),
      AlignmentOptions(
        analysis: ref.watch(alignmentOperationSelectionProvider),
      ),
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
        return const ConcatPage();
      case AlignmentOperationType.conversion:
        return const ConvertPage();
      case AlignmentOperationType.split:
        return const SplitAlignmentPage();
      case AlignmentOperationType.partition:
        return const PartitionConversionPage();
      case AlignmentOperationType.summary:
        return const AlignmentSummaryPage();
      default:
        return const SizedBox();
    }
  }
}
