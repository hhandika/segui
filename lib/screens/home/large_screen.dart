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
          elevation: 2,
          actions: [
            IconButton(
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
          ]),
      body: SafeArea(
        bottom: false,
        top: false,
        child: Row(
          children: [
            NavigationRail(
              elevation: 2,
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
            ),
            Expanded(
              child: Center(
                child: pages[_selectedIndex],
              ),
            )
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
