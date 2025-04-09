import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:pro_calc/Components/bottom_bar.dart';
import 'package:pro_calc/Pages/calc_page.dart';
import 'package:pro_calc/Pages/settings_page.dart';
import 'package:pro_calc/Pages/tools_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set device orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Enable high refresh rate support
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  if (Platform.isAndroid) {
    await FlutterDisplayMode.setHighRefreshRate();
  }

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
        title: 'Pro Calc',
        home: CupertinoPageScaffold(
          child: BottomBar(tabs: _tabs),
        ),
      ),
    );
  }
}
