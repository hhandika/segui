import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:segui/providers/navigation.dart';
import 'package:segui/screens/home/components/faq.dart';
import 'package:segui/screens/home/components/quick_start.dart';
import 'package:segui/screens/home/large_screen.dart';
import 'package:segui/screens/home/compact_screen.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/utils.dart';
import 'package:segui/styles/decoration.dart';

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
    showLargeScreenView = isMediumScreen(context);
  }

  @override
  Widget build(BuildContext context) {
    return showLargeScreenView
        ? const LargeScreenView()
        : const SmallScreenView();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < mediumScreenSize;
    final bool isExpanded = screenHeight >= expandedScreenSize;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Center(
        child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            height: isExpanded ? screenHeight - 80 : null,
            decoration: isPhone ? null : getContainerDecoration(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                    child: SvgPicture.asset(
                      greetingIconPack,
                      height: 80,
                      colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.onSurface,
                          BlendMode.srcIn),
                    )),
                Text(greeting, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 40),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(height: 15),
                const QuickActionContainer(),
                const SizedBox(height: 30),
                const ResourceTiles(),
              ],
            )),
      ),
    );
  }
}

class QuickActionContainer extends ConsumerWidget {
  const QuickActionContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isExpandedScreen = screenWidth >= expandedScreenSize;
    return SizedBox(
        height: isExpandedScreen ? 140 : 240,
        width: isExpandedScreen ? 600 : 240,
        child: GridView.count(
          crossAxisCount: isExpandedScreen ? 4 : 2,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          children: [
            QuickActionButton(
              icon: Icons.compare_arrows,
              label: 'Concatenate Alignments',
              onTap: () {
                ref.read(tabSelectionProvider.notifier).setTab(2);
                ref
                    .read(alignmentOperationSelectionProvider.notifier)
                    .setOperation(AlignmentOperationType.concatenation);
              },
            ),
            QuickActionButton(
              icon: Icons.swap_horiz,
              label: 'Convert Alignments',
              onTap: () {
                ref.read(tabSelectionProvider.notifier).setTab(2);
                ref
                    .read(alignmentOperationSelectionProvider.notifier)
                    .setOperation(AlignmentOperationType.conversion);
              },
            ),
            QuickActionButton(
                icon: Icons.translate,
                label: 'Translate Sequences',
                onTap: () {
                  ref.read(tabSelectionProvider.notifier).setTab(3);
                  ref
                      .read(sequenceOperationSelectionProvider.notifier)
                      .setOperation(SequenceOperationType.translation);
                }),
            QuickActionButton(
              icon: Icons.bar_chart,
              label: 'Summarize Sequences',
              onTap: () {
                ref.read(tabSelectionProvider.notifier).setTab(2);
                ref
                    .read(alignmentOperationSelectionProvider.notifier)
                    .setOperation(AlignmentOperationType.summary);
              },
            ),
          ],
        ));
  }
}

class ResourceTiles extends StatelessWidget {
  const ResourceTiles({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.help_outline_outlined,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              'FAQ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurface),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => const FaqPage())),
          ),
          ListTile(
            leading: Icon(Icons.speed_outlined,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text('Quick start',
                style: Theme.of(context).textTheme.titleMedium),
            trailing: Icon(Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurface),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const QuickStartPage())),
          ),
          // ListTile(
          //   leading: Icon(Icons.school_outlined,
          //       color: Theme.of(context).colorScheme.onSurface),
          //   title: Text('Learning resources',
          //       style: Theme.of(context).textTheme.titleMedium),
          //   trailing: Icon(
          //     Icons.arrow_forward_ios,
          //     color: Theme.of(context).colorScheme.onSurface,
          //   ),
          //   onTap: () {
          //     Navigator.of(context).push(MaterialPageRoute(
          //         builder: (context) => const LearningResourcesPage()));
          //   },
          // ),
          ListTile(
              leading: Icon(Icons.description_outlined,
                  color: Theme.of(context).colorScheme.onSurface),
              title: Text(
                'Documentation',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.onSurface),
              onTap: () => launchSegulDocUrl())
        ],
      ),
    );
  }
}
