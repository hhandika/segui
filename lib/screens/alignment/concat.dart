import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/io.dart';
import 'package:segui/src/rust/api/sequence.dart';

class ConcatPage extends ConsumerStatefulWidget {
  const ConcatPage({super.key});

  @override
  ConcatPageState createState() => ConcatPageState();
}

class ConcatPageState extends ConsumerState<ConcatPage> {
  final IOController _ctr = IOController.empty();
  String _partitionFormatController = partitionFormat[1];
  bool isCodon = false;
  bool isInterleave = false;
  bool _isShowMore = false;

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
          description: 'Concatenate multiple alignments '
              'and generate partition '
              'for the concatenated alignment.',
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
        SharedSequenceInputForm(
          ctr: _ctr,
          xTypeGroup: sequenceTypeGroup,
        ),
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
            hint: 'E.g.: concat, species_concat, etc.',
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
          Visibility(
            visible: _isShowMore,
            child: SwitchForm(
              label: 'Set interleaved format',
              value: isInterleave,
              onPressed: (value) {
                setState(() {
                  isInterleave = value;
                });
              },
            ),
          ),
          SharedDropdownField(
            value: _partitionFormatController,
            label: 'Partition Format',
            items: partitionFormat,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _partitionFormatController = value;
                }
              });
            },
          ),
          Visibility(
            visible: _isShowMore,
            child: SwitchForm(
                label: 'Set codon model partition',
                value: isCodon,
                onPressed: (value) {
                  setState(() {
                    isCodon = value;
                  });
                }),
          ),
          ShowMoreButton(
            isShowMore: _isShowMore,
            onPressed: () {
              setState(() {
                _isShowMore = !_isShowMore;
              });
            },
          ),
        ]),
        const SizedBox(height: 16),
        Center(
          child: ExecutionButton(
            label: 'Concatenate',
            isRunning: _ctr.isRunning,
            controller: _ctr,
            isSuccess: _ctr.isSuccess,
            onNewRun: () => setState(() {}),
            onExecuted: ref.read(fileInputProvider).when(
                  data: (value) {
                    if (value.isEmpty) {
                      return null;
                    } else {
                      return _ctr.isRunning || !_validate()
                          ? null
                          : () async {
                              String dir = await getOutputDir(
                                  _ctr.outputDir.text,
                                  SupportedTask.alignmentConcatenation);
                              setState(() {
                                _ctr.isRunning = true;
                                _ctr.outputDir.text = dir;
                              });
                              await _concat(value);
                            };
                    }
                  },
                  loading: () => null,
                  error: (e, _) => null,
                ),
            onShared: () async {
              try {
                await _shareOutput();
              } catch (e) {
                _showError(e.toString());
              }
            },
          ),
        )
      ],
    );
  }

  bool _validate() {
    if (_ctr.outputFormatController == null) {
      _ctr.outputFormatController == outputFormat[0];
    }
    return _ctr.isValid();
  }

  Future<void> _concat(List<SegulFile> inputFiles) async {
    try {
      String outputFmt =
          getOutputFmt(_ctr.outputFormatController!, isInterleave);
      String partitionFmt =
          getPartitionFmt(_partitionFormatController, isCodon);
      final files = IOServices()
          .convertPathsToString(inputFiles, SegulType.standardSequence);
      await AlignmentServices(
        dir: _ctr.dirPath.text,
        inputFiles: files,
        inputFmt: _ctr.inputFormatController!,
        datatype: _ctr.dataTypeController,
        outputDir: _ctr.outputDir.text,
      ).concatAlignment(
        outFname: _ctr.outputController.text,
        outFmtStr: outputFmt,
        partitionFmt: partitionFmt,
      );
      _setSuccess();
    } catch (e) {
      _showError(e.toString());
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

  void _showError(String error) {
    setState(() {
      _ctr.isRunning = false;
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, error),
      );
    });
  }

  void _setSuccess() {
    setState(() {
      _ctr.isRunning = false;
      _ctr.isSuccess = true;
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(
            context,
            'Concatenation successful! 🎉 \n'
            'Output path: ${showOutputDir(_ctr.outputDir.text)}'),
      );
    });
  }
}
