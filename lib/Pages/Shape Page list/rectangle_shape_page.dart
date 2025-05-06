import 'package:flutter/material.dart';
import '../base_shape_page.dart';

class RectangleShapePage extends StatelessWidget {
  const RectangleShapePage({super.key});

  static const String title = 'Rectangle Calculator';
  static const String shapeType = 'Rectangle';
  static const List<String> parameters = [
    'Length',
    'Width',
    'Height',
    'Area',
    'Perimeter',
    'Volume'
  ];

  static const Map<String, List<Map<String, dynamic>>> unitOptions = {
    'Length': [
      {'unit': 'm', 'factor': 1.0},
      {'unit': 'cm', 'factor': 100.0},
      {'unit': 'km', 'factor': 0.001},
      {'unit': 'ft', 'factor': 3.28084},
      {'unit': 'in', 'factor': 39.3701},
      {'unit': 'mi', 'factor': 0.000621371},
    ],
    'Width': [
      {'unit': 'm', 'factor': 1.0},
      {'unit': 'cm', 'factor': 100.0},
      {'unit': 'km', 'factor': 0.001},
      {'unit': 'ft', 'factor': 3.28084},
      {'unit': 'in', 'factor': 39.3701},
      {'unit': 'mi', 'factor': 0.000621371},
    ],
    'Height': [
      {'unit': 'm', 'factor': 1.0},
      {'unit': 'cm', 'factor': 100.0},
      {'unit': 'km', 'factor': 0.001},
      {'unit': 'ft', 'factor': 3.28084},
      {'unit': 'in', 'factor': 39.3701},
      {'unit': 'mi', 'factor': 0.000621371},
    ],
    'Area': [
      {'unit': 'm²', 'factor': 1.0},
      {'unit': 'cm²', 'factor': 10000.0},
      {'unit': 'km²', 'factor': 0.000001},
      {'unit': 'ft²', 'factor': 10.7639},
      {'unit': 'in²', 'factor': 1550.0},
      {'unit': 'acre', 'factor': 0.000247105},
    ],
    'Perimeter': [
      {'unit': 'm', 'factor': 1.0},
      {'unit': 'cm', 'factor': 100.0},
      {'unit': 'km', 'factor': 0.001},
      {'unit': 'ft', 'factor': 3.28084},
      {'unit': 'in', 'factor': 39.3701},
      {'unit': 'mi', 'factor': 0.000621371},
    ],
    'Volume': [
      {'unit': 'm³', 'factor': 1.0},
      {'unit': 'cm³', 'factor': 1000000.0},
      {'unit': 'km³', 'factor': 0.000000001},
      {'unit': 'ft³', 'factor': 35.3147},
      {'unit': 'in³', 'factor': 61023.7},
      {'unit': 'L', 'factor': 1000.0},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return BaseShapePage(
      title: title,
      shapeType: shapeType,
      parameters: parameters,
      unitOptions: unitOptions,
    );
  }
}
