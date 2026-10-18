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
import 'package:segui/screens/shared/io/picker_widget.dart';
import 'package:segui/services/tasks/sequences.dart';
import 'package:segui/services/workbench.dart';

const SupportedTask task = SupportedTask.sequenceAddition;

class SequenceAdditionView extends StatelessWidget {
  const SequenceAdditionView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SequenceAdditionPage();
  }
}

class SequenceAdditionPage extends ConsumerStatefulWidget {
  const SequenceAdditionPage({super.key});

  @override
  SequenceAdditionPageState createState() => SequenceAdditionPageState();
}

class SequenceAdditionPageState extends ConsumerState<SequenceAdditionPage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  String? _destinationFormat = inputFormat[0];
  bool _isSingleDestination = false;
  bool _isAddedOnly = false;
  bool _isFilenameIncluded = false;
  bool _isInterleave = false;

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
        const CardTitle(step: 1, title: 'Sequences to add'),
        SharedSequenceInputForm(
          ctr: _ctr,
          xTypeGroup: sequenceTypeGroup,
          task: task,
        ),
        const CardTitle(step: 2, title: 'Destination'),
        FormCard(children: [
          SwitchForm(
            label: 'Add all to a single file',
            helper: _isSingleDestination
                ? 'Every sequence is added to one destination file.'
                : 'Sequences are added to destination files with the '
                    'same file name.',
            value: _isSingleDestination,
            onPressed: (value) {
              setState(() {
                _isSingleDestination = value;
              });
            },
          ),
          SharedFilePicker(
            label: 'Select destination files',
            allowMultiple: !_isSingleDestination,
            hasSecondaryPicker: true,
            xTypeGroup: destinationSequenceTypeGroup,
            task: task,
            allowDirectorySelection: !_isSingleDestination,
          ),
          SharedDropdownField(
            value: _destinationFormat,
            label: 'Destination format',
            items: inputFormat,
            onChanged: (String? value) {
              setState(() {
                _destinationFormat = value;
              });
            },
          ),
          if (_isSingleDestination)
            SwitchForm(
              label: 'Add source file name to IDs',
              value: _isFilenameIncluded,
              onPressed: (value) {
                setState(() {
                  _isFilenameIncluded = value;
                });
              },
            ),
        ]),
        const CardTitle(step: 3, title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
            ctr: _ctr.outputDir,
            helper: 'Output is unaligned FASTA.',
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
          SwitchForm(
            label: 'Only write files with added sequences',
            value: _isAddedOnly,
            onPressed: (value) {
              setState(() {
                _isAddedOnly = value;
              });
            },
          ),
        ]),
      ],
      action: ref.watch(fileInputProvider).when(
            data: (value) {
              return ExecutionButton(
                label: 'Add',
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

  /// Settings of this run, listed in the workbench.
  List<RunParameter> get _parameters => [
        RunParameter('Input format', _ctr.inputFormatController ?? ''),
        RunParameter('Data type', _ctr.dataTypeController),
        RunParameter(
          'Add all to a single file',
          _isSingleDestination ? 'Yes' : 'No',
        ),
        RunParameter('Destination format', _destinationFormat ?? ''),
        if (_isSingleDestination)
          RunParameter(
            'Add source file name to IDs',
            _isFilenameIncluded ? 'Yes' : 'No',
          ),
        RunParameter('Interleaved format', _isInterleave ? 'Yes' : 'No'),
        RunParameter(
          'Only write files with added sequences',
          _isAddedOnly ? 'Yes' : 'No',
        ),
      ];

  bool _isValid(List<SegulInputFile> value) {
    final hasSource = value.any((e) => e.type == SegulType.standardSequence);
    final destinations =
        value.where((e) => e.type == SegulType.destinationSequence).length;
    final hasDestination =
        _isSingleDestination ? destinations == 1 : destinations > 0;
    return _ctr.isValid &&
        hasSource &&
        hasDestination &&
        _destinationFormat != null;
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
      await SequenceAdditionRunner(
        inputFiles: inputFiles,
        inputFmt: _ctr.inputFormatController!,
        datatype: _ctr.dataTypeController,
        destinationFmt: _destinationFormat!,
        outputDir: outputDir,
        isInterleave: _isInterleave,
        isAddedOnly: _isAddedOnly,
        isSingleDestination: _isSingleDestination,
        isFilenameIncluded: _isFilenameIncluded,
      ).run();
      _setSuccess(outputDir);
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _setNewRun() {
    setState(() {
      _ctr.reset();
      _destinationFormat = inputFormat[0];
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
    ref.read(lastRunProvider.notifier).record(_parameters);
    ref.read(fileOutputProvider.notifier).refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, 'Sequence addition successful! 🎉'),
      );
    }
    setState(() {
      _ctr.isRunning = false;
      _ctr.isSuccess = true;
    });
  }
}
