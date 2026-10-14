// Module for shared components
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/styles/decoration.dart';

class CommonDivider extends StatelessWidget {
  const CommonDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      thickness: 2,
      height: 2,
      color: getBorderColor(context),
    );
  }
}

class DrawerDivider extends StatelessWidget {
  const DrawerDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      thickness: 2,
      indent: 8,
      endIndent: 8,
    );
  }
}

class TopDivider extends StatelessWidget {
  const TopDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      thickness: 4,
      height: 4,
      color: getBorderColor(context),
    );
  }
}

class SecondaryMenuTile extends StatelessWidget {
  const SecondaryMenuTile({
    super.key,
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        title: Text(text, style: Theme.of(context).textTheme.labelLarge),
        onTap: onTap,
      ),
    );
  }
}

class SharedProgressIndicator extends StatelessWidget {
  const SharedProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 8,
      width: 8,
      child: CircularProgressIndicator(),
    );
  }
}

class FileIcon extends StatelessWidget {
  const FileIcon({
    super.key,
    required this.file,
  });

  final File file;

  @override
  Widget build(BuildContext context) {
    if (file.existsSync()) {
      return CostumFileIcon(
        iconColor: getIconColor(context),
        file: file,
      );
    } else {
      return const Icon(Icons.error_outline);
    }
  }
}

class PrimaryFileIcon extends StatelessWidget {
  const PrimaryFileIcon({super.key, required this.file, this.iconSize = 24});

  final File file;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return CostumFileIcon(
      iconColor: Theme.of(context).colorScheme.primary,
      file: file,
      iconSize: iconSize,
    );
  }
}

class CostumFileIcon extends StatelessWidget {
  const CostumFileIcon({
    super.key,
    required this.iconColor,
    required this.file,
    this.iconSize = 24,
  });

  final Color iconColor;
  final File file;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final FileAssociation association = FileAssociation(file: file);
    return SvgPicture.asset(
      association.matchingIconPath,
      width: iconSize,
      height: iconSize,
      colorFilter: ColorFilter.mode(
        iconColor,
        BlendMode.srcIn,
      ),
    );
  }
}

class FileErrorIcon extends StatelessWidget {
  const FileErrorIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8),
        child: SvgPicture.asset(
          'assets/images/error.svg',
          height: 80,
          colorFilter: ColorFilter.mode(
            getIconColor(context),
            BlendMode.srcIn,
          ),
        ));
  }
}

/// Rounded, outlined page section, the panel form of
/// [getContainerDecoration].
///
/// A [Material] rather than a decorated box: children are clipped to the
/// rounded corners with the outline drawn over them, and list tiles inside
/// keep their background and ink splashes.
class OutlinedPanel extends StatelessWidget {
  const OutlinedPanel({
    super.key,
    required this.child,
    this.padding,
    this.width,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: getContainerShape(context),
        clipBehavior: Clip.antiAlias,
        child:
            padding == null ? child : Padding(padding: padding!, child: child),
      ),
    );
  }
}
