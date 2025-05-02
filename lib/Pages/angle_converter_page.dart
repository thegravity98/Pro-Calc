import 'package:flutter/cupertino.dart';
import 'base_converter_page.dart';

class AngleConverterPage extends StatelessWidget {
  const AngleConverterPage({super.key});

  // Available units for conversion
  static final List<String> _units = [
    'Degrees',
    'Radians',
    'Gradians',
    'Turns'
  ];

  // Conversion rates based on 1 unit = X Degrees
  static final Map<String, double> _conversionRatesFromDegrees = {
    'Degrees': 1.0,
    'Radians': 0.0174533, // pi/180
    'Gradians': 1.11111, // 100/90
    'Turns': 0.00277778 // 1/360
  };

  String _handleConversion(String input, String fromUnit, String toUnit) {
    try {
      double value = double.parse(input);
      double valueInDegrees = value * _conversionRatesFromDegrees[fromUnit]!;
      double result = valueInDegrees / _conversionRatesFromDegrees[toUnit]!;
      return result.toStringAsFixed(6);
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseConverterPage(
      title: 'Angle Converter',
      units: _units,
      conversionRates: _conversionRatesFromDegrees,
      onConvert: _handleConversion,
    );
  }
}