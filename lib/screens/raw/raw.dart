import 'package:flutter/material.dart';
import 'package:segui/screens/raw/summarize.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/types.dart';

class RawPage extends StatefulWidget {
  const RawPage({super.key});

  @override
  State<RawPage> createState() => _RawPageState();
}

class _RawPageState extends State<RawPage> {
  String? analysisType = rawReadOperation[0];
  @override
  Widget build(BuildContext context) {
    return FormView(children: [
      SharedDropdownField(
        value: analysisType,
        label: 'Select operation',
        items: rawReadOperation,
        onChanged: (String? value) {
          setState(() {
            if (value != null) {
              analysisType = value;
            }
          });
        },
      ),
      const SizedBox(height: 20),
      RawOptions(
        analysis: analysisType == null
            ? null
            : RawReadOperationType
                .values[rawReadOperation.indexOf(analysisType!)],
      ),
    ]);
  }
}

class RawOptions extends StatelessWidget {
  const RawOptions({super.key, required this.analysis});

  final RawReadOperationType? analysis;

  @override
  Widget build(BuildContext context) {
    switch (analysis) {
      case RawReadOperationType.summary:
        return const RawSummaryPage();
      default:
        return const SizedBox();
    }
  }
}
