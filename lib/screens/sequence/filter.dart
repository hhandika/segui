import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/tool_layout.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/tasks/sequences.dart';

const SupportedTask task = SupportedTask.sequenceFiltering;

const Map<SequenceFilteringOptions, InputDecoration> _sequenceFilteringInput = {
  SequenceFilteringOptions.minimalLength: InputDecoration(
    labelText: 'Minimal length without gaps',
    hintText: 'E.g., 100, 500, etc.',
  ),
  SequenceFilteringOptions.maximalLength: InputDecoration(
    labelText: 'Maximal length without gaps',
    hintText: 'E.g., 1000, 5000, etc.',
  ),
  SequenceFilteringOptions.maximalGap: InputDecoration(
    labelText: 'Proportion of gaps',
    hintText: 'From 0 to 1, e.g., 0.5',
  ),
};

class SequenceFilteringView extends StatelessWidget {
  const SequenceFilteringView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SequenceFilteringPage();
  }
}

class SequenceFilteringPage extends ConsumerStatefulWidget {
  const SequenceFilteringPage({super.key});

  @override
  SequenceFilteringPageState createState() => SequenceFilteringPageState();
}

class SequenceFilteringPageState extends ConsumerState<SequenceFilteringPage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  final TextEditingController _valueController = TextEditingController();
  SequenceFilteringOptions _option = SequenceFilteringOptions.minimalLength;
  bool _isInterleave = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _ctr.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ToolFormLayout(
      form: [
        const CardTitle(step: 1, title: 'Input'),
        SharedSequenceInputForm(
          ctr: _ctr,
          xTypeGroup: sequenceTypeGroup,
          task: task,
        ),
        const CardTitle(step: 2, title: 'Parameters'),
        FormCard(
          children: [
            DropdownButtonFormField<SequenceFilteringOptions>(
              initialValue: _option,
              decoration: const InputDecoration(
                labelText: 'Select method',
              ),
              isExpanded: true,
              items: sequenceFilteringOptions.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _option = value;
                  });
                }
              },
            ),
            TextField(
              controller: _valueController,
              decoration: _sequenceFilteringInput[_option],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ],
        ),
        const CardTitle(step: 3, title: 'Output'),
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
          SwitchForm(
            label: 'Set interleaved format',
            value: _isInterleave,
            onPressed: (value) {
              setState(() {
                _isInterleave = value;
              });
            },
          ),
        ]),
      ],
      action: ref.watch(fileInputProvider).when(
            data: (value) {
              return ExecutionButton(
                label: 'Filter',
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
    return _ctr.isValid &&
        _ctr.outputFormatController != null &&
        isValidSequenceFilteringValue(_option, _valueController.text);
  }

  Future<void> _execute(List<SegulInputFile> inputFiles) async {
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
              await _run(inputFiles, value.directory!);
            }
          },
          loading: () => null,
          error: (e, s) => _showError(e.toString()),
        );
  }

  Future<void> _run(
      List<SegulInputFile> inputFiles, Directory outputDir) async {
    try {
      _setRunning();
      await SequenceFilteringRunner(
        inputFiles: inputFiles,
        inputFmt: _ctr.inputFormatController!,
        datatype: _ctr.dataTypeController,
        outputDir: outputDir,
        outputFormat: _ctr.outputFormatController!,
        isInterleave: _isInterleave,
        option: _option,
        paramValue: _valueController.text,
      ).run();
      _setSuccess(outputDir);
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _setNewRun() {
    setState(() {
      _ctr.reset();
      _valueController.clear();
      _ctr.isSuccess = false;
      ref.invalidate(fileInputProvider);
      ref.invalidate(fileOutputProvider);
    });
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

  void _setRunning() {
    setState(() {
      _ctr.isRunning = true;
    });
  }

  void _setSuccess(Directory outputDir) {
    ref.read(fileOutputProvider.notifier).refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, 'Sequence filtering successful! 🎉'),
      );
    }
    setState(() {
      _ctr.isRunning = false;
      _ctr.isSuccess = true;
    });
  }
}
