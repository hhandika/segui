// Module for shared components
import 'package:flutter/material.dart';
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
