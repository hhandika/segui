import 'dart:io';

import 'package:flutter/material.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/services/io/metadata.dart';
import 'package:segui/styles/decoration.dart';

class FileInfoScreen extends StatelessWidget {
  const FileInfoScreen({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getMetadata(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Container(
              padding: const EdgeInsets.all(16),
              width: isPhoneScreen(context) ? double.infinity : 480,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  PrimaryFileIcon(file: file, iconSize: 40),
                  const SizedBox(height: 4),
                  Text(
                    snapshot.data!.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    snapshot.data!.path,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const CommonDivider(),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      MetadataTile(
                        title: 'Size',
                        content: snapshot.data!.size,
                        icon: const Icon(Icons.file_copy_outlined),
                      ),
                      MetadataTile(
                        title: 'Last modified',
                        content: snapshot.data!.lastModified,
                        icon: const Icon(Icons.update_outlined),
                      ),
                      MetadataTile(
                        title: 'Last accessed',
                        content: snapshot.data!.accessed,
                        icon: const Icon(Icons.access_time_outlined),
                      ),
                    ],
                  )
                ],
              ));
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          return const Center(
            child: Text('Error loading file info'),
          );
        }
      },
    );
  }

  Future<CompleteFileMetadata> _getMetadata() async {
    return await FileMetadata(file: file).completeMetadata;
  }
}

class MetadataTile extends StatelessWidget {
  const MetadataTile({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
  });

  final String title;
  final String content;
  final Icon icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: icon,
      title: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium,
      ),
      subtitle: Text(content),
    );
  }
}
