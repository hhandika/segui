import 'package:flutter/material.dart';
import 'package:segui/screens/shared/forms.dart';

class SharedInfoForm extends StatelessWidget {
  const SharedInfoForm({
    super.key,
    required this.description,
    required this.onClosed,
    required this.onExpanded,
    required this.isShowingInfo,
  });

  final VoidCallback onExpanded;
  final VoidCallback onClosed;
  final String? description;
  final bool isShowingInfo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Visibility(
          visible: isShowingInfo,
          child: CommonCard(
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                const Icon(Icons.info_outline_rounded),
                const SizedBox(height: 4),
                Text(
                  description ?? '',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Center(
          child: IconButton(
            tooltip: isShowingInfo ? 'Hide info' : 'Show info',
            icon: Icon(
              isShowingInfo
                  ? Icons.expand_less_outlined
                  : Icons.expand_more_outlined,
            ),
            onPressed: () {
              if (isShowingInfo) {
                onClosed();
              } else {
                onExpanded();
              }
            },
          ),
        )
      ],
    );
  }
}
