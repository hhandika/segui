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
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/types.dart';
import 'package:segui/styles/decoration.dart';

const SupportedTask task = SupportedTask.alignmentConversion;

class ConvertView extends StatefulWidget {
  const ConvertView({super.key});

  @override
  State<ConvertView> createState() => _ConvertViewState();
}

class _ConvertViewState extends State<ConvertView> {
  bool _isShowingInfo = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Show large screen view for screen width >= 600 dp
    // which is the recommended screen size for tablets.
    _isShowingInfo = isDesktopScreen(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AlignmentTaskSelection(
          infoContent: SharedInfoForm(
            description: 'Convert sequence alignment to other formats. '
                'It can convert multiple files at once.',
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
        const Expanded(child: ConvertPage()),
      ],
    );
  }
}

class ConvertPage extends ConsumerStatefulWidget {
  const ConvertPage({super.key});

  @override
  ConvertPageState createState() => ConvertPageState();
}

class ConvertPageState extends ConsumerState<ConvertPage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  bool _isSortSequence = false;
  bool _isInterleave = false;
  bool _isShowMore = false;

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
          Visibility(
            visible: _isShowMore,
            child: SwitchForm(
                label: 'Set interleaved format',
                value: _isInterleave,
                onPressed: (value) {
                  setState(() {
                    _isInterleave = value;
                  });
                }),
          ),
          Visibility(
            visible: _isShowMore,
            child: SwitchForm(
              label: 'Sort by sequence ID',
              value: _isSortSequence,
              onPressed: (value) {
                setState(() {
                  _isSortSequence = value;
                });
              },
            ),
          ),
          ShowMoreButton(
            onPressed: () {
              setState(() {
                _isShowMore = !_isShowMore;
              });
            },
            isShowMore: _isShowMore,
          ),
        ]),
        Center(
          child: ref.watch(fileInputProvider).when(
                data: (value) {
                  return ExecutionButton(
                    label: 'Convert',
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
    bool isOutputFmtValid = _ctr.outputFormatController != null;
    bool isValid = _ctr.isValid && isOutputFmtValid;

    return isValid;
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
              await _convert(inputFiles, value.directory!);
            }
          },
          loading: () => null,
          error: (e, _) => null,
        );
  }

  Future<void> _convert(
    List<SegulInputFile> inputFiles,
    Directory outputDir,
  ) async {
    try {
      _setRunning();
      await ConversionRunnerServices(
        inputFiles: inputFiles,
        inputFormat: _ctr.inputFormatController!,
        datatype: _ctr.dataTypeController,
        outputDir: outputDir,
        outputFormat: _ctr.outputFormatController!,
        isInterleave: _isInterleave,
        isSorted: _isSortSequence,
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
        showSharedSnackBar(context, 'Conversion successful! 🎉'),
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
