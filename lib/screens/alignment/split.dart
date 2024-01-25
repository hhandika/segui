import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/info.dart';
import 'package:segui/services/tasks/alignment.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/io.dart';
import 'package:segui/services/types.dart';

const SupportedTask task = SupportedTask.alignmentConversion;

class SplitAlignmentPage extends ConsumerStatefulWidget {
  const SplitAlignmentPage({super.key});

  @override
  SplitAlignmentPageState createState() => SplitAlignmentPageState();
}

class SplitAlignmentPageState extends ConsumerState<SplitAlignmentPage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  String? _partitionFormatController;
  bool _isUnchecked = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _ctr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SharedInfoForm(
          isShowingInfo: _ctr.isShowingInfo,
          description: 'Split a concatenated alignment into multiple files '
              'based in its individual partition.'
              ' The input partition can be in a separate file as a RaXML or NEXUS format,'
              ' or in the same file as a Charset format.',
          onClosed: () {
            setState(() {
              _ctr.isShowingInfo = false;
            });
          },
          onExpanded: () {
            setState(() {
              _ctr.isShowingInfo = true;
            });
          },
        ),
        const CardTitle(title: 'Input Sequence'),
        SharedSequenceInputForm(
          ctr: _ctr,
          allowMultiple: false,
          hasSecondaryPicker: true,
          xTypeGroup: sequenceTypeGroup,
          task: task,
        ),
        const SizedBox(height: 16),
        const CardTitle(title: 'Input Partition'),
        FormCard(children: [
          SharedDropdownField(
            value: _partitionFormatController,
            label: 'Format',
            items: partitionFormat,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _partitionFormatController = value;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          Visibility(
            visible: _partitionFormatController != 'Charset',
            child: const SharedFilePicker(
              label: 'Select partition file',
              allowMultiple: false,
              hasSecondaryPicker: true,
              xTypeGroup: partitionTypeGroup,
              task: task,
              allowDirectorySelection: true,
            ),
          )
        ]),
        const SizedBox(height: 16),
        const CardTitle(title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
            ctr: _ctr.outputDir,
          ),
          SharedTextField(
            controller: _ctr.outputController,
            label: 'Prefix',
            hint: 'E.g., output, split, etc.',
          ),
          SharedDropdownField(
            value: _ctr.outputFormatController,
            label: 'Format',
            items: outputFormat,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _ctr.outputFormatController = value;
                }
              });
            },
          ),
          SwitchForm(
              label: 'Check partition for errors',
              value: _isUnchecked,
              onPressed: (value) {
                setState(() {
                  _isUnchecked = value;
                });
              }),
        ]),
        const SizedBox(height: 16),
        Center(
          child: ref.watch(fileInputProvider).when(
                data: (value) {
                  return ExecutionButton(
                    label: 'Split',
                    isRunning: _ctr.isRunning,
                    isSuccess: _ctr.isSuccess,
                    controller: _ctr,
                    onNewRun: _setNewRun,
                    onExecuted: value.isEmpty || !_isValid
                        ? null
                        : () async {
                            await _execute(value);
                          },
                    onShared: ref.read(fileOutputProvider).when(
                          data: (value) {
                            if (value.directory == null) {
                              return null;
                            } else {
                              return _ctr.isRunning
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
                  );
                },
                loading: () => null,
                error: (e, s) {
                  return null;
                },
              ),
        )
      ],
    );
  }

  bool get _isValid {
    return _ctr.isValid;
  }

  Future<void> _execute(List<SegulInputFile> inputFile) async {
    return await ref.read(fileOutputProvider).when(
          data: (value) async {
            if (value.directory == null) {
              return;
            } else {
              await _split(inputFile, value.directory!);
            }
          },
          loading: () => null,
          error: (e, _) => null,
        );
  }

  Future<void> _split(
      List<SegulInputFile> inputFile, Directory outputDir) async {
    try {
      _setRunning();
      final inputSequence =
          inputFile.firstWhere((e) => e.type == SegulType.standardSequence);
      final inputPartition =
          inputFile.firstWhere((e) => e.type == SegulType.alignmentPartition);
      await SplitAlignmentRunner(
        inputFile: inputSequence.file.path,
        inputFmt: _ctr.inputFormatController!,
        inputPartitionFmt: _partitionFormatController!,
        inputPartition: inputPartition.file.path,
        datatype: _ctr.dataTypeController,
        outputDir: outputDir.path,
        prefix: _ctr.outputController.text,
        outputFmt: _ctr.outputFormatController!,
        isUncheck: _isUnchecked,
      ).run();
      _setSuccess(outputDir);
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _ctr.isRunning = false;
        _ctr.isSuccess = false;
      });
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

  void _showError(String message) {
    setState(() {
      _ctr.isRunning = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(
          context,
          message,
        ),
      );
    }
  }

  void _setSuccess(Directory directory) {
    ref.read(fileOutputProvider.notifier).refresh(isRecursive: false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(
          context,
          'Alignment Splitting successful! 🎉 \n'
          'Output Path: ${showOutputDir(directory)}',
        ),
      );
    }
    setState(() {
      _ctr.isRunning = false;
      _ctr.isSuccess = true;
    });
  }
}
