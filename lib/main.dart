import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:pro_calc/Components/bottom_bar.dart';
import 'package:pro_calc/Pages/calc_page.dart';
import 'package:pro_calc/Pages/history_page.dart';
import 'package:pro_calc/Pages/settings_page.dart';
import 'package:pro_calc/Pages/tools_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const ProCalc());
}

class ProCalc extends StatefulWidget {
  const ProCalc({super.key});

  @override
  State<ProCalc> createState() => _ProCalcState();
}

class _ProCalcState extends State<ProCalc> {
  final List<Widget> _tabs = [
    const CalcPage(),
    const HistoryPage(),
    const ToolsPage(),
    const SettingsPage(),
  ];
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarDividerColor: Color.fromARGB(255, 255, 255, 255),
        statusBarColor: Color.fromARGB(255, 255, 255, 255),
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    return SafeArea(
      child: CupertinoApp(
        theme: const CupertinoThemeData(
          textTheme: CupertinoTextThemeData(
            textStyle: TextStyle(
              fontFamily: 'Inter',
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
        title: 'Pro Calculator',
        home: CupertinoPageScaffold(
          child: BottomBar(tabs: _tabs),
        ),
      ),
    );
  }
}
