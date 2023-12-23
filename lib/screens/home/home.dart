import 'package:flutter/material.dart';
import 'package:segui/screens/alignment/entry_page.dart';
import 'package:segui/screens/alignment/concat.dart';
import 'package:segui/screens/alignment/convert.dart';
import 'package:segui/screens/alignment/summary.dart';
import 'package:segui/screens/genomics/entry_page.dart';
import 'package:segui/screens/home/components/faq.dart';
import 'package:segui/screens/home/components/learning_resources.dart';
import 'package:segui/screens/home/components/quick_start.dart';
import 'package:segui/screens/sequence/entry_page.dart';
import 'package:segui/screens/sequence/translate.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/navigation.dart';
import 'package:segui/screens/shared/settings.dart';
import 'package:segui/services/utils.dart';
import 'package:url_launcher/url_launcher.dart';

const List<Widget> _pages = <Widget>[
  HomePage(),
  SeqReadPage(),
  AlignmentPage(),
  SequencePage(),
];

const List<String> _pageTitles = <String>[
  'SEGUL GUI',
  'Genomic Sequence Tools',
  'Alignment Tools',
  'Sequence Tools',
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
        body: SafeArea(child: Center(child: _pages.elementAt(_selectedIndex))),
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
              ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.9),
                child: IntrinsicHeight(
                  child: NavigationRail(
                      labelType: NavigationRailLabelType.all,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
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
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _pages.elementAt(_selectedIndex),
                  ),
                ),
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
          Image.asset('assets/images/logo.png', height: 100, width: 100),
          Text(greeting, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 40),
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(height: 15),
          const QuickActionContainer(),
          const SizedBox(height: 30),
          const ResourceTiles(),
        ],
      ),
    );
  }
}

class QuickActionContainer extends StatelessWidget {
  const QuickActionContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 250, maxHeight: 250),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            QuickActionButton(
              icon: Icons.compare_arrows,
              label: 'Concatenate Alignments',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const QuickConcatPage()));
              },
            ),
            QuickActionButton(
              icon: Icons.swap_horiz,
              label: 'Convert Alignments',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const QuickConvertPage()));
              },
            ),
            QuickActionButton(
              icon: Icons.translate,
              label: 'Translate Sequences',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const QuickTranslatePage()));
              },
            ),
            QuickActionButton(
              icon: Icons.bar_chart,
              label: 'Summarize Sequences',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const QuickAlignmentSummaryPage()));
              },
            ),
          ],
        ));
  }
}

class ResourceTiles extends StatelessWidget {
  const ResourceTiles({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.help_outline_outlined,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              'FAQ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurface),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => const FaqPage())),
          ),
          ListTile(
            leading: Icon(Icons.speed_outlined,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text('Quick start',
                style: Theme.of(context).textTheme.titleMedium),
            trailing: Icon(Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurface),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const QuickStartPage())),
          ),
          ListTile(
            leading: Icon(Icons.school_outlined,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text('Learning resources',
                style: Theme.of(context).textTheme.titleMedium),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const LearningResourcesPage()));
            },
          ),
          ListTile(
              leading: Icon(Icons.description_outlined,
                  color: Theme.of(context).colorScheme.onSurface),
              title: Text(
                'SEGUL documentation',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.onSurface),
              onTap: () => launchSegulDocUrl())
        ],
      ),
    );
  }

  void launchSegulDocUrl() {
    String url = 'https://docs.page/hhandika/segul-docs/';
    Uri uri = Uri.parse(url);
    launchUrl(uri);
  }
}
