import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/viewers/text.dart';
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
      body: SafeArea(
        child: Center(
          child: FutureBuilder(
              future: _findLogs(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final logs = snapshot.data;
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: ListView.separated(
                        separatorBuilder: (context, index) =>
                            const CommonDivider(),
                        itemCount: logs!.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          return ListTile(
                            title: Text(
                              log.name,
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
                                  builder: (context) => LogViewer(log: log),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  );
                } else {
                  return const CircularProgressIndicator();
                }
              }),
        ),
      ),
    );
  }

  Future<List<XFile>> _findLogs() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = await dir.list().toList();

    final results = files
        .where((element) => element.path.endsWith('.log'))
        .map((e) => File(e.path))
        .toList();
    // Sort by date
    results
        .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return results.map((e) => XFile(e.path)).toList();
  }
}

class LogViewer extends StatelessWidget {
  const LogViewer({super.key, required this.log});

  final XFile log;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Viewer'),
        backgroundColor: getSEGULBackgroundColor(context),
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: PlainTextViewer(file: log),
    );
  }
}
