import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../base_shape_page.dart';

class RectangleShapePage extends StatefulWidget {
  const RectangleShapePage({super.key});

  @override
  State<RectangleShapePage> createState() => _RectangleShapePageState();
}

class _RectangleShapePageState extends State<RectangleShapePage> {
  final List<String> parameters = [
    'Length',
    'Width',
    'Height',
    'Area',
    'Perimeter',
    'Volume'
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

    // Parse input values only for enabled fields with non-empty text
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
    double? length, width, height, area, perimeter, volume;

    // Calculation Logic Based on Available Inputs
    if (inputValues.containsKey('Length') &&
        inputValues.containsKey('Width') &&
        inputValues.containsKey('Height')) {
      debugPrint('[_onCalculate] Case: L, W, H are inputs');
      length = inputValues['Length'];
      width = inputValues['Width'];
      height = inputValues['Height'];
      area = length! * width!;
      perimeter = 2 * (length + width);
      volume = length * width * height!;
    } else if (inputValues.containsKey('Length') &&
        inputValues.containsKey('Width')) {
      debugPrint('[_onCalculate] Case: L, W are inputs (2D)');
      length = inputValues['Length'];
      width = inputValues['Width'];
      area = length! * width!;
      perimeter = 2 * (length + width);
      if (inputValues.containsKey('Height')) {
        height = inputValues['Height'];
        volume = length * width * height!;
      }
    } else if (inputValues.containsKey('Length') &&
        inputValues.containsKey('Area')) {
      debugPrint('[_onCalculate] Case: L, Area are inputs');
      length = inputValues['Length'];
      area = inputValues['Area'];
      if (length! > 0) {
        width = area! / length;
        perimeter = 2 * (length + width);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Length must be greater than 0')),
        );
        return;
      }
    } else if (inputValues.containsKey('Width') &&
        inputValues.containsKey('Area')) {
      debugPrint('[_onCalculate] Case: W, Area are inputs');
      width = inputValues['Width'];
      area = inputValues['Area'];
      if (width! > 0) {
        length = area! / width;
        perimeter = 2 * (length + width);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Width must be greater than 0')),
        );
        return;
      }
    } else if (inputValues.containsKey('Length') &&
        inputValues.containsKey('Perimeter')) {
      debugPrint('[_onCalculate] Case: L, Perimeter are inputs');
      length = inputValues['Length'];
      perimeter = inputValues['Perimeter'];
      double halfPerimeter = perimeter! / 2;
      if (halfPerimeter > length!) {
        width = halfPerimeter - length;
        area = length * width;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Perimeter must be greater than 2 * Length')),
        );
        return;
      }
    } else if (inputValues.containsKey('Width') &&
        inputValues.containsKey('Perimeter')) {
      debugPrint('[_onCalculate] Case: W, Perimeter are inputs');
      width = inputValues['Width'];
      perimeter = inputValues['Perimeter'];
      double halfPerimeter = perimeter! / 2;
      if (halfPerimeter > width!) {
        length = halfPerimeter - width;
        area = length * width;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Perimeter must be greater than 2 * Width')),
        );
        return;
      }
    } else if (inputValues.containsKey('Area') &&
        inputValues.containsKey('Volume')) {
      debugPrint('[_onCalculate] Case: Area, Volume are inputs');
      area = inputValues['Area'];
      volume = inputValues['Volume'];
      if (area! > 0) {
        height = volume! / area;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Area must be greater than 0')),
        );
        return;
      }
    } else if (inputValues.containsKey('Area') &&
        inputValues.containsKey('Perimeter')) {
      debugPrint('[_onCalculate] Case: Area, Perimeter are inputs (2D)');
      area = inputValues['Area'];
      perimeter = inputValues['Perimeter'];
      double sumLW = perimeter! / 2;
      double productLW = area!;
      double discriminant = sumLW * sumLW - 4 * productLW;
      if (discriminant < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Inconsistent inputs: cannot form a rectangle')),
        );
        return;
      }
      double sqrtDiscriminant = sqrt(discriminant);
      length = (sumLW + sqrtDiscriminant) / 2;
      width = (sumLW - sqrtDiscriminant) / 2;
    } else {
      debugPrint('[_onCalculate] Insufficient inputs for calculation');
    }

    // Update Results and Controllers
    setState(() {
      _results.clear();
      if (length != null) _results['Length'] = _numberFormat.format(length);
      if (width != null) _results['Width'] = _numberFormat.format(width);
      if (height != null) _results['Height'] = _numberFormat.format(height);
      if (area != null) _results['Area'] = _numberFormat.format(area);
      if (perimeter != null)
        _results['Perimeter'] = _numberFormat.format(perimeter);
      if (volume != null) _results['Volume'] = _numberFormat.format(volume);

      debugPrint('[_onCalculate] Calculated results: $_results');

      // Update controllers for disabled parameters
      for (var param in parameters) {
        if (!isInputEnabled[param]!) {
          _controllers[param]!.text = _results[param] ?? '';
          debugPrint(
              '[_onCalculate] Updated $param controller: ${_controllers[param]!.text}');
        } else if (!inputValues.containsKey(param)) {
          _controllers[param]!.clear();
        }
      }

      // Save to history if there are results
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
      title: 'Rectangle Calculator',
      parameters: parameters,
      onCalculate: _onCalculate,
      controllers: _controllers,
    );
  }
}
