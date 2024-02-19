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
          child: AboutContent(),
        ));
  }
}

class AboutContent extends StatelessWidget {
  const AboutContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 56,
            child: Container(
              width: MediaQuery.of(context).size.width < 800
                  ? MediaQuery.of(context).size.width
                  : 800,
              height: 460,
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
              decoration: getContainerDecoration(context),
              child: FutureBuilder<SegulVersion>(
                future: segulVersion,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('SEGUI',
                                style: Theme.of(context).textTheme.titleLarge),
                            Text('A GUI version of the SEGUL genomic tool',
                                style: Theme.of(context).textTheme.bodyLarge),
                            Text('Heru Handika & Jacob A. Esselstyn',
                                style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 16),
                            const CommonDivider(),
                            ListTile(
                                dense: true,
                                title: const AboutTitle(title: 'App version'),
                                subtitle: AboutSubtitle(
                                    subtitle: 'v${snapshot.data!.version}'),
                                leading: Icon(
                                  Icons.widgets_outlined,
                                  color: getIconColor(context),
                                )),
                            const CommonDivider(),
                            ListTile(
                                title: const AboutTitle(title: 'Build number'),
                                subtitle: AboutSubtitle(
                                    subtitle: snapshot.data!.buildNumber),
                                leading: Icon(
                                  Icons.build_outlined,
                                  color: getIconColor(context),
                                )),
                            const CommonDivider(),
                            ListTile(
                              title: const AboutTitle(title: 'API version'),
                              subtitle: AboutSubtitle(
                                  subtitle: 'v${snapshot.data!.apiVersion}'),
                              leading: Icon(
                                Icons.api_outlined,
                                color: getIconColor(context),
                              ),
                            ),
                            const CommonDivider(),
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
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
                    width: 100,
                    height: 100,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Future<SegulVersion> get segulVersion async {
    SegulVersion version = SegulVersion.empty();
    await version.getVersions();
    return version;
  }
}

class AboutTitle extends StatelessWidget {
  const AboutTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyMedium,
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
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
