import 'package:flutter/material.dart';
import 'package:segui/bridge_definitions.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/io.dart';
import 'package:segui/services/native.dart';

class QuickTranslatePage extends StatelessWidget {
  const QuickTranslatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sequence Translation'),
      ),
      body: const SingleChildScrollView(
        child: AppPageView(child: TranslatePage()),
      ),
    );
  }
}

class TranslatePage extends StatefulWidget {
  const TranslatePage({super.key});

  @override
  State<TranslatePage> createState() => _TranslatePageState();
}

class _TranslatePageState extends State<TranslatePage> {
  IOController ctr = IOController.empty();
  bool isInterleave = false;
  String _readingFrame = readingFrame[0];
  int _tableIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        const CardTitle(title: 'Input'),
        SharedInputForms(
          ctr: ctr,
          isDatatypeEnabled: false,
        ),
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
          SharedDropdownField(
            value: translationTable[_tableIndex],
            label: 'Translation Table',
            items: translationTable,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _tableIndex = translationTable.indexOf(value);
                }
              });
            },
          ),
          SharedDropdownField(
            value: _readingFrame,
            label: 'Reading Frame',
            items: readingFrame,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _readingFrame = value;
                }
              });
            },
          ),
        ]),
        const SizedBox(height: 20),
        Center(
          child: PrimaryButton(
            label: 'Translate',
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
                      await _translate();
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

  Future<void> _translate() async {
    String outputFmt = getOutputFmt(ctr.outputFormatController!, isInterleave);
    await SegulServices(
      bridge: segulApi,
      files: ctr.files,
      dirPath: ctr.dirPath,
      outputDir: ctr.outputDir!,
      fileFmt: ctr.inputFormatController!,
      datatype: ctr.dataTypeController,
    ).translateSequence(
        table: _tableIndex.toString(),
        readingFrame: int.tryParse(_readingFrame) ?? 1,
        outputFmt: outputFmt);
  }

  void _showError(String error) {
    setState(() {
      ctr.isRunning = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      showSharedSnackBar(context, 'Translation failed!: $error'),
    );
  }

  void _setSuccess() {
    setState(() {
      ctr.isRunning = false;
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(
            context,
            'Translation complete! 🎉 \n'
            'Output path: ${showOutputDir(ctr.outputDir!)}'),
      );
      ctr.reset();
    });
  }
}
