import 'package:flutter/cupertino.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
        child: Center(
      child: Text("Hey this is tools"),
    ));
  }
}
