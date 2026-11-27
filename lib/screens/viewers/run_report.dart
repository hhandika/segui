import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/viewers/common.dart';
import 'package:segui/services/io/directory.dart';
import 'package:segui/services/providers/replay.dart';
import 'package:segui/services/viewers/run_report.dart';
import 'package:segui/src/rust/api/report.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

/// App bar action button that opens [RunReportView] for unified v2 reports.
class RunReportActionButton extends StatelessWidget {
  const RunReportActionButton({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    if (!isRunReportFile(file)) {
      return const SizedBox.shrink();
    }
    return IconButton(
      tooltip: 'Run details & verify',
      icon: const Icon(Icons.verified_outlined),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RunReportView(file: file),
          ),
        );
      },
    );
  }
}

/// Interactive viewer for v2 `report.json` provenance, verification, and replay.
class RunReportView extends ConsumerStatefulWidget {
  const RunReportView({super.key, required this.file});

  final File file;

  @override
  ConsumerState<RunReportView> createState() => _RunReportViewState();
}

class _RunReportViewState extends ConsumerState<RunReportView> {
  late Future<RunReportSummary> _summaryFuture;
  VerifyReportDto? _verification;
  String? _verifyError;
  bool _isVerifying = false;
  bool _isReplaying = false;

  @override
  void initState() {
    super.initState();
    _summaryFuture = RunReportServices.inspect(reportPath: widget.file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(p.basename(widget.file.path)),
        backgroundColor: getSEGULBackgroundColor(context),
        actions: [InfoButton(file: widget.file)],
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: SafeArea(
        child: FutureBuilder<RunReportSummary>(
          future: _summaryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _RunReportError(
                message: snapshot.error.toString(),
                onRetry: () {
                  setState(() {
                    _summaryFuture = RunReportServices.inspect(
                      reportPath: widget.file.path,
                    );
                  });
                },
              );
            }
            final RunReportSummary summary = snapshot.data!;
            return _RunReportContent(
              file: widget.file,
              summary: summary,
              verification: _verification,
              verifyError: _verifyError,
              isVerifying: _isVerifying,
              isReplaying: _isReplaying,
              onVerify: _verify,
              onReplay: _replay,
              onLoadIntoTool: _loadIntoTool,
              onExportMethods: _openMethodsDialog,
              onExportWorkflow: _exportWorkflow,
            );
          },
        ),
      ),
    );
  }

  Future<void> _verify() async {
    setState(() {
      _isVerifying = true;
      _verifyError = null;
    });
    try {
      final VerifyReportDto result = await RunReportServices.verify(
        reportPath: widget.file.path,
        scope: 'all',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _verification = result;
        _isVerifying = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _verifyError = e.toString();
        _isVerifying = false;
      });
    }
  }

  Future<void> _replay() async {
    final Directory? outDir = await pickDirectory();
    if (outDir == null || !mounted) {
      return;
    }
    setState(() => _isReplaying = true);
    try {
      final String newReportPath = await RunReportServices.replay(
        reportPath: widget.file.path,
        outputDir: outDir.path,
        verifyInputs: true,
      );
      if (!mounted) {
        return;
      }
      setState(() => _isReplaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Replayed to ${p.basename(newReportPath)}'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => openFileView(context, File(newReportPath)),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isReplaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Replay failed: $e')),
      );
    }
  }

  Future<void> _loadIntoTool() async {
    try {
      final String? warning = await loadReportIntoTool(ref, widget.file.path);
      if (!mounted) {
        return;
      }
      if (warning != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(warning)),
        );
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load tool: $e')),
      );
    }
  }

  Future<void> _openMethodsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _MethodsExportDialog(reportPath: widget.file.path),
    );
  }

  Future<void> _exportWorkflow() async {
    try {
      final Directory tempDir =
          await Directory.systemTemp.createTemp('segui-wf-');
      try {
        final String tempOut = p.join(tempDir.path, 'segul-workflow.json');
        await RunReportServices.exportWorkflow(
          reportPath: widget.file.path,
          outputPath: tempOut,
        );
        final String jsonText = await File(tempOut).readAsString();
        final String? saved = await saveGeneratedTextFile(
          suggestedName: 'segul-workflow.json',
          contents: jsonText,
          extensions: const <String>['json'],
          label: 'SEGUL workflow JSON',
        );
        if (!mounted || saved == null) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved ${p.basename(saved)}')),
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Workflow export failed: $e')),
      );
    }
  }
}

class _RunReportError extends StatelessWidget {
  const _RunReportError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: SeguiContentWidth.form),
        child: Padding(
          padding: const EdgeInsets.all(SeguiSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: SeguiControlSize.iconLarge),
              const SizedBox(height: SeguiSpacing.md),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: SeguiSpacing.lg),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunReportContent extends StatelessWidget {
  const _RunReportContent({
    required this.file,
    required this.summary,
    required this.verification,
    required this.verifyError,
    required this.isVerifying,
    required this.isReplaying,
    required this.onVerify,
    required this.onReplay,
    required this.onLoadIntoTool,
    required this.onExportMethods,
    required this.onExportWorkflow,
  });

  final File file;
  final RunReportSummary summary;
  final VerifyReportDto? verification;
  final String? verifyError;
  final bool isVerifying;
  final bool isReplaying;
  final VoidCallback onVerify;
  final VoidCallback onReplay;
  final VoidCallback onLoadIntoTool;
  final VoidCallback onExportMethods;
  final VoidCallback onExportWorkflow;

  @override
  Widget build(BuildContext context) {
    final bool isPhone = isPhoneScreen(context);
    final Map<String, dynamic> params =
        _parseParameters(summary.parametersJson);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: SeguiContentWidth.wide),
        child: ListView(
          padding: EdgeInsets.all(
            isPhone ? SeguiPageMargin.compact : SeguiPageMargin.regular,
          ),
          children: [
            _RunReportCard(
              title: 'Provenance',
              icon: Icons.fingerprint_outlined,
              children: [
                _RunReportKvRow(
                  label: 'Task',
                  value: '${summary.kindLabel} (${summary.kind})',
                ),
                _RunReportKvRow(
                  label: 'Frontend',
                  value: summary.frontendVersion.isEmpty
                      ? summary.frontendName
                      : '${summary.frontendName} ${summary.frontendVersion}',
                ),
                _RunReportKvRow(
                  label: 'SEGUL core',
                  value: summary.segulCoreVersion,
                ),
                _RunReportKvRow(
                    label: 'Timestamp (UTC)', value: summary.timestampUtc),
                _RunReportKvRow(
                    label: 'Checksum mode', value: summary.checksumMode),
                _RunReportKvRow(
                    label: 'Runtime', value: '${summary.elapsedMs} ms'),
              ],
            ),
            const SizedBox(height: SeguiSpacing.lg),
            Wrap(
              spacing: SeguiSpacing.sm,
              runSpacing: SeguiSpacing.sm,
              children: [
                FilledButton.icon(
                  onPressed: isVerifying ? null : onVerify,
                  icon: const Icon(Icons.verified_outlined),
                  label:
                      Text(isVerifying ? 'Verifying...' : 'Verify checksums'),
                ),
                FilledButton.tonalIcon(
                  onPressed: isReplaying ? null : onReplay,
                  icon: const Icon(Icons.replay_outlined),
                  label: Text(isReplaying ? 'Replaying...' : 'Replay'),
                ),
                OutlinedButton.icon(
                  onPressed: onLoadIntoTool,
                  icon: const Icon(Icons.tune_outlined),
                  label: const Text('Load into tool'),
                ),
                OutlinedButton.icon(
                  onPressed: onExportMethods,
                  icon: const Icon(Icons.article_outlined),
                  label: const Text('Export methods'),
                ),
                OutlinedButton.icon(
                  onPressed: onExportWorkflow,
                  icon: const Icon(Icons.account_tree_outlined),
                  label: const Text('Export workflow'),
                ),
              ],
            ),
            if (verification != null || verifyError != null) ...[
              const SizedBox(height: SeguiSpacing.lg),
              _VerificationPanel(
                verification: verification,
                error: verifyError,
              ),
            ],
            if (params.isNotEmpty) ...[
              const SizedBox(height: SeguiSpacing.lg),
              _RunReportCard(
                title: 'Parameters',
                icon: Icons.tune_outlined,
                children: [
                  for (final key in params.keys.toList()..sort())
                    _RunReportKvRow(label: key, value: '${params[key]}'),
                ],
              ),
            ],
            const SizedBox(height: SeguiSpacing.lg),
            _RunReportCard(
              title: 'Inputs (${summary.primaryInputs.length})',
              icon: Icons.input_outlined,
              children: [
                if (summary.baseDir.isNotEmpty)
                  _RunReportKvRow(label: 'Base folder', value: summary.baseDir),
                for (final item in summary.primaryInputs)
                  _ManifestEntryRow(
                    path: item.path,
                    sizeBytes: item.sizeBytes,
                    sha256: item.sha256,
                  ),
              ],
            ),
            if (summary.auxiliaryInputs.isNotEmpty) ...[
              const SizedBox(height: SeguiSpacing.lg),
              _RunReportCard(
                title: 'Auxiliary inputs (${summary.auxiliaryInputs.length})',
                icon: Icons.attachment_outlined,
                children: [
                  for (final item in summary.auxiliaryInputs)
                    _ManifestEntryRow(
                      path: '${item.role}: ${item.path}',
                      sizeBytes: item.sizeBytes,
                      sha256: item.sha256,
                    ),
                ],
              ),
            ],
            const SizedBox(height: SeguiSpacing.lg),
            _RunReportCard(
              title: 'Outputs (${summary.outputs.length})',
              icon: Icons.output_outlined,
              children: [
                if (summary.outputDir.isNotEmpty)
                  _RunReportKvRow(
                      label: 'Output folder', value: summary.outputDir),
                for (final item in summary.outputs)
                  _ManifestEntryRow(
                    path: '${item.role}: ${item.path}',
                    sizeBytes: item.sizeBytes,
                    sha256: item.sha256,
                  ),
              ],
            ),
            if (summary.parentReports.isNotEmpty) ...[
              const SizedBox(height: SeguiSpacing.lg),
              _RunReportCard(
                title: 'Lineage (${summary.parentReports.length})',
                icon: Icons.account_tree_outlined,
                children: [
                  for (final parent in summary.parentReports)
                    _ParentReportTile(
                      baseDir: summary.baseDir,
                      parent: parent,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _parseParameters(String jsonText) {
    if (jsonText.trim().isEmpty) {
      return const <String, dynamic>{};
    }
    try {
      final Object? decoded = jsonDecode(jsonText);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}
    return const <String, dynamic>{};
  }
}

class _RunReportCard extends StatelessWidget {
  const _RunReportCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      elevation: SeguiElevation.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SeguiRadius.lg),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SeguiSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: SeguiControlSize.iconMedium,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: SeguiSpacing.sm),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: SeguiSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _RunReportKvRow extends StatelessWidget {
  const _RunReportKvRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SeguiSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: SeguiSpacing.md),
          Expanded(
            flex: 3,
            child: SelectableText(value, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _ManifestEntryRow extends StatelessWidget {
  const _ManifestEntryRow({
    required this.path,
    required this.sizeBytes,
    this.sha256,
  });

  final String path;
  final BigInt sizeBytes;
  final String? sha256;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String sizeText = '${sizeBytes.toInt()} B';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SeguiSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(path, style: theme.textTheme.bodySmall),
                if (sha256 != null && sha256!.isNotEmpty)
                  Tooltip(
                    message: sha256!,
                    child: Text(
                      'sha256: ${_shortDigest(sha256!)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: SeguiSpacing.md),
          Text(
            sizeText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _shortDigest(String digest) {
    return digest.length > 16 ? '${digest.substring(0, 16)}...' : digest;
  }
}

class _VerificationPanel extends StatelessWidget {
  const _VerificationPanel({this.verification, this.error});

  final VerifyReportDto? verification;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return _RunReportCard(
        title: 'Verification failed',
        icon: Icons.error_outline,
        children: [Text(error!)],
      );
    }
    final VerifyReportDto report = verification!;
    final List<VerifyFileDto> entries = [
      ...report.inputs,
      ...report.auxiliary,
      ...report.outputs,
      ...report.parents,
    ];
    return _RunReportCard(
      title: report.passed ? 'Verification passed' : 'Verification failed',
      icon: report.passed
          ? Icons.verified_outlined
          : Icons.warning_amber_outlined,
      children: [
        _RunReportKvRow(
          label: 'Summary',
          value: '${report.ok} ok, ${report.mismatched} mismatched, '
              '${report.missing} missing, ${report.unchecked} unchecked',
        ),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: SeguiSpacing.xxs),
            child: Row(
              children: [
                Icon(
                  _statusIcon(entry.status),
                  size: SeguiControlSize.iconSmall,
                  color: _statusColor(context, entry.status),
                ),
                const SizedBox(width: SeguiSpacing.sm),
                Expanded(
                  child: Text(
                    entry.detail == null || entry.detail!.isEmpty
                        ? '${entry.path} (${entry.status})'
                        : '${entry.path} (${entry.status}: ${entry.detail})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'ok':
        return Icons.check_circle_outline;
      case 'unchecked':
        return Icons.remove_circle_outline;
      default:
        return Icons.cancel_outlined;
    }
  }

  Color _statusColor(BuildContext context, String status) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    switch (status) {
      case 'ok':
        return colors.primary;
      case 'unchecked':
        return colors.onSurfaceVariant;
      default:
        return colors.error;
    }
  }
}

class _ParentReportTile extends StatelessWidget {
  const _ParentReportTile({required this.baseDir, required this.parent});

  final String baseDir;
  final ParentReportDto parent;

  @override
  Widget build(BuildContext context) {
    final String resolved = p.isAbsolute(parent.path) || baseDir.isEmpty
        ? parent.path
        : p.normalize(p.join(baseDir, parent.path));
    final File parentFile = File(resolved);
    final bool exists = parentFile.existsSync();
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history_outlined),
      title: Text('${parent.kind}: ${parent.path}'),
      subtitle: parent.matchedFiles.isEmpty
          ? null
          : Text(parent.matchedFiles.join(', ')),
      trailing: exists ? const Icon(Icons.chevron_right) : null,
      onTap: exists
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RunReportView(file: parentFile),
                ),
              );
            }
          : null,
    );
  }
}

class _MethodsExportDialog extends StatefulWidget {
  const _MethodsExportDialog({required this.reportPath});

  final String reportPath;

  @override
  State<_MethodsExportDialog> createState() => _MethodsExportDialogState();
}

class _MethodsExportDialogState extends State<_MethodsExportDialog> {
  String _format = 'markdown';
  late Future<String> _textFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Publication methods'),
      content: SizedBox(
        width: SeguiContentWidth.form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'markdown', label: Text('Markdown')),
                ButtonSegment(value: 'text', label: Text('Plain text')),
              ],
              selected: {_format},
              onSelectionChanged: (selected) {
                setState(() {
                  _format = selected.first;
                  _load();
                });
              },
            ),
            const SizedBox(height: SeguiSpacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: FutureBuilder<String>(
                future: _textFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  }
                  return SingleChildScrollView(
                    child: SelectableText(snapshot.data ?? ''),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FutureBuilder<String>(
          future: _textFuture,
          builder: (context, snapshot) {
            final String? text = snapshot.data;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: text == null
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: text));
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Copied to clipboard')),
                          );
                        },
                  child: const Text('Copy'),
                ),
                FilledButton.tonal(
                  onPressed: text == null
                      ? null
                      : () async {
                          final String ext =
                              _format == 'markdown' ? 'md' : 'txt';
                          final String? saved = await saveGeneratedTextFile(
                            suggestedName: 'methods.$ext',
                            contents: text,
                            extensions: [ext],
                            label: 'Methods document',
                          );
                          if (!context.mounted || saved == null) {
                            return;
                          }
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Saved ${p.basename(saved)}'),
                            ),
                          );
                        },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _load() {
    _textFuture = RunReportServices.exportMethods(
      reportPath: widget.reportPath,
      format: _format,
      includeChain: true,
    );
  }
}
