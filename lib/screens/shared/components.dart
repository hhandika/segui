// Module for shared components
import 'package:flutter/material.dart';
import 'package:segui/styles/decoration.dart';

class SettingDividers extends StatelessWidget {
  const SettingDividers({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      thickness: 2,
      height: 2,
      color: getSEGULBackgroundColor(context),
    );
  }
}
