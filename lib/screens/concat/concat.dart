import 'package:flutter/material.dart';
import 'package:segui/bridge_definitions.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/types.dart';
import 'package:segui/services/native.dart';

class ConcatPage extends StatefulWidget {
  const ConcatPage({super.key});

  @override
  State<ConcatPage> createState() => _ConcatPageState();
}

class _ConcatPageState extends State<ConcatPage> {
  IOController ctr = IOController.empty();
  String? _partitionFormatController = partitionFormat[0];
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
              Text('Output', style: Theme.of(context).textTheme.titleMedium),
              SelectDirField(
                dirPath: ctr.outputDir,
                onChanged: (value) {
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
                    ctr.outputFormatController = value;
                  });
                },
              ),
              SharedDropdownField(
                value: _partitionFormatController,
                label: 'Partition Format',
                items: partitionFormat,
                onChanged: (String? value) {
                  setState(() {
                    _partitionFormatController = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 80,
                child: PrimaryButton(
                  label: 'Concatenate',
                  isRunning: _isRunning,
                  onPressed: _isRunning || !_validate()
                      ? null
                      : () async {
                          setState(() {
                            _isRunning = true;
                          });
                          try {
                            await _concat();
                            if (mounted) {
                              setState(() {
                                _isRunning = false;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  showSharedSnackBar(
                                      context, 'Concatenation successful'),
                                );
                                _resetController();
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                _isRunning = false;
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
          ),
        ),
      ),
    );
  }

  Future<void> _concat() async {
    await SegulServices(
      bridge: segulApi,
      dirPath: ctr.dirPath!,
      fileFmt: ctr.inputFormatController!,
      datatype: ctr.dataTypeController!,
      outputDir: ctr.outputDir!,
    ).concatAlignment(
      outFname: ctr.outputController.text,
      outFmtStr: ctr.outputFormatController!,
      partitionFmt: _partitionFormatController!,
    );
  }

  bool _validate() {
    return ctr.dirPath != null &&
        ctr.outputDir != null &&
        ctr.outputController.text.isNotEmpty &&
        ctr.outputFormatController != null &&
        ctr.inputFormatController != null &&
        ctr.dataTypeController != null;
  }

  void _resetController() {
    setState(() {
      ctr.reset();
    });
  }
}
