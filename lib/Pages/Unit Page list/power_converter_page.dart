import 'package:flutter/cupertino.dart';
import '../base_converter_page.dart';

class PowerConverterPage extends StatelessWidget {
  const PowerConverterPage({super.key});

  // Available units for conversion
  static final List<String> _units = [
    'Watts',
    'Kilowatts',
    'Megawatts',
    'Horsepower (Metric)',
    'Horsepower (Imperial)',
    'BTU per Hour',
    'Calories per Second'
  ];

  // Conversion rates based on 1 unit = X Watts
  static final Map<String, double> _conversionRatesFromWatts = {
    'Watts': 1.0,
    'Kilowatts': 1000.0,
    'Megawatts': 1000000.0,
    'Horsepower (Metric)': 735.499,
    'Horsepower (Imperial)': 745.7,
    'BTU per Hour': 0.293071,
    'Calories per Second': 4.184
  };

  String _handleConversion(String input, String fromUnit, String toUnit) {
    try {
      double value = double.parse(input);
      double valueInWatts = value * _conversionRatesFromWatts[fromUnit]!;
      double result = valueInWatts / _conversionRatesFromWatts[toUnit]!;
      return result.toStringAsFixed(6);
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseConverterPage(
      title: 'Power Converter',
      units: _units,
      conversionRates: _conversionRatesFromWatts,
      onConvert: _handleConversion,
    );
  }
}
