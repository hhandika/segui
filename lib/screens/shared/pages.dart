import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/info.dart';
import 'package:segui/screens/shared/io.dart';
import 'package:segui/screens/viewers/common.dart';
import 'package:segui/services/io.dart';
import 'package:segui/services/utils.dart';
import 'package:segui/styles/decoration.dart';

/// Standard screen size for medium devices (tablets, small laptops, etc.)
/// based on the Material Design specification.
/// https://material.io/blog/material-you-large-screens
const mdMediumScreenSize = 840;

/// A page that shows a shared operation.
/// to switch layout between compact and expanded screen.
class SharedOperationPage extends StatelessWidget {
  const SharedOperationPage({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      if (constraints.maxWidth > mdMediumScreenSize) {
        return Row(children: [
          AppPageView(child: child),
          const Expanded(
            child: IOExpandedScreen(),
          ),
        ]);
      } else {
        return IOCompactScreen(child: child);
      }
    });
  }
}

class FormView extends StatelessWidget {
  const FormView({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }
}

class AppPageView extends StatelessWidget {
  const AppPageView({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final windowWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        height: double.infinity,
        decoration: getContainerDecoration(context),
        constraints: BoxConstraints(maxWidth: windowWidth > 1800 ? 600 : 500),
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class IOExpandedScreen extends StatefulWidget {
  const IOExpandedScreen({super.key});

  @override
  State<IOExpandedScreen> createState() => _IOExpandedScreenState();
}

class _IOExpandedScreenState extends State<IOExpandedScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: getContainerDecoration(context),
          child: const DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: TabBar(
                tabs: [
                  Tab(
                    icon: Icon(Icons.input),
                  ),
                  Tab(
                    icon: Icon(Icons.output),
                  ),
                ],
              ),
              body: TabBarView(
                children: [
                  InputScreen(),
                  OutputScreen(),
                ],
              ),
            ),
          ),
        ));
  }
}

class IOCompactScreen extends StatefulWidget {
  const IOCompactScreen({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<IOCompactScreen> createState() => _IOCompactScreenState();
}

class _IOCompactScreenState extends State<IOCompactScreen> {
  @override
  Widget build(BuildContext context) {
    return TabContainer(
        child: DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: const TabBar(
          tabs: [
            Tab(
              icon: Icon(Icons.play_circle_outline),
            ),
            Tab(
              icon: Icon(Icons.input),
            ),
            Tab(
              icon: Icon(Icons.output),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: widget.child,
            ),
            const InputScreen(),
            const OutputScreen(),
          ],
        ),
      ),
    ));
  }
}

class InputScreen extends ConsumerWidget {
  const InputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: double.infinity,
      child: ref.watch(fileInputProvider).when(
            data: (data) => data.isEmpty
                ? const EmptyScreen(
                    title: 'No input files selected.',
                    description:
                        'Select one or more input files to start the analysis.',
                  )
                : InputFileList(files: data),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (err, stack) => Text(err.toString()),
          ),
    );
  }
}

class InputFileList extends ConsumerWidget {
  const InputFileList({super.key, required this.files});

  final List<SegulInputFile> files;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IOListContainer(
        title: 'Input Files',
        infoText: 'List of input files to be analyzed.',
        child: ListView.separated(
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            indent: 36,
            endIndent: 40,
          ),
          shrinkWrap: true,
          itemCount: files.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final data = files[index];
            final association = FileAssociation(file: data.file);
            return ListTile(
              minVerticalPadding: 2,
              leading: FileIcon(file: data.file),
              title: FileIOTitle(file: data.file),
              subtitle: FileIOSubtitle(file: data.file),
              trailing: IconButton(
                tooltip: 'Remove file',
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  ref.read(fileInputProvider.notifier).removeFromList(data);
                },
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FileViewer(
                      file: data.file,
                      type: association.commonFileTYpe,
                    ),
                  ),
                );
              },
            );
          },
        ));
  }
}

class OutputScreen extends ConsumerWidget {
  const OutputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: double.infinity,
      child: ref.watch(fileOutputProvider).when(
            data: (data) {
              final files = getFiles(data);
              return data.directory == null
                  ? const EmptyScreen(
                      title: 'No output directory selected.',
                      description:
                          'Select an output directory to store output files.',
                    )
                  : OutputFileList(files: files);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (err, stack) => Text(err.toString()),
          ),
    );
  }

  List<File> getFiles(SegulOutputFile data) {
    if (data.newFiles.isNotEmpty) {
      List<File> files = [];
      files.addAll(data.newFiles);
      files.addAll(data.oldFiles);
      return files;
    } else {
      return data.oldFiles;
    }
  }
}

class OutputFileList extends StatelessWidget {
  const OutputFileList({
    super.key,
    required this.files,
  });

  final List<File> files;

  @override
  Widget build(BuildContext context) {
    return IOListContainer(
      title: 'Output Files',
      infoText: 'List of files in the output directory. '
          'Newly created files are marked with a new icon. '
          'Click on a file to view its content.',
      child: files.isEmpty
          ? const EmptyScreen(
              title: 'No output files found.',
              description: 'Run the analysis to generate output files.',
            )
          : ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                return OutputFileTiles(
                  isOldFile: true,
                  file: file,
                );
              },
            ),
    );
  }
}

class OutputFileTiles extends StatelessWidget {
  const OutputFileTiles({
    super.key,
    required this.isOldFile,
    required this.file,
  });

  final bool isOldFile;
  final File file;

  @override
  Widget build(BuildContext context) {
    final FileAssociation association = FileAssociation(file: file);
    return ListTile(
      minVerticalPadding: 2,
      leading: FileIcon(file: file),
      title: isOldFile
          ? FileIOTitle(file: file)
          : RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  WidgetSpan(
                    child: FileIOTitle(file: file),
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.bottom,
                    child: Icon(
                      Icons.fiber_new_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              )),
      subtitle: FileIOSubtitle(file: file),
      trailing: OutputActionMenu(file: file),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FileViewer(
              file: file,
              type: association.commonFileTYpe,
            ),
          ),
        );
      },
    );
  }
}

class OutputActionMenu extends StatelessWidget {
  const OutputActionMenu({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = isPhoneScreen(context);
    return isSmallScreen
        ? IconButton(
            icon: Icon(Icons.adaptive.more_rounded),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CommonShareTile(file: file),
                        const SizedBox(height: 16),
                        CommonDeleteTile(file: file),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              );
            },
          )
        : PopupMenuButton<PopupMenuItem>(
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  child: CommonShareTile(file: file),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  child: CommonDeleteTile(file: file),
                ),
              ];
            },
          );
  }
}

class IOListContainer extends StatefulWidget {
  const IOListContainer({
    super.key,
    required this.title,
    required this.infoText,
    required this.child,
  });

  final String title;
  final String infoText;
  final Widget child;
  @override
  State<IOListContainer> createState() => _IOListContainerState();
}

class _IOListContainerState extends State<IOListContainer> {
  bool isShowingInfo = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              WidgetSpan(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              WidgetSpan(
                child: IconButton(
                  icon: Icon(
                    size: 18,
                    Icons.info_outline,
                    color: Theme.of(context).disabledColor,
                  ),
                  onPressed: () {
                    setState(() {
                      isShowingInfo = !isShowingInfo;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        isShowingInfo
            ? SharedInfoForm(
                description: widget.infoText,
                isShowingInfo: isShowingInfo,
                onClosed: () {
                  setState(() {
                    isShowingInfo = false;
                  });
                },
                onExpanded: () {
                  setState(() {
                    isShowingInfo = true;
                  });
                },
              )
            : const SizedBox.shrink(),
        Flexible(
          child: widget.child,
        )
      ],
    );
  }
}

class TabContainer extends StatelessWidget {
  const TabContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: getContainerDecoration(context),
          child: child,
        ));
  }
}

class EmptyScreen extends StatelessWidget {
  const EmptyScreen({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          emptyDirIcon,
          height: 80,
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.primary.withAlpha(120),
            BlendMode.srcIn,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
