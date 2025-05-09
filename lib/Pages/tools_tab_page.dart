// lib/pages/tools_tab_page.dart (or your path)

import 'package:flutter/cupertino.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

// import 'calculators/mortgage_page.dart';
// import 'calculators/currency_converter_page.dart';
// import 'calculators/discount_calc_page.dart';
// import 'calculators/time_zone_converter_page.dart';
// import 'calculators/bmi_calc_page.dart';
// import 'calculators/tip_calc_page.dart';

import 'Export_Page_list/tools_page_list.dart';

class ToolsTabPage extends StatelessWidget {
  const ToolsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: null, // No top navigation bar for the tab itself
      child: SafeArea(
        child: ToolsTabGridContent(),
      ),
    );
  }
}

class ToolsTabGridContent extends StatelessWidget {
  ToolsTabGridContent({super.key});

  final List<Map<String, dynamic>> toolsList = [
    {
      'name': 'Date Calc',
      'icon': FluentIcons.calendar_24_regular,
      'page': const DateCalcPage()
    },
    // {'name': 'Mortgage', 'icon': FluentIcons.home_24_regular, 'page': const MortgagePage()},
    // {'name': 'Currency', 'icon': FluentIcons.money_24_regular, 'page': const CurrencyConverterPage()},
    // {'name': 'Discount', 'icon': FluentIcons.tag_24_regular, 'page': const DiscountCalcPage()},
    // {'name': 'Time Zone', 'icon': FluentIcons.globe_24_regular, 'page': const TimeZoneConverterPage()},
    // {'name': 'BMI', 'icon': FluentIcons.person_24_regular, 'page': const BmiCalcPage()},
    {
      'name': 'Fuel Cost',
      'icon': FluentIcons.gas_pump_24_regular,
      'page': const FuelCostCalcPage()
    },
    // {'name': 'Tip Calc', 'icon': FluentIcons.food_24_regular, 'page': const TipCalcPage()},
    {
      'name': 'Loan Calc',
      'icon': FluentIcons.money_hand_24_regular,
      'page': const LoanCalcPage()
    },
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
        final tool = toolsList[index];
        return GestureDetector(
          onTap: () {
            if (tool['page'] != null) {
              Navigator.of(context).push(
                CupertinoPageRoute(
                    builder: (context) => tool['page'] as Widget),
              );
            } else {
              // Fallback for any tool that might not have a page defined yet
              print('Tapped on: ${tool['name']}, but no page is defined.');
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoTheme.of(context).brightness == Brightness.dark
                  ? CupertinoColors.darkBackgroundGray.withOpacity(0.5)
                  : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  tool['icon'],
                  size: 32,
                  color: CupertinoTheme.of(context).primaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  tool['name'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
