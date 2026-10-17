import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io/info.dart';
import 'package:segui/screens/shared/tool_layout.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/types.dart';

/// Runs a tool, then offers a new run and sharing after it succeeds.
///
/// Editing the form after a successful run turns it into a re-run button,
/// which runs again with the current input and options.
class ExecutionButton extends ConsumerWidget {
  const ExecutionButton({
    super.key,
    required this.label,
    required this.isRunning,
    required this.isSuccess,
    required this.controller,
    required this.onExecuted,
    required this.onShared,
    required this.onNewRun,
  });

  final String label;
  final bool isRunning;
  final bool isSuccess;
  final IOController controller;
  final VoidCallback? onExecuted;
  final VoidCallback? onShared;
  final void Function() onNewRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ToolFormEditScope? scope = ToolFormEditScope.maybeOf(context);
    final bool isEdited = scope?.isEdited ?? false;
    if (isSuccess && !isRunning && !isEdited) {
      return Wrap(
        spacing: SeguiSpacing.lg,
        runSpacing: SeguiSpacing.md,
        alignment: WrapAlignment.end,
        children: [
          NewRunButton(
            controller: controller,
            onPressed: onNewRun,
          ),
          ShareButton(
            isRunning: isRunning,
            onPressed: onShared,
          ),
        ],
      );
    }
    return Tooltip(
      message: _tooltip,
      child: PrimaryButton(
        label: _label,
        onPressed: isRunning ? null : _runCallback(ref, scope),
        isRunning: isRunning,
      ),
    );
  }

  String get _label {
    if (isRunning) {
      return 'Running';
    }
    return isSuccess ? 'Re-run' : label;
  }

  String get _tooltip {
    if (isRunning) {
      return 'Keep this screen open to avoid interruption.';
    }
    return isSuccess ? 'Run again with the current input and options.' : '';
  }

  /// Starts each run with a fresh output baseline, so new-file highlights and
  /// Quick Share cover only that run's files.
  VoidCallback? _runCallback(WidgetRef ref, ToolFormEditScope? scope) {
    final VoidCallback? execute = onExecuted;
    if (execute == null) {
      return null;
    }
    return () {
      scope?.onRunStarted();
      ref.read(fileOutputProvider.notifier).markRunStart();
      execute();
    };
  }
}

class NewRunButton extends StatelessWidget {
  const NewRunButton({
    super.key,
    required this.controller,
    required this.onPressed,
  });

  final IOController controller;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return SecondaryButton(
      text: 'New run',
      onPressed: () {
        controller.reset();
        onPressed();
      },
    );
  }
}

class ShareButton extends StatelessWidget {
  const ShareButton({
    super.key,
    required this.isRunning,
    required this.onPressed,
  });

  final bool isRunning;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: SeguiElevation.none,
      ),
      icon: isRunning
          ? const SizedBox(
              height: SeguiControlSize.iconSmall,
              width: SeguiControlSize.iconSmall,
              child: CircularProgressIndicator(
                strokeWidth: SeguiStroke.regular,
              ),
            )
          : Icon(Icons.adaptive.share),
      onPressed: onPressed,
      label: isRunning
          ? const Text('Compressing files...')
          : const Text('Quick Share'),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.isRunning,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, SeguiControlSize.primaryAction),
        padding: const EdgeInsets.symmetric(horizontal: SeguiSpacing.xxl),
        shape: const StadiumBorder(),
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      icon: isRunning
          ? SizedBox(
              height: SeguiControlSize.iconSmall,
              width: SeguiControlSize.iconSmall,
              child: CircularProgressIndicator(
                strokeWidth: SeguiStroke.regular,
                color: colors.onSurfaceVariant,
              ),
            )
          : const Icon(Icons.play_arrow_rounded),
      onPressed: onPressed,
      label: Text(label),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton(
      {super.key, required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
        foregroundColor: Theme.of(context).colorScheme.secondary,
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}

class ShowMoreButton extends StatelessWidget {
  const ShowMoreButton({
    super.key,
    required this.onPressed,
    required this.isShowMore,
  });

  final bool isShowMore;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          isShowMore ? Icons.expand_less_rounded : Icons.expand_more_rounded,
        ),
        label: Text(isShowMore ? 'Fewer options' : 'Advanced options'),
      ),
    );
  }
}

class ShareIconButton extends StatelessWidget {
  const ShareIconButton({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Share file',
      icon: Icon(Icons.adaptive.share),
      onPressed: () {
        IOServices().shareFile(context, file);
      },
    );
  }
}

class ExternalAppLauncher extends StatefulWidget {
  const ExternalAppLauncher({
    super.key,
    required this.file,
    required this.fromPopUp,
  });

  final File file;
  final bool fromPopUp;

  @override
  State<ExternalAppLauncher> createState() => _ExternalAppLauncherState();
}

class _ExternalAppLauncherState extends State<ExternalAppLauncher> {
  final isMobile = runningPlatform == PlatformType.isMobile;
  @override
  Widget build(BuildContext context) {
    if (widget.fromPopUp) {
      return isMobile
          // We do not show the tile if the platform is mobile
          // because the user can't open the file in an external app
          // instead there is a share button to share the file
          ? const SizedBox.shrink()
          : ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open in app'),
              onTap: () async => await _openExternalViewer(),
            );
    } else {
      return Padding(
          padding: const EdgeInsets.only(top: SeguiSpacing.xxs),
          child: TextButton.icon(
            onPressed: () async =>
                isMobile ? await _shareFile() : await _openExternalViewer(),
            icon: Icon(isMobile ? Icons.adaptive.share : Icons.open_in_new),
            label: Text(isMobile ? 'Share' : 'Open in app'),
          ));
    }
  }

  Future<void> _openExternalViewer() async {
    if (widget.fromPopUp) {
      // Close the pop-up first so
      // the user can see snackbar messages if
      // the file can't be opened
      Navigator.pop(context);
    }
    final launcher = UrlLauncherServices(file: widget.file);
    if (await launcher.canLaunch()) {
      try {
        await launcher.launchExternalApp();
      } catch (_) {
        _showSnackBar('An error occurred while opening the file.');
      }
    } else {
      if (mounted) {
        _showSnackBar('No app found to open this file.');
      }
    }
  }

  Future<void> _shareFile() async {
    await IOServices().shareFile(context, widget.file);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(showSharedSnackBar(context, message));
  }
}

class SharedDeleteButton extends ConsumerWidget {
  const SharedDeleteButton({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Delete file',
      icon: const Icon(Icons.delete_outline),
      onPressed: () {
        // Ask for confirmation
        showResponsiveSheet(
          context: context,
          builder: (context) => DeleteAlert(file: file),
        );
      },
    );
  }
}

class DeleteAlert extends ConsumerWidget {
  const DeleteAlert({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SheetContent(
      title: 'Delete file',
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            ref.read(fileOutputProvider.notifier).removeFile(file);
            Navigator.of(context).pop();
          },
          child: Text('Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ],
      child: const Text('Deleting this file will remove it permanently.'),
    );
  }
}

class CommonShareTile extends StatelessWidget {
  const CommonShareTile({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(SeguiRadius.lg)),
      ),
      leading: Icon(Icons.adaptive.share_rounded),
      title: const Text('Share'),
      onTap: () {
        Navigator.pop(context);
        IOServices().shareFile(context, file);
      },
    );
  }
}

class FileInfoTile extends StatelessWidget {
  const FileInfoTile({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(SeguiRadius.lg)),
      ),
      leading: const Icon(Icons.info_outline_rounded),
      title: const Text('Details'),
      onTap: () {
        Navigator.pop(context);
        showResponsiveSheet(
          context: context,
          builder: (context) => FileInfoScreen(file: file),
        );
      },
    );
  }
}

class CommonDeleteTile extends StatelessWidget {
  const CommonDeleteTile({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(SeguiRadius.lg)),
      ),
      leading: Icon(
        Icons.delete_outline_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      title: Text(
        'Delete',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      onTap: () {
        Navigator.pop(context);
        showResponsiveSheet(
          context: context,
          builder: (context) => DeleteAlert(file: file),
        );
      },
    );
  }
}

class InfoButton extends StatelessWidget {
  const InfoButton({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () {
          showResponsiveSheet(
            context: context,
            builder: (context) => FileInfoScreen(file: file),
          );
        },
        icon: const Icon(Icons.info_outline_rounded));
  }
}
