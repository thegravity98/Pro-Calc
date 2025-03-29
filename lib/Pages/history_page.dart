import 'package:flutter/cupertino.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SizedBox(
        width: double.infinity,
        // color: CupertinoColors.systemGrey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: <Widget>[
            Expanded(
              flex: 2,
              child: Container(
                  decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 253, 253, 253),
                      borderRadius: BorderRadius.circular(10.0)),
                  width: double.infinity,
                  child: const Center(
                      child: Text(
                    "History",
                    style: TextStyle(fontSize: 48),
                  ))),
            ),
            const SizedBox(height: 8.0),
            const Expanded(
              flex: 7,
              child: Center(
                child: Text('History results'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
