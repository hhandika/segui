import 'package:flutter/material.dart';
import 'package:segui/screens/shared/io.dart';

/// Standard screen size for medium devices (tablets, small laptops, etc.)
/// based on the Material Design specification.
/// https://material.io/blog/material-you-large-screens
const mdMediumScreenSize = 840;

/// A page that shows a shared operation.
/// to switch layout between compact and expanded screen.
class SharedOperationPage extends StatelessWidget {
  const SharedOperationPage({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      if (constraints.maxWidth > mdMediumScreenSize) {
        return Row(children: [
          child,
          const Expanded(
            child: IOExpandedScreen(),
          ),
        ]);
      } else {
        return IOCompactScreen(child: child);
      }
    });
  }
}
