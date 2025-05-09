import 'package:flutter/material.dart';
import '../base_shape_page.dart';

class SquareShapePage extends StatelessWidget {
  const SquareShapePage({super.key});

  static const String title = 'Square Calculator';
  static const String shapeType = 'Square';
  static const List<String> parameters = [
    'Side',
    'Area',
    'Perimeter',
    'Diagonal'
  ];

  static const Map<String, List<Map<String, dynamic>>> unitOptions = {
    'Side': [
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
    'Diagonal': [
      {'unit': 'm', 'factor': 1.0},
      {'unit': 'cm', 'factor': 100.0},
      {'unit': 'km', 'factor': 0.001},
      {'unit': 'ft', 'factor': 3.28084},
      {'unit': 'in', 'factor': 39.3701},
      {'unit': 'mi', 'factor': 0.000621371},
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
