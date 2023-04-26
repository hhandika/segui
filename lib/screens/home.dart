import 'package:flutter/material.dart';
import 'package:segui/screens/concat/concat.dart';
import 'package:segui/screens/convert/convert.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/navigation.dart';
import 'package:segui/screens/shared/settings.dart';
import 'package:segui/screens/summary/summary.dart';
import 'package:segui/screens/translate/translate.dart';
import 'package:segui/services/utils.dart';

const List<Widget> _pages = <Widget>[
  HomePage(),
  ConcatPage(),
  ConvertPage(),
  SummaryPage(),
  TranslatePage(),
];

const List<String> _pageTitles = <String>[
  'SEGUL GUI',
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
          actions: const [
            SettingButtons(),
          ],
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
              SingleChildScrollView(
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height * .9),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: NavigationRail(
                            labelType: NavigationRailLabelType.all,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surface
                                .withOpacity(0.5),
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
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/icon.png', height: 100, width: 100),
          Text(greeting, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 50),
          const QuickActionContainer(),
        ],
      ),
    );
  }
}

class QuickActionContainer extends StatelessWidget {
  const QuickActionContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 10),
          QuickActionButton(
            icon: Icons.compare_arrows,
            label: 'Concatenate Alignments',
            onPressed: () {},
          ),
          QuickActionButton(
            icon: Icons.swap_horiz,
            label: 'Convert Alignments',
            onPressed: () {},
          ),
          QuickActionButton(
            icon: Icons.translate,
            label: 'Translate Sequences',
            onPressed: () {},
          ),
          QuickActionButton(
            icon: Icons.bar_chart,
            label: 'Summarize Sequences',
            onPressed: () {},
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
