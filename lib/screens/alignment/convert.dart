import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/services/tasks/sequences.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/io.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/types.dart';

const SupportedTask task = SupportedTask.alignmentConversion;

class ConvertPage extends ConsumerStatefulWidget {
  const ConvertPage({super.key});

  @override
  ConvertPageState createState() => ConvertPageState();
}

class ConvertPageState extends ConsumerState<ConvertPage> {
  final IOController _ctr = IOController.empty();
  bool _isSortSequence = false;
  bool _isInterleave = false;
  bool _isShowMore = false;

  @override
  void dispose() {
    _ctr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SharedInfoForm(
          description: 'Convert sequence alignment to other formats.',
          isShowingInfo: _ctr.isShowingInfo,
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
        const CardTitle(title: 'Input'),
        SharedSequenceInputForm(
          ctr: _ctr,
          xTypeGroup: sequenceTypeGroup,
        ),
        const SizedBox(height: 20),
        const CardTitle(title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
            ctr: _ctr.outputDir,
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
          Visibility(
            visible: _isShowMore,
            child: SwitchForm(
                label: 'Set interleaved format',
                value: _isInterleave,
                onPressed: (value) {
                  setState(() {
                    _isInterleave = value;
                  });
                }),
          ),
          Visibility(
            visible: _isShowMore,
            child: SwitchForm(
              label: 'Sort by sequence ID',
              value: _isSortSequence,
              onPressed: (value) {
                setState(() {
                  _isSortSequence = value;
                });
              },
            ),
          ),
          ShowMoreButton(
            onPressed: () {
              setState(() {
                _isShowMore = !_isShowMore;
              });
            },
            isShowMore: _isShowMore,
          ),
        ]),
        const SizedBox(height: 16),
        Center(
          child: ref.watch(fileInputProvider).when(
                data: (value) {
                  return ExecutionButton(
                    label: 'Convert',
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

  Future<void> _execute(List<SegulInputFile> inputFiles) async {
    return await ref.read(fileOutputProvider).when(
          data: (value) async {
            if (value.directory == null) {
              return;
            } else {
              await _convert(inputFiles, value.directory!);
            }
          },
          loading: () => null,
          error: (e, _) => null,
        );
  }

  Future<void> _convert(
    List<SegulInputFile> inputFiles,
    Directory outputDir,
  ) async {
    try {
      _setRunning();
      await AlignConversionRunnerServices(
        inputFiles: inputFiles,
        inputFormat: _ctr.inputFormatController!,
        datatype: _ctr.dataTypeController,
        outputDir: outputDir,
        outputFormat: _ctr.outputFormatController!,
        isInterleave: _isInterleave,
        isSorted: _isSortSequence,
      ).run();
      _setSuccess(outputDir);
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

  void _setSuccess(Directory outputDir) {
    ref.read(fileOutputProvider.notifier).refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(
          context,
          'Conversion successful! 🎉 \n'
          'Output Path: ${showOutputDir(outputDir)}',
        ),
      );
    }
    setState(() {
      _ctr.isRunning = false;
      _ctr.isSuccess = true;
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
