import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as path;
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/common.dart';
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
        actions: [
          InfoButton(file: file),
        ],
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
                        PrimaryFileIcon(file: file),
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

class UnknownFileViewBody extends StatelessWidget {
  const UnknownFileViewBody({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: FileMetadata(file: file).metadata,
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
                ExternalAppLauncher(file: file, fromPopUp: false)
              ],
            );
          } else {
            return const SizedBox();
          }
        });
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
