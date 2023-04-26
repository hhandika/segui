import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

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
    label: 'Raw',
    icon: Icon(Icons.factory_outlined),
    selectedIcon: Icon(Icons.factory_rounded),
  ),
  NavigationTarget(
    label: 'Contigs',
    icon: Icon(Icons.segment_outlined),
    selectedIcon: Icon(Icons.segment_rounded),
  ),
  NavigationTarget(
    label: 'Alignments',
    icon: Icon(Icons.sync_alt_outlined),
    selectedIcon: Icon(Icons.sync_alt_rounded),
  ),
  NavigationTarget(
    label: 'Sequences',
    icon: Icon(LineAwesome.dna_solid),
    selectedIcon: Icon(BoxIcons.bx_dna),
  ),
];
