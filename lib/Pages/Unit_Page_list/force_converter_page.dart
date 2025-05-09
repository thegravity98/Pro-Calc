import 'package:flutter/cupertino.dart';
import '../base_converter_page.dart';

class ForceConverterPage extends StatelessWidget {
  const ForceConverterPage({super.key});

  // Available units for conversion
  static final List<String> _units = [
    'Newtons',
    'Kilogram-Force',
    'Pounds-Force',
    'Dynes'
  ];

  // Conversion rates based on 1 unit = X Newtons
  static final Map<String, double> _conversionRatesFromNewtons = {
    'Newtons': 1.0,
    'Kilogram-Force': 9.80665,
    'Pounds-Force': 4.44822,
    'Dynes': 0.00001
  };

  String _handleConversion(String input, String fromUnit, String toUnit) {
    try {
      double value = double.parse(input);
      double valueInNewtons = value * _conversionRatesFromNewtons[fromUnit]!;
      double result = valueInNewtons / _conversionRatesFromNewtons[toUnit]!;
      return result.toStringAsFixed(6);
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseConverterPage(
      title: 'Force Converter',
      units: _units,
      conversionRates: _conversionRatesFromNewtons,
      onConvert: _handleConversion,
    );
  }
}
