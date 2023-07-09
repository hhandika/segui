import 'package:flutter/material.dart';

class ExecutionButton extends StatelessWidget {
  const ExecutionButton({
    super.key,
    required this.label,
    required this.isRunning,
    required this.isSuccess,
    required this.onExecuted,
    required this.onShared,
  });

  final String label;
  final bool isRunning;
  final bool isSuccess;
  final VoidCallback? onExecuted;
  final VoidCallback? onShared;

  @override
  Widget build(BuildContext context) {
    return isSuccess
        ? ShareButton(isRunning: isRunning, onPressed: onShared)
        : PrimaryButton(
            label: label, onPressed: onExecuted, isRunning: isRunning);
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
          : const Icon(Icons.share),
      onPressed: onPressed,
      label:
          isRunning ? const Text('Compressing files...') : const Text('Share'),
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
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        // elevation: 0,
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
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 120,
        width: 120,
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
}
