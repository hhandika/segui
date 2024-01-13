import 'dart:io';

import 'package:flutter/material.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/io.dart';
import 'package:segui/src/rust/api/sequence.dart';

class IdParsingPage extends StatefulWidget {
  const IdParsingPage({super.key});

  @override
  State<IdParsingPage> createState() => _IdParsingPageState();
}

class _IdParsingPageState extends State<IdParsingPage> {
  IOController ctr = IOController.empty();
  bool _isMap = false;

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
          isDatatypeEnabled: false,
        ),
        const SizedBox(height: 16),
        const CardTitle(title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
              ctr: ctr.outputDir, onChanged: () => setState(() {})),
          SharedTextField(
            controller: ctr.outputController,
            label: 'Filename',
            hint: 'Enter output filename',
          ),
          SwitchForm(
              label: 'Map sequence ID',
              value: _isMap,
              onPressed: (value) {
                setState(() {
                  _isMap = value;
                });
              }),
        ]),
        const SizedBox(height: 16),
        Center(
          child: ExecutionButton(
            label: 'Parse IDs',
            isRunning: ctr.isRunning,
            isSuccess: ctr.isSuccess,
            controller: ctr,
            onNewRun: () => setState(() {}),
            onExecuted: () async {
              String dir = await getOutputDir(
                ctr.outputDir.text,
                SupportedTask.sequenceUniqueId,
              );
              setState(() {
                ctr.isRunning = true;
                ctr.outputDir.text = dir;
              });

              await _parseId();
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

  Future<void> _parseId() async {
    try {
      await SequenceServices(
        inputFiles: ctr.files,
        dir: ctr.dirPath.text,
        outputDir: ctr.outputDir.text,
        inputFmt: ctr.inputFormatController!,
        datatype: ctr.dataTypeController,
      ).parseSequenceId(
        isMap: _isMap,
        outputFname: ctr.outputController.text,
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
      task: SupportedTask.sequenceUniqueId,
    );
    if (mounted) {
      await io.shareFile(context, outputPath);
    }
  }

  void _setSuccess() {
    setState(() {
      ctr.isRunning = false;
      ctr.isSuccess = true;
      ScaffoldMessenger.of(context).showSnackBar(showSharedSnackBar(
        context,
        'Successfully parsed sequence ID! 🎉 \n'
        'Output Path: ${showOutputDir(ctr.outputDir.text)}',
      ));
    });
  }

  void _showError(String error) {
    setState(() {
      ctr.isRunning = false;
      ctr.isSuccess = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(showSharedSnackBar(
      context,
      'Failed to parse sequence ID: $error',
    ));
  }
}
