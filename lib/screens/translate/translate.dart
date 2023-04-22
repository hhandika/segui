import 'package:flutter/material.dart';
import 'package:segui/bridge_generated.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/types.dart';
import 'package:segui/services/native.dart';

class TranslatePage extends StatefulWidget {
  const TranslatePage({super.key});

  @override
  State<TranslatePage> createState() => _TranslatePageState();
}

class _TranslatePageState extends State<TranslatePage> {
  IOController ctr = IOController.empty();
  String _readingFrame = readingFrame[0];
  String _translationTable = translationTable[0];

  @override
  Widget build(BuildContext context) {
    return FormView(
      children: [
        const CardTitle(title: 'Input'),
        SharedInputForms(ctr: ctr),
        const SizedBox(height: 20),
        const CardTitle(title: 'Output'),
        FormCard(children: [
          SelectDirField(
              label: 'Select output directory',
              dirPath: ctr.outputDir,
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
          SharedDropdownField(
            value: _translationTable,
            label: 'Translation Table',
            items: translationTable,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _translationTable = value;
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
        PrimaryButton(
          label: 'Translate',
          isRunning: ctr.isRunning,
          onPressed: ctr.isRunning || !ctr.isValid()
              ? null
              : () async {
                  setState(() {
                    ctr.isRunning = true;
                  });
                  try {
                    await _translate();
                    if (mounted) {
                      setState(() {
                        ctr.isRunning = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        showSharedSnackBar(context, 'Translation complete!'),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        ctr.isRunning = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        showSharedSnackBar(context, 'Translation failed!: $e'),
                      );
                    }
                  }
                },
        ),
      ],
    );
  }

  Future<void> _translate() async {
    await SegulServices(
      bridge: segulApi,
      files: ctr.files,
      dirPath: ctr.dirPath,
      outputDir: ctr.outputDir!,
      fileFmt: ctr.inputFormatController!,
      datatype: ctr.dataTypeController,
    ).translateSequence(
        table: int.tryParse(_translationTable) ?? 1,
        readingFrame: int.tryParse(_readingFrame) ?? 1,
        outputFmt: ctr.outputFormatController!);
  }
}
