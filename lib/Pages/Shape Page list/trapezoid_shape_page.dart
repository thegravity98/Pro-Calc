import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../base_shape_page.dart';

class TrapezoidShapePage extends StatefulWidget {
  const TrapezoidShapePage({super.key});

  @override
  State<TrapezoidShapePage> createState() => _TrapezoidShapePageState();
}

class _TrapezoidShapePageState extends State<TrapezoidShapePage> {
  final List<String> parameters = [
    'Base A',
    'Base B',
    'Height',
    'Side C',
    'Side D',
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
    double? baseA, baseB, height, sideC, sideD, area, perimeter;

    // Calculation Logic
    if (inputValues.containsKey('Base A') &&
        inputValues.containsKey('Base B') &&
        inputValues.containsKey('Height')) {
      baseA = inputValues['Base A'];
      baseB = inputValues['Base B'];
      height = inputValues['Height'];
      if (baseA! <= 0 || baseB! <= 0 || height! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bases and Height must be greater than 0')),
        );
        return;
      }
      area = 0.5 * (baseA + baseB) * height;
      if (inputValues.containsKey('Side C') &&
          inputValues.containsKey('Side D')) {
        sideC = inputValues['Side C'];
        sideD = inputValues['Side D'];
        if (sideC! <= 0 || sideD! <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sides must be greater than 0')),
          );
          return;
        }
        perimeter = baseA + baseB + sideC + sideD;
      }
    } else if (inputValues.containsKey('Base A') &&
        inputValues.containsKey('Base B') &&
        inputValues.containsKey('Area')) {
      baseA = inputValues['Base A'];
      baseB = inputValues['Base B'];
      area = inputValues['Area'];
      if (baseA! <= 0 || baseB! <= 0 || area! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bases and Area must be greater than 0')),
        );
        return;
      }
      height = (2 * area) / (baseA + baseB);
      if (inputValues.containsKey('Side C') &&
          inputValues.containsKey('Side D')) {
        sideC = inputValues['Side C'];
        sideD = inputValues['Side D'];
        if (sideC! <= 0 || sideD! <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sides must be greater than 0')),
          );
          return;
        }
        perimeter = baseA + baseB + sideC + sideD;
      }
    } else if (inputValues.containsKey('Base A') &&
        inputValues.containsKey('Base B') &&
        inputValues.containsKey('Side C') &&
        inputValues.containsKey('Side D')) {
      baseA = inputValues['Base A'];
      baseB = inputValues['Base B'];
      sideC = inputValues['Side C'];
      sideD = inputValues['Side D'];
      if (baseA! <= 0 || baseB! <= 0 || sideC! <= 0 || sideD! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bases and Sides must be greater than 0')),
        );
        return;
      }
      perimeter = baseA + baseB + sideC + sideD;
      if (inputValues.containsKey('Height')) {
        height = inputValues['Height'];
        if (height! <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Height must be greater than 0')),
          );
          return;
        }
        area = 0.5 * (baseA + baseB) * height;
      }
    }

    // Update Results and Controllers
    setState(() {
      _results.clear();
      if (baseA != null) _results['Base A'] = _numberFormat.format(baseA);
      if (baseB != null) _results['Base B'] = _numberFormat.format(baseB);
      if (height != null) _results['Height'] = _numberFormat.format(height);
      if (sideC != null) _results['Side C'] = _numberFormat.format(sideC);
      if (sideD != null) _results['Side D'] = _numberFormat.format(sideD);
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
      title: 'Trapezoid Calculator',
      parameters: parameters,
      onCalculate: _onCalculate,
      controllers: _controllers,
    );
  }
}
