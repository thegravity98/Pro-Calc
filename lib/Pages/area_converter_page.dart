import 'package:flutter/cupertino.dart';
import 'base_converter_page.dart';

class AreaConverterPage extends StatelessWidget {
  const AreaConverterPage({super.key});

  // Available units for conversion
  static final List<String> _units = [
    'Square Meters',
    'Square Kilometers',
    'Square Centimeters',
    'Square Millimeters',
    'Square Miles',
    'Square Yards',
    'Square Feet',
    'Square Inches',
    'Hectares',
    'Acres'
  ];

  // Conversion rates based on 1 unit = X Square Meters
  static final Map<String, double> _conversionRatesFromSquareMeters = {
    'Square Meters': 1.0,
    'Square Kilometers': 1000000.0,
    'Square Centimeters': 0.0001,
    'Square Millimeters': 0.000001,
    'Square Miles': 2589988.11,
    'Square Yards': 0.836127,
    'Square Feet': 0.092903,
    'Square Inches': 0.00064516,
    'Hectares': 10000.0,
    'Acres': 4046.86
  };

  String _handleConversion(String input, String fromUnit, String toUnit) {
    try {
      double value = double.parse(input);
      double valueInSquareMeters =
          value * _conversionRatesFromSquareMeters[fromUnit]!;
      double result =
          valueInSquareMeters / _conversionRatesFromSquareMeters[toUnit]!;
      return result.toStringAsFixed(6);
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseConverterPage(
      title: 'Area Converter',
      units: _units,
      conversionRates: _conversionRatesFromSquareMeters,
      onConvert: _handleConversion,
    );
  }
}
