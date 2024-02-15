import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/settings.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/styles/decoration.dart';

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
        child: ThemeSettingView(),
      ),
    );
  }
}

class ThemeSettingView extends ConsumerWidget {
  const ThemeSettingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        decoration: getContainerDecoration(context),
        child: ref.watch(themeSettingProvider).when(
              data: (theme) => Column(
                children: [
                  ThemeSettingTile(
                    title: 'System default',
                    theme: ThemeMode.system,
                    currentTheme: theme,
                    icon: Icons.brightness_auto_outlined,
                  ),
                  const CommonDivider(),
                  ThemeSettingTile(
                    title: 'Light',
                    theme: ThemeMode.light,
                    currentTheme: theme,
                    icon: Icons.brightness_1_outlined,
                  ),
                  const CommonDivider(),
                  ThemeSettingTile(
                    title: 'Dark',
                    theme: ThemeMode.dark,
                    currentTheme: theme,
                    icon: Icons.brightness_3_outlined,
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text(error.toString())),
            ),
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
        color: Theme.of(context).colorScheme.primary,
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
