import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/styles/segui_icons.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/screens/settings/settings.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

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
    icon: Icon(SeguiIcons.genomicsOutlined),
    selectedIcon: Icon(SeguiIcons.genomicsFilled),
  ),
  NavigationTarget(
    label: 'Alignments',
    icon: Icon(SeguiIcons.alignmentsOutlined),
    selectedIcon: Icon(SeguiIcons.alignmentsFilled),
  ),
  NavigationTarget(
    label: 'Sequences',
    icon: Icon(SeguiIcons.sequencesOutlined),
    selectedIcon: Icon(SeguiIcons.sequencesFilled),
  ),
];

const List<NavigationDrawerDestination> navigationDrawerTargets = [
  NavigationDrawerDestination(
    label: Text(
      'Home',
      overflow: TextOverflow.ellipsis,
    ),
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
  ),
  NavigationDrawerDestination(
    label: Text(
      'Genomics',
      overflow: TextOverflow.ellipsis,
    ),
    icon: Icon(SeguiIcons.genomicsOutlined),
    selectedIcon: Icon(SeguiIcons.genomicsFilled),
  ),
  NavigationDrawerDestination(
    label: Text(
      'Alignments',
      overflow: TextOverflow.ellipsis,
    ),
    icon: Icon(SeguiIcons.alignmentsOutlined),
    selectedIcon: Icon(SeguiIcons.alignmentsFilled),
  ),
  NavigationDrawerDestination(
    label: Text(
      'Sequences',
      overflow: TextOverflow.ellipsis,
    ),
    icon: Icon(SeguiIcons.sequencesOutlined),
    selectedIcon: Icon(SeguiIcons.sequencesFilled),
  ),
];

class ExpandedScreenDrawer extends ConsumerWidget {
  const ExpandedScreenDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NavigationDrawer(
      tilePadding: const EdgeInsets.symmetric(
        horizontal: SeguiSpacing.xs,
        vertical: SeguiSpacing.xxs,
      ),
      elevation: SeguiElevation.none,
      backgroundColor: getSEGULBackgroundColor(context),
      indicatorColor: getIndicatorColor(context),
      indicatorShape: getIndicatorShape(context),
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
      backgroundColor: getSEGULBackgroundColor(context),
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
      trailing: const Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SettingButtons(),
        ),
      ),
    );
  }
}

class CompactScreenNavBar extends ConsumerWidget {
  const CompactScreenNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NavigationBar(
      backgroundColor: Colors.transparent,
      indicatorColor: getIndicatorColor(context),
      elevation: SeguiElevation.medium,
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
    );
  }
}
