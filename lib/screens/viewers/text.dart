import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/services/viewers/text.dart';
import 'package:segui/styles/decoration.dart';

class PlainTextView extends StatelessWidget {
  const PlainTextView({super.key, required this.file});

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
        child: PlainTextViewBody(file: file),
      ),
    );
  }
}

class PlainTextViewBody extends StatelessWidget {
  const PlainTextViewBody({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double containerHeight = screenHeight * 0.8;
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
                child: SizedBox(
                  width: double.infinity,
                  child: FutureBuilder<String>(
                    future: TextParser().parse(file),
                    initialData: 'Loading...',
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return SelectableText(
                          snapshot.data!,
                          maxLines: getLines(containerHeight),
                          style: Theme.of(context).textTheme.bodyMedium,
                        );
                      } else {
                        return const Text('Error');
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int getLines(double containerHeight) {
    if (kDebugMode) {
      print('Container height: $containerHeight');
    }
    if (containerHeight < 400) {
      return 11;
    } else if (containerHeight < 600) {
      return 20;
    } else {
      return (containerHeight ~/ 24) - 1;
    }
  }
}
