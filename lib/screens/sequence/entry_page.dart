import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/screens/sequence/extract.dart';
import 'package:segui/screens/sequence/remove.dart';
import 'package:segui/screens/sequence/rename.dart';
import 'package:segui/screens/sequence/sequence_id.dart';
import 'package:segui/screens/sequence/translate.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/services/types.dart';

class SequencePage extends ConsumerWidget {
  const SequencePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SharedOperationPage(
      child: SequenceOptions(
          analysis: ref.watch(sequenceOperationSelectionProvider)),
    );
  }
}

class SequenceTaskSelection extends ConsumerWidget {
  const SequenceTaskSelection({super.key, required this.infoContent});

  final Widget infoContent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FormView(children: [
      DropdownButton(
          value: ref.watch(sequenceOperationSelectionProvider),
          isExpanded: true,
          items: sequenceOperationMap.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(
                      e.value,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: (SequenceOperationType? value) {
            if (value != null) {
              ref
                  .read(sequenceOperationSelectionProvider.notifier)
                  .setOperation(value);
            }
            ref.invalidate(fileInputProvider);
            ref.invalidate(fileOutputProvider);
          }),
      infoContent,
    ]);
  }
}

class SequenceOptions extends StatelessWidget {
  const SequenceOptions({super.key, required this.analysis});

  final SequenceOperationType analysis;

  @override
  Widget build(BuildContext context) {
    switch (analysis) {
      case SequenceOperationType.extraction:
        return const ExtractSequenceView();
      case SequenceOperationType.removal:
        return const SequenceRemovalView();
      case SequenceOperationType.renaming:
        return const SequenceRenamingView();
      case SequenceOperationType.idExtraction:
        return const IDExtractionView();
      case SequenceOperationType.translation:
        return const TranslateView();
      default:
        return const SizedBox();
    }
  }
}
