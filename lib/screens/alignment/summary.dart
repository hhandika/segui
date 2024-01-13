import 'dart:io';

import 'package:flutter/material.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/io.dart';
import 'package:segui/src/rust/api/sequence.dart';

class QuickAlignmentSummaryPage extends StatelessWidget {
  const QuickAlignmentSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alignment Summary'),
      ),
      body: const SingleChildScrollView(
        child: AppPageView(
            child: SingleChildScrollView(
          child: AlignmentSummaryPage(),
        )),
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
  String? _interval;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CardTitle(title: 'Input'),
        SharedSequenceInputForm(
          ctr: ctr,
          xTypeGroup: const [sequenceTypeGroup],
        ),
        const SizedBox(height: 20),
        const CardTitle(title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
              ctr: ctr.outputDir,
              onChanged: () {
                setState(() {});
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
          child: ExecutionButton(
            label: 'Summarize',
            isRunning: ctr.isRunning,
            isSuccess: ctr.isSuccess,
            controller: ctr,
            onNewRun: () => setState(() {}),
            onExecuted: ctr.isRunning || !ctr.isValid()
                ? null
                : () async {
                    String dir = await getOutputDir(
                        ctr.outputDir.text, SupportedTask.alignmentSummary);
                    setState(() {
                      ctr.isRunning = true;
                      ctr.outputDir.text = dir;
                    });
                    await _summarize();
                  },
            onShared: () async {
              try {
                await _shareOutput();
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
    try {
      await AlignmentServices(
        inputFiles: ctr.files,
        dir: ctr.dirPath.text,
        outputDir: ctr.outputDir.text,
        inputFmt: ctr.inputFormatController!,
        datatype: ctr.dataTypeController,
      ).summarizeAlignment(
          outputPrefix: ctr.outputController.text,
          interval: int.tryParse(_interval!) ?? 5);
      _setSuccess();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _shareOutput() async {
    IOServices io = IOServices();
    File outputPath = await io.archiveOutput(
      dir: Directory(ctr.outputDir.text),
      fileName: ctr.outputController.text,
      task: SupportedTask.alignmentSummary,
    );
    if (mounted) {
      await io.shareFile(context, outputPath);
    }
  }

  void _showError(String error) {
    setState(() {
      ctr.isRunning = false;
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, error),
      );
    });
  }

  void _setSuccess() {
    setState(() {
      ctr.isRunning = false;
      ctr.isSuccess = true;
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(
            context,
            'Summarization complete! 🎉 \n'
            'Output path: ${showOutputDir(ctr.outputDir.text)}'),
      );
    });
  }
}
