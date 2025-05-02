import 'package:flutter/cupertino.dart';
import 'base_converter_page.dart';

class SoundConverterPage extends StatelessWidget {
  const SoundConverterPage({super.key});

  // Available units for conversion
  static final List<String> _units = [
    'Decibels (SPL)',
    'Decibels (Power)',
    'Neper'
  ];

  // Conversion handled directly as sound conversions are logarithmic
  String _handleConversion(String input, String fromUnit, String toUnit) {
    try {
      double value = double.parse(input);
      double valueInDecibelsSPL;

      // Convert from input unit to Decibels (SPL)
      switch (fromUnit) {
        case 'Decibels (SPL)':
          valueInDecibelsSPL = value;
          break;
        case 'Decibels (Power)':
          valueInDecibelsSPL = value * 2; // Approximate, assumes power to intensity
          break;
        case 'Neper':
          valueInDecibelsSPL = value * 8.686; // 1 Np = 8.686 dB
          break;
        default:
          return 'Error';
      }

      // Convert from Decibels (SPL) to target unit
      switch (toUnit) {
        case 'Decibels (SPL)':
          return valueInDecibelsSPL.toStringAsFixed(6);
        case 'Decibels (Power)':
          return (valueInDecibelsSPL / 2).toStringAsFixed(6);
        case 'Neper':
          return (valueInDecibelsSPL / 8.686).toStringAsFixed(6);
        default:
          return 'Error';
      }
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseConverterPage(
      title: 'Sound Converter',
      units: _units,
      conversionRates: {}, // Not used due to logarithmic conversions
      onConvert: _handleConversion,
    );
  }
}