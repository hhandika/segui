import 'package:flutter/material.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/types.dart';
import 'package:segui/services/native.dart';

class ConcatPage extends StatefulWidget {
  const ConcatPage({super.key});

  @override
  State<ConcatPage> createState() => _ConcatPageState();
}

class _ConcatPageState extends State<ConcatPage> {
  String? _dirPath;
  String? _outputDir;
  final TextEditingController _outputController = TextEditingController();
  String? _inputFormatController;
  String? _outputFormatController;
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 25, 5, 5),
          child: ListView(
            shrinkWrap: false,
            children: [
              Text(
                'Input',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SelectDirField(
                  dirPath: _dirPath,
                  onChanged: (value) {
                    setState(() {
                      _dirPath = value;
                    });
                  }),
              SharedDropdownField(
                value: _inputFormatController,
                label: 'Format',
                items: inputFormat,
                onChanged: (String? value) {
                  setState(() {
                    _inputFormatController = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              Text('Output', style: Theme.of(context).textTheme.titleMedium),
              SelectDirField(
                dirPath: _outputDir,
                onChanged: (value) {
                  setState(() {
                    _outputDir = value;
                  });
                },
              ),
              SharedTextField(
                controller: _outputController,
                label: 'Output Filename',
                hint: 'Enter output filename',
              ),
              SharedDropdownField(
                value: _outputFormatController,
                label: 'Format',
                items: outputFormat,
                onChanged: (String? value) {
                  setState(() {
                    _outputFormatController = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 80,
                child: PrimaryButton(
                  label: 'Concatenate',
                  isRunning: _isRunning,
                  onPressed: _isRunning
                      ? null
                      : () {
                          if (_dirPath != null) {
                            setState(() {
                              _isRunning = true;
                            });
                            api
                                .concatAlignment(
                              dirPath: _dirPath!,
                              fileFmt: _inputFormatController!,
                              datatype: 'dna',
                              output: '$_outputDir/${_outputController.text}',
                            )
                                .then(
                              (value) {
                                setState(() {
                                  _dirPath = null;
                                  _outputController.text = '';
                                  _inputFormatController = null;
                                  _outputFormatController = null;
                                  _isRunning = false;
                                });
                              },
                            );
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
}
