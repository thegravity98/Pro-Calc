import 'package:flutter/cupertino.dart';
import '../base_converter_page.dart';

class LengthConverterPage extends StatelessWidget {
  const LengthConverterPage({super.key});

  // Available units for conversion
  static final List<String> _units = [
    'Meters',
    'Kilometers',
    'Centimeters',
    'Millimeters',
    'Miles',
    'Yards',
    'Feet',
    'Inches',
    'Nautical Miles'
  ];

  // Conversion rates based on 1 unit = X Meters
  static final Map<String, double> _conversionRatesFromMeters = {
    'Meters': 1.0,
    'Kilometers': 1000.0,
    'Centimeters': 0.01,
    'Millimeters': 0.001,
    'Miles': 1609.34,
    'Yards': 0.9144,
    'Feet': 0.3048,
    'Inches': 0.0254,
    'Nautical Miles': 1852.0,
  };

  String _handleConversion(String input, String fromUnit, String toUnit) {
    try {
      double value = double.parse(input);
      double valueInMeters = value * _conversionRatesFromMeters[fromUnit]!;
      double result = valueInMeters / _conversionRatesFromMeters[toUnit]!;
      return result.toStringAsFixed(6);
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseConverterPage(
      title: 'Length Converter',
      units: _units,
      conversionRates: _conversionRatesFromMeters,
      onConvert: _handleConversion,
    );
  }
}
