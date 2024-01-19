import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/navigation.dart';
import 'package:segui/screens/home/components/navigation.dart';
import 'package:segui/screens/home/components/pages.dart';
import 'package:segui/screens/settings/settings.dart';

class SmallScreenView extends ConsumerWidget {
  const SmallScreenView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        appBar: AppBar(
          title: Text(pageTitles[ref.watch(tabSelectionProvider)]),
          actions: const [
            SettingButtons(),
          ],
        ),
        body: SafeArea(
            child: Center(
          child: pages.elementAt(ref.watch(tabSelectionProvider)),
        )),
        bottomNavigationBar: NavigationBar(
          destinations: navigationTargets
              .map((e) => NavigationDestination(
                    icon: e.icon,
                    selectedIcon: e.selectedIcon,
                    label: e.label,
                  ))
              .toList(),
          selectedIndex: ref.watch(tabSelectionProvider),
          onDestinationSelected: (value) {
            ref.read(tabSelectionProvider.notifier).setTab(value);
          },
        ));
  }
}
