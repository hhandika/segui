import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/alignment/entry_page.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/info.dart';
import 'package:segui/services/tasks/alignment.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/styles/decoration.dart';

const SupportedTask task = SupportedTask.partitionConversion;

class PartitionConversionView extends StatefulWidget {
  const PartitionConversionView({super.key});

  @override
  State<PartitionConversionView> createState() =>
      _PartitionConversionViewState();
}

class _PartitionConversionViewState extends State<PartitionConversionView> {
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
        AlignmentTaskSelection(
          infoContent: SharedInfoForm(
            description: 'Convert partition files to a different format. '
                'It can convert multiple files at once.',
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
        const Expanded(child: PartitionConversionPage()),
      ],
    );
  }
}

class PartitionConversionPage extends ConsumerStatefulWidget {
  const PartitionConversionPage({super.key});

  @override
  PartitionConversionPageState createState() => PartitionConversionPageState();
}

class PartitionConversionPageState
    extends ConsumerState<PartitionConversionPage>
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
    return SingleChildScrollView(
        child: Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CardTitle(title: 'Input'),
        FormCard(children: [
          const SharedFilePicker(
            label: 'Select partition file',
            allowMultiple: true,
            hasSecondaryPicker: false,
            xTypeGroup: partitionTypeGroup,
            task: task,
            allowDirectorySelection: true,
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
        const CardTitle(title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
            ctr: _ctr.outputDir,
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
        Center(
          child: ref.watch(fileInputProvider).when(
                data: (value) {
                  return ExecutionButton(
                    label: 'Convert',
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
    bool hasPartitionFormat = _partitionFormatController != null;
    bool hasOutputFormat = _ctr.outputFormatController != null;
    bool isInputValid = hasPartitionFormat && hasOutputFormat;
    return isInputValid && _ctr.isValid;
  }

  Future<void> _execute(List<SegulInputFile> inputFiles) async {
    if (runningPlatform == PlatformType.isMobile) {
      ref
          .read(fileOutputProvider.notifier)
          .addMobile(_ctr.outputDir.text, SupportedTask.partitionConversion);
    }
    return await ref.read(fileOutputProvider).when(
          data: (value) async {
            if (value.directory == null) {
              return _showError('Output directory is not selected.');
            } else {
              await _convert(inputFiles, value.directory!);
            }
          },
          loading: () => null,
          error: (e, s) => null,
        );
  }

  Future<void> _convert(
    List<SegulInputFile> inputFiles,
    Directory directory,
  ) async {
    try {
      _setRunning();
      await PartConversionRunnerServices(
        inputFiles: inputFiles,
        inputFormat: _ctr.inputFormatController!,
        outputDir: directory,
        outputFormat: _ctr.outputFormatController!,
        datatype: _ctr.dataTypeController,
        isUnchecked: _isUnchecked,
      ).run();
      _setSuccess(directory);
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
      _ctr.isRunning = false;
    });
    setState(() {
      _ctr.isRunning = true;
    });
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

  void _setSuccess(Directory directory) {
    ref.read(fileOutputProvider.notifier).refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, 'Partition conversion successful! 🎉'),
      );
    }
    setState(() {
      _ctr.isRunning = false;
      _ctr.isSuccess = true;
    });
  }
}
