import 'dart:io';

import 'package:flutter/material.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/services/io.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/types.dart';
import 'package:segui/src/rust/api/sequence.dart';

class QuickConvertPage extends StatelessWidget {
  const QuickConvertPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alignment Conversion'),
      ),
      body: const SingleChildScrollView(
        child: AppPageView(
            child: SingleChildScrollView(
          child: ConvertPage(),
        )),
      ),
    );
  }
}

class ConvertPage extends StatefulWidget {
  const ConvertPage({super.key});

  @override
  State<ConvertPage> createState() => _ConvertPageState();
}

class _ConvertPageState extends State<ConvertPage> {
  IOController ctr = IOController.empty();
  bool isSortSequence = false;
  bool isInterleave = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CardTitle(title: 'Input'),
        SharedSequenceInputForm(ctr: ctr),
        const SizedBox(height: 20),
        const CardTitle(title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
            ctr: ctr.outputDir,
            onChanged: () {
              setState(() {});
            },
          ),
          SharedDropdownField(
            value: ctr.outputFormatController,
            label: 'Format',
            items: outputFormat,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  ctr.outputFormatController = value;
                }
              });
            },
          ),
          SwitchForm(
              label: 'Set interleaved format',
              value: isInterleave,
              onPressed: (value) {
                setState(() {
                  isInterleave = value;
                });
              }),
          SwitchForm(
              label: 'Sort by sequence ID',
              value: isSortSequence,
              onPressed: (value) {
                setState(() {
                  isSortSequence = value;
                });
              }),
        ]),
        const SizedBox(height: 20),
        Center(
          child: ExecutionButton(
            label: 'Convert',
            isRunning: ctr.isRunning,
            isSuccess: ctr.isSuccess,
            controller: ctr,
            onNewRun: () => setState(() {}),
            onExecuted: ctr.isRunning || !ctr.isValid()
                ? null
                : () async {
                    String dir = await getOutputDir(
                        ctr.outputDir.text, SupportedTask.alignmentConversion);
                    setState(() {
                      ctr.isRunning = true;
                      ctr.outputDir.text = dir;
                    });
                    await _convert();
                  },
            onShared: () async {
              try {
                await _shareOutput();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    showSharedSnackBar(
                      context,
                      'Sharing failed!: $e',
                    ),
                  );
                }
              }
            },
          ),
        )
      ],
    );
  }

  Future<void> _convert() async {
    String outputFmt = getOutputFmt(ctr.outputFormatController!, isInterleave);
    try {
      await SequenceServices(
        files: ctr.files,
        dir: ctr.dirPath.text,
        outputDir: ctr.outputDir.text,
        inputFmt: ctr.inputFormatController!,
        datatype: ctr.dataTypeController,
      ).convertSequence(
        outputFmt: outputFmt,
        sort: isSortSequence,
      );
      _setSuccess();
    } catch (e) {
      _showError(e.toString());
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

  Future<void> _shareOutput() async {
    IOServices io = IOServices();
    File outputPath = await io.archiveOutput(
      dir: Directory(ctr.outputDir.text),
      fileName: ctr.outputController.text,
      task: SupportedTask.alignmentConversion,
    );
    if (mounted) {
      await io.shareFile(context, outputPath);
    }
  }

  void _setSuccess() {
    setState(() {
      ctr.isRunning = false;
      ctr.isSuccess = true;
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(
          context,
          'Conversion successful! 🎉 \n'
          'Output Path: ${showOutputDir(ctr.outputDir.text)}',
        ),
      );
    });
  }
}
