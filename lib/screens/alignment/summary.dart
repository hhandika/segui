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

class AlignmentSummaryPage extends ConsumerStatefulWidget {
  const AlignmentSummaryPage({super.key});

  @override
  AlignmentSummaryPageState createState() => AlignmentSummaryPageState();
}

// Always add with AutomaticKeepAliveClientMixin to keep state
// when switching tabs
class AlignmentSummaryPageState extends ConsumerState<AlignmentSummaryPage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  String _interval = '5';

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SharedInfoForm(
          isShowingInfo: _ctr.isShowingInfo,
          text: 'Summarize alignments by calculating the number of '
              'sequences, sites, and parsimony informative sites, etc.',
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
          xTypeGroup: const [sequenceTypeGroup],
        ),
        const SizedBox(height: 20),
        const CardTitle(title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
              ctr: _ctr.outputDir,
              onChanged: () {
                ref
                    .read(fileOutputProvider.notifier)
                    .addFiles(Directory(_ctr.outputDir.text));
                setState(() {});
              }),
          SharedTextField(
            controller: _ctr.outputController,
            label: 'Output Prefix',
            hint: 'Enter output prefix',
          ),
          SharedDropdownField(
            value: _interval,
            label: 'Summary Interval',
            items: summaryInt,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _interval = value;
                }
              });
            },
          ),
        ]),
        const SizedBox(height: 20),
        Center(
          child: ExecutionButton(
            label: 'Summarize',
            isRunning: _ctr.isRunning,
            isSuccess: _ctr.isSuccess,
            controller: _ctr,
            onNewRun: () => setState(() {}),
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

                              await _summarize(value);
                            };
                    }
                  },
                  loading: () => null,
                  error: (e, s) {
                    return null;
                  },
                ),
            onShared: () {
              try {
                _shareOutput();
              } catch (e) {
                _showError(e.toString());
              }
            },
          ),
        ),
      ],
    );
  }

  Future<void> _summarize(List<XFile> files) async {
    try {
      final allFiles = files.map((e) => e.path).toList();
      await AlignmentServices(
        inputFiles: allFiles,
        dir: _ctr.dirPath.text,
        outputDir: _ctr.outputDir.text,
        inputFmt: _ctr.inputFormatController!,
        datatype: _ctr.dataTypeController,
      ).summarizeAlignment(
          outputPrefix: _ctr.outputController.text,
          interval: int.tryParse(_interval) ?? 5);
      _setSuccess();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _shareOutput() async {
    IOServices io = IOServices();
    File outputPath = await io.archiveOutput(
      dir: Directory(_ctr.outputDir.text),
      fileName: _ctr.outputController.text,
      task: SupportedTask.alignmentSummary,
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
            'Summarization complete! 🎉 \n'
            'Output path: ${showOutputDir(_ctr.outputDir.text)}'),
      );
    });
  }
}
