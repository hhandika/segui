import 'package:flutter/material.dart';

BoxDecoration getContainerDecoration(BuildContext context) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    color: Theme.of(context).colorScheme.surface,
  );
}
