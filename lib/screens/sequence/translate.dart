import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/screens/sequence/entry_page.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/info.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/tasks/sequences.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/styles/decoration.dart';

const SupportedTask task = SupportedTask.sequenceTranslation;

class TranslateView extends StatefulWidget {
  const TranslateView({super.key});

  @override
  State<TranslateView> createState() => _TranslateViewState();
}

class _TranslateViewState extends State<TranslateView> {
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
            description:
                'Translate nucleotide sequences to amino acid sequences. '
                'Allow to translate multiple files at once.',
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
        const Expanded(child: TranslatePage()),
      ],
    );
  }
}

class TranslatePage extends ConsumerStatefulWidget {
  const TranslatePage({super.key});

  @override
  TranslatePageState createState() => TranslatePageState();
}

class TranslatePageState extends ConsumerState<TranslatePage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  bool _isInterleave = false;
  String _readingFrame = readingFrame[0];
  int _tableIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        const CardTitle(title: 'Input'),
        SharedSequenceInputForm(
          ctr: _ctr,
          xTypeGroup: sequenceTypeGroup,
          isDatatypeEnabled: false,
          task: task,
        ),
        const CardTitle(title: 'Output'),
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
              }),
          SharedDropdownField(
            value: translationTable[_tableIndex],
            label: 'Translation Table',
            items: translationTable,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _tableIndex = translationTable.indexOf(value);
                }
              });
            },
          ),
          SharedDropdownField(
            value: _readingFrame,
            label: 'Reading Frame',
            items: readingFrame,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _readingFrame = value;
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
                    label: 'Translate',
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
    return _ctr.isValid && _ctr.outputFormatController != null;
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
              await _translate(inputFiles, value.directory!);
            }
          },
          loading: () => null,
          error: (e, s) {
            _showError(e.toString());
          },
        );
  }

  Future<void> _translate(
      List<SegulInputFile> inputFiles, Directory outputDir) async {
    try {
      _setRunning();
      await SequenceTranslationRunner(
        inputFiles: inputFiles,
        inputFmt: _ctr.inputFormatController!,
        datatype: _ctr.dataTypeController,
        outputDir: outputDir,
        outputFmt: _ctr.outputFormatController!,
        tableIndex: _tableIndex,
        readingFrame: _readingFrame,
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
        showSharedSnackBar(context, 'Sequence translation successful! 🎉'),
      );
    }
    setState(() {
      _ctr.isRunning = false;
      _ctr.isSuccess = true;
    });
  }

  void _reset() {
    setState(() {
      _ctr.isSuccess = false;
      _ctr.isRunning = false;
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
