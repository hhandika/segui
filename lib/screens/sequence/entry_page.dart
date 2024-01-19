import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/navigation.dart';
import 'package:segui/screens/sequence/sequence_id.dart';
import 'package:segui/screens/sequence/translate.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/services/types.dart';

class SequencePage extends StatefulWidget {
  const SequencePage({super.key});

  @override
  State<SequencePage> createState() => _SequencePageState();
}

class _SequencePageState extends State<SequencePage> {
  @override
  Widget build(BuildContext context) {
    return const SharedOperationPage(
      child: SequenceContentPage(),
    );
  }
}

class SequenceContentPage extends ConsumerWidget {
  const SequenceContentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      const SizedBox(height: 8),
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
