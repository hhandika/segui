import 'package:flutter/material.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/io.dart';
import 'package:segui/services/native.dart';

class QuickAlignmentSummaryPage extends StatelessWidget {
  const QuickAlignmentSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alignment Summary'),
      ),
      body: const SingleChildScrollView(
        child: AppPageView(child: AlignmentSummaryPage()),
      ),
    );
  }
}

class AlignmentSummaryPage extends StatefulWidget {
  const AlignmentSummaryPage({super.key});

  @override
  State<AlignmentSummaryPage> createState() => _AlignmentSummaryPageState();
}

class _AlignmentSummaryPageState extends State<AlignmentSummaryPage> {
  IOController ctr = IOController.empty();
  String _interval = summaryInt[2];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CardTitle(title: 'Input'),
        SharedInputForms(ctr: ctr),
        const SizedBox(height: 20),
        const CardTitle(title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
              ctr: ctr.outputDir,
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
        Center(
          child: PrimaryButton(
            label: 'Summarize',
            isRunning: ctr.isRunning,
            onPressed: ctr.isRunning || !ctr.isValid()
                ? null
                : () async {
                    String dir = await getOutputDir(ctr.outputDir);
                    setState(() {
                      ctr.isRunning = true;
                      ctr.outputDir = dir;
                    });
                    try {
                      await _summarize();
                      _setSuccess();
                    } catch (e) {
                      _showError(e.toString());
                    }
                  },
          ),
        )
      ],
    );
  }

  Future<void> _summarize() async {
    await SequenceServices(
      bridge: segulApi,
      files: ctr.files,
      dirPath: ctr.dirPath,
      outputDir: ctr.outputDir!,
      fileFmt: ctr.inputFormatController!,
      datatype: ctr.dataTypeController,
    ).summarizeAlignment(
        outputPrefix: ctr.outputController.text,
        interval: int.tryParse(_interval) ?? 5);
  }

  void _showError(String error) {
    setState(() {
      ctr.isRunning = false;
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, 'Summarization failed!: $error'),
      );
    });
  }

  void _setSuccess() {
    setState(() {
      ctr.isRunning = false;
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(
            context,
            'Summarization complete! 🎉 \n'
            'Output path: ${showOutputDir(ctr.outputDir!)}'),
      );
      ctr.reset();
    });
  }
}
