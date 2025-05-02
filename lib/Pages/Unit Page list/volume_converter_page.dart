import 'package:flutter/cupertino.dart';
import '../base_converter_page.dart';

class VolumeConverterPage extends StatelessWidget {
  const VolumeConverterPage({super.key});

  // Available units for conversion
  static final List<String> _units = [
    'Cubic Meters',
    'Liters',
    'Milliliters',
    'Cubic Centimeters',
    'Cubic Feet',
    'Cubic Inches',
    'Gallons (US)',
    'Gallons (UK)',
    'Pints (US)',
    'Quarts (US)'
  ];

  // Conversion rates based on 1 unit = X Cubic Meters
  static final Map<String, double> _conversionRatesFromCubicMeters = {
    'Cubic Meters': 1.0,
    'Liters': 0.001,
    'Milliliters': 0.000001,
    'Cubic Centimeters': 0.000001,
    'Cubic Feet': 0.0283168,
    'Cubic Inches': 0.0000163871,
    'Gallons (US)': 0.00378541,
    'Gallons (UK)': 0.00454609,
    'Pints (US)': 0.000473176,
    'Quarts (US)': 0.000946353
  };

  String _handleConversion(String input, String fromUnit, String toUnit) {
    try {
      double value = double.parse(input);
      double valueInCubicMeters =
          value * _conversionRatesFromCubicMeters[fromUnit]!;
      double result =
          valueInCubicMeters / _conversionRatesFromCubicMeters[toUnit]!;
      return result.toStringAsFixed(6);
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseConverterPage(
      title: 'Volume Converter',
      units: _units,
      conversionRates: _conversionRatesFromCubicMeters,
      onConvert: _handleConversion,
    );
  }
}
