import 'package:flutter/material.dart';
import 'package:segui/screens/home/components/navigation.dart';
import 'package:segui/screens/home/components/pages.dart';
import 'package:segui/screens/settings/settings.dart';

class SmallScreenView extends StatefulWidget {
  const SmallScreenView({super.key});

  @override
  State<SmallScreenView> createState() => _SmallScreenViewState();
}

class _SmallScreenViewState extends State<SmallScreenView> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(pageTitles[_selectedIndex]),
          actions: const [
            SettingButtons(),
          ],
        ),
        body: SafeArea(
            child: Center(
          child: pages.elementAt(_selectedIndex),
        )),
        bottomNavigationBar: NavigationBar(
          destinations: navigationTargets
              .map((e) => NavigationDestination(
                    icon: e.icon,
                    selectedIcon: e.selectedIcon,
                    label: e.label,
                  ))
              .toList(),
          selectedIndex: _selectedIndex,
          onDestinationSelected: (value) {
            setState(() {
              _selectedIndex = value;
            });
          },
        ));
  }
}
