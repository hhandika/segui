import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/viewers/text.dart';
import 'package:segui/styles/decoration.dart';

class PlainTextViewer extends StatelessWidget {
  const PlainTextViewer({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(basename(file.path)),
        backgroundColor: getSEGULBackgroundColor(context),
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: Center(
        child: PlainTextViewerBody(file: file),
      ),
    );
  }
}

class PlainTextViewerBody extends StatelessWidget {
  const PlainTextViewerBody({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double containerHeight = screenHeight - 80;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          height: containerHeight,
          decoration: getContainerDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: FutureBuilder<String>(
                  future: TextParser().parse(file),
                  initialData: 'Loading...',
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return SizedBox(
                        height: containerHeight - 112,
                        width: double.infinity,
                        child: SelectableText(
                          snapshot.data!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    } else {
                      return const Text('Error');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
