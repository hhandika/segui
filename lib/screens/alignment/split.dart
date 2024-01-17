import 'package:flutter/material.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/io.dart';
import 'package:segui/services/types.dart';

class SplitAlignmentPage extends StatefulWidget {
  const SplitAlignmentPage({super.key});

  @override
  State<SplitAlignmentPage> createState() => _SplitAlignmentPageState();
}

class _SplitAlignmentPageState extends State<SplitAlignmentPage> {
  final IOController _ctr = IOController.empty();
  String? _inputFile;
  String? _inputPartitionFile;
  String? _partitionFormatController;
  bool _isShowingInfo = true;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SharedInfoForm(
          isShowingInfo: _isShowingInfo,
          text: 'Split a concatenated alignment into multiple files '
              'based in its individual partition.'
              ' The input partition can in be in a separate file as a RaXML or NEXUS format,'
              ' or in the same file as a Charset format.',
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
        const CardTitle(title: 'Input Sequence'),
        FormCard(children: [
          SharedSingleFilePicker(
            label: 'Select sequence file',
            path: _inputFile,
            xTypeGroup: const [sequenceTypeGroup],
            onPressed: (String? path) {
              setState(() {
                _inputFile = path;
              });
            },
          ),
          SharedDropdownField(
            value: _ctr.inputFormatController,
            label: 'Format',
            items: inputFormat,
            onChanged: (String? value) {
              setState(() {
                _ctr.inputFormatController = value;
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
        const CardTitle(title: 'Input Partition'),
        FormCard(children: [
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
          const SizedBox(height: 16),
          Visibility(
            visible: _partitionFormatController != 'Charset',
            child: SharedSingleFilePicker(
              label: 'Select partition file',
              path: _inputPartitionFile,
              xTypeGroup: const [partitionTypeGroup],
              onPressed: (String? path) {
                setState(() {
                  _inputPartitionFile = path;
                });
              },
            ),
          )
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
          SharedTextField(
            controller: _ctr.outputController,
            label: 'Filename',
            hint: 'Enter output filename',
          ),
          SharedDropdownField(
            value: _ctr.outputFormatController,
            label: 'Format',
            items: outputFormat,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _ctr.outputFormatController = value;
                }
              });
            },
          ),
        ]),
        const SizedBox(height: 16),
        Center(
            child: ExecutionButton(
          label: 'Split',
          controller: _ctr,
          isSuccess: _ctr.isSuccess,
          isRunning: _ctr.isRunning,
          onNewRun: () => setState(() {
            _ctr.isRunning = true;
          }),
          onExecuted: () => setState(() {
            _ctr.isRunning = false;
          }),
          onShared: () {},
        ))
      ],
    );
  }
}
