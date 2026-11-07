import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/screens/home/components/pages.dart';
import 'package:segui/screens/home/components/navigation.dart';
import 'package:segui/screens/shared/tool_search.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

class LargeScreenView extends ConsumerStatefulWidget {
  const LargeScreenView({super.key});

  @override
  LargeScreenViewState createState() => LargeScreenViewState();
}

class LargeScreenViewState extends ConsumerState<LargeScreenView> {
  /// Navigation picked with the menu button, or null to follow the window
  /// size: a rail up to large windows, and a drawer on extra-large ones.
  bool? _isRailChoice;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isRail = screenWidth < expandedScreenSize ||
        (_isRailChoice ?? screenWidth < extraLargeScreenSize);
    final Color? mainColor = getSEGULBackgroundColor(context);
    return Scaffold(
      appBar: AppBar(
        elevation: SeguiElevation.none,
        title: Text(pageTitles[ref.watch(tabSelectionProvider)]),
        backgroundColor: mainColor,
        // Home has its own tool search.
        actions: [
          if (ref.watch(tabSelectionProvider) != 0) const GlobalToolSearch(),
          const SizedBox(width: SeguiSpacing.xl),
        ],
        leading: screenWidth < expandedScreenSize
            ? null
            : IconButton(
                icon: Icon(
                  isRail ? Icons.menu_open_outlined : Icons.menu,
                ),
                onPressed: () {
                  setState(() {
                    _isRailChoice = !isRail;
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
            isRail ? const MediumScreenRail() : const ExpandedScreenDrawer(),
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
