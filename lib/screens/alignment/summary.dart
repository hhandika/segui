import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/screens/alignment/entry_page.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/info.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/tasks/alignment.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/styles/decoration.dart';

const SupportedTask task = SupportedTask.alignmentSummary;

class AlignmentSummaryView extends StatefulWidget {
  const AlignmentSummaryView({super.key});

  @override
  State<AlignmentSummaryView> createState() => _AlignmentSummaryViewState();
}

class _AlignmentSummaryViewState extends State<AlignmentSummaryView> {
  bool _isShowingInfo = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Show info by default for desktop screens
    _isShowingInfo = isDesktopScreen(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AlignmentTaskSelection(
          infoContent: SharedInfoForm(
            isShowingInfo: _isShowingInfo,
            description: 'Summarize alignments by calculating the number of '
                'sequences, sites, and parsimony informative sites, etc.',
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
          ),
        ),
        const Expanded(child: AlignmentSummaryPage()),
      ],
    );
  }
}

class AlignmentSummaryPage extends ConsumerStatefulWidget {
  const AlignmentSummaryPage({super.key});

  @override
  AlignmentSummaryPageState createState() => AlignmentSummaryPageState();
}

// Always add with AutomaticKeepAliveClientMixin to keep state
// when switching tabs
class AlignmentSummaryPageState extends ConsumerState<AlignmentSummaryPage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  String? _interval;

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
            controller: _ctr.prefixController,
            label: 'Output Prefix',
            hint: 'Enter output prefix',
          ),
          SharedDropdownField(
            value: _interval,
            label: 'Summary Interval',
            items: summaryInt,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _interval = value;
                  _reset();
                }
              });
            },
          ),
        ]),
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
        ),
      ],
    ));
  }

  bool get _isValid {
    bool isPrefixValid = _ctr.prefixController.text.isNotEmpty;
    return _ctr.isValid && isPrefixValid;
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
      await AlignmentSummaryRunner(
        inputFiles: inputFiles,
        inputFmt: _ctr.inputFormatController!,
        datatype: _ctr.dataTypeController,
        outputDir: outputDir,
        outputPrefix: _ctr.prefixController.text,
        interval: int.tryParse(_interval ?? '5') ?? 5,
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

  void _reset() {
    setState(() {
      _ctr.isSuccess = false;
      _ctr.isRunning = false;
    });
  }

  void _setRunning() {
    setState(() {
      _ctr.isRunning = true;
    });
  }

  void _setNewRun() {
    setState(() {
      _ctr.reset();
      _interval = null;
      _ctr.isSuccess = false;
      ref.invalidate(fileInputProvider);
      ref.invalidate(fileOutputProvider);
    });
  }

  void _setSuccess(Directory outputDir) {
    ref.read(fileOutputProvider.notifier).refresh();
    ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, 'Summarization successful! 🎉'));
    setState(() {
      _ctr.isRunning = false;
      _ctr.isSuccess = true;
    });
  }
}
