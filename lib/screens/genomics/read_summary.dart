import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/io.dart';
import 'package:segui/src/rust/api/reads.dart';

class ReadSummaryPage extends ConsumerStatefulWidget {
  const ReadSummaryPage({super.key});

  @override
  ReadSummaryPageState createState() => ReadSummaryPageState();
}

class ReadSummaryPageState extends ConsumerState<ReadSummaryPage> {
  IOController ctr = IOController.empty();
  String mode = sequenceReadSummaryMode[0];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CardTitle(title: 'Input'),
        FormCard(children: [
          InputSelectorForm(
            xTypeGroup: genomicTypeGroup,
            allowMultiple: true,
            ctr: ctr,
            hasSecondaryPicker: false,
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
              onChanged: () {
                setState(() {});
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
        ]),
        const SizedBox(height: 16),
        Center(
          child: ExecutionButton(
            isRunning: ctr.isRunning,
            isSuccess: ctr.isSuccess,
            controller: ctr,
            label: 'Summarize',
            onNewRun: () => setState(() {}),
            onExecuted: ref.read(fileInputProvider).when(
                data: (value) {
                  if (value.isEmpty) {
                    return null;
                  } else {
                    return ctr.isRunning || !ctr.isValid()
                        ? null
                        : () async {
                            String dir = await getOutputDir(ctr.outputDir.text,
                                SupportedTask.genomicRawReadSummary);
                            setState(() {
                              ctr.isRunning = true;
                              ctr.outputDir.text = dir;
                            });
                            await _summarize(value);
                          };
                  }
                },
                loading: () => null,
                error: (e, s) {
                  _showError(e.toString());
                  return null;
                }),
            onShared: () {
              try {
                _shareOutput();
              } catch (e) {
                _showError(e.toString());
              }
            },
          ),
        )
      ],
    );
  }

  Future<void> _summarize(List<SegulFile> inputFiles) async {
    try {
      final files =
          IOServices().convertPathsToString(inputFiles, SegulType.genomicReads);
      await RawReadServices(
        files: files,
        dirPath: ctr.dirPath.text,
        outputDir: ctr.outputDir.text,
        fileFmt: ctr.inputFormatController!,
      ).summarize(
        mode: mode,
      );
      _setSuccess();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _shareOutput() async {
    IOServices io = IOServices();
    XFile outputPath = await io.archiveOutput(
      dir: Directory(ctr.outputDir.text),
      fileName: ctr.outputController.text,
      task: SupportedTask.genomicRawReadSummary,
    );
    if (mounted) {
      await io.shareFile(context, outputPath);
    }
  }

  void _showError(String error) {
    setState(() {
      ctr.isRunning = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
        ),
      );
    });
  }

  void _setSuccess() {
    setState(() {
      ctr.isRunning = false;
      ctr.isSuccess = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Summarization complete'),
        ),
      );
    });
  }
}
