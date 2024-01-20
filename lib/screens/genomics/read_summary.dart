import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/services/tasks/genomics.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/io.dart';

const SupportedTask task = SupportedTask.genomicRawReadSummary;

class ReadSummaryPage extends ConsumerStatefulWidget {
  const ReadSummaryPage({super.key});

  @override
  ReadSummaryPageState createState() => ReadSummaryPageState();
}

class ReadSummaryPageState extends ConsumerState<ReadSummaryPage> {
  final IOController _ctr = IOController.empty();
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
            ctr: _ctr,
            hasSecondaryPicker: false,
          ),
          SharedDropdownField(
            value: _ctr.inputFormatController,
            label: 'Format',
            items: sequenceReadFormat,
            onChanged: (String? value) {
              setState(() {
                _ctr.inputFormatController = value;
              });
            },
          ),
        ]),
        const SizedBox(height: 16),
        const CardTitle(title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
            ctr: _ctr.outputDir,
          ),
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
            isRunning: _ctr.isRunning,
            isSuccess: _ctr.isSuccess,
            controller: _ctr,
            label: 'Summarize',
            onNewRun: _setNewRun,
            onExecuted: ref.read(fileInputProvider).when(
                data: (value) {
                  if (value.isEmpty) {
                    return null;
                  } else {
                    return _ctr.isRunning || !_ctr.isValid()
                        ? null
                        : () async {
                            await _execute(value);
                          };
                  }
                },
                loading: () => null,
                error: (e, s) {
                  _showError(e.toString());
                  return null;
                }),
            onShared: ref.read(fileOutputProvider).when(
                  data: (value) {
                    if (value.directory == null) {
                      return null;
                    } else {
                      return _ctr.isRunning || !_ctr.isValid()
                          ? null
                          : () async {
                              await _shareOutput(
                                value.directory!,
                                value.newFiles,
                              );
                            };
                    }
                  },
                  loading: () => null,
                  error: (e, _) => null,
                ),
          ),
        )
      ],
    );
  }

  Future<void> _execute(List<SegulInputFile> inputFiles) async {
    updateOutputDir(ref, _ctr.outputDir.text, task);
    return await ref.read(fileOutputProvider).when(
          data: (value) async {
            if (value.directory == null) {
              return;
            } else {
              await _summarize(inputFiles, value.directory!);
            }
          },
          loading: () => null,
          error: (e, s) => _showError(e.toString()),
        );
  }

  Future<void> _summarize(
      List<SegulInputFile> inputFiles, Directory outputDir) async {
    try {
      _setRunning();
      await ReadSummaryRunner(
        inputFiles: inputFiles,
        inputFmt: _ctr.inputFormatController!,
        outputDir: outputDir,
        mode: mode,
      ).run();
      ref.read(fileOutputProvider.notifier).refresh();
      _setSuccess();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _shareOutput(
      Directory outputDir, List<XFile> newOutputFiles) async {
    try {
      IOServices io = IOServices();
      ArchiveRunner archive = ArchiveRunner(
        outputDir: outputDir,
        outputFiles: newOutputFiles,
      );
      XFile outputPath = await archive.write();

      if (mounted) {
        await io.shareFile(context, outputPath);
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _setRunning() {
    setState(() {
      _ctr.isRunning = true;
    });
  }

  void _setNewRun() {
    setState(() {
      _ctr.reset();
      _ctr.isSuccess = false;
      ref.invalidate(fileInputProvider);
      ref.invalidate(fileOutputProvider);
    });
  }

  void _setSuccess() {
    setState(() {
      _ctr.isRunning = false;
      _ctr.isSuccess = true;
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(
          context,
          'Genomic read summarization successful! 🎉 \n'
          'Output Path: ${showOutputDir(_ctr.outputDir.text)}',
        ),
      );
    });
  }

  void _showError(String error) {
    setState(() {
      _ctr.isRunning = false;
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, error),
      );
    });
  }
}
