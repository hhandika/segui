import 'package:flutter/material.dart';
import 'package:segui/screens/shared/components.dart';
import 'package:segui/services/native.dart';

class SegulHome extends StatefulWidget {
  const SegulHome({super.key, required this.title});

  final String title;

  @override
  State<SegulHome> createState() => _SegulHomeState();
}

class _SegulHomeState extends State<SegulHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Color.lerp(
          Theme.of(context).colorScheme.primary,
          Colors.tealAccent,
          0.5,
        ),
      ),
      drawer: const MenuDrawer(),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 300,
            height: 300,
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: const [
                ConcatButton(),
                ConvertButton(),
                SummaryButton(),
                TranslateButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Menu'),
          ),
          ListTile(
            title: const Text('Item 1'),
            onTap: () {
              // Update the state of the app.
              // ...
              // Then close the drawer.
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Item 2'),
            onTap: () {
              // Update the state of the app.
              // ...
              // Then close the drawer.
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class TranslateButton extends StatelessWidget {
  const TranslateButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureButton(
        onTap: (() {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TranslatePage()),
          );
        }),
        mainColor: Colors.blue,
        icon: Icons.translate,
        title: "Translate");
  }
}

class SummaryButton extends StatelessWidget {
  const SummaryButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureButton(
        onTap: (() {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SummaryPage()),
          );
        }),
        mainColor: Colors.green,
        icon: Icons.bar_chart,
        title: "Summarize");
  }
}

class ConvertButton extends StatelessWidget {
  const ConvertButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureButton(
        onTap: (() {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ConvertPage()),
          );
        }),
        mainColor: Colors.orange,
        icon: Icons.construction,
        title: "Convert");
  }
}

class TranslatePage extends StatefulWidget {
  const TranslatePage({super.key});

  @override
  State<TranslatePage> createState() => _TranslatePageState();
}

class _TranslatePageState extends State<TranslatePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alignment Translation"),
      ),
      body: Center(
        child: FutureBuilder(
          future: api.showDnaUppercase(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data.toString());
            }
            return const Text("Loading...");
          },
        ),
      ),
    );
  }
}

class ConvertPage extends StatefulWidget {
  const ConvertPage({super.key});

  @override
  State<ConvertPage> createState() => _ConvertPageState();
}

class _ConvertPageState extends State<ConvertPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alignment Conversion"),
      ),
      body: Center(
        child: FutureBuilder(
          future: api.showDnaUppercase(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data.toString());
            }
            return const Text("Loading...");
          },
        ),
      ),
    );
  }
}

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alignment Summary"),
      ),
      body: Center(
        child: FutureBuilder(
          future: api.showDnaUppercase(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data.toString());
            }
            return const Text("Loading...");
          },
        ),
      ),
    );
  }
}

class ConcatButton extends StatelessWidget {
  const ConcatButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureButton(
        onTap: (() {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ConcatPage()),
          );
        }),
        mainColor: Colors.purple,
        icon: Icons.compare_arrows,
        title: "Concatenate");
  }
}

class ConcatPage extends StatefulWidget {
  const ConcatPage({super.key});

  @override
  State<ConcatPage> createState() => _ConcatPageState();
}

class _ConcatPageState extends State<ConcatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alignment Concatenation"),
      ),
      body: Center(
        child: FutureBuilder(
          future: api.showDnaUppercase(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data.toString());
            }
            return const Text("Loading...");
          },
        ),
      ),
    );
  }
}
