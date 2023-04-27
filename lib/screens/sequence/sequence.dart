import 'package:flutter/material.dart';
import 'package:segui/screens/sequence/translate.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/types.dart';

class SequencePage extends StatefulWidget {
  const SequencePage({super.key});

  @override
  State<SequencePage> createState() => _SequencePageState();
}

class _SequencePageState extends State<SequencePage> {
  String? analysisType = sequenceOperation[0];

  @override
  Widget build(BuildContext context) {
    return FormView(children: [
      SharedDropdownField(
          value: analysisType,
          label: 'Type of operation',
          items: sequenceOperation,
          onChanged: (String? value) {
            setState(() {
              if (value != null) {
                analysisType = value;
              }
            });
          }),
      const SizedBox(height: 20),
      SequenceOptions(
        analysis: analysisType == null
            ? null
            : SequenceOperationType
                .values[sequenceOperation.indexOf(analysisType!)],
      ),
    ]);
  }
}

class SequenceOptions extends StatelessWidget {
  const SequenceOptions({super.key, required this.analysis});

  final SequenceOperationType? analysis;

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
