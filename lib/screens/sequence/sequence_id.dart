import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/sequence/entry_page.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/info.dart';
import 'package:segui/services/tasks/sequences.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/styles/decoration.dart';

const SupportedTask task = SupportedTask.sequenceUniqueId;

class IDExtractionView extends StatefulWidget {
  const IDExtractionView({super.key});

  @override
  State<IDExtractionView> createState() => _IDExtractionViewState();
}

class _IDExtractionViewState extends State<IDExtractionView> {
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
        SequenceTaskSelection(
          infoContent: SharedInfoForm(
            description: 'Extract unique IDs '
                'across multiple sequence files. '
                'The output file is a '
                'list of unique sequence IDs. '
                'The map option will map sample '
                'distribution across the input dataset.',
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
          ),
        ),
        const Expanded(child: IDExtractionPage()),
      ],
    );
  }
}

class IDExtractionPage extends ConsumerStatefulWidget {
  const IDExtractionPage({super.key});

  @override
  IDExtractionPageState createState() => IDExtractionPageState();
}

class IDExtractionPageState extends ConsumerState<IDExtractionPage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  bool _isMap = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CardTitle(title: 'Input'),
        SharedSequenceInputForm(
          ctr: _ctr,
          xTypeGroup: sequenceTypeGroup,
          isDatatypeEnabled: false,
          task: task,
        ),
        const SizedBox(height: 16),
        const CardTitle(title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
            ctr: _ctr.outputDir,
          ),
          SharedTextField(
            controller: _ctr.prefixController,
            label: 'Prefix',
            hint: 'id, species-id, etc.',
          ),
          SwitchForm(
              label: 'Map sequence ID',
              value: _isMap,
              onPressed: (value) {
                setState(() {
                  _isMap = value;
                  _ctr.isSuccess = false;
                });
              }),
        ]),
        Center(
          child: ref.watch(fileInputProvider).when(
                data: (value) {
                  return ExecutionButton(
                    label: _isMap ? 'Extract and Map ID' : 'Extract ID',
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
    if (runningPlatform == PlatformType.isMobile) {
      await ref
          .read(fileOutputProvider.notifier)
          .addMobile(_ctr.outputDir.text, task);
    }
    return ref.read(fileOutputProvider).when(
          data: (value) async {
            if (value.directory == null) {
              return _showError('Output directory is not selected.');
            } else {
              await _extractId(inputFiles, value.directory!);
            }
          },
          loading: () => null,
          error: (e, s) {
            _showError(e.toString());
          },
        );
  }

  Future<void> _extractId(
      List<SegulInputFile> inputFiles, Directory outputDir) async {
    try {
      _setRunning();
      await SequenceIdExtractionRunner(
        inputFiles: inputFiles,
        inputFmt: _ctr.inputFormatController!,
        datatype: _ctr.dataTypeController,
        outputDir: outputDir,
        prefix: _ctr.prefixController.text,
        isMap: _isMap,
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

  void _setSuccess(Directory outputDir) {
    ref.read(fileOutputProvider.notifier).refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, 'ID extraction successful! 🎉'),
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
