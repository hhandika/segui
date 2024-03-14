import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/screens/settings/about.dart';
import 'package:segui/screens/settings/data_usage.dart';
import 'package:segui/screens/settings/logs.dart';
import 'package:segui/screens/settings/themes.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/styles/decoration.dart';

class SettingButtons extends StatelessWidget {
  const SettingButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingMenu(
              isFromNavigationDrawer: false,
            ),
          ),
        );
      },
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
            builder: (context) => const SettingMenu(
              isFromNavigationDrawer: true,
            ),
          ),
        );
      },
    );
  }
}

class AboutMenuTile extends StatelessWidget {
  const AboutMenuTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SecondaryMenuTile(
      text: 'About',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AppAbout(),
          ),
        );
      },
    );
  }
}

class SettingMenu extends StatefulWidget {
  const SettingMenu({super.key, required this.isFromNavigationDrawer});

  final bool isFromNavigationDrawer;

  @override
  State<SettingMenu> createState() => _SettingMenuState();
}

class _SettingMenuState extends State<SettingMenu> {
  late bool showLargeScreenSettings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Show large screen view for screen width >= 600 dp
    // which is the recommended screen size for tablets.
    showLargeScreenSettings = isDesktopScreen(context);
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = getSEGULBackgroundColor(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: mainColor,
      ),
      backgroundColor: mainColor,
      body: SafeArea(
        child: showLargeScreenSettings && widget.isFromNavigationDrawer
            ? const LargeScreenSettings()
            : const SmallScreenSettings(),
      ),
    );
  }
}

class LargeScreenSettings extends ConsumerStatefulWidget {
  const LargeScreenSettings({super.key});

  @override
  LargeScreenSettingsState createState() => LargeScreenSettingsState();
}

class LargeScreenSettingsState extends ConsumerState<LargeScreenSettings> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NavigationDrawer(
          backgroundColor: getSEGULBackgroundColor(context),
          tilePadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          indicatorColor: getIndicatorColor(context),
          indicatorShape: getIndicatorShape(context),
          elevation: 0,
          selectedIndex: _selectedIndex,
          children: const [
            ...settingsDrawerDestinations,
            DrawerDivider(),
          ],
          onDestinationSelected: (value) {
            setState(() {
              // Add data usage to file output provider
              // When user selects data usage
              if (value == 2) {
                ref.read(fileOutputProvider.notifier).addFromAppDir();
              }
              _selectedIndex = value;
            });
          },
        ),
        Expanded(
          child: _selectedIndex == 0
              ? const LogListView()
              : _selectedIndex == 1
                  ? const DesktopThemeSettingView()
                  : const DataUsageView(),
        ),
      ],
    );
  }
}

const List<NavigationDrawerDestination> settingsDrawerDestinations = [
  NavigationDrawerDestination(
    label: Text('Logs'),
    icon: Icon(Icons.list_alt_outlined),
    selectedIcon: Icon(Icons.list_alt_rounded),
  ),
  NavigationDrawerDestination(
    label: Text('Theme'),
    icon: Icon(Icons.color_lens_outlined),
    selectedIcon: Icon(Icons.color_lens_rounded),
  ),
  NavigationDrawerDestination(
    label: Text('Data Usage'),
    icon: Icon(Icons.data_usage_outlined),
    selectedIcon: Icon(Icons.data_usage_rounded),
  ),
];

class SmallScreenSettings extends ConsumerWidget {
  const SmallScreenSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          height: MediaQuery.of(context).size.height,
          child: ListView(
            children: [
              Container(
                decoration: getContainerDecoration(context),
                child: SettingTile(
                  title: 'Logs',
                  subtitle: 'View logs from previous tasks',
                  icon: Icons.list_alt_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LogScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SettingTitle(title: 'App Settings'),
              const MainSettings(),
              const SettingTitle(title: 'General'),
              Container(
                decoration: getContainerDecoration(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SettingTile(
                      title: 'About',
                      subtitle: 'View app information',
                      icon: Icons.info_outline,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppAbout(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingTitle extends StatelessWidget {
  const SettingTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 0, 2),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge,
          textAlign: TextAlign.start,
        ));
  }
}

class MainSettings extends ConsumerWidget {
  const MainSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: getContainerDecoration(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SettingTile(
            title: 'Theme',
            subtitle: 'Change app theme',
            icon: Icons.color_lens_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeSettings(),
                ),
              );
            },
          ),
          const CommonDivider(),
          SettingTile(
            title: 'Data usage',
            subtitle: 'View and manage app data',
            icon: Icons.data_usage_outlined,
            onTap: () {
              ref.read(fileOutputProvider.notifier).addFromAppDir();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DataUsageScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SettingTile extends StatelessWidget {
  const SettingTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      ),
      leading: Icon(
        icon,
        color: getIconColor(context),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
