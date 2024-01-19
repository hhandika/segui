import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/screens/shared/controllers.dart';
import 'package:segui/screens/shared/forms.dart';

class PartitionConversionPage extends ConsumerStatefulWidget {
  const PartitionConversionPage({super.key});

  @override
  PartitionConversionPageState createState() => PartitionConversionPageState();
}

class PartitionConversionPageState
    extends ConsumerState<PartitionConversionPage> {
  IOController _ctr = IOController.empty();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SharedInfoForm(
          description: 'Convert partition format from one to another.',
          isShowingInfo: _ctr.isShowingInfo,
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
      ],
    );
  }
}
