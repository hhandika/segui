import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingButtons extends StatelessWidget {
  const SettingButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const Settings(),
          ),
        );
      },
    );
  }
}

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: Center(
            child: SettingsList(sections: [
          SettingsSection(
            tiles: [
              // SettingsTile.switchTile(
              //   initialValue: Theme.of(context).brightness == Brightness.dark,
              //   title: const Text('Dark Mode'),
              //   leading: const Icon(Icons.dark_mode),
              //   onToggle: (bool value) {
              //     if (value) {
              //       FlexColorScheme.light(
              //         colors: FlexColor.schemes[FlexScheme.green]!.light,
              //         appBarStyle: FlexAppBarStyle.background,
              //         visualDensity: FlexColorScheme.comfortablePlatformDensity,
              //       ).toTheme;
              //     } else {
              //       FlexColorScheme.dark(
              //         colors: FlexColor.schemes[FlexScheme.green]!.dark,
              //         appBarStyle: FlexAppBarStyle.background,
              //         visualDensity: FlexColorScheme.comfortablePlatformDensity,
              //       ).toTheme;
              //     }
              //   },
              // ),
              SettingsTile.navigation(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                onPressed: (context) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppAbout(),
                  ),
                ),
              ),
            ],
          )
        ])));
  }
}

class AppAbout extends StatefulWidget {
  const AppAbout({super.key});

  @override
  State<AppAbout> createState() => _AppAboutState();
}

class _AppAboutState extends State<AppAbout> {
  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('About'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                        '${snapshot.data!.appName} ${snapshot.data!.version}+${snapshot.data!.buildNumber}');
                  } else {
                    return const Text('Loading...');
                  }
                },
              ),
              const Text('A GUI version of the SEGUL genomic tool'),
              const Text('Heru Handika & Jacob A. Esselstyn'),
            ],
          ),
        ));
  }
}
