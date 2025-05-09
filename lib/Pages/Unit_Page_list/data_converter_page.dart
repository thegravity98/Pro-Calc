import 'package:flutter/cupertino.dart';
import '../base_converter_page.dart';

class DataConverterPage extends StatelessWidget {
  const DataConverterPage({super.key});

  // Available units for conversion
  static final List<String> _units = [
    'Bytes',
    'Kilobytes',
    'Megabytes',
    'Gigabytes',
    'Terabytes',
    'Petabytes'
  ];

  // Conversion rates based on 1 unit = X Bytes
  static final Map<String, double> _conversionRatesFromBytes = {
    'Bytes': 1.0,
    'Kilobytes': 1024.0,
    'Megabytes': 1048576.0,
    'Gigabytes': 1073741824.0,
    'Terabytes': 1099511627776.0,
    'Petabytes': 1125899906842624.0
  };

  String _handleConversion(String input, String fromUnit, String toUnit) {
    try {
      double value = double.parse(input);
      double valueInBytes = value * _conversionRatesFromBytes[fromUnit]!;
      double result = valueInBytes / _conversionRatesFromBytes[toUnit]!;
      return result.toStringAsFixed(6);
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseConverterPage(
      title: 'Data Converter',
      units: _units,
      conversionRates: _conversionRatesFromBytes,
      onConvert: _handleConversion,
    );
  }
}
