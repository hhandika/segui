import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/info.dart';
import 'package:segui/services/tasks/genomics.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/io.dart';
import 'package:segui/services/types.dart';

const SupportedTask task = SupportedTask.genomicContigSummary;

class ContigPage extends ConsumerStatefulWidget {
  const ContigPage({super.key});

  @override
  ContigPageState createState() => ContigPageState();
}

class ContigPageState extends ConsumerState<ContigPage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SharedInfoForm(
            description: 'Summarize contigs by calculating the number of '
                'contigs, total length, base count N50, '
                'and other relevant statistics.',
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
          FormCard(children: [
            InputSelectorForm(
              xTypeGroup: genomicTypeGroup,
              allowMultiple: true,
              ctr: _ctr,
              hasSecondaryPicker: false,
              allowDirectorySelection: true,
              task: task,
            ),
            SharedDropdownField(
              value: _ctr.inputFormatController,
              label: 'Format',
              items: contigFormat,
              onChanged: (value) {
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
            SharedTextField(
              controller: _ctr.outputController,
              label: 'Output Filename',
              hint: 'Enter output filename',
            ),
          ]),
          const SizedBox(height: 16),
          Center(
            child: ref.watch(fileInputProvider).when(
                  data: (value) {
                    return ExecutionButton(
                      label: 'Summarize',
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
        ]);
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
              await _summarize(inputFiles, value.directory!);
            }
          },
          loading: () => null,
          error: (e, s) => _showError(e.toString()),
        );
  }

  Future<void> _summarize(
    List<SegulInputFile> inputFiles,
    Directory outputDir,
  ) async {
    try {
      _setRunning();
      await ContigSummaryRunner(
        inputFiles: inputFiles,
        inputFmt: _ctr.inputFormatController!,
        outputDir: outputDir,
      ).run();

      _setSuccess(outputDir);
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _shareOutput(
      Directory outputDir, List<File> newOutputFiles) async {
    try {
      IOServices io = IOServices();
      ArchiveRunner archive = ArchiveRunner(
        outputDir: outputDir,
        outputFiles: newOutputFiles,
      );
      File outputPath = await archive.write();

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

  void _setSuccess(Directory directory) {
    ref.read(fileOutputProvider.notifier).refresh(isRecursive: false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(
          context,
          'Contig summarization successful! 🎉 \n'
          'Output Path: ${showOutputDir(directory)}',
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
