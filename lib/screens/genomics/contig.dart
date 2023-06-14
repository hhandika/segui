import 'package:flutter/material.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
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
          ]),
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
        ]);
  }
}
