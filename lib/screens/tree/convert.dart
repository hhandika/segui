import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/screens/shared/tool_layout.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/providers/replay.dart';
import 'package:segui/services/tasks/progress.dart';
import 'package:segui/services/tasks/tree.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/workbench.dart';
import 'package:segui/src/rust/api/progress.dart';

const SupportedTask task = SupportedTask.treeConversion;

class TreeConversionView extends StatelessWidget {
  const TreeConversionView({super.key});

  @override
  Widget build(BuildContext context) {
    return const TreeConversionPage();
  }
}

class TreeConversionPage extends ConsumerStatefulWidget {
  const TreeConversionPage({super.key});

  @override
  TreeConversionPageState createState() => TreeConversionPageState();
}

class TreeConversionPageState extends ConsumerState<TreeConversionPage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  String _inputFormat = treeInputFormat.keys.first;
  String _outputFormat = treeOutputFormat.keys.first;
  bool _isAnnotationStripped = false;
  bool _isTranslateSkipped = false;
  bool _isGzipped = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _applyPendingReplay();
      }
    });
  }

  @override
  void dispose() {
    _ctr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen<PendingReplay?>(pendingReplayProvider, (_, next) {
      if (next != null && next.taskKind == 'tree.convert') {
        _applyPendingReplay();
      }
    });
    return ToolFormLayout(
      form: [
        const CardTitle(step: 1, title: 'Input'),
        FormCard(children: [
          InputSelectorForm(
            xTypeGroup: treeTypeGroup,
            allowMultiple: true,
            ctr: _ctr,
            hasSecondaryPicker: true,
            allowDirectorySelection: true,
            task: task,
          ),
          SharedMapDropdownField(
            key: ValueKey('tree-input-$_inputFormat'),
            value: _inputFormat,
            label: 'Format',
            items: treeInputFormat,
            onChanged: (String? value) {
              if (value != null) {
                setState(() => _inputFormat = value);
              }
            },
          ),
        ]),
        const CardTitle(step: 2, title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
            ctr: _ctr.outputDir,
          ),
          SharedMapDropdownField(
            key: ValueKey('tree-output-$_outputFormat'),
            value: _outputFormat,
            label: 'Format',
            items: treeOutputFormat,
            onChanged: (String? value) {
              if (value != null) {
                setState(() => _outputFormat = value);
              }
            },
          ),
          SwitchForm(
            label: 'Strip annotations',
            value: _isAnnotationStripped,
            onPressed: (value) {
              setState(() => _isAnnotationStripped = value);
            },
          ),
          if (_outputFormat == 'nexus')
            SwitchForm(
              label: 'Skip TRANSLATE block',
              value: _isTranslateSkipped,
              onPressed: (value) {
                setState(() => _isTranslateSkipped = value);
              },
            ),
          SwitchForm(
            label: 'Compress with gzip',
            value: _isGzipped,
            onPressed: (value) {
              setState(() => _isGzipped = value);
            },
          ),
        ]),
      ],
      action: ref.watch(fileInputProvider).when(
            data: (value) {
              return ExecutionButton(
                label: 'Convert',
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
        value.any((e) => e.type == SegulType.phylogeneticTree);
  }

  bool get _isNexusOutput => _outputFormat == 'nexus';

  /// Settings of this run, listed in the workbench.
  List<RunParameter> get _parameters {
    return [
      RunParameter('Input format', treeInputFormat[_inputFormat] ?? ''),
      RunParameter('Output format', treeOutputFormat[_outputFormat] ?? ''),
      RunParameter('Strip annotations', _isAnnotationStripped ? 'Yes' : 'No'),
      if (_isNexusOutput)
        RunParameter(
            'Skip TRANSLATE block', _isTranslateSkipped ? 'Yes' : 'No'),
      RunParameter('Compress with gzip', _isGzipped ? 'Yes' : 'No'),
    ];
  }

  void _applyPendingReplay() {
    final PendingReplay? replay =
        ref.read(pendingReplayProvider.notifier).consumeFor('tree.convert');
    if (replay == null) {
      return;
    }
    setState(() {
      replay.applyIoDefaults(_ctr);
      final String? input = replay.stringParam('input_format');
      if (input != null && treeInputFormat.containsKey(input)) {
        _inputFormat = input;
      }
      final String? output = replay.stringParam('output_format');
      if (output != null && treeOutputFormat.containsKey(output)) {
        _outputFormat = output;
      }
      final bool? translate = replay.boolParam('translate');
      if (translate != null) {
        _isTranslateSkipped = !translate;
      }
      final bool? strip = replay.boolParam('strip_annotations');
      if (strip != null) {
        _isAnnotationStripped = strip;
      }
      final bool? gzip = replay.boolParam('gzip');
      if (gzip != null) {
        _isGzipped = gzip;
      }
    });
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
    final RunProgressNotifier progress = ref.read(runProgressProvider.notifier);
    final RunMonitor monitor = progress.start();
    try {
      _setRunning();
      await TreeConversionRunner(
        inputFiles: inputFiles,
        outputDir: outputDir,
        inputFormat: _inputFormat,
        outputFormat: _outputFormat,
        isTranslateSkipped: _isNexusOutput && _isTranslateSkipped,
        isAnnotationStripped: _isAnnotationStripped,
        isGzipped: _isGzipped,
        monitor: monitor,
      ).run();
      _setSuccess(outputDir);
    } catch (e) {
      _showError(monitor.isCancelled() ? runCancelledMessage : e.toString());
    } finally {
      progress.finish();
    }
  }

  void _setNewRun() {
    setState(() {
      _ctr.reset();
      _inputFormat = treeInputFormat.keys.first;
      _outputFormat = treeOutputFormat.keys.first;
      _isAnnotationStripped = false;
      _isTranslateSkipped = false;
      _isGzipped = false;
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
        showSharedSnackBar(context, 'Tree conversion successful! 🎉'),
      );
    }
    setState(() {
      _ctr.isRunning = false;
      _ctr.isSuccess = true;
    });
  }
}
