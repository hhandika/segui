import 'package:flutter/material.dart';

class NavigationTarget {
  const NavigationTarget({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final Widget icon;
  final Widget selectedIcon;
}

const List<NavigationTarget> navigationTargets = [
  NavigationTarget(
    label: 'Home',
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
  ),
  NavigationTarget(
    label: 'Concat',
    icon: Icon(Icons.compare_arrows_outlined),
    selectedIcon: Icon(Icons.compare_arrows),
  ),
  NavigationTarget(
    label: 'Convert',
    icon: Icon(Icons.construction),
    selectedIcon: Icon(Icons.construction_outlined),
  ),
  NavigationTarget(
    label: 'Summarize',
    icon: Icon(Icons.bar_chart_outlined),
    selectedIcon: Icon(Icons.bar_chart),
  ),
  NavigationTarget(
    label: 'Translate',
    icon: Icon(Icons.translate_outlined),
    selectedIcon: Icon(Icons.translate),
  ),
];
