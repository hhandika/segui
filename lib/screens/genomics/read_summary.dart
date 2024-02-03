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
import 'package:segui/services/types.dart';
import 'package:segui/services/io.dart';

const SupportedTask task = SupportedTask.genomicRawReadSummary;

class ReadSummaryPage extends ConsumerStatefulWidget {
  const ReadSummaryPage({super.key});

  @override
  ReadSummaryPageState createState() => ReadSummaryPageState();
}

class ReadSummaryPageState extends ConsumerState<ReadSummaryPage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  String mode = sequenceReadSummaryMode[0];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SharedInfoForm(
          description: 'Summarize raw genomic reads by '
              'calculating the number '
              'of reads, base counts, GC and AT content, '
              'low Q-score counts, '
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
                        error: (e, _) => () {
                          _showError(e.toString());
                        },
                      ),
                );
              },
              loading: () => null,
              error: (e, s) => null),
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
    // We recurse to include read summary files when user running
    // complete read summary task.
    bool isRecursive = mode == sequenceReadSummaryMode[2];
    ref.read(fileOutputProvider.notifier).refresh(isRecursive: isRecursive);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(
          context,
          'Genomic read summarization successful! 🎉 \n'
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
