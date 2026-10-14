import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/io/picker_widget.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/tasks/alignment.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/tool_layout.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/types.dart';

const SupportedTask task = SupportedTask.alignmentConversion;

class SplitAlignmentView extends StatelessWidget {
  const SplitAlignmentView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplitAlignmentPage();
  }
}

class SplitAlignmentPage extends ConsumerStatefulWidget {
  const SplitAlignmentPage({super.key});

  @override
  SplitAlignmentPageState createState() => SplitAlignmentPageState();
}

class SplitAlignmentPageState extends ConsumerState<SplitAlignmentPage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  String? _partitionFormatController = partitionFormat[1];
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
    return ToolFormLayout(
      form: [
        const CardTitle(step: 1, title: 'Input Sequence'),
        SharedSequenceInputForm(
          ctr: _ctr,
          allowMultiple: false,
          hasSecondaryPicker: true,
          xTypeGroup: sequenceTypeGroup,
          allowDirectorySelection: false,
          task: task,
        ),
        const CardTitle(step: 2, title: 'Input Partition'),
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
          const SizedBox(height: 8),
          Visibility(
            visible: _partitionFormatController != 'Charset',
            child: const SharedFilePicker(
              label: 'Select partition file',
              allowMultiple: false,
              hasSecondaryPicker: true,
              xTypeGroup: partitionTypeGroup,
              task: task,
              allowDirectorySelection: false,
            ),
          )
        ]),
        const CardTitle(step: 3, title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
            ctr: _ctr.outputDir,
          ),
          SharedTextField(
            controller: _ctr.prefixController,
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
      ],
      action: ref.watch(fileInputProvider).when(
            data: (value) {
              return ExecutionButton(
                label: 'Split',
                isRunning: _ctr.isRunning,
                isSuccess: _ctr.isSuccess,
                controller: _ctr,
                onNewRun: _setNewRun,
                onExecuted: value.isEmpty || !_isValid(value)
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
                                  final newFiles = getNewFilesFromOutput(value);
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
    );
  }

  bool _isValid(List<SegulInputFile> value) {
    // Find files contain sequence and partition
    final hasSequence = value.any((e) => e.type == SegulType.standardSequence);
    final hasPartition =
        value.any((e) => e.type == SegulType.alignmentPartition);
    final hasOutputFormat = _ctr.outputFormatController != null;

    return _ctr.isValid && hasSequence && hasPartition && hasOutputFormat;
  }

  Future<void> _execute(List<SegulInputFile> inputFile) async {
    if (runningPlatform == PlatformType.isMobile) {
      await ref
          .read(fileOutputProvider.notifier)
          .addMobile(_ctr.outputDir.text, task);
    }
    return await ref.read(fileOutputProvider).when(
          data: (value) async {
            if (value.directory == null) {
              return _showError('Output directory is not selected.');
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
        prefix: _ctr.prefixController.text,
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
    ref.read(fileOutputProvider.notifier).refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, 'Splitting successful! 🎉'),
      );
    }
    setState(() {
      _ctr.isRunning = false;
      _ctr.isSuccess = true;
    });
  }
}
