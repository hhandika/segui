import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/navigation.dart';
import 'package:segui/screens/home/components/pages.dart';
import 'package:segui/screens/home/components/navigation.dart';

class LargeScreenView extends ConsumerStatefulWidget {
  const LargeScreenView({super.key});

  @override
  LargeScreenViewState createState() => LargeScreenViewState();
}

class LargeScreenViewState extends ConsumerState<LargeScreenView> {
  bool isUsingNavigationRail = false;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(pageTitles[ref.watch(tabSelectionProvider)]),
        backgroundColor: Color.lerp(Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.surface, 0.9),
        leading: screenWidth < 840
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  setState(() {
                    isUsingNavigationRail = !isUsingNavigationRail;
                  });
                },
              ),
      ),
      backgroundColor: Color.lerp(Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.surface, 0.9),
      body: SafeArea(
        bottom: false,
        top: false,
        child: Row(
          children: [
            screenWidth > 840 && !isUsingNavigationRail
                ? const ExpandedScreenDrawer()
                : const MediumScreenRail(),
            Expanded(
              child: Center(
                child: pages[ref.watch(tabSelectionProvider)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
