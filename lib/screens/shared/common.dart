// Module for shared components
import 'package:file_selector/file_selector.dart';
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
      color: getSEGULBackgroundColor(context),
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
      color: getSEGULBackgroundColor(context),
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

  final XFile file;

  @override
  Widget build(BuildContext context) {
    final FileAssociation association = FileAssociation(file: file);
    return SvgPicture.asset(
      association.matchingIcon,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(
        Theme.of(context).colorScheme.primary.withAlpha(240),
        BlendMode.srcIn,
      ),
    );
  }
}
