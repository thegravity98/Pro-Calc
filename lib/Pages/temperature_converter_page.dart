import 'package:flutter/cupertino.dart';
import 'base_converter_page.dart';

class TemperatureConverterPage extends StatelessWidget {
  const TemperatureConverterPage({super.key});

  // Available units for conversion
  static final List<String> _units = [
    'Celsius',
    'Fahrenheit',
    'Kelvin',
    'Rankine'
  ];

  // Conversion handled directly as temperature conversions are not simple ratios
  String _handleConversion(String input, String fromUnit, String toUnit) {
    try {
      double value = double.parse(input);
      double valueInCelsius;

      // Convert from input unit to Celsius
      switch (fromUnit) {
        case 'Celsius':
          valueInCelsius = value;
          break;
        case 'Fahrenheit':
          valueInCelsius = (value - 32) * 5 / 9;
          break;
        case 'Kelvin':
          valueInCelsius = value - 273.15;
          break;
        case 'Rankine':
          valueInCelsius = (value - 491.67) * 5 / 9;
          break;
        default:
          return 'Error';
      }

      // Convert from Celsius to target unit
      switch (toUnit) {
        case 'Celsius':
          return valueInCelsius.toStringAsFixed(6);
        case 'Fahrenheit':
          return (valueInCelsius * 9 / 5 + 32).toStringAsFixed(6);
        case 'Kelvin':
          return (valueInCelsius + 273.15).toStringAsFixed(6);
        case 'Rankine':
          return (valueInCelsius * 9 / 5 + 491.67).toStringAsFixed(6);
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
      title: 'Temperature Converter',
      units: _units,
      conversionRates: {}, // Not used due to non-linear conversions
      onConvert: _handleConversion,
    );
  }
}