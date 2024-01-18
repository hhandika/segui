import 'dart:io';
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
  IOController ctr = IOController.empty();
  String _partitionFormatController = partitionFormat[1];
  bool isCodon = false;
  bool isInterleave = false;
  bool _isShowMore = false;

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
          isShowingInfo: ctr.isShowingInfo,
          onClosed: () {
            setState(() {
              ctr.isShowingInfo = false;
            });
          },
          onExpanded: () {
            setState(() {
              ctr.isShowingInfo = true;
            });
          },
        ),
        const CardTitle(title: 'Input'),
        SharedSequenceInputForm(
          ctr: ctr,
          xTypeGroup: const [sequenceTypeGroup],
        ),
        const SizedBox(height: 16),
        const CardTitle(title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
            ctr: ctr.outputDir,
            onChanged: () {
              setState(() {});
            },
          ),
          SharedTextField(
            controller: ctr.outputController,
            label: 'Prefix',
            hint: 'E.g.: concat, species_concat, etc.',
          ),
          // Default to NEXUS if user does not select
          SharedDropdownField(
            value: ctr.outputFormatController ?? outputFormat[1],
            label: 'Format',
            items: outputFormat,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  ctr.outputFormatController = value;
                  ctr.isSuccess = false;
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
            isRunning: ctr.isRunning,
            controller: ctr,
            isSuccess: ctr.isSuccess,
            onNewRun: () => setState(() {}),
            onExecuted: ref.read(fileInputProvider).when(
                  data: (value) {
                    if (value.isEmpty) {
                      return null;
                    } else {
                      return ctr.isRunning || !_validate()
                          ? null
                          : () async {
                              String dir = await getOutputDir(
                                  ctr.outputDir.text,
                                  SupportedTask.alignmentConcatenation);
                              setState(() {
                                ctr.isRunning = true;
                                ctr.outputDir.text = dir;
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
    bool isInputValid = ctr.outputFormatController != null;
    return isInputValid && ctr.isValid();
  }

  Future<void> _concat(List<SegulFile> inputFiles) async {
    try {
      String outputFmt =
          getOutputFmt(ctr.outputFormatController!, isInterleave);
      String partitionFmt =
          getPartitionFmt(_partitionFormatController, isCodon);
      final files = inputFiles.map((e) => e.file.path).toList();
      await AlignmentServices(
        dir: ctr.dirPath.text,
        inputFiles: files,
        inputFmt: ctr.inputFormatController!,
        datatype: ctr.dataTypeController,
        outputDir: ctr.outputDir.text,
      ).concatAlignment(
        outFname: ctr.outputController.text,
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
    File outputPath = await io.archiveOutput(
      dir: Directory(ctr.outputDir.text),
      fileName: ctr.outputController.text,
      task: SupportedTask.alignmentConcatenation,
    );

    if (mounted) {
      await io.shareFile(context, outputPath);
    }
  }

  void _showError(String error) {
    setState(() {
      ctr.isRunning = false;
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, error),
      );
    });
  }

  void _setSuccess() {
    setState(() {
      ctr.isRunning = false;
      ctr.isSuccess = true;
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(
            context,
            'Concatenation successful! 🎉 \n'
            'Output path: ${showOutputDir(ctr.outputDir.text)}'),
      );
    });
  }
}
