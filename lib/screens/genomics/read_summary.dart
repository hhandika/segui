import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/tasks/genomics.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/tool_layout.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/workbench.dart';
import 'package:segui/src/rust/api/reads.dart';

const SupportedTask task = SupportedTask.genomicRawReadSummary;

class ReadSummaryView extends StatelessWidget {
  const ReadSummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReadSummaryPage();
  }
}

class ReadSummaryPage extends ConsumerStatefulWidget {
  const ReadSummaryPage({super.key});

  @override
  ReadSummaryPageState createState() => ReadSummaryPageState();
}

class ReadSummaryPageState extends ConsumerState<ReadSummaryPage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  String mode = sequenceReadSummaryMode[0];
  String phred = sequenceReadPhredOffset[0];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ToolFormLayout(
      form: [
        const CardTitle(step: 1, title: 'Input'),
        FormCard(children: [
          InputSelectorForm(
            xTypeGroup: genomicRawReadTypeGroup,
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
        const CardTitle(step: 2, title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
            ctr: _ctr.outputDir,
          ),
          SharedTextField(
            controller: _ctr.prefixController,
            label: 'Prefix',
            hint: 'raw_reads_summary, species_summary, etc.',
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
          // Minimal mode only counts reads, so it reads no quality scores.
          if (mode != 'Minimal')
            SharedDropdownField(
              value: phred,
              label: 'Quality score offset',
              items: sequenceReadPhredOffset,
              onChanged: (String? value) {
                setState(() {
                  if (value != null) {
                    phred = value;
                  }
                });
              },
            ),
        ]),
      ],
      action: ref.watch(fileInputProvider).when(
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
                                final newFiles = getNewFilesFromOutput(value);
                                await _shareOutput(
                                  value.directory!,
                                  newFiles,
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
    );
  }

  bool get _isValid {
    return _ctr.isValid;
  }

  /// Settings of this run, listed in the workbench.
  List<RunParameter> get _parameters => [
        RunParameter('Input format', _ctr.inputFormatController ?? ''),
        RunParameter('Output prefix', _ctr.prefixController.text),
        RunParameter('Summary mode', mode),
        if (mode != 'Minimal') RunParameter('Quality score offset', phred),
      ];

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
      final ReadSummaryOutput output = await ReadSummaryRunner(
        inputFiles: inputFiles,
        inputFmt: _ctr.inputFormatController!,
        outputDir: outputDir,
        prefix: _ctr.prefixController.text,
        mode: mode,
        phred: phred,
      ).run();
      _setSuccess(output.reportPath);
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

  /// [reportPath] is the read report, written in Complete mode, which the
  /// workbench offers to open.
  void _setSuccess(String? reportPath) {
    ref.read(lastRunProvider.notifier).record(
          _parameters,
          report: reportPath == null ? null : File(reportPath),
        );
    // We recurse to include read summary files when user running
    // complete read summary task.
    ref.read(fileOutputProvider.notifier).refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, 'Read summarization successful! 🎉'),
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
