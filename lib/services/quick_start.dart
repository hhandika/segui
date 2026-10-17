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
    description: 'Add files, or a folder on desktop. The app finds every '
        'matching file in it.',
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

/// Tools with a feature guide in [category], or every tool when null,
/// in home screen order.
List<HomeTool> featureGuidesFor(ToolCategory? category) {
  return [
    for (final tool in homeTools)
      if (category == null || tool.category == category) tool,
  ];
}
