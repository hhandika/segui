import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/screens/shared/tool_layout.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/styles/decoration.dart';

const double _searchBarWidth = 280;

/// App bar search that finds and opens any SEGUI tool.
///
/// Shows a search bar on wide screens and a search button on phones.
class GlobalToolSearch extends StatelessWidget {
  const GlobalToolSearch({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isCompact = isPhoneScreen(context);
    return SearchAnchor(
      viewHintText: 'Search tools, e.g. NEXUS or rename',
      isFullScreen: isCompact,
      viewBackgroundColor: Theme.of(context).colorScheme.surface,
      viewConstraints: const BoxConstraints(
        minWidth: 360,
        maxWidth: 480,
        maxHeight: 520,
      ),
      builder: (context, controller) {
        if (isCompact) {
          return IconButton(
            tooltip: 'Search tools',
            icon: const Icon(Icons.search),
            onPressed: controller.openView,
          );
        }
        return SizedBox(
          width: _searchBarWidth,
          child: SearchBar(
            controller: controller,
            hintText: 'Search tools',
            elevation: const WidgetStatePropertyAll(0),
            // A lighter tint of the app bar instead of the default grey.
            backgroundColor: WidgetStatePropertyAll(
              Color.lerp(
                getSEGULBackgroundColor(context),
                Theme.of(context).colorScheme.surface,
                0.6,
              ),
            ),
            side: WidgetStatePropertyAll(
              BorderSide(color: getBorderColor(context)),
            ),
            constraints: const BoxConstraints(minHeight: 44),
            leading: const Icon(Icons.search),
            onTap: controller.openView,
            onChanged: (_) => controller.openView(),
          ),
        );
      },
      suggestionsBuilder: (context, controller) {
        final List<HomeTool> tools =
            homeTools.where((tool) => tool.matches(controller.text)).toList();
        if (tools.isEmpty) {
          return [
            ListTile(
              title: Text('No tools match "${controller.text.trim()}".'),
            ),
          ];
        }
        return [
          for (final tool in tools)
            ToolSearchResult(tool: tool, controller: controller),
        ];
      },
    );
  }
}

/// One search match; opening it closes the search and shows the tool.
class ToolSearchResult extends ConsumerWidget {
  const ToolSearchResult({
    super.key,
    required this.tool,
    required this.controller,
  });

  final HomeTool tool;
  final SearchController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ToolDescriptionTooltip(
      tool: tool,
      child: ListTile(
        leading: ToolIconTile(tool: tool, isSelected: false),
        title: Text(tool.title),
        subtitle: Text(
          '${tool.category.label} · ${tool.description}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          controller.closeView('');
          ref.read(homeToolNavigatorProvider).open(tool);
        },
      ),
    );
  }
}
