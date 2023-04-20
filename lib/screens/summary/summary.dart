import 'package:flutter/material.dart';
import 'package:segui/bridge_definitions.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/types.dart';
import 'package:segui/services/native.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  IOController ctr = IOController.empty();
  String _interval = summaryInt[2];

  @override
  Widget build(BuildContext context) {
    return FormView(
      children: [
        const CardTitle(title: 'Input'),
        SharedInputForms(ctr: ctr),
        const SizedBox(height: 20),
        const CardTitle(title: 'Output'),
        FormCard(children: [
          SelectDirField(
              label: 'Select output directory',
              dirPath: ctr.outputDir,
              onPressed: (value) {
                setState(() {
                  ctr.outputDir = value;
                });
              }),
          SharedTextField(
            controller: ctr.outputController,
            label: 'Output Prefix',
            hint: 'Enter output prefix',
          ),
          SharedDropdownField(
            value: _interval,
            label: 'Summary Interval',
            items: summaryInt,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _interval = value;
                }
              });
            },
          ),
        ]),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Summarize',
          isRunning: ctr.isRunning,
          onPressed: ctr.isRunning || !ctr.isValid()
              ? null
              : () async {
                  setState(() {
                    ctr.isRunning = true;
                  });
                  try {
                    await _summarize();
                    if (mounted) {
                      setState(() {
                        ctr.isRunning = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        showSharedSnackBar(context, 'Summarization complete!'),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        ctr.isRunning = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        showSharedSnackBar(context, 'Summarization failed!'),
                      );
                    }
                  }
                },
        )
      ],
    );
  }

  Future<void> _summarize() async {
    await SegulServices(
      bridge: segulApi,
      dirPath: ctr.dirPath!,
      outputDir: ctr.outputDir!,
      fileFmt: ctr.inputFormatController!,
      datatype: ctr.dataTypeController,
    ).summarizeAlignment(
        outputPrefix: ctr.outputController.text,
        interval: int.tryParse(_interval) ?? 5);
  }
}
