import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/settings/data_usage.dart';
import 'package:segui/screens/settings/logs.dart';
import 'package:segui/screens/settings/themes.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/services/io.dart';
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

class SettingPages extends ConsumerWidget {
  const SettingPages({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
              child: Container(
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 800),
            decoration: getContainerDecoration(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SettingTile(
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
                const CommonDivider(),
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
                FutureBuilder(
                  future: getUsage(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return SettingTile(
                        title: 'Data Usage',
                        subtitle: snapshot.data as String,
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
                      );
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
                const CommonDivider(),
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
          ))),
    );
  }

  Future<String> getUsage() async {
    return await DataUsageServices().calculateUsage();
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
          backgroundColor: getSEGULBackgroundColor(context),
        ),
        backgroundColor: getSEGULBackgroundColor(context),
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
        color: Theme.of(context).colorScheme.primary,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
