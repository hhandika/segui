import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:segui/screens/shared/forms.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
      ),
      body: Center(
          child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: 800, maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: FutureBuilder(
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return MarkdownViewer(data: snapshot.data!);
            }
            return const CircularProgressIndicator();
          },
          future: parseMarkdown(),
        ),
      )),
    );
  }

  Future<List<String>> parseMarkdown() async {
    String path = 'assets/markdown/FAQ.md';
    try {
      String data = await DefaultAssetBundle.of(context).loadString(path);
      return const LineSplitter().convert(data);
    } catch (e) {
      return ['Error loading FAQ'];
    }
  }
}

class MarkdownViewer extends StatelessWidget {
  const MarkdownViewer({super.key, required this.data});

  final List<String> data;
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        if (data[index].startsWith('##')) {
          return Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
              child: CardTitle(
                title: data[index].replaceAll('##', ''),
              ));
        } else if (data[index].isEmpty | data[index].startsWith('#')) {
          return const SizedBox.shrink();
        } else {
          return CommonCard(
            child: Text(
              data[index],
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
      },
    );
  }
}
