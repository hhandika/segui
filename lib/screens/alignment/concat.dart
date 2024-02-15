import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/alignment/entry_page.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/info.dart';
import 'package:segui/services/tasks/alignment.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/io.dart';

const SupportedTask task = SupportedTask.alignmentConcatenation;

class ConcatViewer extends StatefulWidget {
  const ConcatViewer({super.key});

  @override
  State<ConcatViewer> createState() => _ConcatViewerState();
}

class _ConcatViewerState extends State<ConcatViewer> {
  bool _isShowingInfo = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AlignmentTaskSelection(
            infoContent: SharedInfoForm(
          description: 'Concatenate multiple alignments '
              'and generate partition '
              'for the concatenated alignment.',
          isShowingInfo: _isShowingInfo,
          onClosed: () {
            setState(() {
              _isShowingInfo = false;
            });
          },
          onExpanded: () {
            setState(() {
              _isShowingInfo = true;
            });
          },
        )),
        const Expanded(child: ConcatPage()),
      ],
    );
  }
}

class ConcatPage extends ConsumerStatefulWidget {
  const ConcatPage({super.key});

  @override
  ConcatPageState createState() => ConcatPageState();
}

class ConcatPageState extends ConsumerState<ConcatPage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  String _partitionFormatController = partitionFormat[1];
  bool isCodon = false;
  bool isInterleave = false;
  bool _isShowMore = false;

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
    return SingleChildScrollView(
        child: Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CardTitle(title: 'Input'),
        SharedSequenceInputForm(
          ctr: _ctr,
          xTypeGroup: sequenceTypeGroup,
          task: task,
        ),
        const CardTitle(title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
            ctr: _ctr.outputDir,
          ),
          SharedTextField(
            controller: _ctr.outputController,
            label: 'Prefix',
            hint: 'concat, species_concat, etc.',
          ),
          // Default to NEXUS if user does not select
          SharedDropdownField(
            value: _ctr.outputFormatController,
            label: 'Format',
            items: outputFormat,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _ctr.outputFormatController = value;
                  _ctr.isSuccess = false;
                }
              });
            },
          ),
          Visibility(
            visible: _isShowMore,
            child: SwitchForm(
              label: 'Set interleaved format',
              value: isInterleave,
              onPressed: (value) {
                setState(() {
                  isInterleave = value;
                });
              },
            ),
          ),
          SharedDropdownField(
            value: _partitionFormatController,
            label: 'Partition Format',
            items: partitionFormat,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _partitionFormatController = value;
                }
              });
            },
          ),
          Visibility(
            visible: _isShowMore,
            child: SwitchForm(
                label: 'Set codon model partition',
                value: isCodon,
                onPressed: (value) {
                  setState(() {
                    isCodon = value;
                  });
                }),
          ),
          ShowMoreButton(
            isShowMore: _isShowMore,
            onPressed: () {
              setState(() {
                _isShowMore = !_isShowMore;
              });
            },
          ),
        ]),
        Center(
          child: ref.watch(fileInputProvider).when(
                data: (value) {
                  return ExecutionButton(
                    label: 'Concatenate',
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
                                      final newFiles =
                                          getNewFilesFromOutput(value);
                                      await _shareOutput(
                                        value.directory!,
                                        newFiles,
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
    ));
  }

  bool get _isValid {
    return _ctr.isValid;
  }

  Future<void> _execute(List<SegulInputFile> inputFiles) async {
    return await ref.read(fileOutputProvider).when(
        data: (value) async {
          if (value.directory == null) {
            return _showError('Output directory is not selected.');
          } else {
            await _convert(inputFiles, value.directory!);
          }
        },
        loading: () => null,
        error: (e, _) => _showError(e.toString()));
  }

  Future<void> _convert(
    List<SegulInputFile> inputFiles,
    Directory outputDir,
  ) async {
    try {
      _setRunning();
      await ConcatRunnerServices(
        inputFiles: inputFiles,
        inputFormat: _ctr.inputFormatController!,
        datatype: _ctr.dataTypeController,
        outputDir: outputDir,
        outputPrefix: _ctr.outputController.text,
        outputFormat: _ctr.outputFormatController!,
        partitionFormat: _partitionFormatController,
        isCodonModel: isCodon,
        isInterleave: isInterleave,
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

  void _showError(String error) {
    setState(() {
      _ctr.isRunning = false;
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, error),
      );
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

  void _setRunning() {
    setState(() {
      _ctr.isRunning = true;
    });
  }

  Future<void> _setSuccess(Directory directory) async {
    ref.read(fileOutputProvider.notifier).refresh(isRecursive: false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          showSharedSnackBar(context, 'Concatenation successful! 🎉'));
    }
    setState(() {
      _ctr.isRunning = false;
      _ctr.isSuccess = true;
    });
  }
}
