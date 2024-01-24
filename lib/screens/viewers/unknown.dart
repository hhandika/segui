import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/io.dart';
import 'package:segui/styles/decoration.dart';

class UnknownFileViewer extends StatelessWidget {
  const UnknownFileViewer({super.key, required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(file.name),
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
                    child: Text(
                      '${getFileExtension(file).toUpperCase()} '
                      'is unsupported.',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const TopDivider(),
                  Expanded(
                    child: UnknownFileViewerBody(file: file),
                  ),
                ],
              ),
            )),
      ),
    );
  }
}

class UnknownFileViewerBody extends StatelessWidget {
  const UnknownFileViewerBody({super.key, required this.file});

  final XFile file;

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
                const UnknownViewerIcon(),
                const SizedBox(height: 16),
                FileIOTitle(file: file),
                const SizedBox(height: 2),
                FileIOSubtitle(file: file),
              ],
            );
          } else {
            return const SizedBox();
          }
        });
  }
}

class UnknownViewerIcon extends StatelessWidget {
  const UnknownViewerIcon({
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
