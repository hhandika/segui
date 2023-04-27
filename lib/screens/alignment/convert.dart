import 'package:flutter/material.dart';
// import 'package:segui/bridge_definitions.dart';
// ignore: unused_import
import 'package:segui/bridge_generated.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/services/io.dart';
import 'package:segui/services/native.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/types.dart';

class QuickConvertPage extends StatelessWidget {
  const QuickConvertPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alignment Conversion'),
      ),
      body: const AppPageView(child: ConvertPage()),
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
                    setState(() {
                      ctr.isRunning = true;
                    });
                    try {
                      await _convert();
                      if (mounted) {
                        setState(() {
                          ctr.isRunning = false;
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
                          ctr.isRunning = false;
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
        )
      ],
    );
  }

  Future<void> _convert() async {
    String outputDir = await getOutputDir(ctr.outputDir);
    await SegulServices(
      bridge: segulApi,
      files: ctr.files,
      dirPath: ctr.dirPath,
      outputDir: outputDir,
      fileFmt: ctr.inputFormatController!,
      datatype: ctr.dataTypeController,
    ).convertSequence(
      outputFmt: ctr.outputFormatController!,
      sort: isSortSequence,
    );
  }

  void _resetController() {
    setState(() {
      ctr.reset();
    });
  }
}