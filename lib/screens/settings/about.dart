import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/services/utils.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

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
            padding: EdgeInsets.fromLTRB(
              SeguiSpacing.xl,
              SeguiSpacing.xl,
              SeguiSpacing.xl,
              SeguiSpacing.xxl,
            ),
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
          top: SeguiControlSize.illustrationLarge / 2 + SeguiSpacing.sm,
          child: Container(
            // We add extra padding to the width
            // to account for the container decoration
            // added to the container
            width: MediaQuery.of(context).size.width > expandedScreenSize
                ? SeguiContentWidth.reading
                : MediaQuery.of(context).size.width - 2 * SeguiSpacing.xl,
            padding: const EdgeInsets.fromLTRB(
              SeguiSpacing.xl,
              SeguiSpacing.display,
              SeguiSpacing.xl,
              SeguiSpacing.xl,
            ),
            decoration: getContainerDecoration(context),
            child: FutureBuilder<SegulVersion>(
              future: segulVersion,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return SingleChildScrollView(
                      padding: const EdgeInsets.only(top: SeguiSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'SEGUI',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: SeguiSpacing.xs),
                          Text(
                            'A GUI version of the SEGUL genomic tool',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Heru Handika & Jacob A. Esselstyn',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: SeguiSpacing.xs),
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
                            padding:
                                const EdgeInsets.only(top: SeguiSpacing.md),
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
              padding: const EdgeInsets.all(SeguiSpacing.sm),
              decoration: getContainerDecoration(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(SeguiRadius.lg),
                child: Image.asset(
                  'assets/launcher/icon.png',
                  cacheHeight: 420,
                  cacheWidth: 420,
                  width: SeguiControlSize.illustrationLarge,
                  height: SeguiControlSize.illustrationLarge,
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
