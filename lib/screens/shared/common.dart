// Module for shared components
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:segui/services/io.dart';
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
    final FileAssociation association = FileAssociation(file: file);
    if (file.existsSync()) {
      return SvgPicture.asset(
        association.matchingIcon,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          getIconColor(context),
          BlendMode.srcIn,
        ),
      );
    } else {
      return const Icon(Icons.error_outline);
    }
  }
}
