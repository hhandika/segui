import 'package:flutter/material.dart';

BoxDecoration getContainerDecoration(BuildContext context) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    color: Theme.of(context).colorScheme.surface,
  );
}

Color? getSEGULBackgroundColor(BuildContext context) {
  return Color.lerp(Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.surface, 0.9);
}
