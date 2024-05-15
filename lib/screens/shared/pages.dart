import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:segui/screens/shared/info.dart';
import 'package:segui/screens/shared/io/input_view.dart';
import 'package:segui/screens/shared/io/output_view.dart';
import 'package:segui/services/utils.dart';
import 'package:segui/styles/decoration.dart';

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
          AppPageView(child: child),
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

class FormView extends StatelessWidget {
  const FormView({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }
}

class AppPageView extends StatelessWidget {
  const AppPageView({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final windowWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        height: double.infinity,
        decoration: getContainerDecoration(context),
        constraints: BoxConstraints(maxWidth: windowWidth > 1800 ? 600 : 500),
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class IOExpandedScreen extends ConsumerStatefulWidget {
  const IOExpandedScreen({super.key});

  @override
  IOExpandedScreenState createState() => IOExpandedScreenState();
}

class IOExpandedScreenState extends ConsumerState<IOExpandedScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: getContainerDecoration(context),
          child: const DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: TabBar(
                tabs: [
                  Tab(
                    icon: Icon(Icons.input),
                  ),
                  Tab(
                    icon: Icon(Icons.output),
                  ),
                ],
              ),
              body: TabBarView(
                children: [
                  InputScreen(),
                  OutputScreen(),
                ],
              ),
            ),
          ),
        ));
  }
}

class IOCompactScreen extends StatefulWidget {
  const IOCompactScreen({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<IOCompactScreen> createState() => _IOCompactScreenState();
}

class _IOCompactScreenState extends State<IOCompactScreen> {
  @override
  Widget build(BuildContext context) {
    return TabContainer(
        child: DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: const TabBar(
          tabs: [
            Tab(
              icon: Icon(Icons.play_circle_outline),
            ),
            Tab(
              icon: Icon(Icons.input),
            ),
            Tab(
              icon: Icon(Icons.output),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            widget.child,
            const InputScreen(),
            const OutputScreen(),
          ],
        ),
      ),
    ));
  }
}

class IOListContainer extends StatefulWidget {
  const IOListContainer({
    super.key,
    required this.title,
    required this.infoText,
    required this.child,
  });

  final String title;
  final String infoText;
  final Widget child;
  @override
  State<IOListContainer> createState() => _IOListContainerState();
}

class _IOListContainerState extends State<IOListContainer> {
  bool isShowingInfo = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              WidgetSpan(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              WidgetSpan(
                child: IconButton(
                  icon: Icon(
                    size: 18,
                    Icons.info_outline,
                    color: Theme.of(context).disabledColor,
                  ),
                  onPressed: () {
                    setState(() {
                      isShowingInfo = !isShowingInfo;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        isShowingInfo
            ? SharedInfoForm(
                description: widget.infoText,
                isShowingInfo: isShowingInfo,
                onClosed: () {
                  setState(() {
                    isShowingInfo = false;
                  });
                },
                onExpanded: () {
                  setState(() {
                    isShowingInfo = true;
                  });
                },
              )
            : const SizedBox.shrink(),
        Flexible(
          child: widget.child,
        )
      ],
    );
  }
}

class TabContainer extends StatelessWidget {
  const TabContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: getContainerDecoration(context),
          child: child,
        ));
  }
}

class EmptyScreen extends StatelessWidget {
  const EmptyScreen({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          emptyDirIcon,
          height: 80,
          colorFilter: ColorFilter.mode(
            getIconColor(context),
            BlendMode.srcIn,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            )),
      ],
    );
  }
}
