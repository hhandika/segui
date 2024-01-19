import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/io.dart';
import 'package:segui/services/types.dart';

class SplitAlignmentPage extends ConsumerStatefulWidget {
  const SplitAlignmentPage({super.key});

  @override
  SplitAlignmentPageState createState() => SplitAlignmentPageState();
}

class SplitAlignmentPageState extends ConsumerState<SplitAlignmentPage>
    with AutomaticKeepAliveClientMixin {
  final IOController _ctr = IOController.empty();
  String? _partitionFormatController;

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
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SharedInfoForm(
          isShowingInfo: _ctr.isShowingInfo,
          description: 'Split a concatenated alignment into multiple files '
              'based in its individual partition.'
              ' The input partition can be in a separate file as a RaXML or NEXUS format,'
              ' or in the same file as a Charset format.',
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
        const CardTitle(title: 'Input Sequence'),
        FormCard(children: [
          SharedSequenceInputForm(
            ctr: _ctr,
            xTypeGroup: sequenceTypeGroup,
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
            child: const SharedFilePicker(
              label: 'Select partition file',
              allowMultiple: false,
              xTypeGroup: partitionTypeGroup,
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
            label: 'Prefix',
            hint: 'E.g., output, split, etc.',
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
