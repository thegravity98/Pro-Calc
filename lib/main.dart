import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:pro_calc/Components/bottom_bar.dart';
import 'package:pro_calc/Pages/calc_page.dart';
import 'package:pro_calc/Pages/settings_page.dart';
import 'package:pro_calc/Pages/tools_page.dart';

Future<void> initializeApp() async {
  try {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    if (Platform.isAndroid) {
      await FlutterDisplayMode.setHighRefreshRate();
    }
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeApp();
    runApp(const ProCalc());
  } catch (e) {
    debugPrint('Fatal error during app startup: $e');
    rethrow;
  }
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
          primaryColor: CupertinoColors.activeBlue,
          textTheme: CupertinoTextThemeData(
            textStyle: TextStyle(
              fontFamily: 'Inter',
              color: Color.fromARGB(255, 0, 0, 0),
            ),
            actionTextStyle: TextStyle(
              fontFamily: 'Inter',
            ),
            tabLabelTextStyle: TextStyle(
              fontFamily: 'Inter',
            ),
            navTitleTextStyle: TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            navLargeTitleTextStyle: TextStyle(
              fontFamily: 'Inter',
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
            pickerTextStyle: TextStyle(
              fontFamily: 'Inter',
            ),
            dateTimePickerTextStyle: TextStyle(
              fontFamily: 'Inter',
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
