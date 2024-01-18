import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/navigation.dart';
import 'package:segui/screens/sequence/sequence_id.dart';
import 'package:segui/screens/sequence/translate.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/types.dart';

class SequencePage extends ConsumerStatefulWidget {
  const SequencePage({super.key});

  @override
  SequencePageState createState() => SequencePageState();
}

class SequencePageState extends ConsumerState<SequencePage> {
  @override
  Widget build(BuildContext context) {
    return FormView(children: [
      DropdownButton(
          value: ref.watch(sequenceOperationSelectionProvider),
          isExpanded: true,
          items: sequenceOperationMap.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
          onChanged: (SequenceOperationType? value) {
            if (value != null) {
              ref
                  .read(sequenceOperationSelectionProvider.notifier)
                  .setOperation(value);
            }
          }),
      const SizedBox(height: 20),
      SequenceOptions(
        analysis: ref.watch(sequenceOperationSelectionProvider),
      ),
    ]);
  }
}

class SequenceOptions extends StatelessWidget {
  const SequenceOptions({super.key, required this.analysis});

  final SequenceOperationType analysis;

  @override
  Widget build(BuildContext context) {
    switch (analysis) {
      case SequenceOperationType.translation:
        return const TranslatePage();
      case SequenceOperationType.idExtraction:
        return const IDExtractionPage();
      default:
        return const SizedBox();
    }
  }
}
