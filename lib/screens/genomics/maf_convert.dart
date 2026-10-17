import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/tool_layout.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/screens/shared/io/picker_widget.dart';
import 'package:segui/services/tasks/genomics.dart';

const SupportedTask task = SupportedTask.genomicMafConversion;

class MafConversionView extends StatelessWidget {
  const MafConversionView({super.key});

  @override
  Widget build(BuildContext context) {
    return const MafConversionPage();
  }
}

class MafConversionPage extends ConsumerStatefulWidget {
  const MafConversionPage({super.key});

  @override
  MafConversionPageState createState() => MafConversionPageState();
}

class MafConversionPageState extends ConsumerState<MafConversionPage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  final TextEditingController _refSpecies = TextEditingController();
  final TextEditingController _species = TextEditingController();
  final TextEditingController _minBlockLength = TextEditingController();
  final TextEditingController _minSpecies = TextEditingController();
  final TextEditingController _minScore = TextEditingController();
  String _groupBy = mafGroupingOptions.keys.first;
  bool _isClipped = true;
  bool _isStrandAware = false;
  bool _isInterleave = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _ctr.dispose();
    _refSpecies.dispose();
    _species.dispose();
    _minBlockLength.dispose();
    _minSpecies.dispose();
    _minScore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool hasBed = (ref.watch(fileInputProvider).value ?? [])
        .any((e) => e.type == SegulType.bed);
    return ToolFormLayout(
      form: [
        const CardTitle(step: 1, title: 'Input'),
        FormCard(children: [
          InputSelectorForm(
            xTypeGroup: mafTypeGroup,
            allowMultiple: true,
            ctr: _ctr,
            hasSecondaryPicker: true,
            allowDirectorySelection: true,
            task: task,
          ),
        ]),
        const CardTitle(step: 2, title: 'Loci (optional)'),
        FormCard(children: [
          FieldWithHelper(
            helper: hasBed
                ? 'Each block is matched to every locus it overlaps on the '
                    'same chromosome, and blocks of a locus are joined.'
                : 'Without a BED file, each block or each reference '
                    'chromosome becomes its own alignment.',
            child: const SharedFilePicker(
              label: 'Select BED file',
              allowMultiple: false,
              hasSecondaryPicker: true,
              xTypeGroup: bedTypeGroup,
              task: task,
              allowDirectorySelection: false,
            ),
          ),
          if (hasBed) ...[
            SwitchForm(
              label: 'Clip blocks to each locus',
              value: _isClipped,
              onPressed: (value) {
                setState(() {
                  _isClipped = value;
                });
              },
            ),
            SwitchForm(
              label: 'Reverse complement minus-strand loci',
              value: _isStrandAware,
              onPressed: (value) {
                setState(() {
                  _isStrandAware = value;
                });
              },
            ),
          ] else
            SharedMapDropdownField(
              value: _groupBy,
              label: 'Group blocks',
              items: mafGroupingOptions,
              onChanged: (String? value) {
                setState(() {
                  if (value != null) {
                    _groupBy = value;
                  }
                });
              },
            ),
        ]),
        const CardTitle(step: 3, title: 'Blocks (optional)'),
        FormCard(children: [
          SharedTextField(
            controller: _refSpecies,
            label: 'Reference species',
            hint: 'Default: first species in the first block',
          ),
          SharedTextField(
            controller: _species,
            label: 'Species to write',
            hint: 'Comma-separated, e.g., hg38, panTro6',
          ),
          SharedTextField(
            controller: _minBlockLength,
            label: 'Minimum reference bases',
            hint: 'E.g., 50',
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          SharedTextField(
            controller: _minSpecies,
            label: 'Minimum species',
            hint: 'Counting the reference, e.g., 3',
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          SharedTextField(
            controller: _minScore,
            label: 'Minimum score',
            hint: 'E.g., 0',
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ]),
        const CardTitle(step: 4, title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
            ctr: _ctr.outputDir,
          ),
          SharedDropdownField(
            value: _ctr.outputFormatController,
            label: 'Format',
            items: mafOutputFormat,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _ctr.outputFormatController = value;
                }
              });
            },
          ),
          SwitchForm(
            label: 'Set interleaved format',
            value: _isInterleave,
            onPressed: (value) {
              setState(() {
                _isInterleave = value;
              });
            },
          ),
        ]),
      ],
      action: ref.watch(fileInputProvider).when(
            data: (value) {
              return ExecutionButton(
                label: 'Convert',
                isRunning: _ctr.isRunning,
                isSuccess: _ctr.isSuccess,
                controller: _ctr,
                onNewRun: _setNewRun,
                onExecuted: value.isEmpty || !_isValid(value)
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
                                  final newFiles = getNewFilesFromOutput(value);
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
    );
  }

  bool _isValid(List<SegulInputFile> value) {
    final hasMaf = value.any((e) => e.type == SegulType.multipleAlignment);
    final bedCount = value.where((e) => e.type == SegulType.bed).length;
    return _ctr.isValid &&
        hasMaf &&
        bedCount <= 1 &&
        _ctr.outputFormatController != null &&
        isValidOptionalCount(_minBlockLength.text) &&
        isValidOptionalCount(_minSpecies.text) &&
        isValidOptionalNumber(_minScore.text);
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
              await _run(inputFiles, value.directory!);
            }
          },
          loading: () => null,
          error: (e, s) => _showError(e.toString()),
        );
  }

  Future<void> _run(
      List<SegulInputFile> inputFiles, Directory outputDir) async {
    try {
      _setRunning();
      await MafConversionRunner(
        inputFiles: inputFiles,
        outputDir: outputDir,
        outputFormat: _ctr.outputFormatController!,
        isInterleave: _isInterleave,
        groupBy: _groupBy,
        isClipped: _isClipped,
        isStrandAware: _isStrandAware,
        refSpecies: _refSpecies.text,
        minBlockLength: _minBlockLength.text,
        minSpecies: _minSpecies.text,
        minScore: _minScore.text,
        species: _species.text,
      ).run();
      _setSuccess(outputDir);
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _setNewRun() {
    setState(() {
      _ctr.reset();
      for (final field in [
        _refSpecies,
        _species,
        _minBlockLength,
        _minSpecies,
        _minScore,
      ]) {
        field.clear();
      }
      _groupBy = mafGroupingOptions.keys.first;
      _isClipped = true;
      _isStrandAware = false;
      _ctr.isSuccess = false;
      ref.invalidate(fileInputProvider);
      ref.invalidate(fileOutputProvider);
    });
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

  void _setRunning() {
    setState(() {
      _ctr.isRunning = true;
    });
  }

  void _setSuccess(Directory outputDir) {
    ref.read(fileOutputProvider.notifier).refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, 'MAF conversion successful! 🎉'),
      );
    }
    setState(() {
      _ctr.isRunning = false;
      _ctr.isSuccess = true;
    });
  }
}
