import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/navigation.dart';
import 'package:segui/screens/home/components/pages.dart';
import 'package:segui/screens/home/components/navigation.dart';
import 'package:segui/styles/decoration.dart';

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
    final Color? mainColor = getSEGULBackgroundColor(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(pageTitles[ref.watch(tabSelectionProvider)]),
        backgroundColor: mainColor,
        leading: screenWidth < 840
            ? null
            : IconButton(
                icon: Icon(
                  isUsingNavigationRail ? Icons.menu_open_outlined : Icons.menu,
                ),
                onPressed: () {
                  setState(() {
                    isUsingNavigationRail = !isUsingNavigationRail;
                  });
                },
              ),
      ),
      backgroundColor: mainColor,
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
