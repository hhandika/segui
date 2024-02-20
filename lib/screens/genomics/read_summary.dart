import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/genomics/entry_page.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/info.dart';
import 'package:segui/services/tasks/genomics.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/styles/decoration.dart';

const SupportedTask task = SupportedTask.genomicRawReadSummary;

class ReadSummaryView extends StatefulWidget {
  const ReadSummaryView({super.key});

  @override
  State<ReadSummaryView> createState() => _ReadSummaryViewState();
}

class _ReadSummaryViewState extends State<ReadSummaryView> {
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
            description: 'Summarize raw genomic reads by '
                'calculating the number '
                'of reads, base counts, GC and AT content, '
                'low Q-score counts, '
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
        const Expanded(child: ReadSummaryPage()),
      ],
    );
  }
}

class ReadSummaryPage extends ConsumerStatefulWidget {
  const ReadSummaryPage({super.key});

  @override
  ReadSummaryPageState createState() => ReadSummaryPageState();
}

class ReadSummaryPageState extends ConsumerState<ReadSummaryPage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  String mode = sequenceReadSummaryMode[0];

  @override
  bool get wantKeepAlive => true;

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
            xTypeGroup: genomicRawReadTypeGroup,
            allowMultiple: true,
            ctr: _ctr,
            hasSecondaryPicker: false,
            allowDirectorySelection: true,
            task: task,
          ),
          SharedDropdownField(
            value: _ctr.inputFormatController,
            label: 'Format',
            items: sequenceReadFormat,
            onChanged: (String? value) {
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
            hint: 'raw_reads_summary, species_summary, etc.',
          ),
          SharedDropdownField(
            value: mode,
            label: 'Summary Mode',
            items: sequenceReadSummaryMode,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  mode = value;
                }
              });
            },
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
                        error: (e, _) => () {
                          _showError(e.toString());
                        },
                      ),
                );
              },
              loading: () => null,
              error: (e, s) => null),
        )
      ],
    ));
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
      List<SegulInputFile> inputFiles, Directory outputDir) async {
    try {
      _setRunning();
      await ReadSummaryRunner(
        inputFiles: inputFiles,
        inputFmt: _ctr.inputFormatController!,
        outputDir: outputDir,
        prefix: _ctr.prefixController.text,
        mode: mode,
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
    // We recurse to include read summary files when user running
    // complete read summary task.
    ref.read(fileOutputProvider.notifier).refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, 'Read summarization successful! 🎉'),
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
