import 'package:flutter/cupertino.dart';
import 'base_converter_page.dart';

class SpeedConverterPage extends StatelessWidget {
  const SpeedConverterPage({super.key});

  // Available units for conversion
  static final List<String> _units = [
    'Meters per Second',
    'Kilometers per Hour',
    'Miles per Hour',
    'Knots',
    'Feet per Second'
  ];

  // Conversion rates based on 1 unit = X Meters per Second
  static final Map<String, double> _conversionRatesFromMetersPerSecond = {
    'Meters per Second': 1.0,
    'Kilometers per Hour': 3.6,
    'Miles per Hour': 2.23694,
    'Knots': 1.94384,
    'Feet per Second': 3.28084
  };

  String _handleConversion(String input, String fromUnit, String toUnit) {
    try {
      double value = double.parse(input);
      double valueInMetersPerSecond = value * _conversionRatesFromMetersPerSecond[fromUnit]!;
      double result = valueInMetersPerSecond / _conversionRatesFromMetersPerSecond[toUnit]!;
      return result.toStringAsFixed(6);
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseConverterPage(
      title: 'Speed Converter',
      units: _units,
      conversionRates: _conversionRatesFromMetersPerSecond,
      onConvert: _handleConversion,
    );
  }
}