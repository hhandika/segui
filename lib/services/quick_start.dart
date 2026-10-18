import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/styles/segui_icons.dart';

/// A step in the quick start guide. Every tool follows the same steps.
class QuickStartStep {
  const QuickStartStep({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

const List<QuickStartStep> quickStartSteps = [
  QuickStartStep(
    title: 'Pick a tool',
    description: 'Choose a tool on the home screen, or from Genomics, '
        'Alignments, or Sequences in the navigation.',
    icon: Icons.apps,
  ),
  QuickStartStep(
    title: 'Add files',
    description: 'Add files, a folder, or an archive. The app keeps only '
        'files that match the tool.',
    icon: SeguiIcons.inputFolderOutlined,
  ),
  QuickStartStep(
    title: 'Set options',
    description: 'Pick the input format, data type, and any options the tool '
        'needs. Most have defaults.',
    icon: Icons.tune,
  ),
  QuickStartStep(
    title: 'Run',
    description: 'Press Run and keep the page open until the task finishes.',
    icon: Icons.play_arrow_rounded,
  ),
  QuickStartStep(
    title: 'Open results',
    description: 'New files are marked in the output list. Open, view, or '
        'share them from there.',
    icon: SeguiIcons.outputFolderOutlined,
  ),
];

/// Platforms with their own ways to add input files.
enum InputPlatform {
  desktop('On desktop'),
  android('On Android'),
  ios('On iPhone and iPad');

  const InputPlatform(this.label);

  final String label;

  static InputPlatform get current {
    if (Platform.isAndroid) {
      return InputPlatform.android;
    }
    if (Platform.isIOS) {
      return InputPlatform.ios;
    }
    return InputPlatform.desktop;
  }

  /// Phones and tablets copy picked files into the app first.
  bool get isMobile => this != InputPlatform.desktop;
}

/// A way to add input files, named after its picker button.
class InputGuideline {
  const InputGuideline({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

const InputGuideline _archiveGuideline = InputGuideline(
  title: 'Open archive',
  description: 'Pick one .zip or .tar.gz file. SEGUI extracts it and keeps '
      'the matching files.',
  icon: Icons.folder_zip_outlined,
);

/// Ways to add input files on [platform], most useful first.
List<InputGuideline> inputGuidelinesFor(InputPlatform platform) {
  return switch (platform) {
    InputPlatform.desktop => const [
        InputGuideline(
          title: 'Browse files',
          description: 'Pick files, or drag them onto the input area.',
          icon: Icons.note_add_outlined,
        ),
        InputGuideline(
          title: 'Browse folder',
          description: 'Adds every matching file in a folder and its '
              'subfolders. You can drop folders too.',
          icon: Icons.create_new_folder_outlined,
        ),
        _archiveGuideline,
      ],
    InputPlatform.android => const [
        InputGuideline(
          title: 'Browse files',
          description: 'For a few files. Android copies each one into SEGUI '
              'first.',
          icon: Icons.note_add_outlined,
        ),
        InputGuideline(
          title: 'Browse folder',
          description: 'For many files. SEGUI copies the matching files and '
              'counts them. Tap ✕ to stop.',
          icon: Icons.create_new_folder_outlined,
        ),
        InputGuideline(
          title: 'Open archive',
          description: 'For the largest datasets. Only one file is copied, '
              'then SEGUI extracts it.',
          icon: Icons.folder_zip_outlined,
        ),
        InputGuideline(
          title: 'Use shared files',
          description: 'Share files or an archive to SEGUI from another app, '
              'then pick them in the tool.',
          icon: Icons.move_to_inbox_outlined,
        ),
      ],
    InputPlatform.ios => const [
        InputGuideline(
          title: 'Browse files',
          description: 'For a few files. iOS copies each one into SEGUI '
              'first.',
          icon: Icons.note_add_outlined,
        ),
        InputGuideline(
          title: 'Browse folder',
          description: 'For many files. SEGUI opens the folder in place, '
              'without copying.',
          icon: Icons.create_new_folder_outlined,
        ),
        _archiveGuideline,
        InputGuideline(
          title: 'SEGUI folder',
          description: 'Copy data into On My iPhone › SEGUI › inputs in the '
              'Files app, then add it in the tool.',
          icon: Icons.snippet_folder_outlined,
        ),
        InputGuideline(
          title: 'Use shared files',
          description: 'Open or share files with SEGUI from another app, '
              'then pick them in the tool.',
          icon: Icons.move_to_inbox_outlined,
        ),
      ],
  };
}

/// Advice for large inputs on phones and tablets.
const String mobileInputTip = 'For more than about 500 files, use a folder '
    'or an archive instead of picking files. Clearing the inputs deletes '
    'the copies SEGUI made.';

/// Tools with a feature guide in [category], or every tool when null,
/// in home screen order.
List<HomeTool> featureGuidesFor(ToolCategory? category) {
  return [
    for (final tool in homeTools)
      if (category == null || tool.category == category) tool,
  ];
}
