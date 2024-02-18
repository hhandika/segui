import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                  '${snapshot.data!.appName} ${snapshot.data!.version}+${snapshot.data!.buildNumber}'),
              const Text('A GUI version of the SEGUL genomic tool'),
              const Text('Heru Handika & Jacob A. Esselstyn'),
              // Show license
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton(
                  // Open license
                  onPressed: () {
                    showLicensePage(
                      context: context,
                      applicationName: snapshot.data!.appName,
                      applicationVersion: snapshot.data!.version,
                    );
                  },
                  child: const Text('Licenses'),
                ),
              ),
            ],
          );
        } else {
          return const Text('Loading...');
        }
      },
    );
  }
}
