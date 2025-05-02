import 'package:flutter/cupertino.dart';
import '../base_converter_page.dart';

class IlluminanceConverterPage extends StatelessWidget {
  const IlluminanceConverterPage({super.key});

  // Available units for conversion
  static final List<String> _units = ['Lux', 'Foot-Candles', 'Phot', 'Nox'];

  // Conversion rates based on 1 unit = X Lux
  static final Map<String, double> _conversionRatesFromLux = {
    'Lux': 1.0,
    'Foot-Candles': 0.092903,
    'Phot': 0.0001,
    'Nox': 0.001
  };

  String _handleConversion(String input, String fromUnit, String toUnit) {
    try {
      double value = double.parse(input);
      double valueInLux = value * _conversionRatesFromLux[fromUnit]!;
      double result = valueInLux / _conversionRatesFromLux[toUnit]!;
      return result.toStringAsFixed(6);
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseConverterPage(
      title: 'Illuminance Converter',
      units: _units,
      conversionRates: _conversionRatesFromLux,
      onConvert: _handleConversion,
    );
  }
}
