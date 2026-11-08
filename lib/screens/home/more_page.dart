import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/settings/about.dart';
import 'package:segui/screens/settings/colors.dart';
import 'package:segui/screens/settings/data_usage.dart';
import 'package:segui/screens/settings/folder_access.dart';
import 'package:segui/screens/settings/logs.dart';
import 'package:segui/screens/settings/settings.dart';
import 'package:segui/screens/settings/themes.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/viewers/viewer_page.dart';
import 'package:segui/services/io/folder_access.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/providers/viewer.dart';
import 'package:segui/services/utils.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

/// GUI guide on the documentation website.
const String _guideUrl = '${segulDocUrl}docs/gui-usage/intro/';

/// Phone tab with shortcuts to the viewer, colors, logs, and guide, then
/// settings: common ones change here, the rest open their pages.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: SeguiContentWidth.form),
        child: ListView(
          padding: const EdgeInsets.all(SeguiSpacing.lg),
          children: const [
            MoreShortcutGrid(),
            SettingTitle(title: 'Quick settings'),
            OutlinedPanel(
              child: Column(
                children: [
                  ThemeModeTile(),
                  CommonDivider(),
                  ReduceMotionTile(isOutlined: false),
                ],
              ),
            ),
            SettingTitle(title: 'More settings'),
            MoreSettingsList(),
          ],
        ),
      ),
    );
  }
}

/// Two-column tiles that open the viewer, colors, logs, and guide.
class MoreShortcutGrid extends ConsumerWidget {
  const MoreShortcutGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int recents = ref.watch(viewerRecentsProvider).length;
    final List<MoreShortcut> shortcuts = [
      MoreShortcut(
        icon: Icons.visibility_outlined,
        title: 'Viewer',
        subtitle: recents == 0 ? 'Open files to view' : '$recents recent',
        onTap: () => _push(context, const ViewerPage()),
      ),
      MoreShortcut(
        icon: Icons.palette_outlined,
        title: 'Colors',
        subtitle: 'Charts and residues',
        onTap: () => _push(context, const ColorSettings()),
      ),
      MoreShortcut(
        icon: Icons.list_alt_outlined,
        title: 'Logs',
        subtitle: 'Past tasks',
        onTap: () => _push(context, const LogScreen()),
      ),
      MoreShortcut(
        icon: Icons.menu_book_outlined,
        title: 'Guide',
        subtitle: 'Online docs',
        onTap: () => launchUrl(Uri.parse(_guideUrl)),
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: SeguiSpacing.md,
      crossAxisSpacing: SeguiSpacing.md,
      childAspectRatio: SeguiControlSize.moreTileAspect,
      children: [
        for (final MoreShortcut shortcut in shortcuts)
          MoreShortcutTile(shortcut: shortcut),
      ],
    );
  }
}

/// What a shortcut tile shows and does.
class MoreShortcut {
  const MoreShortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class MoreShortcutTile extends StatelessWidget {
  const MoreShortcutTile({super.key, required this.shortcut});

  final MoreShortcut shortcut;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return OutlinedPanel(
      child: InkWell(
        onTap: shortcut.onTap,
        child: Padding(
          padding: const EdgeInsets.all(SeguiSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(shortcut.icon, color: theme.colorScheme.primary),
              const SizedBox(height: SeguiSpacing.sm),
              Text(
                shortcut.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                shortcut.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Light, system, or dark theme, chosen in place.
class ThemeModeTile extends ConsumerWidget {
  const ThemeModeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode =
        ref.watch(themeSettingProvider).value ?? ThemeMode.system;
    return ListTile(
      leading: Icon(Icons.brightness_6_outlined, color: getIconColor(context)),
      title: const Text('Theme'),
      trailing: SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: const [
          ButtonSegment(value: ThemeMode.light, label: Text('Light')),
          ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
          ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
        ],
        selected: {mode},
        onSelectionChanged: (modes) =>
            ref.read(themeSettingProvider.notifier).setTheme(modes.first),
      ),
    );
  }
}

/// Settings that open their own pages.
class MoreSettingsList extends ConsumerWidget {
  const MoreSettingsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedPanel(
      child: Column(
        children: [
          SettingTile(
            title: 'Data usage',
            subtitle: 'View and manage app data',
            icon: Icons.data_usage_outlined,
            onTap: () {
              // Data usage lists the files in the app folder.
              ref.read(fileOutputProvider.notifier).addFromAppDir();
              _push(context, const DataUsageScreen());
            },
          ),
          if (FolderAccessChannel.isSupported) ...[
            const CommonDivider(),
            SettingTile(
              title: 'Folder access',
              subtitle: 'Folders SEGUI opens without asking',
              icon: Icons.folder_outlined,
              onTap: () => _push(context, const FolderAccessScreen()),
            ),
          ],
          const CommonDivider(),
          SettingTile(
            title: 'About',
            subtitle: 'Version, authors, and licenses',
            icon: Icons.info_outline,
            onTap: () => showAppAbout(context),
          ),
        ],
      ),
    );
  }
}

void _push(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
}
