import 'package:flutter/material.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/native.dart';

class IdParsingPage extends StatefulWidget {
  const IdParsingPage({super.key});

  @override
  State<IdParsingPage> createState() => _IdParsingPageState();
}

class _IdParsingPageState extends State<IdParsingPage> {
  IOController ctr = IOController.empty();
  bool _isRunning = false;
  bool _isMap = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        const CardTitle(title: 'Input'),
        SharedSequenceInputForm(
          ctr: ctr,
          isDatatypeEnabled: false,
        ),
        const SizedBox(height: 16),
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
        ]),
        SwitchForm(
            label: 'Map sequence ID',
            value: _isMap,
            onPressed: (value) {
              setState(() {
                _isMap = value;
              });
            }),
        const SizedBox(height: 16),
        Center(
          child: PrimaryButton(
            label: 'Parse IDs',
            isRunning: _isRunning,
            onPressed: () async {
              setState(() {
                _isRunning = true;
              });
              try {
                await _parseId();
                setState(() {
                  _isRunning = false;
                });
              } catch (e) {
                _showError(e.toString());
              }
            },
          ),
        )
      ],
    );
  }

  Future<void> _parseId() async {
    await SequenceServices(
      bridge: segulApi,
      files: ctr.files,
      dirPath: ctr.dirPath,
      outputDir: ctr.outputDir!,
      fileFmt: ctr.inputFormatController!,
      datatype: ctr.dataTypeController,
    ).parseSequenceId(isMap: _isMap);
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(showSharedSnackBar(
      context,
      'Failed to parse sequence ID: $error',
    ));
  }
}
