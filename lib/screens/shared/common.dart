// Module for shared components
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

class CommonDivider extends StatelessWidget {
  const CommonDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      thickness: SeguiStroke.regular,
      height: SeguiStroke.regular,
      color: getBorderColor(context),
    );
  }
}

class DrawerDivider extends StatelessWidget {
  const DrawerDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      thickness: SeguiStroke.regular,
      indent: SeguiSpacing.md,
      endIndent: SeguiSpacing.md,
    );
  }
}

class TopDivider extends StatelessWidget {
  const TopDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      thickness: SeguiStroke.thick,
      height: SeguiStroke.thick,
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
      padding: const EdgeInsets.only(left: SeguiSpacing.xxs),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SeguiRadius.sm),
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
      height: SeguiControlSize.iconSmall,
      width: SeguiControlSize.iconSmall,
      child: CircularProgressIndicator(strokeWidth: SeguiStroke.regular),
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
        padding: const EdgeInsets.all(SeguiSpacing.md),
        child: SvgPicture.asset(
          'assets/images/error.svg',
          height: SeguiControlSize.illustration,
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

/// Widest a dialog from [showResponsiveSheet] grows.
const double responsiveDialogMaxWidth = 560;

/// Shows [builder] as a bottom sheet on phones and as a dialog on larger
/// screens.
Future<T?> showResponsiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  if (isPhoneScreen(context)) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SafeArea(child: builder(context)),
    );
  }
  return showDialog<T>(
    context: context,
    builder: (context) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: responsiveDialogMaxWidth),
        child: builder(context),
      ),
    ),
  );
}

/// Title, message, and actions laid out to read well in both a dialog and
/// a bottom sheet from [showResponsiveSheet].
class SheetContent extends StatelessWidget {
  const SheetContent({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final bool isCompact = isPhoneScreen(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(SeguiSpacing.xxl,
          isCompact ? 0 : SeguiSpacing.xxl, SeguiSpacing.xxl, SeguiSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: SeguiSpacing.xl),
          Flexible(child: SingleChildScrollView(child: child)),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: SeguiSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: SeguiSpacing.md,
                runSpacing: SeguiSpacing.md,
                children: actions,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
