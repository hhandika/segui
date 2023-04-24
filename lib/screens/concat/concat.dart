import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:segui/bridge_definitions.dart';
// ignore: unused_import
import 'package:segui/bridge_generated.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/types.dart';
import 'package:segui/services/io.dart';

import 'package:segui/services/native.dart';

class ConcatPage extends StatefulWidget {
  const ConcatPage({super.key});

  @override
  State<ConcatPage> createState() => _ConcatPageState();
}

class _ConcatPageState extends State<ConcatPage> {
  IOController ctr = IOController.empty();
  String _partitionFormatController = partitionFormat[1];
  String? analysisType;

  @override
  Widget build(BuildContext context) {
    return FormView(
      children: [
        SharedDropdownField(
            value: analysisType,
            label: 'Type of analyses',
            items: alignmentAnalysis,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  analysisType = value;
                }
              });
            }),
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 10, 0, 20),
          child: Divider(),
        ),
        const CardTitle(title: 'Input'),
        SharedInputForms(ctr: ctr),
        const SizedBox(height: 20),
        const CardTitle(title: 'Output'),
        FormCard(children: [
          Platform.isIOS
              ? const SizedBox.shrink()
              : SelectDirField(
                  label: 'Select output directory',
                  dirPath: ctr.outputDir,
                  onPressed: (value) {
                    setState(() {
                      ctr.outputDir = value;
                    });
                  },
                ),
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
          )
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: 80,
          child: PrimaryButton(
            label: 'Concatenate',
            isRunning: ctr.isRunning,
            onPressed: ctr.isRunning || !_validate()
                ? null
                : () async {
                    setState(() {
                      ctr.isRunning = true;
                    });
                    try {
                      await _concat();
                      if (mounted) {
                        setState(() {
                          ctr.isRunning = false;
                          ScaffoldMessenger.of(context).showSnackBar(
                            showSharedSnackBar(
                                context, 'Concatenation successful!'),
                          );
                          _resetController();
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          ctr.isRunning = false;
                          ScaffoldMessenger.of(context).showSnackBar(
                            showSharedSnackBar(context, e.toString()),
                          );
                        });
                      }
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
    String outputDir = await getOutputDir(ctr.outputDir);
    await SegulServices(
      bridge: segulApi,
      dirPath: ctr.dirPath,
      files: ctr.files,
      fileFmt: ctr.inputFormatController!,
      datatype: ctr.dataTypeController,
      outputDir: outputDir,
    ).concatAlignment(
      outFname: ctr.outputController.text,
      outFmtStr: ctr.outputFormatController!,
      partitionFmt: _partitionFormatController,
    );
  }

  void _resetController() {
    setState(() {
      ctr.reset();
    });
  }
}
