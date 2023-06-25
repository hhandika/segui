import 'package:flutter/material.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/io.dart';
import 'package:segui/services/native.dart';
import 'package:segui/services/types.dart';

class ContigPage extends StatefulWidget {
  const ContigPage({super.key});

  @override
  State<ContigPage> createState() => _ContigPageState();
}

class _ContigPageState extends State<ContigPage> {
  IOController ctr = IOController.empty();

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(title: 'Input'),
          FormCard(children: [
            InputSelectorForm(
              onDirPressed: (value) {
                setState(() {
                  ctr.dirPath = value;
                });
              },
              onFilePressed: (value) {
                setState(() {
                  ctr.files = value;
                });
              },
              ctr: ctr,
            ),
            SharedDropdownField(
              value: ctr.inputFormatController,
              label: 'Format',
              items: contigFormat,
              onChanged: (value) {
                setState(() {
                  ctr.inputFormatController = value;
                });
              },
            ),
          ]),
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
          const SizedBox(height: 16),
          Center(
              child: PrimaryButton(
            isRunning: ctr.isRunning,
            label: 'Summarize',
            onPressed: ctr.isRunning || !ctr.isValid()
                ? null
                : () async {
                    String dir = await getOutputDir(ctr.outputDir);
                    setState(() {
                      ctr.isRunning = true;
                      ctr.outputDir = dir;
                    });
                    await _summarize(ctr);
                    setState(() {
                      ctr.isRunning = false;
                    });
                  },
          ))
        ]);
  }

  Future<void> _summarize(IOController ctr) async {
    try {
      await ContigServices(
        bridge: segulApi,
        files: ctr.files,
        dirPath: ctr.dirPath,
        fileFmt: ctr.inputFormatController!,
        outputDir: ctr.outputDir!,
      ).summarize();
      _setSuccess();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _setSuccess() {
    setState(() {
      ctr.isRunning = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Summarization complete!'),
          backgroundColor: Colors.green,
        ),
      );

      ctr.reset();
    });
  }
}
