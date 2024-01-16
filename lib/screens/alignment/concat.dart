import 'dart:io';

import 'package:flutter/material.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/io.dart';
import 'package:segui/src/rust/api/sequence.dart';

class QuickConcatPage extends StatelessWidget {
  const QuickConcatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alignment Concatenation'),
      ),
      body: const AppPageView(
        child: SingleChildScrollView(child: ConcatPage()),
      ),
    );
  }
}

class ConcatPage extends StatefulWidget {
  const ConcatPage({super.key});

  @override
  State<ConcatPage> createState() => _ConcatPageState();
}

class _ConcatPageState extends State<ConcatPage> {
  IOController ctr = IOController.empty();
  String _partitionFormatController = partitionFormat[1];
  bool isCodon = false;
  bool isInterleave = false;
  bool isShowMore = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CardTitle(title: 'Input'),
        SharedSequenceInputForm(
          ctr: ctr,
          xTypeGroup: const [sequenceTypeGroup],
        ),
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
            label: 'Filename',
            hint: 'Enter output filename',
          ),
          SharedDropdownField(
            value: ctr.outputFormatController,
            label: 'Format',
            items: outputFormat,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  ctr.outputFormatController = value;
                  ctr.isSuccess = false;
                }
              });
            },
          ),
          Visibility(
            visible: isShowMore,
            child: SwitchForm(
              label: 'Set interleaved format',
              value: isInterleave,
              onPressed: (value) {
                setState(() {
                  isInterleave = value;
                });
              },
            ),
          ),
          SharedDropdownField(
            value: _partitionFormatController,
            label: 'Partition Format',
            items: partitionFormat,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _partitionFormatController = value;
                }
              });
            },
          ),
          Visibility(
            visible: isShowMore,
            child: SwitchForm(
                label: 'Set codon model partition',
                value: isCodon,
                onPressed: (value) {
                  setState(() {
                    isCodon = value;
                  });
                }),
          ),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  isShowMore = !isShowMore;
                });
              },
              child: Text(isShowMore ? 'Show less' : 'Show more'),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        Center(
          child: ExecutionButton(
            label: 'Concatenate',
            isRunning: ctr.isRunning,
            controller: ctr,
            isSuccess: ctr.isSuccess,
            onNewRun: () => setState(() {}),
            onExecuted: ctr.isRunning || !_validate()
                ? null
                : () async {
                    String dir = await getOutputDir(ctr.outputDir.text,
                        SupportedTask.alignmentConcatenation);
                    setState(() {
                      ctr.isRunning = true;
                      ctr.outputDir.text = dir;
                    });
                    await _concat();
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

  bool _validate() {
    bool isInputValid = ctr.outputFormatController != null;
    return isInputValid && ctr.isValid();
  }

  Future<void> _concat() async {
    String outputFmt = getOutputFmt(ctr.outputFormatController!, isInterleave);
    String partitionFmt = getPartitionFmt(_partitionFormatController, isCodon);
    try {
      await AlignmentServices(
        dir: ctr.dirPath.text,
        inputFiles: ctr.files,
        inputFmt: ctr.inputFormatController!,
        datatype: ctr.dataTypeController,
        outputDir: ctr.outputDir.text,
      ).concatAlignment(
        outFname: ctr.outputController.text,
        outFmtStr: outputFmt,
        partitionFmt: partitionFmt,
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
      task: SupportedTask.alignmentConcatenation,
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
            'Concatenation successful! 🎉 \n'
            'Output path: ${showOutputDir(ctr.outputDir.text)}'),
      );
    });
  }
}
