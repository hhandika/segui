import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:segui/screens/home/components/illustration.dart';
import 'package:segui/screens/shared/info.dart';
import 'package:segui/screens/shared/tool_layout.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/services/utils.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

/// Tool page that pairs the tool form with tool switching and file lists.
///
/// Wide pages show the tool list, the form, and the file panel side by
/// side. Narrower pages drop the tool list for a switcher in the header,
/// and compact pages open the files from the header instead.
class SharedOperationPage extends StatelessWidget {
  const SharedOperationPage({
    super.key,
    required this.operation,
    required this.child,
  });

  /// Selected [GenomicOperationType], [AlignmentOperationType], or
  /// [SequenceOperationType].
  final Enum operation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final HomeTool tool = homeToolFor(operation);
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      final double width = constraints.maxWidth;
      if (width <= expandedScreenSize) {
        return ToolWorkspace(
          tool: tool,
          showSwitcher: true,
          isCompact: true,
          child: child,
        );
      }
      final bool showToolList = width >= toolListPageWidth;
      return Padding(
        padding: const EdgeInsets.all(SeguiSpacing.md),
        // Outlined like the home screen; the clip keeps the side panels
        // inside the rounded border.
        child: OutlinedPanel(
          child: Row(
            children: [
              if (showToolList)
                ToolListPanel(category: tool.category, selected: tool),
              Expanded(
                child: ToolWorkspace(
                  tool: tool,
                  showSwitcher: !showToolList,
                  isCompact: false,
                  child: child,
                ),
              ),
              FileSidePanel(
                width: filePanelWidth(width, hasToolList: showToolList),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Tool header above the tool form.
class ToolWorkspace extends StatelessWidget {
  const ToolWorkspace({
    super.key,
    required this.tool,
    required this.showSwitcher,
    required this.isCompact,
    required this.child,
  });

  final HomeTool tool;
  final bool showSwitcher;
  final bool isCompact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolHeader(
          tool: tool,
          showSwitcher: showSwitcher,
          isCompact: isCompact,
        ),
        Expanded(child: child),
      ],
    );
  }
}

class IOListContainer extends StatefulWidget {
  const IOListContainer({
    super.key,
    required this.title,
    required this.infoText,
    required this.child,
  });

  final String title;
  final String infoText;
  final Widget child;
  @override
  State<IOListContainer> createState() => _IOListContainerState();
}

class _IOListContainerState extends State<IOListContainer> {
  bool isShowingInfo = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: SeguiSpacing.md),
        RichText(
          text: TextSpan(
            children: [
              WidgetSpan(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              WidgetSpan(
                child: IconButton(
                  icon: Icon(
                    size: SeguiControlSize.iconSmall,
                    Icons.info_outline,
                    color: Theme.of(context).disabledColor,
                  ),
                  onPressed: () {
                    setState(() {
                      isShowingInfo = !isShowingInfo;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SeguiSpacing.md),
        isShowingInfo
            ? SharedInfoForm(
                description: widget.infoText,
                isShowingInfo: isShowingInfo,
                onClosed: () {
                  setState(() {
                    isShowingInfo = false;
                  });
                },
                onExpanded: () {
                  setState(() {
                    isShowingInfo = true;
                  });
                },
              )
            : const SizedBox.shrink(),
        Flexible(
          child: widget.child,
        )
      ],
    );
  }
}

class EmptyScreen extends StatelessWidget {
  const EmptyScreen({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SadGull(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SeguiSpacing.xxl),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: SeguiSpacing.xxl),
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            )),
      ],
    );
  }
}

/// The SEGUL gull slumped and teary, shown when a list is empty.
class SadGull extends StatelessWidget {
  const SadGull({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SvgPicture(
        SvgAssetLoader(
          emptyDirIcon,
          colorMapper: HomeIllustrationColors(
            line: colors.onSurfaceVariant,
            // Container tones go muddy in dark mode, as in the greeting.
            accent: colors.brightness == Brightness.dark
                ? colors.tertiary
                : colors.tertiaryContainer,
            fill: colors.surfaceContainerLowest,
          ),
        ),
        height: SeguiControlSize.illustrationLarge,
      ),
    );
  }
}
