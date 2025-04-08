import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({
    super.key,
    required List<Widget> tabs,
  }) : _tabs = tabs;

  final List<Widget> _tabs;

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        height: 60.0, // Increased from 40.0 to 60.0
        border: Border.all(
          color: const Color.fromARGB(255, 255, 255, 255),
          width: 0,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: SizedBox(
              height: 60,
              child: Center(
                child: Icon(
                  FluentIcons.calculator_24_regular,
                  size: 28,
                ),
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              height: 60,
              child: Center(
                child: Icon(
                  FluentIcons.grid_24_regular,
                  size: 28,
                ),
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              height: 60,
              child: Center(
                child: Icon(
                  FluentIcons.settings_24_regular,
                  size: 28,
                ),
              ),
            ),
            label: '',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, index) {
        return _tabs[index];
      },
    );
  }
}
