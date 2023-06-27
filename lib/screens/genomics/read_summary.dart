import 'package:flutter/material.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/io.dart';
import 'package:segui/services/native.dart';

class QuickRawSummary extends StatelessWidget {
  const QuickRawSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Raw Sequence Summary'),
        ),
        body: const SingleChildScrollView(
          child: AppPageView(child: ReadSummaryPage()),
        ));
  }
}

class ReadSummaryPage extends StatefulWidget {
  const ReadSummaryPage({super.key});

  @override
  State<ReadSummaryPage> createState() => _ReadSummaryPageState();
}

class _ReadSummaryPageState extends State<ReadSummaryPage> {
  IOController ctr = IOController.empty();
  String mode = sequenceReadSummaryMode[0];
  bool lowMemory = false;

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
            items: sequenceReadFormat,
            onChanged: (String? value) {
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
          SharedDropdownField(
            value: mode,
            label: 'Summary Mode',
            items: sequenceReadSummaryMode,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  mode = value;
                }
              });
            },
          ),
          SwitchForm(
            label: 'Use low memory mode',
            value: lowMemory,
            onPressed: (value) {
              setState(() {
                lowMemory = value;
              });
            },
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
                      try {
                        await _summarize();
                        _setSuccess();
                      } catch (e) {
                        _showError(e.toString());
                      }
                    }),
        )
      ],
    );
  }

  Future<void> _summarize() async {
    await FastqServices(
      bridge: segulApi,
      files: ctr.files,
      dirPath: ctr.dirPath,
      outputDir: ctr.outputDir!,
      fileFmt: ctr.inputFormatController!,
    ).summarize(
      mode: mode,
      lowmem: lowMemory,
    );
  }

  void _showError(String error) {
    setState(() {
      ctr.isRunning = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Summarization failed: $error'),
        ),
      );
      ctr.reset();
    });
  }

  void _setSuccess() {
    setState(() {
      ctr.isRunning = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Summarization complete'),
        ),
      );
      ctr.reset();
    });
  }
}
