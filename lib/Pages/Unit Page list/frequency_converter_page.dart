import 'package:flutter/cupertino.dart';
import '../base_converter_page.dart';

class FrequencyConverterPage extends StatelessWidget {
  const FrequencyConverterPage({super.key});

  // Available units for conversion
  static final List<String> _units = [
    'Hertz',
    'Kilohertz',
    'Megahertz',
    'Gigahertz'
  ];

  // Conversion rates based on 1 unit = X Hertz
  static final Map<String, double> _conversionRatesFromHertz = {
    'Hertz': 1.0,
    'Kilohertz': 1000.0,
    'Megahertz': 1000000.0,
    'Gigahertz': 1000000000.0
  };

  String _handleConversion(String input, String fromUnit, String toUnit) {
    try {
      double value = double.parse(input);
      double valueInHertz = value * _conversionRatesFromHertz[fromUnit]!;
      double result = valueInHertz / _conversionRatesFromHertz[toUnit]!;
      return result.toStringAsFixed(6);
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseConverterPage(
      title: 'Frequency Converter',
      units: _units,
      conversionRates: _conversionRatesFromHertz,
      onConvert: _handleConversion,
    );
  }
}
