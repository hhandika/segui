import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/styles/segui_icons.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/screens/settings/settings.dart';
import 'package:segui/screens/home/components/pages.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/viewers/viewer_page.dart';
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
  NavigationTarget(
    label: 'Trees',
    icon: Icon(SeguiIcons.treesOutlined),
    selectedIcon: Icon(SeguiIcons.treesFilled),
  ),
];

/// Bottom bar targets on phones. Trees opens from More.
final List<NavigationTarget> compactNavigationTargets =
    navigationTargets.sublist(0, treeTab);

const List<NavigationDrawerDestination> navigationDrawerTargets = [
  NavigationDrawerDestination(
    label: NavigationDrawerLabel('Home'),
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
  ),
  NavigationDrawerDestination(
    label: NavigationDrawerLabel('Genomics'),
    icon: Icon(SeguiIcons.genomicsOutlined),
    selectedIcon: Icon(SeguiIcons.genomicsFilled),
  ),
  NavigationDrawerDestination(
    label: NavigationDrawerLabel('Alignments'),
    icon: Icon(SeguiIcons.alignmentsOutlined),
    selectedIcon: Icon(SeguiIcons.alignmentsFilled),
  ),
  NavigationDrawerDestination(
    label: NavigationDrawerLabel('Sequences'),
    icon: Icon(SeguiIcons.sequencesOutlined),
    selectedIcon: Icon(SeguiIcons.sequencesFilled),
  ),
  NavigationDrawerDestination(
    label: NavigationDrawerLabel('Trees'),
    icon: Icon(SeguiIcons.treesOutlined),
    selectedIcon: Icon(SeguiIcons.treesFilled),
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
      selectedIndex: toolTab(ref.watch(tabSelectionProvider)),
      children: const [
        ...navigationDrawerTargets,
        DrawerDivider(),
        ViewerMenuTile(),
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
      selectedIndex: toolTab(ref.watch(tabSelectionProvider)),
      onDestinationSelected: (int index) {
        ref.read(tabSelectionProvider.notifier).setTab(index);
      },
      groupAlignment: BorderSide.strokeAlignCenter,
      trailing: const Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [ViewerButton(), SettingButtons()],
          ),
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
      destinations: [
        ...compactNavigationTargets.map((e) => NavigationDestination(
              icon: e.icon,
              selectedIcon: e.selectedIcon,
              label: e.label,
            )),
        const NavigationDestination(
          icon: Icon(Icons.more_horiz_rounded),
          label: 'More',
        ),
      ],
      // Trees opens from More, so More stays selected on its page.
      selectedIndex: compactBarIndex(ref.watch(tabSelectionProvider)),
      onDestinationSelected: (value) {
        ref
            .read(tabSelectionProvider.notifier)
            .setTab(value < treeTab ? value : moreTab);
      },
    );
  }
}

/// Bottom bar index for [tab]. Tabs after the bar's tool tabs select More.
int compactBarIndex(int tab) => tab < treeTab ? tab : treeTab;

/// Drawer entry that opens the viewer.
class ViewerMenuTile extends StatelessWidget {
  const ViewerMenuTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SecondaryMenuTile(
      text: 'Viewer',
      icon: Icons.visibility_outlined,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ViewerPage()),
      ),
    );
  }
}

/// Rail button that opens the viewer.
class ViewerButton extends StatelessWidget {
  const ViewerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Viewer',
      icon: const Icon(Icons.visibility_outlined),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ViewerPage()),
      ),
    );
  }
}
