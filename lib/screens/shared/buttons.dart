import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.text, required this.onPressed});

  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}

class FormButton extends StatelessWidget {
  const FormButton({
    super.key,
    required this.isEditing,
    required this.onDeleted,
    required this.onSubmitted,
  });

  final bool isEditing;
  final VoidCallback onDeleted;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        SecondaryButton(
          text: 'Cancel',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        const SizedBox(width: 10),
        PrimaryButton(
          text: isEditing ? 'Update' : 'Add',
          onPressed: onSubmitted,
        ),
      ],
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        // elevation: 0,
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
