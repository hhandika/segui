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
    label: 'Genomics',
    icon: Icon(Icons.factory_outlined),
    selectedIcon: Icon(Icons.factory_rounded),
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

const List<NavigationDrawerDestination> navigationDrawerTargets = [
  NavigationDrawerDestination(
    label: Text('Home'),
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
  ),
  NavigationDrawerDestination(
    label: Text('Genomics'),
    icon: Icon(Icons.factory_outlined),
    selectedIcon: Icon(Icons.factory_rounded),
  ),
  NavigationDrawerDestination(
    label: Text('Alignments'),
    icon: Icon(Icons.sync_alt_outlined),
    selectedIcon: Icon(Icons.sync_alt_rounded),
  ),
  NavigationDrawerDestination(
    label: Text('Sequences'),
    icon: Icon(LineAwesome.dna_solid),
    selectedIcon: Icon(BoxIcons.bx_dna),
  ),
];
