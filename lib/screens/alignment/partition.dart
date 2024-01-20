import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/src/rust/api/sequence.dart';

class PartitionConversionPage extends ConsumerStatefulWidget {
  const PartitionConversionPage({super.key});

  @override
  PartitionConversionPageState createState() => PartitionConversionPageState();
}

class PartitionConversionPageState
    extends ConsumerState<PartitionConversionPage> {
  final IOController _ctr = IOController.empty();
  String? _partitionFormatController;
  bool _isUnchecked = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _ctr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SharedInfoForm(
          description: 'Convert partition files to a different format. '
              'It can convert multiple files at once.',
          isShowingInfo: _ctr.isShowingInfo,
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
        const CardTitle(title: 'Input'),
        FormCard(children: [
          const SharedFilePicker(
            label: 'Select partition file',
            allowMultiple: true,
            hasSecondaryPicker: false,
            xTypeGroup: partitionTypeGroup,
          ),
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
          SharedDropdownField(
            value: _ctr.dataTypeController,
            label: 'Data Type',
            items: dataType,
            enabled: true,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _ctr.dataTypeController = value;
                }
              });
            },
          ),
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
          SharedDropdownField(
            value: _ctr.outputFormatController,
            label: 'Format',
            items: partitionFormat,
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
            label: 'Convert',
            controller: _ctr,
            isRunning: _ctr.isRunning,
            isSuccess: _ctr.isSuccess,
            onNewRun: () {
              setState(() {
                _ctr.reset();
                ref.invalidate(fileInputProvider);
                ref.invalidate(fileOutputProvider);
                _ctr.isRunning = false;
                _ctr.isSuccess = false;
              });
            },
            onExecuted: ref.read(fileInputProvider).when(
                  data: (value) {
                    if (value.isEmpty) {
                      return null;
                    } else {
                      return _ctr.isRunning || !_isValid
                          ? null
                          : () async {
                              _setRunning();
                              await _convert(value);
                              _setSuccess();
                            };
                    }
                  },
                  loading: () => null,
                  error: (e, s) => null,
                ),
            onShared: () async {
              try {
                _setRunning();
                await _shareOutput();
                _stopRunning();
              } catch (e) {
                _showError(e.toString());
                _stopRunning();
              }
            },
          ),
        )
      ],
    );
  }

  Future<void> _convert(List<SegulFile> inputFiles) async {
    try {
      final inputPartitions = inputFiles
          .where((e) => e.type == SegulType.alignmentPartition)
          .map((e) => e.file.path)
          .toList();

      await PartitionServices(
        inputFiles: inputPartitions,
        inputPartFmt: _partitionFormatController!,
        output: _ctr.outputDir.text,
        outputPartFmt: _ctr.outputFormatController!,
        datatype: _ctr.dataTypeController,
        isUncheck: _isUnchecked,
      ).convertPartition();
    } catch (e) {
      _showError(e.toString());
      _stopRunning();
    }
  }

  bool get _isValid {
    bool hasPartitionFormat = _partitionFormatController != null;
    bool hasOutputFormat = _ctr.outputFormatController != null;
    bool isInputValid = hasPartitionFormat && hasOutputFormat;
    return isInputValid && _ctr.isValid();
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

  void _setRunning() {
    setState(() {
      _ctr.isRunning = true;
    });
  }

  void _stopRunning() {
    setState(() {
      _ctr.isRunning = false;
    });
  }

  void _setSuccess() {
    setState(() {
      _ctr.isRunning = false;
      _ctr.isSuccess = true;
    });
  }
}
