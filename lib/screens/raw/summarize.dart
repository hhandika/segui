import 'package:flutter/material.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/types.dart';
import 'package:segui/services/io.dart';
import 'package:segui/bridge_generated.dart';
import 'package:segui/services/native.dart';

class QuickRawSummary extends StatelessWidget {
  const QuickRawSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raw Sequence Summary'),
      ),
      body: const AppPageView(child: RawSummaryPage()),
    );
  }
}

class RawSummaryPage extends StatefulWidget {
  const RawSummaryPage({super.key});

  @override
  State<RawSummaryPage> createState() => _RawSummaryPageState();
}

class _RawSummaryPageState extends State<RawSummaryPage> {
  IOController ctr = IOController.empty();
  String mode = rawReadSummaryMode[0];
  bool lowMemory = false;

  @override
  Widget build(BuildContext context) {
    return Column(
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
            items: rawReadFormat,
            onChanged: (String? value) {
              setState(() {
                ctr.inputFormatController = value;
              });
            },
          ),
        ]),
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
            value: mode,
            label: 'Summary Mode',
            items: rawReadSummaryMode,
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
        const SizedBox(height: 20),
        Center(
          child: PrimaryButton(
              isRunning: ctr.isRunning,
              label: 'Summarize',
              onPressed: ctr.isRunning || !ctr.isValid()
                  ? null
                  : () async {
                      setState(() {
                        ctr.isRunning = true;
                      });
                      try {
                        await _summarize();
                        if (mounted) {
                          ctr.isRunning = false;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Summarization complete'),
                            ),
                          );
                          ctr.reset();
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            ctr.isRunning = false;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                              ),
                            );
                            ctr.reset();
                          });
                        }
                      }
                    }),
        )
      ],
    );
  }

  Future<void> _summarize() async {
    String outputDir = await getOutputDir(ctr.outputDir);

    await RawReadServices(
      bridge: segulApi,
      files: ctr.files,
      dirPath: ctr.dirPath,
      outputDir: outputDir,
      fileFmt: ctr.inputFormatController!,
    ).summarize(
      mode: mode,
      lowmem: lowMemory,
    );
  }
}
