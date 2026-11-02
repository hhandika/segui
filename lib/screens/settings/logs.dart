import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart';
import 'package:segui/screens/settings/settings_layout.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/io/file_list.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/screens/viewers/text.dart';
import 'package:segui/services/io/logging.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

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
        child: LogListView(),
      ),
    );
  }
}

class LogListView extends StatelessWidget {
  const LogListView({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _findLogs(),
      builder: (context, snapshot) {
        final List<File>? logs = snapshot.data;
        if (logs == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Padding(
          padding: const EdgeInsets.all(SeguiSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsPageHeader(
                title: 'Logs',
                detail: '${logs.length} files',
              ),
              const SizedBox(height: SeguiSpacing.xl),
              Expanded(
                child: logs.isEmpty
                    ? const Center(child: Text('No logs yet'))
                    : SettingsListCard(
                        itemCount: logs.length,
                        itemBuilder: (context, index) =>
                            LogFileTile(log: logs[index]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Newest first. Log names end with their date.
  Future<List<File>> _findLogs() async {
    final List<File> logs = await FileLoggingService().findLogs();
    return logs..sort((a, b) => basename(b.path).compareTo(basename(a.path)));
  }
}

/// A log file that opens in the text viewer.
class LogFileTile extends StatelessWidget {
  const LogFileTile({super.key, required this.log});

  final File log;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: log.path,
      waitDuration: const Duration(milliseconds: 600),
      child: ListTile(
        leading: FileIconTile(icon: FileIcon(file: log)),
        title: Text(
          basename(log.path),
          style: Theme.of(context).textTheme.titleSmall,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: FileIOSubtitle(file: log),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlainTextView(file: log)),
        ),
      ),
    );
  }
}
