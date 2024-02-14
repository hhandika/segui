import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/viewers/text.dart';
import 'package:segui/services/io.dart';
import 'package:segui/styles/decoration.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log files'),
        backgroundColor: getSEGULBackgroundColor(context),
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: const SafeArea(
        child: Center(
          child: LogListViewer(),
        ),
      ),
    );
  }
}

class LogListViewer extends StatelessWidget {
  const LogListViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _findLogs(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final logs = snapshot.data;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    decoration: getContainerDecoration(context),
                    child: ListView.separated(
                      separatorBuilder: (context, index) =>
                          const CommonDivider(),
                      itemCount: logs!.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return ListTile(
                          title: Text(
                            basename(log.path),
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Tooltip(
                            message: log.path,
                            child: Text(
                              log.path,
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          leading: const Icon(Icons.list_alt_outlined),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PlainTextViewer(file: log),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          } else {
            return const CircularProgressIndicator();
          }
        });
  }

  Future<List<File>> _findLogs() async {
    return FileLoggingService().findLogs();
  }
}
