import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:segui/screens/shared/pages.dart';
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
    return isSuccess
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
            label: label, onPressed: onExecuted, isRunning: isRunning);
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

class OpenViewerButton extends StatelessWidget {
  const OpenViewerButton({super.key, required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Open in viewer',
      icon: const Icon(Icons.open_in_new),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PlainTextScreen(file: file),
          ),
        );
      },
    );
  }
}

class ShareIconButton extends StatelessWidget {
  const ShareIconButton({super.key, required this.file});

  final XFile file;

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
