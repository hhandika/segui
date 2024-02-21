import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/genomics/entry_page.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/info.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/tasks/genomics.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/styles/decoration.dart';

const SupportedTask task = SupportedTask.genomicContigSummary;

class ContigView extends StatefulWidget {
  const ContigView({super.key});

  @override
  State<ContigView> createState() => _ContigViewState();
}

class _ContigViewState extends State<ContigView> {
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
        GenomicTaskSelection(
          infoContent: SharedInfoForm(
            description: 'Summarize contigs by calculating the number of '
                'contigs, total length, base count N50, '
                'and other relevant statistics.',
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
        const Expanded(child: ContigPage()),
      ],
    );
  }
}

class ContigPage extends ConsumerStatefulWidget {
  const ContigPage({super.key});

  @override
  ContigPageState createState() => ContigPageState();
}

class ContigPageState extends ConsumerState<ContigPage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();

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
    return SingleChildScrollView(
        child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const CardTitle(title: 'Input'),
          FormCard(children: [
            InputSelectorForm(
              xTypeGroup: genomicContigTypeGroup,
              allowMultiple: true,
              ctr: _ctr,
              hasSecondaryPicker: false,
              allowDirectorySelection: true,
              task: task,
            ),
            SharedDropdownField(
              value: _ctr.inputFormatController,
              label: 'Format',
              items: contigFormat,
              onChanged: (value) {
                setState(() {
                  _ctr.inputFormatController = value;
                });
              },
            ),
          ]),
          const CardTitle(title: 'Output'),
          FormCard(children: [
            SharedOutputDirField(
              ctr: _ctr.outputDir,
            ),
            SharedTextField(
              controller: _ctr.prefixController,
              label: 'Prefix',
              hint: 'contig_summary, species_contig_summary, etc.',
            ),
          ]),
          Center(
            child: ref.watch(fileInputProvider).when(
                  data: (value) {
                    return ExecutionButton(
                      label: 'Summarize',
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
        ]));
  }

  bool get _isValid {
    return _ctr.isValid;
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
              await _summarize(inputFiles, value.directory!);
            }
          },
          loading: () => null,
          error: (e, s) => _showError(e.toString()),
        );
  }

  Future<void> _summarize(
    List<SegulInputFile> inputFiles,
    Directory outputDir,
  ) async {
    try {
      _setRunning();
      await ContigSummaryRunner(
        inputFiles: inputFiles,
        inputFmt: _ctr.inputFormatController!,
        outputDir: outputDir,
        prefix: _ctr.prefixController.text,
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

  void _setRunning() {
    setState(() {
      _ctr.isRunning = true;
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

  void _setSuccess(Directory directory) {
    ref.read(fileOutputProvider.notifier).refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, 'Contig summarization successful! 🎉'),
      );
    }
    setState(() {
      _ctr.isRunning = false;
      _ctr.isSuccess = true;
    });
  }

  void _showError(String error) {
    setState(() {
      _ctr.isRunning = false;
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, error),
      );
    });
  }
}
