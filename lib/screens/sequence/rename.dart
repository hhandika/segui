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
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/tasks/sequences.dart';
import 'package:segui/services/types.dart';
import 'package:segui/styles/decoration.dart';

const SupportedTask task = SupportedTask.sequenceRenaming;

class SequenceRenamingView extends StatefulWidget {
  const SequenceRenamingView({super.key});

  @override
  State<SequenceRenamingView> createState() => _SequenceRenamingViewState();
}

class _SequenceRenamingViewState extends State<SequenceRenamingView> {
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
            description: 'Rename sequence ID from a collection '
                'of sequence files. '
                'Include support for file, '
                'text, and regular expression input. ',
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
        const Expanded(child: SequenceRenamingPage()),
      ],
    );
  }
}

class SequenceRenamingPage extends ConsumerStatefulWidget {
  const SequenceRenamingPage({super.key});

  @override
  SequenceRenamingPageState createState() => SequenceRenamingPageState();
}

class SequenceRenamingPageState extends ConsumerState<SequenceRenamingPage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  RenamingOptions? _renamingOptionController;

  final TextEditingController _paramValueController = TextEditingController();
  final TextEditingController _paramReplaceWithController =
      TextEditingController();
  bool _isRegexMatchAll = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _ctr.dispose();
    _paramValueController.dispose();
    _paramReplaceWithController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
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
              value: _renamingOptionController,
              decoration: const InputDecoration(
                labelText: 'Select method',
              ),
              isExpanded: true,
              items: renamingOptionsMap.entries
                  .map((MapEntry<RenamingOptions, String> e) =>
                      DropdownMenuItem<RenamingOptions>(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (RenamingOptions? value) {
                setState(() {
                  _renamingOptionController = value;
                  _ctr.isSuccess = false;
                });
              },
            ),
            if (_renamingOptionController == RenamingOptions.renameFile)
              const SharedFilePicker(
                label: 'Input file',
                xTypeGroup: plainTextTypeGroup,
                allowMultiple: false,
                task: task,
                hasSecondaryPicker: true,
                allowDirectorySelection: false,
              ),
            if (_renamingOptionController != RenamingOptions.renameFile)
              SharedTextField(
                controller: _paramValueController,
                label: _isRemove
                    ? _isRegex
                        ? 'Regex pattern'
                        : 'Input text'
                    : _isRegex
                        ? 'Find matches'
                        : 'Find',
                hint: _isRemove
                    ? _isRegex
                        ? '^[A-Z]{3}[0-9]{5}'
                        : '_contigs1'
                    : _isRegex
                        ? '^[A-Z]{3}[0-9]{5}'
                        : '_contigs1',
              ),
            if (_isReplace)
              SharedTextField(
                controller: _paramReplaceWithController,
                label: 'Replace with',
                hint: 'contigs_1',
              ),
            if (_isRegex)
              SwitchForm(
                value: _isRegexMatchAll,
                label: _isRemove ? 'Remove all matches' : 'Replace all matches',
                onPressed: (value) {
                  setState(() {
                    _isRegexMatchAll = value;
                  });
                },
              ),
            if (_isRegexMatchAll)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'If multiple matches are found in a single sequence ID, '
                    'they will be removed.',
                    style: Theme.of(context).textTheme.labelSmall,
                  )),
          ],
        ),
        const CardTitle(title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
            ctr: _ctr.outputDir,
          ),
          // Default to NEXUS if user does not select
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
        ]),
        Center(
          child: ref.watch(fileInputProvider).when(
                data: (value) {
                  return ExecutionButton(
                    label: 'Rename',
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

  bool _isValid(List<SegulInputFile> inputFiles) {
    final isValid = _ctr.isValid && _ctr.outputFormatController != null;
    if (_renamingOptionController == RenamingOptions.renameFile) {
      final hasInputSequence =
          inputFiles.any((e) => e.type == SegulType.standardSequence);
      final hasInputText = inputFiles.any((e) => e.type == SegulType.plainText);
      return isValid && hasInputSequence && hasInputText;
    } else if (_isRemove) {
      return isValid && _paramValueController.text.isNotEmpty;
    } else {
      return isValid &&
          _paramValueController.text.isNotEmpty &&
          _paramReplaceWithController.text.isNotEmpty;
    }
  }

  bool get _isRemove {
    return _renamingOptionController == RenamingOptions.removeString ||
        _renamingOptionController == RenamingOptions.removeRegex;
  }

  bool get _isReplace {
    return _renamingOptionController == RenamingOptions.replaceString ||
        _renamingOptionController == RenamingOptions.replaceRegex;
  }

  bool get _isRegex {
    return _renamingOptionController == RenamingOptions.removeRegex ||
        _renamingOptionController == RenamingOptions.replaceRegex;
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
            await _rename(inputFiles, value.directory!);
          }
        },
        loading: () => null,
        error: (e, _) => _showError(e.toString()));
  }

  Future<void> _rename(
      List<SegulInputFile> inputFiles, Directory outputDir) async {
    try {
      _setRunning();
      await SequenceRenamingRunner(
        inputFiles: inputFiles,
        datatype: _ctr.dataTypeController,
        inputFmt: _ctr.inputFormatController!,
        outputDir: outputDir,
        outputFmt: _ctr.outputFormatController!,
        params: _renamingOptionController!,
        value: _paramValueController.text,
        replaceWithValue: _paramReplaceWithController.text,
        isRegexMatchAll: _isRegexMatchAll,
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
        showSharedSnackBar(context, 'Sequence renaming successful! 🎉'),
      );
    }
    setState(() {
      _ctr.isRunning = false;
      _ctr.isSuccess = true;
    });
  }
}
