import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../base_shape_page.dart';

class CircleShapePage extends StatefulWidget {
  const CircleShapePage({super.key});

  @override
  State<CircleShapePage> createState() => _CircleShapePageState();
}

class _CircleShapePageState extends State<CircleShapePage> {
  final List<String> parameters = [
    'Radius',
    'Diameter',
    'Area',
    'Circumference'
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
    double? radius, diameter, area, circumference;

    // Calculation Logic
    if (inputValues.containsKey('Radius')) {
      radius = inputValues['Radius'];
      if (radius! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Radius must be greater than 0')),
        );
        return;
      }
      diameter = 2 * radius;
      area = pi * radius * radius;
      circumference = 2 * pi * radius;
    } else if (inputValues.containsKey('Diameter')) {
      diameter = inputValues['Diameter'];
      if (diameter! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diameter must be greater than 0')),
        );
        return;
      }
      radius = diameter / 2;
      area = pi * radius * radius;
      circumference = pi * diameter;
    } else if (inputValues.containsKey('Area')) {
      area = inputValues['Area'];
      if (area! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Area must be greater than 0')),
        );
        return;
      }
      radius = sqrt(area / pi);
      diameter = 2 * radius;
      circumference = 2 * pi * radius;
    } else if (inputValues.containsKey('Circumference')) {
      circumference = inputValues['Circumference'];
      if (circumference! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Circumference must be greater than 0')),
        );
        return;
      }
      radius = circumference / (2 * pi);
      diameter = 2 * radius;
      area = pi * radius * radius;
    }

    // Update Results and Controllers
    setState(() {
      _results.clear();
      if (radius != null) _results['Radius'] = _numberFormat.format(radius);
      if (diameter != null)
        _results['Diameter'] = _numberFormat.format(diameter);
      if (area != null) _results['Area'] = _numberFormat.format(area);
      if (circumference != null)
        _results['Circumference'] = _numberFormat.format(circumference);

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
      title: 'Circle Calculator',
      parameters: parameters,
      onCalculate: _onCalculate,
      controllers: _controllers,
    );
  }
}
