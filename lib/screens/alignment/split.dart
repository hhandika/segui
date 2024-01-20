import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/src/rust/api/sequence.dart';

class SplitAlignmentPage extends ConsumerStatefulWidget {
  const SplitAlignmentPage({super.key});

  @override
  SplitAlignmentPageState createState() => SplitAlignmentPageState();
}

class SplitAlignmentPageState extends ConsumerState<SplitAlignmentPage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  String? _partitionFormatController;
  bool _isUnchecked = false;

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
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SharedInfoForm(
          isShowingInfo: _ctr.isShowingInfo,
          description: 'Split a concatenated alignment into multiple files '
              'based in its individual partition.'
              ' The input partition can be in a separate file as a RaXML or NEXUS format,'
              ' or in the same file as a Charset format.',
          onClosed: () {
            setState(() {
              _ctr.isShowingInfo = false;
            });
          },
          onExpanded: () {
            setState(() {
              _ctr.isShowingInfo = true;
            });
          },
        ),
        const CardTitle(title: 'Input Sequence'),
        FormCard(children: [
          SharedSequenceInputForm(
            ctr: _ctr,
            allowMultiple: false,
            hasSecondaryPicker: true,
            xTypeGroup: sequenceTypeGroup,
          ),
        ]),
        const SizedBox(height: 16),
        const CardTitle(title: 'Input Partition'),
        FormCard(children: [
          SharedDropdownField(
            value: _partitionFormatController,
            label: 'Format',
            items: partitionFormat,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _partitionFormatController = value;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          Visibility(
            visible: _partitionFormatController != 'Charset',
            child: const SharedFilePicker(
              label: 'Select partition file',
              allowMultiple: false,
              hasSecondaryPicker: true,
              xTypeGroup: partitionTypeGroup,
            ),
          )
        ]),
        const SizedBox(height: 16),
        const CardTitle(title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
            ctr: _ctr.outputDir,
            onChanged: () {
              setState(() {});
            },
          ),
          SharedTextField(
            controller: _ctr.outputController,
            label: 'Prefix',
            hint: 'E.g., output, split, etc.',
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
              label: 'Check partition for errors',
              value: _isUnchecked,
              onPressed: (value) {
                setState(() {
                  _isUnchecked = value;
                });
              }),
        ]),
        const SizedBox(height: 16),
        Center(
            child: ExecutionButton(
          label: 'Split',
          controller: _ctr,
          isSuccess: _ctr.isSuccess,
          isRunning: _ctr.isRunning,
          onNewRun: () => setState(() {
            _ctr.isRunning = true;
            _ctr.isSuccess = false;
          }),
          onExecuted: ref.read(fileInputProvider).when(
                data: (value) {
                  if (value.isEmpty) {
                    return null;
                  } else {
                    return _ctr.isRunning || !_ctr.isValid()
                        ? null
                        : () async {
                            setState(() {
                              _ctr.isRunning = true;
                            });
                            await _split(value);
                            setState(() {
                              _ctr.isRunning = false;
                              _ctr.isSuccess = true;
                            });
                          };
                  }
                },
                loading: () => null,
                error: (error, stack) => null,
              ),
          onShared: () async {
            try {
              await _shareOutput();
            } catch (e) {
              _showError(e.toString());
            }
          },
        ))
      ],
    );
  }

  Future<void> _split(List<SegulInputFile> inputFile) async {
    try {
      final inputSequence =
          inputFile.firstWhere((e) => e.type == SegulType.standardSequence);
      final inputPartition =
          inputFile.firstWhere((e) => e.type == SegulType.alignmentPartition);
      await SplitAlignmentServices(
        inputFile: inputSequence.file.path,
        inputFmt: _ctr.inputFormatController ?? 'Auto',
        inputPartitionFmt: _partitionFormatController ?? 'Charset',
        inputPartition: inputPartition.file.path,
        datatype: _ctr.dataTypeController,
        outputDir: _ctr.outputDir.text,
        prefix: _ctr.outputController.text,
        outputFmt: _ctr.outputFormatController ?? 'NEXUS',
        isUncheck: _isUnchecked,
      ).splitAlignment();
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _ctr.isRunning = false;
        _ctr.isSuccess = false;
      });
    }
  }

  Future<void> _shareOutput() async {
    IOServices io = IOServices();
    XFile outputPath = await io.archiveOutput(
      dir: Directory(_ctr.outputDir.text),
      fileName: _ctr.outputController.text,
      task: SupportedTask.alignmentConcatenation,
    );

    if (mounted) {
      await io.shareFile(context, outputPath);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(
          context,
          message,
        ),
      );
    }
  }
}
