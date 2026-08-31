import 'package:flutter/widgets.dart';

/// The existing SEGUI glyphs, using icons_plus only for its bundled fonts.
/// IconData is final in Flutter 3.47, so the package's subclasses cannot be used.
abstract final class SeguiIcons {
  static const dna = IconData(
    0xea94,
    fontFamily: 'LineAwesome',
    fontPackage: 'icons_plus',
  );

  static const dnaSelected = IconData(
    0xecb5,
    fontFamily: 'BoxIcons',
    fontPackage: 'icons_plus',
  );
}
