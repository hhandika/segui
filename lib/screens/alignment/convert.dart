import 'package:flutter/material.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/services/io.dart';
import 'package:segui/services/native.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/types.dart';

class QuickConvertPage extends StatelessWidget {
  const QuickConvertPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alignment Conversion'),
      ),
      body: const SingleChildScrollView(
        child: AppPageView(child: ConvertPage()),
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
          child: PrimaryButton(
            label: 'Convert',
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
                      await _convert();
                      _setSuccess();
                    } catch (e) {
                      setState(() {
                        ctr.isRunning = false;
                        ScaffoldMessenger.of(context).showSnackBar(
                          showSharedSnackBar(
                            context,
                            'Conversion failed!: $e',
                          ),
                        );
                      });
                    }
                  },
          ),
        )
      ],
    );
  }

  Future<void> _convert() async {
    String outputFmt = getOutputFmt(ctr.outputFormatController!, isInterleave);
    await SequenceServices(
      bridge: segulApi,
      files: ctr.files,
      dirPath: ctr.dirPath,
      outputDir: ctr.outputDir!,
      fileFmt: ctr.inputFormatController!,
      datatype: ctr.dataTypeController,
    ).convertSequence(
      outputFmt: outputFmt,
      sort: isSortSequence,
    );
  }

  void _setSuccess() {
    setState(() {
      ctr.isRunning = false;
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(
          context,
          'Conversion successful! 🎉 \n'
          'Output Path: ${showOutputDir(ctr.outputDir!)}',
        ),
      );
      ctr.reset();
    });
  }
}
