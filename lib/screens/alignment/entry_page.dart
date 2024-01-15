import 'package:flutter/material.dart';
import 'package:segui/screens/alignment/concat.dart';
import 'package:segui/screens/alignment/convert.dart';
import 'package:segui/screens/alignment/split.dart';
import 'package:segui/screens/alignment/summary.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/types.dart';

class AlignmentPage extends StatefulWidget {
  const AlignmentPage({super.key});

  @override
  State<AlignmentPage> createState() => _AlignmentPageState();
}

class _AlignmentPageState extends State<AlignmentPage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      if (constraints.maxWidth > 800) {
        return const Row(children: [
          AlignmentContent(),
          Expanded(child: Center(child: Text('No view'))),
        ]);
      } else {
        return const AlignmentContent();
      }
    });
  }
}

class AlignmentContent extends StatefulWidget {
  const AlignmentContent({super.key});

  @override
  State<AlignmentContent> createState() => _AlignmentContentState();
}

class _AlignmentContentState extends State<AlignmentContent> {
  AlignmentOperationType analysisType = AlignmentOperationType.summary;

  @override
  Widget build(BuildContext context) {
    return FormView(children: [
      DropdownButton(
          value: analysisType,
          isExpanded: true,
          items: alignmentOperationMap.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
          onChanged: (AlignmentOperationType? value) {
            setState(() {
              if (value != null) {
                analysisType = value;
              }
            });
          }),
      const SizedBox(height: 20),
      AlignmentOptions(
        analysis: analysisType,
      ),
    ]);
  }
}

class AlignmentOptions extends StatelessWidget {
  const AlignmentOptions({super.key, required this.analysis});

  final AlignmentOperationType analysis;

  @override
  Widget build(BuildContext context) {
    switch (analysis) {
      case AlignmentOperationType.concat:
        return const ConcatPage();
      case AlignmentOperationType.summary:
        return const AlignmentSummaryPage();
      case AlignmentOperationType.convert:
        return const ConvertPage();
      case AlignmentOperationType.split:
        return const SplitAlignmentPage();
      default:
        return const SizedBox();
    }
  }
}
