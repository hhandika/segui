import 'package:flutter/material.dart';
import 'package:segui/screens/home/components/pages.dart';
import 'package:segui/screens/settings/settings.dart';
import 'package:segui/screens/home/components/navigation.dart';

class LargeScreenView extends StatefulWidget {
  const LargeScreenView({super.key});

  @override
  State<LargeScreenView> createState() => _LargeScreenViewState();
}

class _LargeScreenViewState extends State<LargeScreenView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitles[_selectedIndex]),
        elevation: 10,
      ),
      body: SafeArea(
        bottom: false,
        top: false,
        child: Row(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.9),
              child: IntrinsicHeight(
                child: NavigationRail(
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    destinations: navigationTargets
                        .map((e) => NavigationRailDestination(
                              icon: e.icon,
                              selectedIcon: e.selectedIcon,
                              label: Text(e.label),
                            ))
                        .toList(),
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (int index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    groupAlignment: BorderSide.strokeAlignCenter,
                    trailing: const Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SettingButtons(),
                      ),
                    )),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  child: pages.elementAt(_selectedIndex),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
