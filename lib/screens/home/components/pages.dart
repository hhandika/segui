import 'package:flutter/material.dart';
import 'package:segui/screens/alignment/entry_page.dart';
import 'package:segui/screens/genomics/entry_page.dart';
import 'package:segui/screens/home/home.dart';
import 'package:segui/screens/sequence/entry_page.dart';

const List<Widget> pages = <Widget>[
  HomePage(),
  SeqReadPage(),
  AlignmentPage(),
  SequencePage(),
];

const List<String> pageTitles = <String>[
  'SEGUL GUI',
  'Genomic Sequence Tools',
  'Alignment Tools',
  'Sequence Tools',
];
