import 'package:flutter/cupertino.dart';
import 'base_converter_page.dart';

class PressureConverterPage extends StatelessWidget {
  const PressureConverterPage({super.key});

  // Available units for conversion
  static final List<String> _units = [
    'Pascals',
    'Kilopascals',
    'Bars',
    'Millibars',
    'Atmospheres',
    'PSI',
    'Torr',
    'Inches of Mercury'
  ];

  // Conversion rates based on 1 unit = X Pascals
  static final Map<String, double> _conversionRatesFromPascals = {
    'Pascals': 1.0,
    'Kilopascals': 1000.0,
    'Bars': 100000.0,
    'Millibars': 100.0,
    'Atmospheres': 101325.0,
    'PSI': 6894.76,
    'Torr': 133.322,
    'Inches of Mercury': 3386.39
  };

  String _handleConversion(String input, String fromUnit, String toUnit) {
    try {
      double value = double.parse(input);
      double valueInPascals = value * _conversionRatesFromPascals[fromUnit]!;
      double result = valueInPascals / _conversionRatesFromPascals[toUnit]!;
      return result.toStringAsFixed(6);
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseConverterPage(
      title: 'Pressure Converter',
      units: _units,
      conversionRates: _conversionRatesFromPascals,
      onConvert: _handleConversion,
    );
  }
}