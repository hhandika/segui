import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:segui/providers/io.dart';
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
            return ListTile(
              minVerticalPadding: 2,
              leading: const Icon(Icons.attach_file_outlined),
              title: Text(data.file.name),
              subtitle: FutureBuilder<String>(
                future: getFileSize(data.file),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(snapshot.data!);
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  ref.read(fileInputProvider.notifier).removeFile(data);
                },
              ),
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
            data: (data) => data.directory == null
                ? const EmptyScreen(
                    title: 'No output directory selected.',
                    description:
                        'Select an output directory to store output files.',
                  )
                : OutputFileList(files: data),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (err, stack) => Text(err.toString()),
          ),
    );
  }
}

class OutputFileList extends StatelessWidget {
  const OutputFileList({
    super.key,
    required this.files,
  });

  final SegulOutputFile files;

  @override
  Widget build(BuildContext context) {
    return IOListContainer(
        title: 'Output Files',
        child: ListView(children: [
          ...files.newFiles
              .map((e) => OutputFileTiles(isOldFile: false, file: e)),
          ...files.oldFiles
              .map((e) => OutputFileTiles(isOldFile: true, file: e)),
        ]));
  }
}

class OutputFileTiles extends StatelessWidget {
  const OutputFileTiles({
    super.key,
    required this.isOldFile,
    required this.file,
  });

  final bool isOldFile;
  final XFile file;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 2,
      leading: const Icon(Icons.note_outlined),
      title: isOldFile
          ? Text(file.name, style: Theme.of(context).textTheme.labelLarge)
          : RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                      text: file.name,
                      style: Theme.of(context).textTheme.labelLarge),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.bottom,
                    child: Icon(
                      Icons.fiber_new_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              )),
      subtitle: FutureBuilder<String>(
        future: getFileSize(file),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Text(snapshot.data!);
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
      trailing: IconButton(
        icon: Icon(Icons.adaptive.share),
        onPressed: () {
          IOServices().shareFile(context, file);
        },
      ),
    );
  }
}

class IOListContainer extends StatelessWidget {
  const IOListContainer({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Flexible(
          child: child,
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
