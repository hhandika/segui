import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/group_preview.dart';
import 'package:segui/screens/shared/io/picker_widget.dart';
import 'package:segui/screens/shared/tool_layout.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/tasks/alignment.dart';
import 'package:segui/src/rust/api/sequence.dart';

const SupportedTask task = SupportedTask.alignmentDistance;

class AlignmentDistanceView extends StatelessWidget {
  const AlignmentDistanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlignmentDistancePage();
  }
}

class AlignmentDistancePage extends ConsumerStatefulWidget {
  const AlignmentDistancePage({super.key});

  @override
  AlignmentDistancePageState createState() => AlignmentDistancePageState();
}

class AlignmentDistancePageState extends ConsumerState<AlignmentDistancePage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  String _model = distanceModels.keys.first;
  String _triangle = distanceMatrixTriangles.keys.first;
  String _diagonal = distanceMatrixDiagonals.keys.first;
  String _grouping = distanceGroupingMethods.keys.first;
  String _groupDiagonal = distanceGroupDiagonals.keys.first;
  final TextEditingController _groupDelimiter = TextEditingController();
  final TextEditingController _groupFields = TextEditingController();
  final TextEditingController _groupPattern = TextEditingController();
  bool _isLongFormat = false;
  bool _isPreviewing = false;
  DistanceGroupPreview? _groupPreview;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _ctr.dispose();
    _groupDelimiter.dispose();
    _groupFields.dispose();
    _groupPattern.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ToolFormLayout(
      form: [
        const CardTitle(step: 1, title: 'Input'),
        SharedSequenceInputForm(
          ctr: _ctr,
          xTypeGroup: sequenceTypeGroup,
          task: task,
        ),
        const CardTitle(step: 2, title: 'Parameters'),
        FormCard(children: [
          SharedMapDropdownField(
            value: _model,
            label: 'Distance model',
            items: distanceModels,
            helper: 'K2P and TN93 need DNA. Poisson needs amino acid data.',
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _model = value;
                }
              });
            },
          ),
          SharedMapDropdownField(
            value: _triangle,
            label: 'Matrix',
            items: distanceMatrixTriangles,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _triangle = value;
                }
              });
            },
          ),
          SharedMapDropdownField(
            value: _diagonal,
            label: 'Diagonal',
            items: distanceMatrixDiagonals,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _diagonal = value;
                }
              });
            },
          ),
        ]),
        const CardTitle(step: 3, title: 'Groups (optional)'),
        FormCard(children: [
          SharedMapDropdownField(
            // Rebuild when detection switches the method to delimiter.
            key: ValueKey(_grouping),
            value: _grouping,
            label: 'Group samples',
            items: distanceGroupingMethods,
            helper: _groupingHelper,
            onChanged: (String? value) {
              if (value != null) {
                _updateGrouping(() => _grouping = value);
              }
            },
          ),
          if (_grouping == 'delimiter') ...[
            SharedTextField(
              controller: _groupDelimiter,
              label: 'Delimiter',
              hint: '_',
              helper: 'A single character that separates parts of the name.',
              onChanged: (_) => _updateGrouping(() {}),
            ),
            SharedTextField(
              controller: _groupFields,
              label: 'Fields to keep',
              hint: '2',
              helper: 'Leading parts that name the group. With _ and 2, '
                  'Rattus_rattus_FMNH1 belongs to Rattus_rattus.',
              keyboardType: TextInputType.number,
              onChanged: (_) => _updateGrouping(() {}),
            ),
          ],
          if (_grouping == 'regex')
            SharedTextField(
              controller: _groupPattern,
              label: 'Regex pattern',
              hint: r'^([A-Za-z]+_[a-z]+)_',
              helper: 'The first capture group, or the whole match if there '
                  'is none, names the group.',
              onChanged: (_) => _updateGrouping(() {}),
            ),
          if (_grouping == 'file')
            const FieldWithHelper(
              helper: 'A CSV or TSV file. The first row is a header, '
                  'followed by one sample and its group per row.',
              child: SharedFilePicker(
                label: 'Select group file',
                allowMultiple: false,
                hasSecondaryPicker: true,
                xTypeGroup: sampleGroupTypeGroup,
                task: task,
                allowDirectorySelection: false,
              ),
            ),
          if (_grouping != 'none')
            SharedMapDropdownField(
              value: _groupDiagonal,
              label: 'Group matrix diagonal',
              items: distanceGroupDiagonals,
              helper: 'Highest mean in the row is the largest mean distance '
                  'from the group to any other group.',
              onChanged: (String? value) {
                setState(() {
                  if (value != null) {
                    _groupDiagonal = value;
                  }
                });
              },
            ),
          if (_grouping != 'none')
            SecondaryButton(
              text: _isPreviewing
                  ? 'Reading sample names...'
                  : _grouping == 'auto'
                      ? 'Detect groups'
                      : 'Preview groups',
              onPressed: _previewGroups,
            ),
          if (_groupPreview != null)
            SampleGroupPreview(preview: _groupPreview!),
        ]),
        const CardTitle(step: 4, title: 'Output'),
        FormCard(children: [
          SharedOutputDirField(
            ctr: _ctr.outputDir,
          ),
          SharedTextField(
            controller: _ctr.prefixController,
            label: 'Summary prefix',
            hint: 'Optional, e.g., distance',
          ),
          SwitchForm(
            label: 'Long-format tables',
            helper: 'Also write the distances of all loci as one table with '
                'a row per pair, and with groups, a table of group statistics.',
            value: _isLongFormat,
            onPressed: (value) {
              setState(() {
                _isLongFormat = value;
              });
            },
          ),
        ]),
      ],
      action: ref.watch(fileInputProvider).when(
            data: (value) {
              return ExecutionButton(
                label: 'Compute',
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

  String get _groupingHelper {
    switch (_grouping) {
      case 'none':
        return 'Group individuals into populations or species to also '
            'compute mean distances within and between groups.';
      case 'auto':
        return 'Finds a delimiter and number of fields that pool most '
            'samples, such as species in Genus_species_ID names.';
      default:
        return 'Within- and between-group means are written for each locus '
            'and pooled across loci.';
    }
  }

  DistanceGrouping get _groupingParams {
    return DistanceGrouping(
      method: _grouping,
      delimiter: _groupDelimiter.text,
      fields: _groupFields.text,
      pattern: _groupPattern.text,
    );
  }

  /// Apply a grouping change and drop the preview, which no longer applies.
  void _updateGrouping(VoidCallback update) {
    setState(() {
      update();
      _groupPreview = null;
    });
  }

  Future<void> _previewGroups() async {
    if (_isPreviewing) {
      return;
    }
    final List<SegulInputFile> inputFiles =
        ref.read(fileInputProvider).value ?? const [];
    final DistanceGrouping grouping = _groupingParams;
    if (_ctr.inputFormatController == null) {
      return _showError('Select the input files and format first.');
    }
    if (!grouping.isValid(inputFiles)) {
      return _showError('Complete the grouping options first.');
    }
    setState(() {
      _isPreviewing = true;
    });
    try {
      final DistanceGroupPreview preview = await DistanceGroupPreviewRunner(
        inputFiles: inputFiles,
        inputFmt: _ctr.inputFormatController!,
        datatype: _ctr.dataTypeController,
        grouping: grouping,
      ).run();
      if (!mounted) {
        return;
      }
      setState(() {
        _isPreviewing = false;
        _groupPreview = preview;
        if (preview.delimiter != null && preview.fields != null) {
          _grouping = 'delimiter';
          _groupDelimiter.text = preview.delimiter!;
          _groupFields.text = preview.fields.toString();
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPreviewing = false;
      });
      _showError(e.toString());
    }
  }

  bool _isValid(List<SegulInputFile> value) {
    return _ctr.isValid && _groupingParams.isValid(value);
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
    final datatype = _ctr.dataTypeController;
    if (!distanceModelsFor(datatype).contains(_model)) {
      return _showError(
          'The ${distanceModels[_model]} model does not support $datatype '
          'data. Select DNA or AA and a matching model.');
    }
    try {
      _setRunning();
      await AlignmentDistanceRunner(
        inputFiles: inputFiles,
        inputFmt: _ctr.inputFormatController!,
        datatype: datatype,
        outputDir: outputDir,
        prefix: _ctr.prefixController.text,
        model: _model,
        triangle: _triangle,
        diagonal: _diagonal,
        grouping: _groupingParams,
        groupDiagonal: _groupDiagonal,
        isLongFormat: _isLongFormat,
      ).run();
      _setSuccess(outputDir);
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _setNewRun() {
    setState(() {
      _ctr.reset();
      _grouping = distanceGroupingMethods.keys.first;
      _groupDiagonal = distanceGroupDiagonals.keys.first;
      _groupDelimiter.clear();
      _groupFields.clear();
      _groupPattern.clear();
      _groupPreview = null;
      _isLongFormat = false;
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
        showSharedSnackBar(context, 'Distance computation successful! 🎉'),
      );
    }
    setState(() {
      _ctr.isRunning = false;
      _ctr.isSuccess = true;
    });
  }
}
