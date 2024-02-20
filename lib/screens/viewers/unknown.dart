import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as path;
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/io.dart';
import 'package:segui/styles/decoration.dart';

class UnknownFileView extends StatelessWidget {
  const UnknownFileView({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(path.basename(file.path)),
        backgroundColor: getSEGULBackgroundColor(context),
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: Center(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: getContainerDecoration(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FileIcon(file: file),
                        const SizedBox(width: 8),
                        FileIOSubtitle(file: file),
                      ],
                    ),
                  ),
                  const TopDivider(),
                  Expanded(
                    child: UnknownFileViewBody(file: file),
                  ),
                ],
              ),
            )),
      ),
    );
  }
}

class UnknownFileViewBody extends StatefulWidget {
  const UnknownFileViewBody({super.key, required this.file});

  final File file;

  @override
  State<UnknownFileViewBody> createState() => _UnknownFileViewBodyState();
}

class _UnknownFileViewBodyState extends State<UnknownFileViewBody> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: FileMetadata(file: widget.file).metadata,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const FileErrorIcon(),
                const Text(
                  'Unsupported file format.',
                ),
                // Open external viewer
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async => await _openExternalViewer(),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open in app...'),
                )
              ],
            );
          } else {
            return const SizedBox();
          }
        });
  }

  Future<void> _openExternalViewer() async {
    final launcher = UrlLauncherServices(file: widget.file);
    if (await launcher.canLaunch()) {
      try {
        await launcher.launchExternalApp();
      } catch (e) {
        _showSnackBar(e.toString());
      }
    } else {
      if (mounted) {
        _showSnackBar('No app found to open this file.');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(showSharedSnackBar(context, message));
  }
}

class UnknownViewIcon extends StatelessWidget {
  const UnknownViewIcon({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/unknown.svg',
      width: 80,
      height: 80,
      colorFilter: ColorFilter.mode(
        Theme.of(context).colorScheme.primary,
        BlendMode.srcIn,
      ),
    );
  }
}
