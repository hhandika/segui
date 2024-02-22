import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/settings.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/styles/decoration.dart';

const List<String> themeTitles = ['System default', 'Light', 'Dark'];
const List<ThemeMode> themes = [
  ThemeMode.system,
  ThemeMode.light,
  ThemeMode.dark
];
const List<IconData> themeIcons = [
  Icons.brightness_auto_outlined,
  Icons.brightness_1_outlined,
  Icons.brightness_3_outlined
];

class ThemeSettings extends StatelessWidget {
  const ThemeSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
        backgroundColor: getSEGULBackgroundColor(context),
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: const SingleChildScrollView(
        child: Padding(
            padding: EdgeInsets.all(16), child: CompactThemeSettingView()),
      ),
    );
  }
}

class CompactThemeSettingView extends ConsumerWidget {
  const CompactThemeSettingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: getContainerDecoration(context),
      child: ref.watch(themeSettingProvider).when(
            data: (theme) => ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: themeTitles.length,
              itemBuilder: (context, index) {
                return ThemeSettingTile(
                  title: themeTitles[index],
                  theme: themes[index],
                  currentTheme: theme,
                  icon: themeIcons[index],
                );
              },
              separatorBuilder: (context, index) {
                return const CommonDivider();
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text(error.toString())),
          ),
    );
  }
}

class DesktopThemeSettingView extends ConsumerWidget {
  const DesktopThemeSettingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.topCenter,
      child: ref.watch(themeSettingProvider).when(
            data: (theme) {
              return SizedBox(
                height: 200,
                child: GridView.count(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 28,
                  crossAxisCount: 1,
                  children: List.generate(
                    themeTitles.length,
                    (index) {
                      return ThemeSettingGrid(
                        title: themeTitles[index],
                        theme: themes[index],
                        currentTheme: theme,
                        icon: themeIcons[index],
                      );
                    },
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text(error.toString())),
          ),
    );
  }
}

class ThemeSettingTile extends ConsumerWidget {
  const ThemeSettingTile({
    super.key,
    required this.title,
    required this.theme,
    required this.currentTheme,
    required this.icon,
  });

  final String title;
  final ThemeMode theme;
  final ThemeMode currentTheme;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        icon,
        color: getIconColor(context),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      trailing: theme == currentTheme
          ? const Icon(
              Icons.check,
            )
          : null,
      onTap: () {
        ref.read(themeSettingProvider.notifier).setTheme(theme);
      },
    );
  }
}

class ThemeSettingGrid extends ConsumerWidget {
  const ThemeSettingGrid({
    super.key,
    required this.title,
    required this.theme,
    required this.currentTheme,
    required this.icon,
  });

  final String title;
  final ThemeMode theme;
  final ThemeMode currentTheme;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: theme == currentTheme
          ? getContainerDecoration(context).copyWith(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 4,
              ),
            )
          : getContainerDecoration(context),
      padding: const EdgeInsets.all(16),
      width: 320,
      height: 120,
      child: InkWell(
        onTap: () {
          ref.read(themeSettingProvider.notifier).setTheme(theme);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: getIconColor(context),
              size: 80,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
