import 'dart:async';
import 'dart:math';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class BaseShapePage extends StatefulWidget {
  final String title;
  final String shapeType;
  final List<String> parameters;
  final Map<String, List<Map<String, dynamic>>> unitOptions;

  const BaseShapePage({
    super.key,
    required this.title,
    required this.shapeType,
    required this.parameters,
    required this.unitOptions,
  });

  @override
  State<BaseShapePage> createState() => _BaseShapePageState();
}

class _BaseShapePageState extends State<BaseShapePage> {
  final Map<String, bool> _isInputEnabled = {};
  final Map<String, String> _unitSelections = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _results = {};
  String? _activeParameter;
  String _baseUnit = 'm';
  Timer? _debounce;
  final List<Map<String, String>> _history = [];
  final NumberFormat _numberFormat = NumberFormat.decimalPattern();

  final List<Map<String, dynamic>> _baseUnitOptions = [
    {'unit': 'm', 'label': 'Meter (m)', 'factor': 1.0},
    {'unit': 'cm', 'label': 'Centimeter (cm)', 'factor': 100.0},
    {'unit': 'km', 'label': 'Kilometer (km)', 'factor': 0.001},
    {'unit': 'ft', 'label': 'Foot (ft)', 'factor': 3.28084},
    {'unit': 'in', 'label': 'Inch (in)', 'factor': 39.3701},
    {'unit': 'mi', 'label': 'Mile (mi)', 'factor': 0.000621371},
  ];

  @override
  void initState() {
    super.initState();
    for (var param in widget.parameters) {
      _isInputEnabled[param] = false;
      _unitSelections[param] = _getDefaultUnitForParameter(param, _baseUnit);
      _controllers[param] = TextEditingController();
      _controllers[param]!.addListener(() => _calculate(_activeParameter));
    }
    _activeParameter = widget.parameters.first;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getDefaultUnitForParameter(String param, String baseUnit) {
    final units = widget.unitOptions[param] ?? [];
    if (units.isEmpty) return baseUnit;
    if (param.contains('Area')) {
      return units.firstWhere(
        (unit) =>
            unit['unit'].contains('²') && unit['unit'].startsWith(baseUnit),
        orElse: () => units.first,
      )['unit'];
    }
    if (param.contains('Volume')) {
      return units.firstWhere(
        (unit) =>
            unit['unit'].contains('³') && unit['unit'].startsWith(baseUnit),
        orElse: () => units.first,
      )['unit'];
    }
    return units.firstWhere(
      (unit) => unit['unit'] == baseUnit,
      orElse: () => units.first,
    )['unit'];
  }

  void _updateUnitSelections() {
    for (var param in widget.parameters) {
      _unitSelections[param] = _getDefaultUnitForParameter(param, _baseUnit);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void addToHistory(String expr, String res) {
    setState(() {
      _history.add({'expression': expr, 'result': res});
    });
  }

  void _showHistory() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Calculation History'),
        actions: _history.isEmpty
            ? [
                CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('No history available'),
                )
              ]
            : _history
                .asMap()
                .entries
                .map(
                  (entry) => CupertinoActionSheetAction(
                    onPressed: () {
                      _copyToClipboard(
                          '${entry.value['expression']} = ${entry.value['result']}');
                      Navigator.pop(context);
                    },
                    child: Text(
                      '${entry.value['expression']} = ${entry.value['result']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                )
                .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _clearInputs() {
    setState(() {
      for (var param in widget.parameters) {
        _controllers[param]!.clear();
        _isInputEnabled[param] = false;
        _unitSelections[param] = _getDefaultUnitForParameter(param, _baseUnit);
      }
      _activeParameter = widget.parameters.first;
      _baseUnit = 'm';
      _results.clear();
    });
  }

  void _onKeypadPress(String value) {
    if (_activeParameter != null && _isInputEnabled[_activeParameter]!) {
      final controller = _controllers[_activeParameter]!;
      if (value == '⌫') {
        if (controller.text.isNotEmpty) {
          controller.text =
              controller.text.substring(0, controller.text.length - 1);
        }
      } else {
        if (value == '.' && controller.text.contains('.')) return;
        controller.text += value;
      }
      _calculate(_activeParameter);
    }
  }

  void _calculate(String? activeParameter) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!_baseUnitOptions.any((unit) => unit['unit'] == _baseUnit)) {
        setState(() {
          _baseUnit = 'm';
          _updateUnitSelections();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid base unit, reset to meters')),
        );
      }

      double baseUnitToMeters = _baseUnitOptions
          .firstWhere((unit) => unit['unit'] == _baseUnit)['factor'];

      Map<String, String> inputs = {};
      for (var param in widget.parameters) {
        if (_isInputEnabled[param]! && _controllers[param]!.text.isNotEmpty) {
          inputs[param] = _controllers[param]!.text;
        }
      }

      Map<String, double> inputValues = {};
      for (var param in widget.parameters) {
        if (_isInputEnabled[param]! &&
            inputs.containsKey(param) &&
            inputs[param]!.isNotEmpty) {
          final text = inputs[param]!.replaceAll(',', '');
          try {
            double value = double.parse(text);
            if (param.contains('Area')) {
              value = value / (baseUnitToMeters * baseUnitToMeters);
            } else if (param.contains('Volume')) {
              value = value /
                  (baseUnitToMeters * baseUnitToMeters * baseUnitToMeters);
            } else {
              value = value / baseUnitToMeters;
            }
            inputValues[param] = value;
          } catch (e) {
            debugPrint('[_onCalculate] Invalid input for $param: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid input for $param')),
            );
            return;
          }
        }
      }

      debugPrint(
          '[_onCalculate] Parsed input values (in meters): $inputValues');

      _results.clear();
      switch (widget.shapeType) {
        case 'Rectangle':
          double? length, width, height, area, perimeter, volume;
          if (inputValues.containsKey('Length') &&
              inputValues.containsKey('Width') &&
              inputValues.containsKey('Height')) {
            length = inputValues['Length'];
            width = inputValues['Width'];
            height = inputValues['Height'];
            if (length! <= 0 || width! <= 0 || height! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Length, Width, and Height must be greater than 0')),
              );
              return;
            }
            area = length * width;
            perimeter = 2 * (length + width);
            volume = length * width * height;
          } else if (inputValues.containsKey('Length') &&
              inputValues.containsKey('Width')) {
            length = inputValues['Length'];
            width = inputValues['Width'];
            if (length! <= 0 || width! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Length and Width must be greater than 0')),
              );
              return;
            }
            area = length * width;
            perimeter = 2 * (length + width);
            if (inputValues.containsKey('Height')) {
              height = inputValues['Height'];
              if (height! <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Height must be greater than 0')),
                );
                return;
              }
              volume = length * width * height;
            }
          } else if (inputValues.containsKey('Length') &&
              inputValues.containsKey('Area')) {
            length = inputValues['Length'];
            area = inputValues['Area'];
            if (length! <= 0 || area! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Length and Area must be greater than 0')),
              );
              return;
            }
            width = area / length;
            perimeter = 2 * (length + width);
          } else if (inputValues.containsKey('Width') &&
              inputValues.containsKey('Area')) {
            width = inputValues['Width'];
            area = inputValues['Area'];
            if (width! <= 0 || area! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Width and Area must be greater than 0')),
              );
              return;
            }
            length = area / width;
            perimeter = 2 * (length + width);
          } else if (inputValues.containsKey('Length') &&
              inputValues.containsKey('Perimeter')) {
            length = inputValues['Length'];
            perimeter = inputValues['Perimeter'];
            if (length! <= 0 || perimeter! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Length and Perimeter must be greater than 0')),
              );
              return;
            }
            double halfPerimeter = perimeter / 2;
            if (halfPerimeter <= length) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Perimeter must be greater than 2 * Length')),
              );
              return;
            }
            width = halfPerimeter - length;
            area = length * width;
          } else if (inputValues.containsKey('Width') &&
              inputValues.containsKey('Perimeter')) {
            width = inputValues['Width'];
            perimeter = inputValues['Perimeter'];
            if (width! <= 0 || perimeter! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Width and Perimeter must be greater than 0')),
              );
              return;
            }
            double halfPerimeter = perimeter / 2;
            if (halfPerimeter <= width) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Perimeter must be greater than 2 * Width')),
              );
              return;
            }
            length = halfPerimeter - width;
            area = length * width;
          } else if (inputValues.containsKey('Area') &&
              inputValues.containsKey('Volume')) {
            area = inputValues['Area'];
            volume = inputValues['Volume'];
            if (area! <= 0 || volume! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Area and Volume must be greater than 0')),
              );
              return;
            }
            height = volume / area;
          } else if (inputValues.containsKey('Area') &&
              inputValues.containsKey('Perimeter')) {
            area = inputValues['Area'];
            perimeter = inputValues['Perimeter'];
            if (area! <= 0 || perimeter! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Area and Perimeter must be greater than 0')),
              );
              return;
            }
            double sumLW = perimeter / 2;
            double productLW = area;
            double discriminant = sumLW * sumLW - 4 * productLW;
            if (discriminant < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Inconsistent inputs: cannot form a rectangle')),
              );
              return;
            }
            double sqrtDiscriminant = sqrt(discriminant);
            length = (sumLW + sqrtDiscriminant) / 2;
            width = (sumLW - sqrtDiscriminant) / 2;
          }
          if (length != null) _results['Length'] = _numberFormat.format(length);
          if (width != null) _results['Width'] = _numberFormat.format(width);
          if (height != null) _results['Height'] = _numberFormat.format(height);
          if (area != null) _results['Area'] = _numberFormat.format(area);
          if (perimeter != null)
            _results['Perimeter'] = _numberFormat.format(perimeter);
          if (volume != null) _results['Volume'] = _numberFormat.format(volume);
          break;

        case 'Square':
          double? side, area, perimeter, diagonal;
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
                const SnackBar(
                    content: Text('Perimeter must be greater than 0')),
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
                const SnackBar(
                    content: Text('Diagonal must be greater than 0')),
              );
              return;
            }
            side = diagonal / sqrt(2);
            area = side * side;
            perimeter = 4 * side;
          }
          if (side != null) _results['Side'] = _numberFormat.format(side);
          if (area != null) _results['Area'] = _numberFormat.format(area);
          if (perimeter != null)
            _results['Perimeter'] = _numberFormat.format(perimeter);
          if (diagonal != null)
            _results['Diagonal'] = _numberFormat.format(diagonal);
          break;

        case 'Circle':
          double? radius, diameter, area, circumference;
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
                const SnackBar(
                    content: Text('Diameter must be greater than 0')),
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
                const SnackBar(
                    content: Text('Circumference must be greater than 0')),
              );
              return;
            }
            radius = circumference / (2 * pi);
            diameter = 2 * radius;
            area = pi * radius * radius;
          }
          if (radius != null) _results['Radius'] = _numberFormat.format(radius);
          if (diameter != null)
            _results['Diameter'] = _numberFormat.format(diameter);
          if (area != null) _results['Area'] = _numberFormat.format(area);
          if (circumference != null)
            _results['Circumference'] = _numberFormat.format(circumference);
          break;

        case 'Triangle':
          double? base, height, sideA, sideB, area, perimeter;
          if (inputValues.containsKey('Base') &&
              inputValues.containsKey('Height')) {
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
                      content: Text(
                          'Invalid triangle: sides do not form a triangle')),
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
                const SnackBar(
                    content: Text('Base and Area must be greater than 0')),
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
                      content: Text(
                          'Invalid triangle: sides do not form a triangle')),
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
                    content:
                        Text('Invalid triangle: sides do not form a triangle')),
              );
              return;
            }
            perimeter = sideA + sideB + base;
            if (inputValues.containsKey('Height')) {
              height = inputValues['Height'];
              if (height! <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Height must be greater than 0')),
                );
                return;
              }
              area = 0.5 * base * height;
            }
          }
          if (base != null) _results['Base'] = _numberFormat.format(base);
          if (height != null) _results['Height'] = _numberFormat.format(height);
          if (sideA != null) _results['Side A'] = _numberFormat.format(sideA);
          if (sideB != null) _results['Side B'] = _numberFormat.format(sideB);
          if (area != null) _results['Area'] = _numberFormat.format(area);
          if (perimeter != null)
            _results['Perimeter'] = _numberFormat.format(perimeter);
          break;

        case 'Trapezoid':
          double? baseA, baseB, height, sideC, sideD, area, perimeter;
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
                  const SnackBar(
                      content: Text('Height must be greater than 0')),
                );
                return;
              }
              area = 0.5 * (baseA + baseB) * height;
            }
          }
          if (baseA != null) _results['Base A'] = _numberFormat.format(baseA);
          if (baseB != null) _results['Base B'] = _numberFormat.format(baseB);
          if (height != null) _results['Height'] = _numberFormat.format(height);
          if (sideC != null) _results['Side C'] = _numberFormat.format(sideC);
          if (sideD != null) _results['Side D'] = _numberFormat.format(sideD);
          if (area != null) _results['Area'] = _numberFormat.format(area);
          if (perimeter != null)
            _results['Perimeter'] = _numberFormat.format(perimeter);
          break;
      }

      setState(() {
        debugPrint('[_onCalculate] Calculated results (in meters): $_results');
        for (var param in widget.parameters) {
          if (!(_isInputEnabled[param] ?? false)) {
            _controllers[param]!.text = _results[param] ?? '';
            debugPrint(
                '[_onCalculate] Updated $param controller: ${_controllers[param]!.text}');
          } else if (!inputValues.containsKey(param)) {
            _controllers[param]!.clear();
          }
        }

        if (_results.isNotEmpty) {
          String expr = inputValues.entries
              .map((e) =>
                  '${e.key}=${_numberFormat.format(double.parse(inputs[e.key]!))} $_baseUnit')
              .join(', ');
          String res = _results.entries
              .map((e) =>
                  '${e.key}=${e.value} ${_isInputEnabled[e.key]! ? _baseUnit : _unitSelections[e.key]}')
              .join(', ');
          addToHistory(expr, res);
        }
      });
    });
  }

  Widget _buildKeypadButton(String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: CupertinoButton(
          color: CupertinoColors.systemGrey5,
          padding: EdgeInsets.zero,
          onPressed: () => _onKeypadPress(value),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              color: CupertinoColors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitPicker(String parameter) {
    final units = widget.unitOptions[parameter] ?? [];
    if (units.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: 100,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => CupertinoActionSheet(
              title: Text('Select Unit for $parameter'),
              actions: units
                  .map(
                    (unit) => CupertinoActionSheetAction(
                      onPressed: () {
                        setState(() {
                          _unitSelections[parameter] = unit['unit'];
                        });
                        Navigator.pop(context);
                      },
                      child: Text(unit['unit']),
                    ),
                  )
                  .toList(),
              cancelButton: CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _unitSelections[parameter] ??
                  _getDefaultUnitForParameter(parameter, _baseUnit),
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.activeBlue,
              ),
            ),
            const Icon(
              FluentIcons.chevron_down_24_regular,
              size: 16,
              color: CupertinoColors.activeBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBaseUnitPicker() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey4, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Base Unit:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              color: CupertinoColors.black,
            ),
          ),
          GestureDetector(
            onTap: () {
              showCupertinoModalPopup(
                context: context,
                builder: (context) => Container(
                  height: 240,
                  color: CupertinoColors.systemBackground,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: const Text(
                          'Select Base Unit',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 36,
                          onSelectedItemChanged: (index) {
                            setState(() {
                              _baseUnit = _baseUnitOptions[index]['unit'];
                              _updateUnitSelections();
                              _calculate(_activeParameter);
                            });
                          },
                          scrollController: FixedExtentScrollController(
                            initialItem: _baseUnitOptions.indexWhere(
                                (unit) => unit['unit'] == _baseUnit),
                          ),
                          children: _baseUnitOptions
                              .map((unit) => Center(
                                    child: Text(
                                      unit['label'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      CupertinoButton(
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.activeBlue,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Row(
              children: [
                Text(
                  _baseUnitOptions.firstWhere(
                          (unit) => unit['unit'] == _baseUnit,
                          orElse: () => _baseUnitOptions[0])['label'] ??
                      'Meter (m)',
                  style: const TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.activeBlue,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  FluentIcons.chevron_down_24_regular,
                  size: 16,
                  color: CupertinoColors.activeBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterCard(BuildContext context, String parameter) {
    final currentTheme = CupertinoTheme.of(context);
    final bool isInput = _isInputEnabled[parameter] ?? false;
    final currentUnit = _unitSelections[parameter] ??
        _getDefaultUnitForParameter(parameter, _baseUnit);
    final units = widget.unitOptions[parameter] ?? [];
    double conversionFactor = 1.0;
    if (!isInput && units.isNotEmpty) {
      final selectedUnit = units.firstWhere(
        (unit) => unit['unit'] == currentUnit,
        orElse: () => units.first,
      );
      conversionFactor = selectedUnit['factor'];
    }

    String displayText = _controllers[parameter]!.text;
    if (!isInput && displayText.isNotEmpty) {
      try {
        final value = double.parse(displayText.replaceAll(',', ''));
        final convertedValue = value * conversionFactor;
        displayText = _numberFormat.format(convertedValue);
      } catch (e) {
        debugPrint('Error converting value for $parameter: $e');
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, right: 8.0),
          child: CupertinoCheckbox(
            value: isInput,
            shape: const CircleBorder(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _isInputEnabled[parameter] = value;
                  if (value) {
                    _controllers[parameter]!.clear();
                    _activeParameter = parameter;
                  } else {
                    _controllers[parameter]!.text = _results[parameter] ?? '';
                    if (_activeParameter == parameter) {
                      _activeParameter = widget.parameters.firstWhere(
                          (p) => _isInputEnabled[p]!,
                          orElse: () => widget.parameters.first);
                    }
                  }
                  _calculate(_activeParameter);
                });
              }
            },
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (isInput) {
                setState(() {
                  _activeParameter = parameter;
                });
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: currentTheme.barBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _activeParameter == parameter && isInput
                      ? currentTheme.primaryColor
                      : CupertinoColors.systemGrey4,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              parameter,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: currentTheme.textTheme.textStyle.color,
                              ),
                            ),
                            if (!isInput &&
                                _controllers[parameter]!.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: _buildUnitPicker(parameter),
                              ),
                          ],
                        ),
                      ),
                      if (!isInput && _controllers[parameter]!.text.isNotEmpty)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () =>
                              _copyToClipboard('$displayText $currentUnit'),
                          child: Icon(
                            FluentIcons.copy_24_regular,
                            size: 20,
                            color: currentTheme.primaryColor,
                          ),
                        ),
                    ],
                  ),
                  if (isInput)
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoTextField(
                            controller: _controllers[parameter],
                            placeholder: 'Enter value ($_baseUnit)',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 24,
                              fontFamily: 'Inter',
                              color: currentTheme.textTheme.textStyle.color,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            readOnly: true,
                            showCursor: true,
                            decoration: const BoxDecoration(),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _baseUnit,
                          style: const TextStyle(
                            fontSize: 24,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      displayText.isNotEmpty ? '$displayText $currentUnit' : '',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                        color: displayText.isNotEmpty
                            ? currentTheme.textTheme.textStyle.color
                            : currentTheme.textTheme.textStyle.color!
                                .withOpacity(0.5),
                      ),
                      textAlign: TextAlign.left,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showHistory,
          child: const Icon(CupertinoIcons.clock),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ...widget.parameters
                  .map((param) => _buildParameterCard(context, param)),
              _buildBaseUnitPicker(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: () => _calculate(_activeParameter),
                      child: const Text('Calculate'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CupertinoButton(
                      onPressed: _clearInputs,
                      color: CupertinoColors.systemGrey,
                      child: const Text('Clear'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildKeypadButton('7'),
                        _buildKeypadButton('8'),
                        _buildKeypadButton('9'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildKeypadButton('4'),
                        _buildKeypadButton('5'),
                        _buildKeypadButton('6'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildKeypadButton('1'),
                        _buildKeypadButton('2'),
                        _buildKeypadButton('3'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildKeypadButton('0'),
                        _buildKeypadButton('.'),
                        _buildKeypadButton('⌫'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
