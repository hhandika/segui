import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/services/providers/settings.dart';

/// Turns off animations below it when the app's reduce motion setting is
/// on, the same way the device setting does, so every widget that checks
/// [MediaQuery.disableAnimationsOf] honors both.
class ReduceMotionScope extends ConsumerWidget {
  const ReduceMotionScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool reduceMotion = ref.watch(reduceMotionProvider);
    if (!reduceMotion || MediaQuery.disableAnimationsOf(context)) return child;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child,
    );
  }
}
