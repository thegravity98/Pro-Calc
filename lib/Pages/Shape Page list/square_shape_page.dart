import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../base_shape_page.dart';

class SquareShapePage extends StatefulWidget {
  const SquareShapePage({super.key});

  @override
  State<SquareShapePage> createState() => _SquareShapePageState();
}

class _SquareShapePageState extends State<SquareShapePage> {
  final List<String> parameters = ['Side', 'Area', 'Perimeter', 'Diagonal'];
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
    double? side, area, perimeter, diagonal;

    // Calculation Logic
    if (inputValues.containsKey('Side')) {
      side = inputValues['Side'];
      if (side! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Side must be greater than 0')),
        );
        return;
      }
      area = side * side;
      perimeter = 4 * side;
      diagonal = side * sqrt(2);
    } else if (inputValues.containsKey('Area')) {
      area = inputValues['Area'];
      if (area! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Area must be greater than 0')),
        );
        return;
      }
      side = sqrt(area);
      perimeter = 4 * side;
      diagonal = side * sqrt(2);
    } else if (inputValues.containsKey('Perimeter')) {
      perimeter = inputValues['Perimeter'];
      if (perimeter! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perimeter must be greater than 0')),
        );
        return;
      }
      side = perimeter / 4;
      area = side * side;
      diagonal = side * sqrt(2);
    } else if (inputValues.containsKey('Diagonal')) {
      diagonal = inputValues['Diagonal'];
      if (diagonal! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diagonal must be greater than 0')),
        );
        return;
      }
      side = diagonal / sqrt(2);
      area = side * side;
      perimeter = 4 * side;
    }

    // Update Results and Controllers
    setState(() {
      _results.clear();
      if (side != null) _results['Side'] = _numberFormat.format(side);
      if (area != null) _results['Area'] = _numberFormat.format(area);
      if (perimeter != null)
        _results['Perimeter'] = _numberFormat.format(perimeter);
      if (diagonal != null)
        _results['Diagonal'] = _numberFormat.format(diagonal);

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
      title: 'Square Calculator',
      parameters: parameters,
      onCalculate: _onCalculate,
      controllers: _controllers,
    );
  }
}
