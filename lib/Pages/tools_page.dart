import 'package:flutter/cupertino.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'length_converter_page.dart';
import 'area_converter_page.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Unit Converter'),
      ),
      child: SafeArea(
        child: ToolsGridContent(),
      ),
    );
  }
}

class ToolsGridContent extends StatelessWidget {
  ToolsGridContent({super.key});

  final List<Map<String, dynamic>> converterTools = [
    {'name': 'Length', 'icon': FluentIcons.ruler_24_regular},
    {'name': 'Area', 'icon': FluentIcons.square_24_regular},
    {'name': 'Volume', 'icon': FluentIcons.beaker_24_regular},
    {'name': 'Temperature', 'icon': FluentIcons.temperature_24_regular},
    {'name': 'Speed', 'icon': FluentIcons.cellular_data_1_24_regular},
    {'name': 'Time', 'icon': FluentIcons.clock_24_regular},
    {'name': 'Pressure', 'icon': FluentIcons.gauge_24_regular},
    {'name': 'Power', 'icon': FluentIcons.flash_24_regular},
    {'name': 'Data', 'icon': FluentIcons.data_trending_24_regular},
    {'name': 'Angle', 'icon': FluentIcons.triangle_24_regular},
    {'name': 'Currency', 'icon': FluentIcons.money_24_regular},
    {'name': 'Fuel', 'icon': FluentIcons.gas_pump_24_regular},
    {'name': 'Frequency', 'icon': FluentIcons.cellular_data_3_24_regular},
    {'name': 'Storage', 'icon': FluentIcons.hard_drive_24_regular},
    {'name': 'Force', 'icon': FluentIcons.arrow_forward_24_regular},
    {'name': 'Sound', 'icon': FluentIcons.speaker_2_24_regular},
    {'name': 'Illuminance', 'icon': FluentIcons.lightbulb_24_regular},
    {'name': 'BMI', 'icon': FluentIcons.person_24_regular},
  ];

  void _navigateToConverter(BuildContext context, String name) {
    switch (name) {
      case 'Length':
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LengthConverterPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration:
                const Duration(milliseconds: 300), // Adjust duration
          ),
        );
        break;
      case 'Area':
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AreaConverterPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration:
                const Duration(milliseconds: 300), // Adjust duration
          ),
        );
        break;
      default:
        break;
    }
  }

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
      itemCount: converterTools.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () =>
              _navigateToConverter(context, converterTools[index]['name']),
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  converterTools[index]['icon'],
                  size: 32,
                  color: CupertinoColors.activeBlue,
                ),
                const SizedBox(height: 8),
                Text(
                  converterTools[index]['name'],
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
