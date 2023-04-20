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
              Text(
                'Input',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SelectDirField(
                  dirPath: ctr.dirPath,
                  onChanged: (value) {
                    setState(() {
                      ctr.dirPath = value;
                    });
                  }),
              SharedDropdownField(
                value: ctr.inputFormatController,
                label: 'Format',
                items: inputFormat,
                onChanged: (String? value) {
                  setState(() {
                    ctr.inputFormatController = value;
                  });
                },
              ),
              SharedDropdownField(
                value: ctr.dataTypeController,
                label: 'Data Type',
                items: dataType,
                onChanged: (String? value) {
                  setState(() {
                    ctr.dataTypeController = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Output',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SelectDirField(
                  dirPath: ctr.outputDir,
                  onChanged: (value) {
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
                    ctr.outputFormatController = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Convert',
                isRunning: _isRunning,
                onPressed: _isRunning
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
                                const SnackBar(
                                  content: Text('Conversion complete!'),
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
                                SnackBar(
                                  content: Text(
                                    'Conversion failed! $e',
                                  ),
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
      output: ctr.outputDir!,
      fileFmt: ctr.inputFormatController!,
      datatype: ctr.dataTypeController!,
    ).convertSequence(
      outputFmt: ctr.outputFormatController!,
      sort: false,
    );
  }

  void _resetController() {
    setState(() {
      ctr.reset();
    });
  }
}
