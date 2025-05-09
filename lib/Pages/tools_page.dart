import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import 'Export_Page_list/unit_page_list.dart';
import 'shapes_page.dart';
import 'tools_tab_page.dart';

class ToolsPage extends StatefulWidget {
  final bool isModal;

  const ToolsPage({super.key, this.isModal = false});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    ToolsGridContent(),
    const ShapesPage(),
    const ToolsTabPage(),
  ];

  final List<String> _titles = [
    'Units',
    'Shapes',
    'Tools',
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: null,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: widget.isModal
                    ? Colors.transparent
                    : CupertinoColors.systemBackground,
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.systemGrey4,
                    width: 0.5,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: List.generate(_titles.length, (index) {
                    return _buildTab(
                        index,
                        _titles[index],
                        [
                          FluentIcons.ruler_24_regular,
                          FluentIcons.square_24_regular,
                          FluentIcons.toolbox_24_regular
                        ][index]);
                  }),
                ),
              ),
            ),
            Expanded(
              child: _pages[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemGrey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 3,
              color:
                  isSelected ? CupertinoColors.activeBlue : Colors.transparent,
            )
          ],
        ),
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
    Widget? page;
    switch (name) {
      case 'Length':
        page = const LengthConverterPage();
        break;
      case 'Area':
        page = const AreaConverterPage();
        break;
      case 'Volume':
        page = const VolumeConverterPage();
        break;
      case 'Temperature':
        page = const TemperatureConverterPage();
        break;
      case 'Speed':
        page = const SpeedConverterPage();
        break;
      case 'Time':
        page = const TimeConverterPage();
        break;
      case 'Pressure':
        page = const PressureConverterPage();
        break;
      case 'Power':
        page = const PowerConverterPage();
        break;
      case 'Data':
        page = const DataConverterPage();
        break;
      case 'Angle':
        page = const AngleConverterPage();
        break;
      case 'Currency':
        page = const CurrencyConverterPage();
        break;
      case 'Fuel':
        page = const FuelConverterPage();
        break;
      case 'Frequency':
        page = const FrequencyConverterPage();
        break;
      case 'Storage':
        // page = const StorageConverterPage();
        return; // Storage page commented out as per original
      case 'Force':
        page = const ForceConverterPage();
        break;
      case 'Sound':
        page = const SoundConverterPage();
        break;
      case 'Illuminance':
        page = const IlluminanceConverterPage();
        break;
      default:
        return;
    }
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page!,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
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
