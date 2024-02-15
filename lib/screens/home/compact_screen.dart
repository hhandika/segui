import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/navigation.dart';
import 'package:segui/screens/home/components/navigation.dart';
import 'package:segui/screens/home/components/pages.dart';
import 'package:segui/screens/settings/settings.dart';
import 'package:segui/styles/decoration.dart';

class SmallScreenView extends ConsumerWidget {
  const SmallScreenView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color? mainColor = getSEGULBackgroundColor(context);
    return Scaffold(
        appBar: AppBar(
          title: Text(pageTitles[ref.watch(tabSelectionProvider)]),
          elevation: 0,
          backgroundColor:
              ref.watch(tabSelectionProvider) == 0 ? null : mainColor,
          actions: const [
            SettingButtons(),
          ],
        ),
        backgroundColor:
            ref.watch(tabSelectionProvider) == 0 ? null : mainColor,
        body: SafeArea(
            child: Center(
          child: pages.elementAt(ref.watch(tabSelectionProvider)),
        )),
        bottomNavigationBar: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: getIndicatorColor(context),
          elevation: 4,
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
