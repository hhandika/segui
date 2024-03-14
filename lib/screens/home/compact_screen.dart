import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/screens/home/components/navigation.dart';
import 'package:segui/screens/home/components/pages.dart';
import 'package:segui/screens/settings/settings.dart';
import 'package:segui/styles/decoration.dart';

class CompactScreenView extends ConsumerWidget {
  const CompactScreenView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color? mainColor = getSEGULBackgroundColor(context);
    return Scaffold(
        appBar: AppBar(
          title: Text(pageTitles[ref.watch(tabSelectionProvider)]),
          elevation: 0,
          backgroundColor:
              ref.watch(tabSelectionProvider) == 0 ? null : mainColor,
          actions: const [
            SettingButtons(),
          ],
        ),
        backgroundColor:
            ref.watch(tabSelectionProvider) == 0 ? null : mainColor,
        body: SafeArea(
            child: Center(
          child: pages.elementAt(ref.watch(tabSelectionProvider)),
        )),
        bottomNavigationBar: const CompactScreenNavBar());
  }
}
