import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/navigation.dart';
import 'package:segui/screens/home/components/pages.dart';
import 'package:segui/screens/home/components/navigation.dart';
import 'package:segui/screens/settings/settings.dart';

class LargeScreenView extends ConsumerStatefulWidget {
  const LargeScreenView({super.key});

  @override
  LargeScreenViewState createState() => LargeScreenViewState();
}

class LargeScreenViewState extends ConsumerState<LargeScreenView> {
  bool isUsingNavigationRail = true;

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
                ? NavigationDrawer(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                    elevation: 0,
                    backgroundColor: Color.lerp(
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.surface,
                        0.9),
                    indicatorColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    indicatorShape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(16), left: Radius.circular(8)),
                    ),
                    selectedIndex: ref.watch(tabSelectionProvider),
                    children: [
                      ...navigationDrawerTargets,
                      const Divider(
                        thickness: 2,
                        indent: 8,
                        endIndent: 8,
                      ),
                      ListTile(
                        title: const Text('Settings'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Settings(),
                            ),
                          );
                        },
                      ),
                    ],
                    onDestinationSelected: (int index) {
                      ref.read(tabSelectionProvider.notifier).setTab(index);
                    },
                  )
                : NavigationRail(
                    backgroundColor: Color.lerp(
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.surface,
                        0.9),
                    labelType: NavigationRailLabelType.all,
                    indicatorColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    destinations: navigationTargets
                        .map((e) => NavigationRailDestination(
                              icon: e.icon,
                              selectedIcon: e.selectedIcon,
                              label: Text(e.label),
                            ))
                        .toList(),
                    selectedIndex: ref.watch(tabSelectionProvider),
                    onDestinationSelected: (int index) {
                      ref.read(tabSelectionProvider.notifier).setTab(index);
                    },
                    groupAlignment: BorderSide.strokeAlignCenter,
                    trailing: Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Settings(),
                              ),
                            );
                          },
                        ),
                      ),
                    )),
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

class LargeScreenContentView extends StatelessWidget {
  const LargeScreenContentView({
    super.key,
    required this.selectedIndex,
  });

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          child: Row(children: [
            SizedBox(
              width: 500,
              child: pages[selectedIndex],
            ),
            const Expanded(
                child: Center(
              child: Text('Viewer'),
            )),
          ]),
        ),
      ),
    );
  }
}
