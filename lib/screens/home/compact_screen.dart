import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/screens/home/components/navigation.dart';
import 'package:segui/screens/home/components/pages.dart';
import 'package:segui/screens/home/more_page.dart';
import 'package:segui/screens/shared/tool_search.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

class CompactScreenView extends ConsumerWidget {
  const CompactScreenView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color? mainColor = getSEGULBackgroundColor(context);
    final int tab = ref.watch(tabSelectionProvider);
    final bool isMore = tab == moreTab;
    return Scaffold(
        appBar: AppBar(
          title: Text(isMore ? 'More' : pageTitles[tab]),
          elevation: SeguiElevation.none,
          backgroundColor: tab == 0 ? null : mainColor,
          actions: [
            // Home has its own tool search.
            // Settings live under More in the bottom bar.
            if (tab != 0 && !isMore) const GlobalToolSearch(),
          ],
        ),
        backgroundColor: tab == 0 ? null : mainColor,
        body: SafeArea(
            child: Center(
          child: isMore ? const MorePage() : pages[tab],
        )),
        bottomNavigationBar: const CompactScreenNavBar());
  }
}
