import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/settings.dart';

class ThemeSettings extends ConsumerStatefulWidget {
  const ThemeSettings({super.key});

  @override
  ThemeSettingsState createState() => ThemeSettingsState();
}

class ThemeSettingsState extends ConsumerState<ThemeSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
      ),
      body: Center(
          child: ref.watch(themeSettingProvider).when(
                data: (theme) => ListView(
                  children: [
                    RadioListTile(
                      value: ThemeMode.light,
                      title: const Text('Light'),
                      groupValue: theme,
                      onChanged: (value) => ref
                          .read(themeSettingProvider.notifier)
                          .setTheme(value!),
                    ),
                    RadioListTile(
                      value: ThemeMode.dark,
                      title: const Text('Dark'),
                      groupValue: theme,
                      onChanged: (value) => ref
                          .read(themeSettingProvider.notifier)
                          .setTheme(value!),
                    ),
                    RadioListTile(
                      value: ThemeMode.system,
                      title: const Text('System'),
                      groupValue: theme,
                      onChanged: (value) => ref
                          .read(themeSettingProvider.notifier)
                          .setTheme(value!),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    Center(child: Text(error.toString())),
              )),
    );
  }
}
