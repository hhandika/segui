import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/alignment/entry_page.dart';
import 'package:segui/screens/genomics/entry_page.dart';
import 'package:segui/screens/home/home.dart';
import 'package:segui/screens/sequence/entry_page.dart';
import 'package:segui/screens/tree/entry_page.dart';

const List<Widget> pages = <Widget>[
  HomePage(),
  GenomicPage(),
  AlignmentPage(),
  SequencePage(),
  TreePage(),
];

/// Tab index of Trees. Phones open it from More, not the bottom bar.
const int treeTab = 4;

/// Tab index of More, which only phones have, after the tool tabs.
const int moreTab = 5;

/// [tab] on screens without a More tab, which open Home instead.
int toolTab(int tab) => tab < pages.length ? tab : 0;

const List<String> pageTitles = <String>[
  'SEGUL GUI',
  'Genomic Sequence Tools',
  'Alignment Tools',
  'Sequence Tools',
  'Tree Tools',
];
