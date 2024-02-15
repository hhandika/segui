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
import 'package:segui/services/io.dart';
import 'package:segui/services/tasks/sequences.dart';
import 'package:segui/services/types.dart';

const SupportedTask task = SupportedTask.sequenceExtraction;

class ExtractSequenceView extends StatefulWidget {
  const ExtractSequenceView({super.key});

  @override
  State<ExtractSequenceView> createState() => _ExtractSequenceViewState();
}

class _ExtractSequenceViewState extends State<ExtractSequenceView> {
  bool _isShowingInfo = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SequenceTaskSelection(
          infoContent: SharedInfoForm(
            description: 'Extract sequences from multiple files. '
                'Supports regex, text file, '
                'and semicolon-separated IDs.',
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
        const Expanded(child: ExtractSequencePage()),
      ],
    );
  }
}

class ExtractSequencePage extends ConsumerStatefulWidget {
  const ExtractSequencePage({super.key});

  @override
  ExtractSequencePageState createState() => ExtractSequencePageState();
}

class ExtractSequencePageState extends ConsumerState<ExtractSequencePage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  ExtractionOptions _extractionOptionsController = ExtractionOptions.id;
  final TextEditingController _idRegexController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
        child: Column(
      mainAxisSize: MainAxisSize.min,
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
        FormCard(children: [
          DropdownButtonFormField(
            decoration: const InputDecoration(
              labelText: 'Select method',
            ),
            isExpanded: true,
            value: _extractionOptionsController,
            items: extractionOptionsMap.entries
                .map((MapEntry<ExtractionOptions, String> e) =>
                    DropdownMenuItem<ExtractionOptions>(
                      value: e.key,
                      child: Text(e.value),
                    ))
                .toList(),
            onChanged: (ExtractionOptions? newValue) {
              setState(() {
                _extractionOptionsController = newValue!;
                _ctr.isSuccess = false;
              });
            },
          ),
          _extractionOptionsController == ExtractionOptions.file
              ? const SharedFilePicker(
                  label: 'Input file',
                  xTypeGroup: plainTextTypeGroup,
                  allowMultiple: false,
                  task: task,
                  hasSecondaryPicker: true,
                  allowDirectorySelection: false,
                )
              : SharedTextField(
                  controller: _idRegexController,
                  label: _extractionOptionsController == ExtractionOptions.regex
                      ? 'Regular expression'
                      : 'Sequence ID',
                  hint: _extractionOptionsController == ExtractionOptions.regex
                      ? '^Rattus'
                      : 'seq1;seq2;seq3',
                ),
        ]),
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
                    label: 'Extract',
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
    return await ref.read(fileOutputProvider).when(
        data: (value) async {
          if (value.directory == null) {
            return _showError('Output directory is not selected.');
          } else {
            await _extract(inputFiles, value.directory!);
          }
        },
        loading: () => null,
        error: (e, _) => _showError(e.toString()));
  }

  Future<void> _extract(
      List<SegulInputFile> inputFiles, Directory outputDir) async {
    try {
      _setRunning();
      await SequenceExtractionRunner(
        ref,
        inputFiles: inputFiles,
        inputFmt: _ctr.inputFormatController!,
        datatype: _ctr.dataTypeController,
        outputDir: outputDir,
        outputFmt: _ctr.outputFormatController!,
        params: _extractionOptionsController,
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
    ref.read(fileOutputProvider.notifier).refresh(isRecursive: false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          showSharedSnackBar(context, 'Sequence extraction successful! 🎉'));
    }
    setState(() {
      _ctr.isRunning = false;
      _ctr.isSuccess = true;
    });
  }
}
