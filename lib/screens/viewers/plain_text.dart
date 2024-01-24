import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:segui/screens/shared/components.dart';
import 'package:segui/styles/decoration.dart';

class PlainTextScreen extends StatelessWidget {
  const PlainTextScreen({super.key, required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plain Text Viewer'),
        backgroundColor: getSEGULBackgroundColor(context),
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: Center(
        child: PlainTextViewer(file: file),
      ),
    );
  }
}

class PlainTextViewer extends StatelessWidget {
  const PlainTextViewer({super.key, required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double containerHeight = screenHeight - 80;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          height: containerHeight,
          decoration: getContainerDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  file.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const TopDivider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FutureBuilder<String>(
                  future: _readFile(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return SizedBox(
                        height: containerHeight - 112,
                        width: double.infinity,
                        child: SelectableText(
                          snapshot.data!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _readFile() async {
    return await file.readAsString();
  }
}
