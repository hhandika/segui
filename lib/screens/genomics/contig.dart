import 'dart:io';

import 'package:flutter/material.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/src/rust/api/contig.dart';

class ContigPage extends StatefulWidget {
  const ContigPage({super.key});

  @override
  State<ContigPage> createState() => _ContigPageState();
}

class _ContigPageState extends State<ContigPage> {
  IOController ctr = IOController.empty();

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(title: 'Input'),
          FormCard(children: [
            InputSelectorForm(
              xTypeGroup: const [genomicTypeGroup],
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
              items: contigFormat,
              onChanged: (value) {
                setState(() {
                  ctr.inputFormatController = value;
                });
              },
            ),
          ]),
          const SizedBox(height: 16),
          const CardTitle(title: 'Output'),
          FormCard(children: [
            SharedOutputDirField(
              ctr: ctr.outputDir,
              onChanged: () {
                setState(() {});
              },
            ),
            SharedTextField(
              controller: ctr.outputController,
              label: 'Output Filename',
              hint: 'Enter output filename',
            ),
          ]),
          const SizedBox(height: 16),
          Center(
              child: ExecutionButton(
            isRunning: ctr.isRunning,
            isSuccess: ctr.isSuccess,
            controller: ctr,
            label: 'Summarize',
            onNewRun: () => setState(() {}),
            onExecuted: ctr.isRunning || !ctr.isValid()
                ? null
                : () async {
                    String dir = await getOutputDir(
                        ctr.outputDir.text, SupportedTask.genomicContigSummary);
                    setState(() {
                      ctr.isRunning = true;
                      ctr.outputDir.text = dir;
                    });
                    await _summarize(ctr);
                  },
            onShared: () {
              try {
                _shareOutput();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ))
        ]);
  }

  Future<void> _summarize(IOController ctr) async {
    try {
      await ContigServices(
        files: ctr.files,
        dirPath: ctr.dirPath.text,
        fileFmt: ctr.inputFormatController!,
        outputDir: ctr.outputDir.text,
      ).summarize();
      _setSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareOutput() async {
    IOServices io = IOServices();
    File outputPath = await io.archiveOutput(
      dir: Directory(ctr.outputDir.text),
      fileName: ctr.outputController.text,
      task: SupportedTask.genomicContigSummary,
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
        const SnackBar(
          content: Text('Summarization complete!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }
}
