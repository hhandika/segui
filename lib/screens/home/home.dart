import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/home/components/citation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/screens/home/components/faq.dart';
import 'package:segui/screens/home/components/greeting.dart';
import 'package:segui/screens/home/components/illustration.dart';
import 'package:segui/screens/home/components/quick_start.dart';
import 'package:segui/screens/home/components/shared_files.dart';
import 'package:segui/screens/home/components/tool_catalog.dart';
import 'package:segui/screens/home/components/workflows.dart';
import 'package:segui/screens/home/large_screen.dart';
import 'package:segui/screens/home/compact_screen.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/utils.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

class SegulHome extends StatefulWidget {
  const SegulHome({super.key});

  @override
  State<SegulHome> createState() => _SegulHomeState();
}

class _SegulHomeState extends State<SegulHome> {
  late bool showLargeScreenView;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Show large screen view for screen width >= 600 dp
    // which is the recommended screen size for tablets.
    showLargeScreenView = isTabletScreen(context);
  }

  @override
  Widget build(BuildContext context) {
    return showLargeScreenView
        ? const LargeScreenView()
        : const CompactScreenView();
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Match container decoration with layout changes
    final isSmallScreen = !isTabletScreen(context);
    final HomeView view = ref.watch(homeViewProvider);
    final double verticalPadding =
        isSmallScreen ? SeguiSpacing.md : SeguiSpacing.xxl;
    return Padding(
      padding: const EdgeInsets.all(SeguiSpacing.md),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isSmallScreen ? null : getContainerDecoration(context),
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? SeguiSpacing.md : SeguiSpacing.xxl,
              vertical: verticalPadding,
            ),
            child: Center(
              child: ConstrainedBox(
                // Fill the screen height so the resource links stay at the
                // bottom when the content is short.
                constraints: BoxConstraints(
                  maxWidth: maxGridContentWidth,
                  minHeight: constraints.maxHeight - verticalPadding * 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const HomeHeader(),
                        const SharedFilesBanner(),
                        const SizedBox(height: SeguiSpacing.xl),
                        Wrap(
                          spacing: SeguiSpacing.xl,
                          runSpacing: SeguiSpacing.lg,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const HomeViewToggle(),
                            if (view == HomeView.tools)
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                    maxWidth: SeguiContentWidth.card),
                                child: ToolSearchField(
                                  controller: _searchController,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: SeguiSpacing.xxl),
                        switch (view) {
                          HomeView.tools =>
                            ToolCatalog(query: _searchController.text),
                          HomeView.workflows => const WorkflowPanel(),
                        },
                        const SizedBox(height: SeguiSpacing.xl),
                      ],
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // The sketch's ground line separates the footer.
                        HomeIllustration(),
                        SizedBox(height: SeguiSpacing.xs),
                        ResourceLinks(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GreetingTime time = GreetingTime.of(DateTime.now());
    return Row(
      children: [
        GreetingIllustration(time: time),
        const SizedBox(width: SeguiSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'What would you like to work on?',
                style: theme.textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Switches the home screen between the tool catalog and workflows.
class HomeViewToggle extends ConsumerWidget {
  const HomeViewToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<HomeView>(
      segments: [
        ButtonSegment(
          value: HomeView.tools,
          icon: const Icon(Icons.apps),
          label: Text('All tools (${homeTools.length})'),
        ),
        const ButtonSegment(
          value: HomeView.workflows,
          icon: Icon(Icons.route_outlined),
          label: Text('Workflows'),
        ),
      ],
      selected: {ref.watch(homeViewProvider)},
      onSelectionChanged: (selection) =>
          ref.read(homeViewProvider.notifier).setView(selection.first),
    );
  }
}

class ToolSearchField extends StatelessWidget {
  const ToolSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search tools, e.g. NEXUS or rename',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        isDense: true,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SeguiRadius.full),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class ResourceLinks extends StatelessWidget {
  const ResourceLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: SeguiSpacing.md,
      runSpacing: SeguiSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'New to SEGUI?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        TextButton.icon(
          icon: const Icon(Icons.speed_outlined),
          label: const Text('Quick start'),
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const QuickStartPage())),
        ),
        TextButton.icon(
          icon: const Icon(Icons.help_outline_outlined),
          label: const Text('FAQ'),
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => const FaqPage())),
        ),
        TextButton.icon(
          icon: const Icon(Icons.description_outlined),
          label: const Text('Documentation'),
          onPressed: launchSegulDocUrl,
        ),
        const CiteSegulButton(),
      ],
    );
  }
}
