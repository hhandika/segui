import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/navigation.dart';
import 'package:segui/screens/home/components/pages.dart';
import 'package:segui/screens/home/components/navigation.dart';
import 'package:segui/screens/settings/settings.dart';

class LargeScreenView extends ConsumerWidget {
  const LargeScreenView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitles[ref.watch(tabSelectionProvider)]),
        elevation: 2,
      ),
      body: SafeArea(
        bottom: false,
        top: false,
        child: Row(
          children: [
            NavigationRail(
                elevation: 4,
                labelType: NavigationRailLabelType.all,
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

const List<NavigationDrawerDestination> navigationDrawerTargets = [
  NavigationDrawerDestination(
    icon: Icon(Icons.home),
    selectedIcon: Icon(Icons.admin_panel_settings),
    label: Text('Log files'),
  ),
  NavigationDrawerDestination(
    icon: Icon(Icons.settings),
    selectedIcon: Icon(Icons.color_lens_outlined),
    label: Text('Theme'),
  ),
];
