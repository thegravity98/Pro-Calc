import 'package:flutter/cupertino.dart';
import '../base_converter_page.dart';

class CurrencyConverterPage extends StatelessWidget {
  const CurrencyConverterPage({super.key});

  // Available units for conversion (sample currencies)
  static final List<String> _units = ['USD', 'EUR', 'GBP', 'JPY', 'AUD'];

  // Conversion rates based on 1 unit = X USD (static, for demonstration)
  static final Map<String, double> _conversionRatesFromUSD = {
    'USD': 1.0,
    'EUR': 0.93, // Sample rate
    'GBP': 0.80, // Sample rate
    'JPY': 150.0, // Sample rate
    'AUD': 1.50 // Sample rate
  };

  String _handleConversion(String input, String fromUnit, String toUnit) {
    try {
      double value = double.parse(input);
      double valueInUSD = value * _conversionRatesFromUSD[fromUnit]!;
      double result = valueInUSD / _conversionRatesFromUSD[toUnit]!;
      return result.toStringAsFixed(2); // 2 decimals for currency
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseConverterPage(
      title: 'Currency Converter',
      units: _units,
      conversionRates: _conversionRatesFromUSD,
      onConvert: _handleConversion,
    );
  }
}
