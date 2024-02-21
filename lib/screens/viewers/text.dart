import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/io/io.dart';
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
        actions: [
          InfoButton(file: file),
        ],
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: PlainTextViewBody(file: file),
    );
  }
}

class PlainTextViewBody extends StatelessWidget {
  const PlainTextViewBody({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: getContainerDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  Flexible(
                    fit: FlexFit.loose,
                    child: FileIOSubtitle(file: file),
                  ),
                ],
              ),
            ),
            const TopDivider(),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: screenHeight * 0.85,
                child: FutureBuilder<String>(
                  future: TextParser().parse(file),
                  initialData: 'Loading...',
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return SingleChildScrollView(
                          child: SelectableText(
                        snapshot.data!,
                        maxLines: null,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ));
                    } else {
                      return const Text('Error');
                    }
                  },
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
