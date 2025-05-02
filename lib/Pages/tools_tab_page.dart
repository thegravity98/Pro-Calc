import 'package:flutter/cupertino.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class ToolsTabPage extends StatelessWidget {
  const ToolsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      // Removed navigation bar as requested
      navigationBar: null,
      child: SafeArea(
        child: ToolsTabGridContent(),
      ),
    );
  }
}

class ToolsTabGridContent extends StatelessWidget {
  ToolsTabGridContent({super.key});

  final List<Map<String, dynamic>> toolsList = [
    {'name': 'Calculator', 'icon': FluentIcons.calculator_24_regular},
    {'name': 'Scientific', 'icon': FluentIcons.math_formula_24_regular},
    {'name': 'Programmer', 'icon': FluentIcons.code_24_regular},
    {'name': 'Date Calc', 'icon': FluentIcons.calendar_24_regular},
    {'name': 'Mortgage', 'icon': FluentIcons.home_24_regular},
    {'name': 'Currency', 'icon': FluentIcons.money_24_regular},
    {'name': 'Discount', 'icon': FluentIcons.tag_24_regular},
    {'name': 'Time Zone', 'icon': FluentIcons.globe_24_regular},
    {'name': 'BMI', 'icon': FluentIcons.person_24_regular},
    {'name': 'Fuel Cost', 'icon': FluentIcons.gas_pump_24_regular},
    {'name': 'Tip Calc', 'icon': FluentIcons.food_24_regular},
    {'name': 'Loan Calc', 'icon': FluentIcons.money_hand_24_regular},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: toolsList.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // TODO: Implement tool functionality
          },
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  toolsList[index]['icon'],
                  size: 32,
                  color: CupertinoColors.activeBlue,
                ),
                const SizedBox(height: 8),
                Text(
                  toolsList[index]['name'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
