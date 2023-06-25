import 'package:flutter/material.dart';
import 'package:segui/screens/sequence/translate.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/types.dart';

class SequencePage extends StatefulWidget {
  const SequencePage({super.key});

  @override
  State<SequencePage> createState() => _SequencePageState();
}

class _SequencePageState extends State<SequencePage> {
  SequenceOperationType analysisType = SequenceOperationType.translation;

  @override
  Widget build(BuildContext context) {
    return FormView(children: [
      DropdownButton(
          value: analysisType,
          isExpanded: true,
          items: sequenceOperationMap.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
          onChanged: (SequenceOperationType? value) {
            setState(() {
              if (value != null) {
                analysisType = value;
              }
            });
          }),
      const SizedBox(height: 20),
      SequenceOptions(
        analysis: analysisType,
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
      default:
        return const SizedBox();
    }
  }
}
