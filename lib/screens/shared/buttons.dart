import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/services/io.dart';

class ExecutionButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: isSuccess
          ? Wrap(
              spacing: 16,
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
            )
          : PrimaryButton(
              label: label, onPressed: onExecuted, isRunning: isRunning),
    );
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
        elevation: 0,
      ),
      icon: isRunning
          ? const SizedBox(
              height: 8,
              width: 8,
              child: CircularProgressIndicator(),
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
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
      ),
      icon: isRunning
          ? const SizedBox(
              height: 8,
              width: 8,
              child: CircularProgressIndicator(),
            )
          : const Icon(Icons.play_arrow),
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

class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.label,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double containerSize = getContainerSize(screenWidth);
    return Container(
      height: containerSize,
      width: containerSize,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            20,
          ),

          // Lerp colors
          color: Color.lerp(
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.primaryContainer,
            0.5,
          )),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Icon(icon,
                    color: Theme.of(context).colorScheme.onSecondaryContainer),
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  double getContainerSize(double screenWidth) {
    bool isSmallerThanScreen = screenWidth < ((120 * 4) + (16 * 2));
    return isSmallerThanScreen ? (screenWidth / 4) - (16 * 2) : 120;
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
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: TextButton(
          onPressed: onPressed,
          child: Text(isShowMore ? 'Show less' : 'Show more'),
        ),
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
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return DeleteAlert(file: file);
          },
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
    return AlertDialog(
      title: const Text('Delete file'),
      content: const Text(
          'Deleting this file will remove it permanently. Continue?'),
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
          child: const Text('Delete'),
        ),
      ],
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
        borderRadius: BorderRadius.all(Radius.circular(16)),
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

class CommonDeleteTile extends StatelessWidget {
  const CommonDeleteTile({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
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
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return DeleteAlert(file: file);
          },
        );
      },
    );
  }
}
