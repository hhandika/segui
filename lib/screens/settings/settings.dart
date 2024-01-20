import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:segui/screens/settings/logs.dart';
import 'package:segui/screens/settings/themes.dart';
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
    final mainColor = getSEGULBackgroundColor(context);
    return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: mainColor,
        ),
        backgroundColor: mainColor,
        body: const SettingPages());
  }
}

class SettingPages extends StatelessWidget {
  const SettingPages({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ListTile(
                title: const Text('Log files'),
                leading: const Icon(Icons.admin_panel_settings),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LogScreen(),
                    ),
                  );
                },
              ),
              const SettingDividers(),
              ListTile(
                title: const Text('Theme'),
                leading: const Icon(Icons.color_lens_outlined),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ThemeSettings(),
                    ),
                  );
                },
              ),
              const SettingDividers(),
              ListTile(
                title: const Text('About'),
                leading: const Icon(Icons.info_outline),
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
        ));
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

class SettingDividers extends StatelessWidget {
  const SettingDividers({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      thickness: 2,
      height: 2,
      indent: 4,
      endIndent: 2,
      color: getSEGULBackgroundColor(context),
    );
  }
}
