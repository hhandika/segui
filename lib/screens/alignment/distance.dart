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
import 'package:segui/services/tasks/alignment.dart';

const SupportedTask task = SupportedTask.alignmentDistance;

class AlignmentDistanceView extends StatelessWidget {
  const AlignmentDistanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlignmentDistancePage();
  }
}

class AlignmentDistancePage extends ConsumerStatefulWidget {
  const AlignmentDistancePage({super.key});

  @override
  AlignmentDistancePageState createState() => AlignmentDistancePageState();
}

class AlignmentDistancePageState extends ConsumerState<AlignmentDistancePage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  String _model = distanceModels.keys.first;
  String _triangle = distanceMatrixTriangles.keys.first;
  String _diagonal = distanceMatrixDiagonals.keys.first;

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
        const CardTitle(step: 1, title: 'Input'),
        SharedSequenceInputForm(
          ctr: _ctr,
          xTypeGroup: sequenceTypeGroup,
          task: task,
        ),
        const CardTitle(step: 2, title: 'Parameters'),
        FormCard(children: [
          SharedMapDropdownField(
            value: _model,
            label: 'Distance model',
            items: distanceModels,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _model = value;
                }
              });
            },
          ),
          Text(
            'K2P and TN93 need DNA. Poisson needs amino acid data.',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          SharedMapDropdownField(
            value: _triangle,
            label: 'Matrix',
            items: distanceMatrixTriangles,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _triangle = value;
                }
              });
            },
          ),
          SharedMapDropdownField(
            value: _diagonal,
            label: 'Diagonal',
            items: distanceMatrixDiagonals,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _diagonal = value;
                }
              });
            },
          ),
        ]),
        const CardTitle(step: 3, title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
            ctr: _ctr.outputDir,
          ),
          SharedTextField(
            controller: _ctr.prefixController,
            label: 'Summary prefix',
            hint: 'Optional, e.g., distance',
          ),
        ]),
      ],
      action: ref.watch(fileInputProvider).when(
            data: (value) {
              return ExecutionButton(
                label: 'Compute',
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
    return _ctr.isValid;
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
    final datatype = _ctr.dataTypeController;
    if (!distanceModelsFor(datatype).contains(_model)) {
      return _showError(
          'The ${distanceModels[_model]} model does not support $datatype '
          'data. Select DNA or AA and a matching model.');
    }
    try {
      _setRunning();
      await AlignmentDistanceRunner(
        inputFiles: inputFiles,
        inputFmt: _ctr.inputFormatController!,
        datatype: datatype,
        outputDir: outputDir,
        prefix: _ctr.prefixController.text,
        model: _model,
        triangle: _triangle,
        diagonal: _diagonal,
      ).run();
      _setSuccess(outputDir);
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _setNewRun() {
    setState(() {
      _ctr.reset();
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
        showSharedSnackBar(context, 'Distance computation successful! 🎉'),
      );
    }
    setState(() {
      _ctr.isRunning = false;
      _ctr.isSuccess = true;
    });
  }
}
