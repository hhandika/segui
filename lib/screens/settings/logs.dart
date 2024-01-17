import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

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
      ),
      body: Center(
        child: FutureBuilder(
            future: _findLogs(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final logs = snapshot.data as List<File>;
                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return ListTile(
                      title: Text(log.path.split('/').last),
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
                );
              } else {
                return const CircularProgressIndicator();
              }
            }),
      ),
    );
  }

  Future<List<File>> _findLogs() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = await dir.list().toList();
    return files
        .where((element) => element.path.endsWith('.log'))
        .map((e) => e as File)
        .toList();
  }
}

class LogViewer extends StatelessWidget {
  const LogViewer({super.key, required this.log});

  final File log;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Viewer'),
      ),
      body: Center(
        child: FutureBuilder(
            future: _readLog(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final log = snapshot.data as String;
                return SingleChildScrollView(
                  child: SelectableText(log),
                );
              } else {
                return const CircularProgressIndicator();
              }
            }),
      ),
    );
  }

  Future<String> _readLog() async {
    return await log.readAsString();
  }
}
