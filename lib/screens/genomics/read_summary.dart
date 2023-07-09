import 'dart:io';

import 'package:flutter/material.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/io.dart';
import 'package:segui/services/native.dart';

class QuickRawSummary extends StatelessWidget {
  const QuickRawSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Raw Sequence Summary'),
        ),
        body: const SingleChildScrollView(
          child: AppPageView(child: ReadSummaryPage()),
        ));
  }
}

class ReadSummaryPage extends StatefulWidget {
  const ReadSummaryPage({super.key});

  @override
  State<ReadSummaryPage> createState() => _ReadSummaryPageState();
}

class _ReadSummaryPageState extends State<ReadSummaryPage> {
  IOController ctr = IOController.empty();
  String mode = sequenceReadSummaryMode[0];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CardTitle(title: 'Input'),
        FormCard(children: [
          InputSelectorForm(
            onFilePressed: (value) {
              setState(() {
                ctr.files = value;
              });
            },
            ctr: ctr,
          ),
          SharedDropdownField(
            value: ctr.inputFormatController,
            label: 'Format',
            items: sequenceReadFormat,
            onChanged: (String? value) {
              setState(() {
                ctr.inputFormatController = value;
              });
            },
          ),
        ]),
        const SizedBox(height: 16),
        const CardTitle(title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(ctr: ctr.outputDir),
          SharedDropdownField(
            value: mode,
            label: 'Summary Mode',
            items: sequenceReadSummaryMode,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  mode = value;
                }
              });
            },
          ),
        ]),
        const SizedBox(height: 16),
        Center(
          child: ExecutionButton(
            isRunning: ctr.isRunning,
            isSuccess: ctr.isSuccess,
            label: 'Summarize',
            onExecuted: ctr.isRunning || !ctr.isValid()
                ? null
                : () async {
                    String dir = await getOutputDir(ctr.outputDir.text,
                        SupportedTask.genomicRawReadSummary);
                    setState(() {
                      ctr.isRunning = true;
                      ctr.outputDir.text = dir;
                    });
                    await _summarize();
                  },
            onShared: () {
              try {
                _shareOutput();
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
      await FastqServices(
        bridge: segulApi,
        files: ctr.files,
        dirPath: ctr.dirPath.text,
        outputDir: ctr.outputDir.text,
        fileFmt: ctr.inputFormatController!,
      ).summarize(
        mode: mode,
      );
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
      task: SupportedTask.genomicRawReadSummary,
    );
    if (mounted) {
      await io.shareFile(context, outputPath);
    }
  }

  void _showError(String error) {
    setState(() {
      ctr.isRunning = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
        ),
      );
    });
  }

  void _setSuccess() {
    setState(() {
      ctr.isRunning = false;
      ctr.isSuccess = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Summarization complete'),
        ),
      );
    });
  }
}
