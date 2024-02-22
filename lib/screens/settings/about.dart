import 'package:flutter/material.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/services/utils.dart';
import 'package:segui/styles/decoration.dart';

class AboutButton extends StatelessWidget {
  const AboutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AppAbout(),
          ),
        );
      },
      child: Text(
        'About',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
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
        body: const Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: AboutContent(),
          ),
        ));
  }
}

class AboutContent extends StatelessWidget {
  const AboutContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 56,
          child: Container(
            // We add extra padding to the width
            // to account for the container decoration
            // added to the container
            width: MediaQuery.of(context).size.width > 840
                ? 800
                : MediaQuery.of(context).size.width - 32,
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
            decoration: getContainerDecoration(context),
            child: FutureBuilder<SegulVersion>(
              future: segulVersion,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('SEGUI',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text('A GUI version of the SEGUL genomic tool',
                              style: Theme.of(context).textTheme.bodyLarge),
                          Text('Heru Handika & Jacob A. Esselstyn',
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 4),
                          const CommonDivider(),
                          AboutTile(
                            title: 'App version',
                            subtitle: 'v${snapshot.data!.version}',
                            icon: Icons.apps_outlined,
                          ),
                          AboutTile(
                            title: 'Build number',
                            subtitle: snapshot.data!.buildNumber,
                            icon: Icons.build_outlined,
                          ),
                          AboutTile(
                            title: 'API version',
                            subtitle: 'v${snapshot.data!.apiVersion}',
                            icon: Icons.api_outlined,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton(
                              onPressed: () {
                                showLicensePage(
                                  context: context,
                                  applicationName: snapshot.data!.name,
                                  applicationVersion: snapshot.data!.version,
                                );
                              },
                              child: const Text('Licenses'),
                            ),
                          ),
                        ],
                      ));
                } else {
                  return const Text('Loading...');
                }
              },
            ),
          ),
        ),
        Align(
            alignment: Alignment.topCenter,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: getContainerDecoration(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/launcher/icon.png',
                  cacheHeight: 420,
                  cacheWidth: 420,
                  width: 100,
                  height: 100,
                ),
              ),
            )),
      ],
    );
  }

  Future<SegulVersion> get segulVersion async {
    SegulVersion version = SegulVersion.empty();
    await version.getVersions();
    return version;
  }
}

class AboutTile extends StatelessWidget {
  const AboutTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(title),
      subtitle: Text(subtitle),
      leading: Icon(icon, color: getIconColor(context)),
    );
  }
}

class AboutTitle extends StatelessWidget {
  const AboutTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}

class AboutSubtitle extends StatelessWidget {
  const AboutSubtitle({super.key, required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Text(
      subtitle,
    );
  }
}
