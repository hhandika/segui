import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/io/folder_access.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/screens/settings/about.dart';
import 'package:segui/screens/settings/colors.dart';
import 'package:segui/screens/settings/data_usage.dart';
import 'package:segui/screens/settings/folder_access.dart';
import 'package:segui/screens/settings/logs.dart';
import 'package:segui/screens/settings/themes.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

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
      icon: Icons.settings_outlined,
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
      icon: Icons.info_outline,
      onTap: () => showAppAbout(context),
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

/// Pages of the large-screen settings, listed in the side panel.
enum SettingsPage {
  logs('Logs', Icons.list_alt_outlined, Icons.list_alt_rounded),
  theme('Theme', Icons.brightness_6_outlined, Icons.brightness_6_rounded),
  colors('Colors', Icons.palette_outlined, Icons.palette_rounded),
  dataUsage('Data usage', Icons.data_usage_outlined, Icons.data_usage_rounded),
  folderAccess('Folder access', Icons.folder_outlined, Icons.folder_rounded);

  const SettingsPage(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Pages shown on this platform. Only the macOS sandbox needs folder
  /// access.
  static List<SettingsPage> get available => [
        for (final SettingsPage page in values)
          if (page != folderAccess || FolderAccessChannel.isSupported) page,
      ];
}

/// Settings laid out like the home screen: the pages in a drawer on the
/// page background, and the open page in an outlined container.
class LargeScreenSettings extends ConsumerStatefulWidget {
  const LargeScreenSettings({super.key});

  @override
  LargeScreenSettingsState createState() => LargeScreenSettingsState();
}

class LargeScreenSettingsState extends ConsumerState<LargeScreenSettings> {
  SettingsPage _page = SettingsPage.logs;

  @override
  Widget build(BuildContext context) {
    final List<SettingsPage> pages = SettingsPage.available;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Styled like the home screen's navigation drawer.
        NavigationDrawer(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: SeguiSpacing.xs,
            vertical: SeguiSpacing.xxs,
          ),
          elevation: SeguiElevation.none,
          backgroundColor: getSEGULBackgroundColor(context),
          indicatorColor: getIndicatorColor(context),
          indicatorShape: getIndicatorShape(context),
          selectedIndex: pages.indexOf(_page),
          onDestinationSelected: (i) => _open(pages[i]),
          children: [
            for (final SettingsPage page in pages)
              NavigationDrawerDestination(
                label: Text(page.label),
                icon: Icon(page.icon),
                selectedIcon: Icon(page.selectedIcon),
              ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(SeguiSpacing.md),
            child: OutlinedPanel(
              child: switch (_page) {
                SettingsPage.logs => const LogListView(),
                SettingsPage.theme => const ThemeSettingView(),
                SettingsPage.colors => const ColorSettingView(),
                SettingsPage.dataUsage => const DataUsageView(),
                SettingsPage.folderAccess => const FolderAccessView(),
              },
            ),
          ),
        ),
      ],
    );
  }

  void _open(SettingsPage page) {
    // Data usage lists the files in the app folder.
    if (page == SettingsPage.dataUsage) {
      ref.read(fileOutputProvider.notifier).addFromAppDir();
    }
    setState(() => _page = page);
  }
}

class SmallScreenSettings extends ConsumerWidget {
  const SmallScreenSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(SeguiSpacing.xl),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: SeguiContentWidth.form),
          height: MediaQuery.of(context).size.height,
          child: ListView(
            children: [
              OutlinedPanel(
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
              OutlinedPanel(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SettingTile(
                      title: 'About',
                      subtitle: 'View app information',
                      icon: Icons.info_outline,
                      onTap: () => showAppAbout(context),
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
        padding: const EdgeInsets.fromLTRB(
          SeguiSpacing.md,
          SeguiSpacing.md,
          SeguiSpacing.md,
          SeguiSpacing.xs,
        ),
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
    return OutlinedPanel(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SettingTile(
            title: 'Theme',
            subtitle: 'Change app theme and motion',
            icon: Icons.brightness_6_outlined,
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
            title: 'Colors',
            subtitle: 'Chart, table, and alignment colors',
            icon: Icons.palette_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ColorSettings(),
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
          if (FolderAccessChannel.isSupported) ...[
            const CommonDivider(),
            SettingTile(
              title: 'Folder access',
              subtitle: 'Folders SEGUI opens without asking',
              icon: Icons.folder_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FolderAccessScreen(),
                ),
              ),
            ),
          ],
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
