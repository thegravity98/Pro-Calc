import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../base_shape_page.dart';

class TriangleShapePage extends StatefulWidget {
  const TriangleShapePage({super.key});

  @override
  State<TriangleShapePage> createState() => _TriangleShapePageState();
}

class _TriangleShapePageState extends State<TriangleShapePage> {
  final List<String> parameters = [
    'Base',
    'Height',
    'Side A',
    'Side B',
    'Area',
    'Perimeter'
  ];
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _results = {};
  final NumberFormat _numberFormat = NumberFormat.decimalPattern();

  @override
  void initState() {
    super.initState();
    for (var param in parameters) {
      _controllers[param] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onCalculate(
    Map<String, String> inputs,
    String? activeParameter,
    Map<String, bool> isInputEnabled,
    Function(String, String)? addToHistory,
  ) {
    debugPrint('[_onCalculate] Triggered');
    debugPrint('[_onCalculate] Active parameter: $activeParameter');
    debugPrint('[_onCalculate] isInputEnabled: $isInputEnabled');
    debugPrint('[_onCalculate] Inputs: $inputs');

    // Parse input values
    Map<String, double> inputValues = {};
    for (var param in parameters) {
      if (isInputEnabled[param]! &&
          inputs.containsKey(param) &&
          inputs[param]!.isNotEmpty) {
        final text = inputs[param]!.replaceAll(',', '');
        try {
          inputValues[param] = double.parse(text);
        } catch (e) {
          debugPrint('[_onCalculate] Invalid input for $param: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid input for $param')),
          );
          return;
        }
      }
    }

    debugPrint('[_onCalculate] Parsed input values: $inputValues');

    // Variables to hold calculated values
    double? base, height, sideA, sideB, area, perimeter;

    // Calculation Logic
    if (inputValues.containsKey('Base') && inputValues.containsKey('Height')) {
      base = inputValues['Base'];
      height = inputValues['Height'];
      if (base! <= 0 || height! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Base and Height must be greater than 0')),
        );
        return;
      }
      area = 0.5 * base * height;
      // Side A and Side B required for perimeter
      if (inputValues.containsKey('Side A') &&
          inputValues.containsKey('Side B')) {
        sideA = inputValues['Side A'];
        sideB = inputValues['Side B'];
        if (sideA! <= 0 || sideB! <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sides must be greater than 0')),
          );
          return;
        }
        // Validate triangle inequality
        if (sideA + sideB <= base ||
            sideA + base <= sideB ||
            sideB + base <= sideA) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Invalid triangle: sides do not form a triangle')),
          );
          return;
        }
        perimeter = base + sideA + sideB;
      }
    } else if (inputValues.containsKey('Base') &&
        inputValues.containsKey('Area')) {
      base = inputValues['Base'];
      area = inputValues['Area'];
      if (base! <= 0 || area! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Base and Area must be greater than 0')),
        );
        return;
      }
      height = (2 * area) / base;
      if (inputValues.containsKey('Side A') &&
          inputValues.containsKey('Side B')) {
        sideA = inputValues['Side A'];
        sideB = inputValues['Side B'];
        if (sideA! <= 0 || sideB! <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sides must be greater than 0')),
          );
          return;
        }
        if (sideA + sideB <= base ||
            sideA + base <= sideB ||
            sideB + base <= sideA) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Invalid triangle: sides do not form a triangle')),
          );
          return;
        }
        perimeter = base + sideA + sideB;
      }
    } else if (inputValues.containsKey('Side A') &&
        inputValues.containsKey('Side B') &&
        inputValues.containsKey('Base')) {
      sideA = inputValues['Side A'];
      sideB = inputValues['Side B'];
      base = inputValues['Base'];
      if (sideA! <= 0 || sideB! <= 0 || base! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sides must be greater than 0')),
        );
        return;
      }
      if (sideA + sideB <= base ||
          sideA + base <= sideB ||
          sideB + base <= sideA) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Invalid triangle: sides do not form a triangle')),
        );
        return;
      }
      perimeter = sideA + sideB + base;
      // Need height or area to calculate the other
      if (inputValues.containsKey('Height')) {
        height = inputValues['Height'];
        if (height! <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Height must be greater than 0')),
          );
          return;
        }
        area = 0.5 * base * height;
      }
    }

    // Update Results and Controllers
    setState(() {
      _results.clear();
      if (base != null) _results['Base'] = _numberFormat.format(base);
      if (height != null) _results['Height'] = _numberFormat.format(height);
      if (sideA != null) _results['Side A'] = _numberFormat.format(sideA);
      if (sideB != null) _results['Side B'] = _numberFormat.format(sideB);
      if (area != null) _results['Area'] = _numberFormat.format(area);
      if (perimeter != null)
        _results['Perimeter'] = _numberFormat.format(perimeter);

      debugPrint('[_onCalculate] Calculated results: $_results');

      for (var param in parameters) {
        if (!isInputEnabled[param]!) {
          _controllers[param]!.text = _results[param] ?? '';
          debugPrint(
              '[_onCalculate] Updated $param controller: ${_controllers[param]!.text}');
        } else if (!inputValues.containsKey(param)) {
          _controllers[param]!.clear();
        }
      }

      if (_results.isNotEmpty && addToHistory != null) {
        String expr =
            inputValues.entries.map((e) => '${e.key}=${e.value}').join(', ');
        String res =
            _results.entries.map((e) => '${e.key}=${e.value}').join(', ');
        addToHistory(expr, res);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseShapePage(
      title: 'Triangle Calculator',
      parameters: parameters,
      onCalculate: _onCalculate,
      controllers: _controllers,
    );
  }
}
