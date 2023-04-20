import 'package:flutter/material.dart';
import 'package:segui/bridge_generated.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/services/native.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/types.dart';

class ConvertPage extends StatefulWidget {
  const ConvertPage({super.key});

  @override
  State<ConvertPage> createState() => _ConvertPageState();
}

class _ConvertPageState extends State<ConvertPage> {
  IOController ctr = IOController.empty();
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 25, 10, 15),
          child: ListView(
            shrinkWrap: false,
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
                )
              ]),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Convert',
                isRunning: _isRunning,
                onPressed: _isRunning || !_validate()
                    ? null
                    : () async {
                        setState(() {
                          _isRunning = true;
                        });
                        try {
                          await _convert();
                          if (mounted) {
                            setState(() {
                              _isRunning = false;
                              ScaffoldMessenger.of(context).showSnackBar(
                                showSharedSnackBar(
                                  context,
                                  'Conversion successful!',
                                ),
                              );
                              _resetController();
                            });
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              _isRunning = false;
                              ScaffoldMessenger.of(context).showSnackBar(
                                showSharedSnackBar(
                                  context,
                                  'Conversion failed!: $e',
                                ),
                              );
                            });
                          }
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _convert() async {
    await SegulServices(
      bridge: segulApi,
      dirPath: ctr.dirPath!,
      outputDir: ctr.outputDir!,
      fileFmt: ctr.inputFormatController!,
      datatype: ctr.dataTypeController,
    ).convertSequence(
      outputFmt: ctr.outputFormatController,
      sort: false,
    );
  }

  bool _validate() {
    return ctr.dirPath != null ||
        ctr.files.isNotEmpty &&
            ctr.outputDir != null &&
            ctr.inputFormatController != null;
  }

  void _resetController() {
    setState(() {
      ctr.reset();
    });
  }
}
