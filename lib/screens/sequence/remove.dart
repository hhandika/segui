import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/sequence/entry_page.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/info.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/tasks/sequences.dart';
import 'package:segui/services/types.dart';
import 'package:segui/styles/decoration.dart';

const SupportedTask task = SupportedTask.sequenceRemoval;

class SequenceRemovalView extends StatefulWidget {
  const SequenceRemovalView({super.key});

  @override
  State<SequenceRemovalView> createState() => _SequenceRemovalViewState();
}

class _SequenceRemovalViewState extends State<SequenceRemovalView> {
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
            description: 'Remove sequences from a collection '
                'of sequence files based on sequence name. '
                'Include support for regular expression.',
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
        const Expanded(child: SequenceRemovalPage()),
      ],
    );
  }
}

class SequenceRemovalPage extends ConsumerStatefulWidget {
  const SequenceRemovalPage({super.key});

  @override
  SequenceRemovalPageState createState() => SequenceRemovalPageState();
}

class SequenceRemovalPageState extends ConsumerState<SequenceRemovalPage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  RemovalOptions _removalMethodController = RemovalOptions.id;
  final TextEditingController _idRegexController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _ctr.dispose();
    _idRegexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
        child: Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CardTitle(title: 'Input'),
        SharedSequenceInputForm(
          ctr: _ctr,
          xTypeGroup: sequenceTypeGroup,
          task: task,
        ),
        const CardTitle(title: 'Parameters'),
        FormCard(
          children: [
            DropdownButtonFormField(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Select method',
                hintText: 'Select removal method',
              ),
              value: _removalMethodController,
              items: removalOptionsMap.entries
                  .map((MapEntry<RemovalOptions, String> e) =>
                      DropdownMenuItem<RemovalOptions>(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (RemovalOptions? value) {
                if (value != null) {
                  setState(() {
                    _removalMethodController = value;
                  });
                }
              },
            ),
            SharedTextField(
              controller: _idRegexController,
              label: _removalMethodController == RemovalOptions.regex
                  ? 'Regular expression'
                  : 'Sequence IDs',
              hint: _removalMethodController == RemovalOptions.regex
                  ? '^[A-Z]{3}[0-9]{5}'
                  : 'seq1;seq2;seq3',
            ),
          ],
        ),
        const CardTitle(title: 'Output'),
        FormCard(
          children: [
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
                    _ctr.isSuccess = false;
                  }
                });
              },
            ),
          ],
        ),
        Center(
          child: ref.watch(fileInputProvider).when(
                data: (value) {
                  return ExecutionButton(
                    label: 'Remove',
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
    bool isRemovalMethodValid = _ctr.outputFormatController != null &&
        _idRegexController.text.isNotEmpty;

    return _ctr.isValid && isRemovalMethodValid;
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
            await _remove(inputFiles, value.directory!);
          }
        },
        loading: () => null,
        error: (e, _) => _showError(e.toString()));
  }

  Future<void> _remove(
      List<SegulInputFile> inputFiles, Directory outputDir) async {
    try {
      _setRunning();
      await SequenceRemovalRunner(
        inputFiles: inputFiles,
        inputFmt: _ctr.inputFormatController!,
        datatype: _ctr.dataTypeController,
        outputDir: outputDir,
        outputFmt: _ctr.outputFormatController!,
        params: _removalMethodController,
        paramsText: _idRegexController.text,
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

  void _setNewRun() {
    setState(() {
      _ctr.reset();
      _ctr.isSuccess = false;
      ref.invalidate(fileInputProvider);
      ref.invalidate(fileOutputProvider);
    });
  }

  void _setRunning() {
    setState(() {
      _ctr.isRunning = true;
    });
  }

  Future<void> _setSuccess(Directory directory) async {
    ref.read(fileOutputProvider.notifier).refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, 'Sequence removal successful! 🎉'),
      );
    }
    setState(() {
      _ctr.isRunning = false;
      _ctr.isSuccess = true;
    });
  }
}
