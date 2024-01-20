import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/io.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/types.dart';
import 'package:segui/src/rust/api/sequence.dart';

class ConvertPage extends ConsumerStatefulWidget {
  const ConvertPage({super.key});

  @override
  ConvertPageState createState() => ConvertPageState();
}

class ConvertPageState extends ConsumerState<ConvertPage> {
  IOController ctr = IOController.empty();
  bool isSortSequence = false;
  bool isInterleave = false;
  bool _isShowMore = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SharedInfoForm(
          description: 'Convert sequence alignment to other formats.',
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
          xTypeGroup: sequenceTypeGroup,
        ),
        const SizedBox(height: 20),
        const CardTitle(title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
            ctr: ctr.outputDir,
            onChanged: () {
              setState(() {});
            },
          ),
          SharedDropdownField(
            value: ctr.outputFormatController,
            label: 'Format',
            items: outputFormat,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  ctr.outputFormatController = value;
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
                }),
          ),
          Visibility(
            visible: _isShowMore,
            child: SwitchForm(
              label: 'Sort by sequence ID',
              value: isSortSequence,
              onPressed: (value) {
                setState(() {
                  isSortSequence = value;
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
        const SizedBox(height: 16),
        Center(
          child: ExecutionButton(
            label: 'Convert',
            isRunning: ctr.isRunning,
            isSuccess: ctr.isSuccess,
            controller: ctr,
            onNewRun: () => setState(() {}),
            onExecuted: ref.read(fileInputProvider).when(
                  data: (value) {
                    if (value.isEmpty) {
                      return null;
                    } else {
                      return ctr.isRunning || !ctr.isValid()
                          ? null
                          : () async {
                              String dir = await getOutputDir(
                                  ctr.outputDir.text,
                                  SupportedTask.alignmentConversion);
                              setState(() {
                                ctr.isRunning = true;
                                ctr.outputDir.text = dir;
                              });
                              await _convert(value);
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
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    showSharedSnackBar(
                      context,
                      'Sharing failed!: $e',
                    ),
                  );
                }
              }
            },
          ),
        )
      ],
    );
  }

  Future<void> _convert(List<SegulInputFile> inputFiles) async {
    try {
      String outputFmt =
          getOutputFmt(ctr.outputFormatController!, isInterleave);
      final files = IOServices()
          .convertPathsToString(inputFiles, SegulType.standardSequence);
      await SequenceServices(
        inputFiles: files,
        dir: ctr.dirPath.text,
        outputDir: ctr.outputDir.text,
        inputFmt: ctr.inputFormatController!,
        datatype: ctr.dataTypeController,
      ).convertSequence(
        outputFmt: outputFmt,
        sort: isSortSequence,
      );
      _setSuccess();
    } catch (e) {
      _showError(e.toString());
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

  Future<void> _shareOutput() async {
    IOServices io = IOServices();
    XFile outputPath = await io.archiveOutput(
      dir: Directory(ctr.outputDir.text),
      fileName: ctr.outputController.text,
      task: SupportedTask.alignmentConversion,
    );
    if (mounted) {
      await io.shareFile(context, outputPath);
    }
  }

  void _setSuccess() {
    setState(() {
      ctr.isRunning = false;
      ctr.isSuccess = true;
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(
          context,
          'Conversion successful! 🎉 \n'
          'Output Path: ${showOutputDir(ctr.outputDir.text)}',
        ),
      );
    });
  }
}
