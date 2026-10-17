import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/tool_layout.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/screens/shared/io/picker_widget.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/tasks/sequences.dart';
import 'package:segui/services/types.dart';

const SupportedTask task = SupportedTask.sequenceRenaming;

class SequenceRenamingView extends StatelessWidget {
  const SequenceRenamingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SequenceRenamingPage();
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
    return ToolFormLayout(
      form: [
        const CardTitle(step: 1, title: 'Input'),
        SharedSequenceInputForm(
          ctr: _ctr,
          xTypeGroup: sequenceTypeGroup,
          task: task,
        ),
        const CardTitle(step: 2, title: 'Parameters'),
        FormCard(
          children: [
            DropdownButtonFormField(
              initialValue: _renamingOptionController,
              decoration: const InputDecoration(
                labelText: 'Rename by',
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
                helper: _isRegexMatchAll
                    ? 'If multiple matches are found in a single sequence ID, '
                        'they will be removed.'
                    : null,
                onPressed: (value) {
                  setState(() {
                    _isRegexMatchAll = value;
                  });
                },
              ),
          ],
        ),
        const CardTitle(step: 3, title: 'Output'),
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
                }
              });
            },
          ),
        ]),
      ],
      action: ref.watch(fileInputProvider).when(
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
