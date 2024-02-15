import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:segui/providers/navigation.dart';
import 'package:segui/screens/settings/settings.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/styles/decoration.dart';

class NavigationTarget {
  const NavigationTarget({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final Widget icon;
  final Widget selectedIcon;
}

const List<NavigationTarget> navigationTargets = [
  NavigationTarget(
    label: 'Home',
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
  ),
  NavigationTarget(
    label: 'Genomics',
    icon: Icon(Icons.factory_outlined),
    selectedIcon: Icon(Icons.factory_rounded),
  ),
  NavigationTarget(
    label: 'Alignments',
    icon: Icon(Icons.sync_alt_outlined),
    selectedIcon: Icon(Icons.sync_alt_rounded),
  ),
  NavigationTarget(
    label: 'Sequences',
    icon: Icon(LineAwesome.dna_solid),
    selectedIcon: Icon(BoxIcons.bx_dna),
  ),
];

const List<NavigationDrawerDestination> navigationDrawerTargets = [
  NavigationDrawerDestination(
    label: Text('Home'),
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
  ),
  NavigationDrawerDestination(
    label: Text('Genomics'),
    icon: Icon(Icons.factory_outlined),
    selectedIcon: Icon(Icons.factory_rounded),
  ),
  NavigationDrawerDestination(
    label: Text('Alignments'),
    icon: Icon(Icons.sync_alt_outlined),
    selectedIcon: Icon(Icons.sync_alt_rounded),
  ),
  NavigationDrawerDestination(
    label: Text('Sequences'),
    icon: Icon(LineAwesome.dna_solid),
    selectedIcon: Icon(BoxIcons.bx_dna),
  ),
];

class ExpandedScreenDrawer extends ConsumerWidget {
  const ExpandedScreenDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NavigationDrawer(
      tilePadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      elevation: 0,
      backgroundColor: getSEGULBackgroundColor(context),
      indicatorColor: getIndicatorColor(context),
      indicatorShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(16),
          left: Radius.circular(16),
        ),
      ),
      selectedIndex: ref.watch(tabSelectionProvider),
      children: const [
        ...navigationDrawerTargets,
        DrawerDivider(),
        SettingMenuTile(),
        AboutMenuTile(),
      ],
      onDestinationSelected: (int index) {
        ref.read(tabSelectionProvider.notifier).setTab(index);
      },
    );
  }
}

class MediumScreenRail extends ConsumerWidget {
  const MediumScreenRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NavigationRail(
      backgroundColor: Color.lerp(Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.surface, 0.9),
      labelType: NavigationRailLabelType.all,
      indicatorColor: getIndicatorColor(context),
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
                  builder: (context) => const SettingMenu(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class SettingMenuTile extends StatelessWidget {
  const SettingMenuTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SecondaryMenuTile(
      text: 'Settings',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingMenu(),
          ),
        );
      },
    );
  }
}
