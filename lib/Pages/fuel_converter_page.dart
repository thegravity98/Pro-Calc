import 'package:flutter/cupertino.dart';
import 'base_converter_page.dart';

class FuelConverterPage extends StatelessWidget {
  const FuelConverterPage({super.key});

  // Available units for conversion
  static final List<String> _units = [
    'Miles per Gallon (US)',
    'Liters per 100 Kilometers',
    'Kilometers per Liter',
    'Miles per Gallon (UK)'
  ];

  // Conversion handled directly as fuel efficiency conversions are not simple ratios
  String _handleConversion(String input, String fromUnit, String toUnit) {
    try {
      double value = double.parse(input);
      double valueInLitersPer100Km;

      // Convert from input unit to Liters per 100 Kilometers
      switch (fromUnit) {
        case 'Miles per Gallon (US)':
          valueInLitersPer100Km = 235.215 / value;
          break;
        case 'Liters per 100 Kilometers':
          valueInLitersPer100Km = value;
          break;
        case 'Kilometers per Liter':
          valueInLitersPer100Km = 100 / value;
          break;
        case 'Miles per Gallon (UK)':
          valueInLitersPer100Km = 282.481 / value;
          break;
        default:
          return 'Error';
      }

      // Convert from Liters per 100 Kilometers to target unit
      switch (toUnit) {
        case 'Miles per Gallon (US)':
          return (235.215 / valueInLitersPer100Km).toStringAsFixed(6);
        case 'Liters per 100 Kilometers':
          return valueInLitersPer100Km.toStringAsFixed(6);
        case 'Kilometers per Liter':
          return (100 / valueInLitersPer100Km).toStringAsFixed(6);
        case 'Miles per Gallon (UK)':
          return (282.481 / valueInLitersPer100Km).toStringAsFixed(6);
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
      title: 'Fuel Converter',
      units: _units,
      conversionRates: {}, // Not used due to non-linear conversions
      onConvert: _handleConversion,
    );
  }
}