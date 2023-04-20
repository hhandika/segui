import 'package:flutter/material.dart';
import 'package:segui/screens/concat/concat.dart';
import 'package:segui/screens/convert/convert.dart';
import 'package:segui/screens/shared/navigation.dart';
import 'package:segui/screens/summary/summary.dart';
import 'package:segui/screens/translate/translate.dart';

const List<Widget> _pages = <Widget>[
  HomePage(),
  ConcatPage(),
  ConvertPage(),
  SummaryPage(),
  TranslatePage(),
];

const List<String> _pageTitles = <String>[
  'HOME',
  'Alignment Concatenation',
  'Sequence Conversion',
  'Sequence Summary',
  'Sequence Translation',
];

class SegulHome extends StatefulWidget {
  const SegulHome({super.key});

  @override
  State<SegulHome> createState() => _SegulHomeState();
}

class _SegulHomeState extends State<SegulHome> {
  late bool showLargeScreenView;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    showLargeScreenView = MediaQuery.of(context).size.width >= 450;
  }

  @override
  Widget build(BuildContext context) {
    return showLargeScreenView
        ? const LargeScreenView()
        : const SmallScreenView();
  }
}

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
          title: Text(_pageTitles[_selectedIndex]),
        ),
        body: SafeArea(
          child: Center(
            child: _pages.elementAt(_selectedIndex),
          ),
        ),
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
        title: Text(_pageTitles[_selectedIndex]),
        elevation: 10,
      ),
      body: SafeArea(
          bottom: false,
          top: false,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: NavigationRail(
                    labelType: NavigationRailLabelType.all,
                    backgroundColor:
                        Theme.of(context).colorScheme.surface.withOpacity(0.5),
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
                    trailing: Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () {},
                        ),
                      ),
                    )),
              ),
              const VerticalDivider(thickness: 0.5, width: 1),
              Expanded(
                flex: 3,
                child: _pages.elementAt(_selectedIndex),
              ),
            ],
          )),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          height: 200,
          width: 400,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.secondary),
            borderRadius: BorderRadius.circular(10),
            color: Color.lerp(Theme.of(context).colorScheme.secondary,
                Theme.of(context).colorScheme.surface, 0.95),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text("Welcome to SEGUL GUI!"),
              Text("Select a tool from the navigation bar to get started."),
            ],
          ),
        ),
      ),
    );
  }
}
