import 'package:flutter/material.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/io.dart';
import 'package:segui/services/native.dart';

class QuickConcatPage extends StatelessWidget {
  const QuickConcatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Alignment Concatenation'),
        ),
        body: const SingleChildScrollView(
          child: AppPageView(child: ConcatPage()),
        ));
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CardTitle(title: 'Input'),
        SharedSequenceInputForm(ctr: ctr),
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
            label: 'Output Filename',
            hint: 'Enter output filename',
          ),
          SharedDropdownField(
            value: ctr.outputFormatController,
            label: 'Output Format',
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
            },
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
          SwitchForm(
              label: 'Set codon model partition',
              value: isCodon,
              onPressed: (value) {
                setState(() {
                  isCodon = value;
                });
              }),
        ]),
        const SizedBox(height: 20),
        Center(
          child: PrimaryButton(
            label: 'Concatenate',
            isRunning: ctr.isRunning,
            onPressed: ctr.isRunning || !_validate()
                ? null
                : () async {
                    String dir = await getOutputDir(ctr.outputDir);
                    setState(() {
                      ctr.isRunning = true;
                      ctr.outputDir = dir;
                    });
                    try {
                      await _concat();
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

  bool _validate() {
    bool isInputValid = ctr.outputFormatController != null;
    return isInputValid && ctr.isValid();
  }

  Future<void> _concat() async {
    String outputFmt = getOutputFmt(ctr.outputFormatController!, isInterleave);
    String partitionFmt = getPartitionFmt(_partitionFormatController, isCodon);
    await SequenceServices(
      bridge: segulApi,
      dirPath: ctr.dirPath,
      files: ctr.files,
      fileFmt: ctr.inputFormatController!,
      datatype: ctr.dataTypeController,
      outputDir: ctr.outputDir!,
    ).concatAlignment(
      outFname: ctr.outputController.text,
      outFmtStr: outputFmt,
      partitionFmt: partitionFmt,
    );
  }

  void _showError(String error) {
    setState(() {
      ctr.isRunning = false;
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, 'Failed to concatenate: $error'),
      );
    });
  }

  void _setSuccess() {
    setState(() {
      ctr.isRunning = false;
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(
            context,
            'Concatenation successful! 🎉 \n'
            'Output path: ${showOutputDir(ctr.outputDir!)}'),
      );
      ctr.reset();
    });
  }
}
