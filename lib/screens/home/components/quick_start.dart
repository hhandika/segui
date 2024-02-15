import 'package:flutter/material.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/utils.dart';
import 'package:segui/styles/decoration.dart';

class QuickStartPage extends StatefulWidget {
  const QuickStartPage({super.key});

  @override
  State<QuickStartPage> createState() => _QuickStartPageState();
}

class _QuickStartPageState extends State<QuickStartPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Quick Start'),
          backgroundColor: getSEGULBackgroundColor(context),
        ),
        backgroundColor: getSEGULBackgroundColor(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: ListView(
              children: const [
                CardTitle(title: 'Task Selection'),
                HelpContent(
                  text: 'Use the navigation bar '
                      'to select the task category you want to perform. '
                      'For instance, to perform genomic analysis, '
                      'click on the Genomics tab. '
                      'This will take you to the Genomic Analysis page. '
                      'From there, use the top dropdown menu to '
                      'select the task you want to perform. ',
                ),
                CardTitle(title: 'Input'),
                HelpContent(
                  text: 'Use the input form to provide the required data. '
                      'On mobile, you can only add files. '
                      'On desktop, you can add files or a directory. '
                      'The add files option allows you to select multiple files. '
                      ' When you add a directory,'
                      'the app will find all matching files '
                      'in the directory. Recursive search is not yet supported.',
                ),
                CardTitle(title: 'Output'),
                HelpContent(
                  text: 'On desktop, you can select the output directory. '
                      'On mobile, the app will use the default app directory. '
                      'The app will create a new directory ',
                ),
                CardTitle(title: 'Parameters'),
                HelpContent(
                  text:
                      'Use the parameter form to provide the required parameters. '
                      'The parameters are specific to the task you are performing. '
                      'Not all tasks require parameters. ',
                ),
                CardTitle(title: 'Run'),
                HelpContent(
                  text: 'Click the Run button to start the task. '
                      ' Keep the same screen open until the task is complete. ',
                ),
                CardTitle(title: 'Results'),
                HelpContent(
                  text: 'The app will display the results of the task '
                      'in the output tab. '
                      'This tab can contain other files '
                      'in the output directory. '
                      'The result from the current task will be highlighted '
                      'with a "new" icon.',
                ),
                LaunchDocButton(),
                SizedBox(height: 8),
              ],
            ),
          ),
        ));
  }
}

class LaunchDocButton extends StatelessWidget {
  const LaunchDocButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: () {
          launchSegulDocUrl();
        },
        child: const Text('Learn more'));
  }
}

class HelpContent extends StatelessWidget {
  const HelpContent({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: getContainerDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
