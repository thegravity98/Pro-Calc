import 'package:flutter/cupertino.dart';
import 'base_converter_page.dart';

class TimeConverterPage extends StatelessWidget {
  const TimeConverterPage({super.key});

  // Available units for conversion
  static final List<String> _units = [
    'Seconds',
    'Minutes',
    'Hours',
    'Days',
    'Weeks',
    'Years'
  ];

  // Conversion rates based on 1 unit = X Seconds
  static final Map<String, double> _conversionRatesFromSeconds = {
    'Seconds': 1.0,
    'Minutes': 60.0,
    'Hours': 3600.0,
    'Days': 86400.0,
    'Weeks': 604800.0,
    'Years': 31536000.0 // Approximate, assuming 365 days
  };

  String _handleConversion(String input, String fromUnit, String toUnit) {
    try {
      double value = double.parse(input);
      double valueInSeconds = value * _conversionRatesFromSeconds[fromUnit]!;
      double result = valueInSeconds / _conversionRatesFromSeconds[toUnit]!;
      return result.toStringAsFixed(6);
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseConverterPage(
      title: 'Time Converter',
      units: _units,
      conversionRates: _conversionRatesFromSeconds,
      onConvert: _handleConversion,
    );
  }
}