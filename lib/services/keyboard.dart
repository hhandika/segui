import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Modifier keys as the running platform names and uses them: Cmd and
/// Option on Apple platforms, Ctrl and Alt elsewhere.
abstract final class PlatformKeys {
  static bool get isApple =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// The key held for shortcuts such as zooming and adding to a selection.
  static String get primaryLabel => isApple ? 'Cmd' : 'Ctrl';

  /// The key held with the arrows to switch files.
  static String get altLabel => isApple ? 'Option' : 'Alt';

  /// Whether [primaryLabel]'s key is down.
  static bool get isPrimaryPressed {
    final HardwareKeyboard keyboard = HardwareKeyboard.instance;
    return isApple ? keyboard.isMetaPressed : keyboard.isControlPressed;
  }
}
