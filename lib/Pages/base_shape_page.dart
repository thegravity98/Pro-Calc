import 'dart:async';
import 'dart:math';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart' show Material, Colors; // For Overlay message if needed, and default shadow color
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
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

  // --- Keypad Configuration (Adapted from CalcPage) ---
  final List<List<String>> _keypadRows = [
    ['7', '8', '9'],
    ['4', '5', '6'],
    ['1', '2', '3'],
    ['00', '0', '.']
  ];
  final List<String> _sideButtons = ['AC', 'del'];

  @override
  void initState() {
    super.initState();
    for (var param in widget.parameters) {
      _isInputEnabled[param] = false;
      _unitSelections[param] = _getDefaultUnitForParameter(param, _baseUnit);
      _controllers[param] = TextEditingController();
      // Attach listener only if the field is an input field.
      // Calculation is triggered by _onKeypadPress or when input field focus changes.
      _controllers[param]!.addListener(() {
        if (_isInputEnabled[param] == true && _activeParameter == param) {
          _calculate(_activeParameter);
        }
      });
    }
    _activeParameter = widget.parameters.firstWhere(
        (p) => _isInputEnabled[p] == true,
        orElse: () => widget.parameters.first);
    if (_isInputEnabled.values.every((enabled) => !enabled) &&
        widget.parameters.isNotEmpty) {
      _isInputEnabled[widget.parameters.first] = true;
      _activeParameter = widget.parameters.first;
    }
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
        orElse: () => units.firstWhere((unit) => unit['unit'].contains('²'),
            orElse: () => units.first),
      )['unit'];
    }
    if (param.contains('Volume')) {
      return units.firstWhere(
        (unit) =>
            unit['unit'].contains('³') && unit['unit'].startsWith(baseUnit),
        orElse: () => units.firstWhere((unit) => unit['unit'].contains('³'),
            orElse: () => units.first),
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
    _calculate(_activeParameter); // Recalculate when base unit changes units
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void addToHistory(String expr, String res) {
    if (!mounted) return;
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
    if (!mounted) return;
    setState(() {
      for (var param in widget.parameters) {
        _controllers[param]!.clear();
        // Reset all fields to be non-inputs initially, or based on some default
        _isInputEnabled[param] = false;
        _unitSelections[param] = _getDefaultUnitForParameter(param, _baseUnit);
      }
      // Set the first parameter as active input by default after clearing
      if (widget.parameters.isNotEmpty) {
        _isInputEnabled[widget.parameters.first] = true;
        _activeParameter = widget.parameters.first;
      } else {
        _activeParameter = null;
      }
      // _baseUnit = 'm'; // Optionally reset base unit, or keep user's preference
      _results.clear();
      // _updateUnitSelections(); // This will be called if baseUnit is reset
    });
  }

  void _onKeypadPress(String value) {
    if (_activeParameter != null && _isInputEnabled[_activeParameter]!) {
      final controller = _controllers[_activeParameter]!;
      final String currentText = controller.text;
      final TextSelection currentSelection = controller.selection;
      final int cursorPos = currentSelection.baseOffset >= 0
          ? currentSelection.baseOffset.clamp(0, currentText.length)
          : currentText.length; // Fallback to end if selection is invalid

      String newText;
      int newCursorPos = cursorPos;

      if (value == '⌫') {
        // Corresponds to 'del'
        if (cursorPos > 0) {
          newText = currentText.substring(0, cursorPos - 1) +
              currentText.substring(cursorPos);
          newCursorPos = cursorPos - 1;
        } else {
          newText = currentText; // No change if cursor is at the beginning
        }
      } else if (value == '.' &&
          currentText.substring(0, cursorPos).contains('.')) {
        // Prevent multiple decimal points in the part of the number before the cursor
        // More robust checking might be needed if inserting in middle of a number
        if (!currentText.substring(cursorPos).contains('.') &&
            !currentText.contains('.')) {
          newText = currentText.substring(0, cursorPos) +
              value +
              currentText.substring(cursorPos);
          newCursorPos = cursorPos + value.length;
        } else {
          return; // Do nothing if decimal already exists
        }
      } else {
        newText = currentText.substring(0, cursorPos) +
            value +
            currentText.substring(cursorPos);
        newCursorPos = cursorPos + value.length;
      }

      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: newCursorPos.clamp(0, newText.length)),
      );
      // _calculate(_activeParameter); // Listener will trigger this
    }
  }

  void _calculate(String? activeParameter) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final baseUnitOption = _baseUnitOptions.firstWhere(
          (unit) => unit['unit'] == _baseUnit,
          orElse: () => _baseUnitOptions.firstWhere((u) => u['unit'] == 'm'));

      _baseUnit = baseUnitOption['unit'];
      double metersToBaseUnitFactor = baseUnitOption['factor'];

      Map<String, String> inputsForHistory = {};
      Map<String, double> inputValuesInMeters = {};

      for (var param in widget.parameters) {
        if (_isInputEnabled[param]! && _controllers[param]!.text.isNotEmpty) {
          final text = _controllers[param]!.text.replaceAll(',', '');
          inputsForHistory[param] = text;
          try {
            double value = double.parse(text);
            if (param.contains('Area')) {
              inputValuesInMeters[param] =
                  value / (metersToBaseUnitFactor * metersToBaseUnitFactor);
            } else if (param.contains('Volume')) {
              inputValuesInMeters[param] = value /
                  (metersToBaseUnitFactor *
                      metersToBaseUnitFactor *
                      metersToBaseUnitFactor);
            } else {
              inputValuesInMeters[param] = value / metersToBaseUnitFactor;
            }
          } catch (e) {
            debugPrint('[_calculate] Invalid input for $param: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invalid input for $param')),
              );
            }
            // Clear results for this invalid calculation attempt
            setState(() {
              _results.clear();
              for (var p in widget.parameters) {
                if (!(_isInputEnabled[p] ?? false)) {
                  _controllers[p]!.clear();
                }
              }
            });
            return;
          }
        }
      }

      debugPrint(
          '[_calculate] Parsed input values (in meters): $inputValuesInMeters');

      Map<String, double> calculatedValuesInMeters = {};
      // --- Calculation logic (switch widget.shapeType) ---
      // ... (existing calculation logic remains the same)
      // ... ensure all results are stored in calculatedValuesInMeters
      switch (widget.shapeType) {
        case 'Rectangle':
          double? length, width, height, area, perimeter, volume;
          if (inputValuesInMeters.containsKey('Length') &&
              inputValuesInMeters.containsKey('Width') &&
              inputValuesInMeters.containsKey('Height')) {
            length = inputValuesInMeters['Length'];
            width = inputValuesInMeters['Width'];
            height = inputValuesInMeters['Height'];
            if (length! <= 0 || width! <= 0 || height! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Length, Width, and Height must be > 0')),
              );
              return;
            }
            area = length * width;
            perimeter = 2 * (length + width);
            volume = length * width * height;
          } else if (inputValuesInMeters.containsKey('Length') &&
              inputValuesInMeters.containsKey('Width')) {
            length = inputValuesInMeters['Length'];
            width = inputValuesInMeters['Width'];
            if (length! <= 0 || width! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Length and Width must be > 0')),
              );
              return;
            }
            area = length * width;
            perimeter = 2 * (length + width);
            if (inputValuesInMeters.containsKey('Height')) {
              height = inputValuesInMeters['Height'];
              if (height! <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Height must be > 0')),
                );
                return;
              }
              volume = length * width * height;
            }
          } else if (inputValuesInMeters.containsKey('Length') &&
              inputValuesInMeters.containsKey('Area')) {
            length = inputValuesInMeters['Length'];
            area = inputValuesInMeters['Area'];
            if (length! <= 0 || area! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Length and Area must be > 0')),
              );
              return;
            }
            width = area / length;
            perimeter = 2 * (length + width);
          } else if (inputValuesInMeters.containsKey('Width') &&
              inputValuesInMeters.containsKey('Area')) {
            width = inputValuesInMeters['Width'];
            area = inputValuesInMeters['Area'];
            if (width! <= 0 || area! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Width and Area must be > 0')),
              );
              return;
            }
            length = area / width;
            perimeter = 2 * (length + width);
          } else if (inputValuesInMeters.containsKey('Length') &&
              inputValuesInMeters.containsKey('Perimeter')) {
            length = inputValuesInMeters['Length'];
            perimeter = inputValuesInMeters['Perimeter'];
            if (length! <= 0 || perimeter! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Length and Perimeter must be > 0')),
              );
              return;
            }
            double halfPerimeter = perimeter / 2;
            if (halfPerimeter <= length) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Perimeter must be > 2 * Length')),
              );
              return;
            }
            width = halfPerimeter - length;
            area = length * width;
          } else if (inputValuesInMeters.containsKey('Width') &&
              inputValuesInMeters.containsKey('Perimeter')) {
            width = inputValuesInMeters['Width'];
            perimeter = inputValuesInMeters['Perimeter'];
            if (width! <= 0 || perimeter! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Width and Perimeter must be > 0')),
              );
              return;
            }
            double halfPerimeter = perimeter / 2;
            if (halfPerimeter <= width) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Perimeter must be > 2 * Width')),
              );
              return;
            }
            length = halfPerimeter - width;
            area = length * width;
          } else if (inputValuesInMeters.containsKey('Area') &&
              inputValuesInMeters.containsKey('Volume')) {
            area = inputValuesInMeters['Area'];
            volume = inputValuesInMeters['Volume'];
            if (area! <= 0 || volume! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Area and Volume must be > 0')),
              );
              return;
            }
            height = volume / area;
          } else if (inputValuesInMeters.containsKey('Area') &&
              inputValuesInMeters.containsKey('Perimeter')) {
            area = inputValuesInMeters['Area'];
            perimeter = inputValuesInMeters['Perimeter'];
            if (area! <= 0 || perimeter! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Area and Perimeter must be > 0')),
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
          if (length != null) calculatedValuesInMeters['Length'] = length;
          if (width != null) calculatedValuesInMeters['Width'] = width;
          if (height != null) calculatedValuesInMeters['Height'] = height;
          if (area != null) calculatedValuesInMeters['Area'] = area;
          if (perimeter != null) {
            calculatedValuesInMeters['Perimeter'] = perimeter;
          }
          if (volume != null) calculatedValuesInMeters['Volume'] = volume;
          break;

        case 'Square':
          double? side, area, perimeter, diagonal;
          if (inputValuesInMeters.containsKey('Side')) {
            side = inputValuesInMeters['Side'];
            if (side! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Side must be > 0')),
              );
              return;
            }
            area = side * side;
            perimeter = 4 * side;
            diagonal = side * sqrt(2);
          } else if (inputValuesInMeters.containsKey('Area')) {
            area = inputValuesInMeters['Area'];
            if (area! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Area must be > 0')),
              );
              return;
            }
            side = sqrt(area);
            perimeter = 4 * side;
            diagonal = side * sqrt(2);
          } else if (inputValuesInMeters.containsKey('Perimeter')) {
            perimeter = inputValuesInMeters['Perimeter'];
            if (perimeter! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Perimeter must be > 0')),
              );
              return;
            }
            side = perimeter / 4;
            area = side * side;
            diagonal = side * sqrt(2);
          } else if (inputValuesInMeters.containsKey('Diagonal')) {
            diagonal = inputValuesInMeters['Diagonal'];
            if (diagonal! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Diagonal must be > 0')),
              );
              return;
            }
            side = diagonal / sqrt(2);
            area = side * side;
            perimeter = 4 * side;
          }
          if (side != null) calculatedValuesInMeters['Side'] = side;
          if (area != null) calculatedValuesInMeters['Area'] = area;
          if (perimeter != null) {
            calculatedValuesInMeters['Perimeter'] = perimeter;
          }
          if (diagonal != null) calculatedValuesInMeters['Diagonal'] = diagonal;
          break;

        case 'Circle':
          double? radius, diameter, area, circumference;
          if (inputValuesInMeters.containsKey('Radius')) {
            radius = inputValuesInMeters['Radius'];
            if (radius! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Radius must be > 0')),
              );
              return;
            }
            diameter = 2 * radius;
            area = pi * radius * radius;
            circumference = 2 * pi * radius;
          } else if (inputValuesInMeters.containsKey('Diameter')) {
            diameter = inputValuesInMeters['Diameter'];
            if (diameter! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Diameter must be > 0')),
              );
              return;
            }
            radius = diameter / 2;
            area = pi * radius * radius;
            circumference = pi * diameter;
          } else if (inputValuesInMeters.containsKey('Area')) {
            area = inputValuesInMeters['Area'];
            if (area! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Area must be > 0')),
              );
              return;
            }
            radius = sqrt(area / pi);
            diameter = 2 * radius;
            circumference = 2 * pi * radius;
          } else if (inputValuesInMeters.containsKey('Circumference')) {
            circumference = inputValuesInMeters['Circumference'];
            if (circumference! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Circumference must be > 0')),
              );
              return;
            }
            radius = circumference / (2 * pi);
            diameter = 2 * radius;
            area = pi * radius * radius;
          }
          if (radius != null) calculatedValuesInMeters['Radius'] = radius;
          if (diameter != null) calculatedValuesInMeters['Diameter'] = diameter;
          if (area != null) calculatedValuesInMeters['Area'] = area;
          if (circumference != null) {
            calculatedValuesInMeters['Circumference'] = circumference;
          }
          break;

        case 'Triangle':
          double? base, height, sideA, sideB, area, perimeter;
          if (inputValuesInMeters.containsKey('Base') &&
              inputValuesInMeters.containsKey('Height')) {
            base = inputValuesInMeters['Base'];
            height = inputValuesInMeters['Height'];
            if (base! <= 0 || height! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Base and Height must be > 0')),
              );
              return;
            }
            area = 0.5 * base * height;
            if (inputValuesInMeters.containsKey('Side A') &&
                inputValuesInMeters.containsKey('Side B')) {
              sideA = inputValuesInMeters['Side A'];
              sideB = inputValuesInMeters['Side B'];
              if (sideA! <= 0 || sideB! <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sides must be > 0')),
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
          } else if (inputValuesInMeters.containsKey('Base') &&
              inputValuesInMeters.containsKey('Area')) {
            base = inputValuesInMeters['Base'];
            area = inputValuesInMeters['Area'];
            if (base! <= 0 || area! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Base and Area must be > 0')),
              );
              return;
            }
            height = (2 * area) / base;
            if (inputValuesInMeters.containsKey('Side A') &&
                inputValuesInMeters.containsKey('Side B')) {
              sideA = inputValuesInMeters['Side A'];
              sideB = inputValuesInMeters['Side B'];
              if (sideA! <= 0 || sideB! <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sides must be > 0')),
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
          } else if (inputValuesInMeters.containsKey('Side A') &&
              inputValuesInMeters.containsKey('Side B') &&
              inputValuesInMeters.containsKey('Base')) {
            sideA = inputValuesInMeters['Side A'];
            sideB = inputValuesInMeters['Side B'];
            base = inputValuesInMeters['Base'];
            if (sideA! <= 0 || sideB! <= 0 || base! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sides must be > 0')),
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
            double s = perimeter / 2;
            area = sqrt(s * (s - sideA) * (s - sideB) * (s - base));
            if (area.isNaN || area <= 0) {
              /* Potentially inconsistent sides for Heron's */
            } else {
              if (base > 0) {
                height = (2 * area) / base;
              } else {
                height = 0;
              }
            }

            if (inputValuesInMeters.containsKey('Height')) {
              height = inputValuesInMeters['Height'];
              if (height! <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Height must be > 0')),
                );
                return;
              }
              if (base > 0) {
                area = 0.5 * base * height;
              } else {
                area = 0;
              }
            }
          }
          if (base != null) calculatedValuesInMeters['Base'] = base;
          if (height != null) calculatedValuesInMeters['Height'] = height;
          if (sideA != null) calculatedValuesInMeters['Side A'] = sideA;
          if (sideB != null) calculatedValuesInMeters['Side B'] = sideB;
          if (area != null && !area.isNaN) {
            calculatedValuesInMeters['Area'] = area;
          }
          if (perimeter != null) {
            calculatedValuesInMeters['Perimeter'] = perimeter;
          }
          break;

        case 'Trapezoid':
          double? baseA, baseB, height, sideC, sideD, area, perimeter;
          if (inputValuesInMeters.containsKey('Base A') &&
              inputValuesInMeters.containsKey('Base B') &&
              inputValuesInMeters.containsKey('Height')) {
            baseA = inputValuesInMeters['Base A'];
            baseB = inputValuesInMeters['Base B'];
            height = inputValuesInMeters['Height'];
            if (baseA! <= 0 || baseB! <= 0 || height! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bases and Height must be > 0')),
              );
              return;
            }
            area = 0.5 * (baseA + baseB) * height;
            if (inputValuesInMeters.containsKey('Side C') &&
                inputValuesInMeters.containsKey('Side D')) {
              sideC = inputValuesInMeters['Side C'];
              sideD = inputValuesInMeters['Side D'];
              if (sideC! <= 0 || sideD! <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sides must be > 0')),
                );
                return;
              }
              perimeter = baseA + baseB + sideC + sideD;
            }
          } else if (inputValuesInMeters.containsKey('Base A') &&
              inputValuesInMeters.containsKey('Base B') &&
              inputValuesInMeters.containsKey('Area')) {
            baseA = inputValuesInMeters['Base A'];
            baseB = inputValuesInMeters['Base B'];
            area = inputValuesInMeters['Area'];
            if (baseA! <= 0 || baseB! <= 0 || area! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bases and Area must be > 0')),
              );
              return;
            }
            if ((baseA + baseB) == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sum of bases cannot be zero')),
              );
              return;
            }
            height = (2 * area) / (baseA + baseB);
            if (inputValuesInMeters.containsKey('Side C') &&
                inputValuesInMeters.containsKey('Side D')) {
              sideC = inputValuesInMeters['Side C'];
              sideD = inputValuesInMeters['Side D'];
              if (sideC! <= 0 || sideD! <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sides must be > 0')),
                );
                return;
              }
              perimeter = baseA + baseB + sideC + sideD;
            }
          } else if (inputValuesInMeters.containsKey('Base A') &&
              inputValuesInMeters.containsKey('Base B') &&
              inputValuesInMeters.containsKey('Side C') &&
              inputValuesInMeters.containsKey('Side D')) {
            baseA = inputValuesInMeters['Base A'];
            baseB = inputValuesInMeters['Base B'];
            sideC = inputValuesInMeters['Side C'];
            sideD = inputValuesInMeters['Side D'];
            if (baseA! <= 0 || baseB! <= 0 || sideC! <= 0 || sideD! <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bases and Sides must be > 0')),
              );
              return;
            }
            perimeter = baseA + baseB + sideC + sideD;
            if (inputValuesInMeters.containsKey('Height')) {
              height = inputValuesInMeters['Height'];
              if (height! <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Height must be > 0')),
                );
                return;
              }
              area = 0.5 * (baseA + baseB) * height;
            }
          }
          if (baseA != null) calculatedValuesInMeters['Base A'] = baseA;
          if (baseB != null) calculatedValuesInMeters['Base B'] = baseB;
          if (height != null) calculatedValuesInMeters['Height'] = height;
          if (sideC != null) calculatedValuesInMeters['Side C'] = sideC;
          if (sideD != null) calculatedValuesInMeters['Side D'] = sideD;
          if (area != null) calculatedValuesInMeters['Area'] = area;
          if (perimeter != null) {
            calculatedValuesInMeters['Perimeter'] = perimeter;
          }
          break;
      }
      // --- End of Calculation Logic ---

      _results.clear(); // Clear previous calculation attempt's results map
      calculatedValuesInMeters.forEach((key, value) {
        _results[key] = _numberFormat.format(value);
      });

      if (!mounted) return;
      setState(() {
        debugPrint(
            '[_calculate] Calculated results (in m-based units before display conversion): $_results');
        for (var param in widget.parameters) {
          if (!(_isInputEnabled[param] ?? false)) {
            _controllers[param]!.text = _results[param] ?? '';
          } else if (!inputValuesInMeters.containsKey(param) &&
              _controllers[param]!.text.isNotEmpty) {
            // This case means the input field was not used for this calculation, but had text.
            // If it's not the active parameter, we might want to clear it or leave it.
            // For now, leave it, as the user might be switching between input sets.
          }
        }

        if (calculatedValuesInMeters.isNotEmpty &&
            inputsForHistory.isNotEmpty) {
          String expr = inputsForHistory.entries
              .map((e) =>
                  '${e.key}=${_numberFormat.format(double.parse(e.value))} $_baseUnit')
              .join(', ');

          String res = calculatedValuesInMeters.entries.map((e) {
            final displayUnitKey = _unitSelections[e.key] ??
                _getDefaultUnitForParameter(e.key, _baseUnit);
            final unitInfoList = widget.unitOptions[e.key] ?? [];
            final unitInfo = unitInfoList.firstWhere(
                (u) => u['unit'] == displayUnitKey,
                orElse: () => {'factor': 1.0, 'unit': _baseUnit});
            double displayFactor = unitInfo['factor'];
            double valueInDisplayUnit = e.value * displayFactor;
            return '${e.key}=${_numberFormat.format(valueInDisplayUnit)} $displayUnitKey';
          }).join(', ');
          addToHistory(expr, res);
        }
      });
    });
  }

  Widget _buildUnitPicker(String parameter) {
    final units = widget.unitOptions[parameter] ?? [];
    if (units.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: 110,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => CupertinoActionSheet(
              title: Text('Select Unit for $parameter'),
              actions: units
                  .map(
                    (unit) => CupertinoActionSheetAction(
                      onPressed: () {
                        if (!mounted) return;
                        setState(() {
                          _unitSelections[parameter] = unit['unit'];
                          _calculate(
                              _activeParameter); // Recalculate if unit of a result changes
                        });
                        Navigator.pop(context);
                      },
                      child: Text(unit['label'] ?? unit['unit']),
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
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                _unitSelections[parameter] ??
                    _getDefaultUnitForParameter(parameter, _baseUnit),
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.activeBlue,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              FluentIcons.chevron_down_20_regular,
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
      margin: const EdgeInsets.symmetric(
          vertical: 8.0, horizontal: 4.0), // Added horizontal margin
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context)
            .scaffoldBackgroundColor, // Use theme color
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: CupertinoColors.systemGrey4, width: 0.5), // Softer border
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
              // color: CupertinoColors.black, // Will adapt to theme
            ),
          ),
          GestureDetector(
            onTap: () {
              showCupertinoModalPopup(
                context: context,
                builder: (context) => Container(
                  height: 240,
                  color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: CupertinoColors.systemGrey4,
                                    width: 0.5))),
                        child: const Text(
                          'Select Base Unit',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 36,
                          magnification: 1.1,
                          squeeze: 1.3,
                          onSelectedItemChanged: (index) {
                            if (!mounted) return;
                            setState(() {
                              _baseUnit = _baseUnitOptions[index]['unit'];
                              _updateUnitSelections();
                              // _calculate(_activeParameter); // _updateUnitSelections now calls _calculate
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
                                        fontSize: 18,
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
                            fontSize: 17,
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

    final String displayUnitKey = _unitSelections[parameter] ??
        _getDefaultUnitForParameter(parameter, _baseUnit);
    final unitsForParameter = widget.unitOptions[parameter] ?? [];

    double conversionFactorToDisplayUnit = 1.0;
    String currentDisplayUnitSymbol = _baseUnit;

    if (!isInput && unitsForParameter.isNotEmpty) {
      final selectedDisplayUnitInfo = unitsForParameter.firstWhere(
        (unit) => unit['unit'] == displayUnitKey,
        orElse: () => unitsForParameter.first,
      );
      conversionFactorToDisplayUnit = selectedDisplayUnitInfo['factor'];
      currentDisplayUnitSymbol = selectedDisplayUnitInfo['unit'];
    } else if (isInput) {
      currentDisplayUnitSymbol = _baseUnit;
    }

    String valueInController = _controllers[parameter]!.text;
    String displayText = "";

    if (valueInController.isNotEmpty) {
      if (!isInput) {
        try {
          final valueInMeters =
              double.parse(valueInController.replaceAll(',', ''));
          final convertedValue = valueInMeters * conversionFactorToDisplayUnit;
          displayText = _numberFormat.format(convertedValue);
        } catch (e) {
          debugPrint(
              'Error converting result value for $parameter to display unit: $e');
          displayText = "Error"; // Display error if conversion fails
        }
      } else {
        // For input, just format the number if it's a valid number
        try {
          final doubleValue =
              double.parse(valueInController.replaceAll(',', ''));
          displayText = _numberFormat.format(doubleValue);
        } catch (e) {
          displayText = valueInController; // If not a number, show as is
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center, // Center items vertically
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CupertinoCheckbox(
              value: isInput,
              shape: const CircleBorder(),
              activeColor: currentTheme.primaryColor,
              onChanged: (value) {
                if (value != null) {
                  if (!mounted) return;
                  setState(() {
                    // Only allow one input at a time (optional, but common for this UI type)
                    if (value) {
                      _isInputEnabled.forEach((key, _) {
                        _isInputEnabled[key] = false;
                      });
                      _isInputEnabled[parameter] = true;
                      _activeParameter = parameter;
                      _controllers[parameter]!
                          .clear(); // Clear when it becomes input
                    } else {
                      // If unchecking, and it was the active parameter, find a new active one or none
                      _isInputEnabled[parameter] = false;
                      // if (_activeParameter == parameter) {
                      //   _activeParameter = widget.parameters.firstWhere(
                      //       (p) => _isInputEnabled[p]!,
                      //       orElse: () =>
                      //           null); // No active parameter if all are outputs
                      // }
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
                if (!mounted) return;
                // When tapping a card, if it's not already an input, make it the sole input.
                // If it is an input, it remains the active input for the keypad.
                setState(() {
                  if (!_isInputEnabled[parameter]!) {
                    _isInputEnabled.forEach((key, _) {
                      _isInputEnabled[key] = false;
                    });
                    _isInputEnabled[parameter] = true;
                    _controllers[parameter]!
                        .clear(); // Clear previous output value
                  }
                  _activeParameter = parameter;
                  _calculate(_activeParameter);
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: currentTheme.barBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _activeParameter == parameter && isInput
                        ? currentTheme.primaryColor
                        : CupertinoColors.systemGrey4,
                    width: _activeParameter == parameter && isInput ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize:
                      MainAxisSize.min, // Important for intrinsic height
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            parameter,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: Color.fromRGBO(
                                  20, 20, 20, 1), // Use labelColor
                            ),
                          ),
                        ),
                        if (!isInput &&
                            displayText.isNotEmpty &&
                            displayText != "Error")
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => _copyToClipboard(
                                '$displayText $currentDisplayUnitSymbol'),
                            // minimumSize: Size(0, 0),
                            child: Icon(
                              FluentIcons.copy_20_regular,
                              size: 18,
                              color: currentTheme.primaryColor,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: isInput ? 4 : 8),
                    if (isInput)
                      Row(
                        children: [
                          Expanded(
                            child: AbsorbPointer(
                              // Makes TextField non-interactive for direct input
                              child: CupertinoTextField(
                                controller: _controllers[parameter],
                                placeholder: 'Enter value',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'Inter',
                                  color: currentTheme.textTheme.textStyle.color,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                readOnly: true,
                                showCursor: true,
                                cursorColor: currentTheme.primaryColor,
                                decoration: const BoxDecoration(),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _baseUnit,
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'Inter',
                              color: currentTheme.textTheme.textStyle.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        displayText.isNotEmpty
                            ? (displayText == "Error"
                                ? "Error"
                                : '$displayText $currentDisplayUnitSymbol')
                            : '-',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          color: displayText == "Error"
                              ? CupertinoColors.systemRed
                              : (displayText.isNotEmpty
                                  ? currentTheme.textTheme.textStyle.color
                                  : currentTheme.textTheme.textStyle.color!
                                      .withOpacity(0.5)),
                        ),
                        textAlign: TextAlign.left,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (!isInput &&
              displayText.isNotEmpty &&
              displayText != "Error" &&
              unitsForParameter.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: _buildUnitPicker(parameter),
            )
          else if (!isInput && unitsForParameter.isNotEmpty)
            SizedBox(width: 110 + 8.0)
          else
            SizedBox(width: 110 + 8.0),
        ],
      ),
    );
  }

  // --- Adapted Button Styling and Building Logic from CalcPage ---
  Color _getButtonBackgroundColor(BuildContext context, String text) {
    final bool isDarkMode =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    switch (text) {
      case 'AC':
        return isDarkMode
            ? CupertinoColors.systemRed.withOpacity(0.6)
            : CupertinoColors.systemRed.withOpacity(0.3);
      case 'del':
        return isDarkMode
            ? const Color.fromRGBO(
                45, 45, 45, 1) // Darker grey for special actions
            : const Color.fromRGBO(220, 220, 225, 1);
      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
      case '00':
      case '.':
        return isDarkMode
            ? const Color.fromRGBO(30, 30, 30, 1) // Dark grey for numbers
            : const Color.fromRGBO(240, 240, 245, 1); // Light grey for numbers
      default: // Should not happen with current button set
        return isDarkMode
            ? CupertinoColors.systemGrey5
            : CupertinoColors.systemGrey6;
    }
  }

  Color _getButtonForegroundColor(BuildContext context, String text) {
    // final bool isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    switch (text) {
      case 'AC':
        return CupertinoColors.white; // Or a color that contrasts with red
      case 'del':
        return CupertinoColors.systemRed;
      default:
        return CupertinoTheme.of(context).textTheme.textStyle.color!;
    }
  }

  double _getButtonTextSize(String text, double btnSize) {
    // Simplified from CalcPage, as we don't have complex functions
    if (text == '00') return btnSize * 0.36;
    if (text == 'AC') return btnSize * 0.38;
    return btnSize * 0.4; // Default for digits and dot
  }

  Widget _buildKeypadButton(BuildContext context, String text, double btnSize,
      {double? height, VoidCallback? onPressedOverride}) {
    final currentTheme = CupertinoTheme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    Color buttonColor = _getButtonBackgroundColor(context, text);
    Color fgColor = _getButtonForegroundColor(context, text);

    Widget content;
    if (text == 'del') {
      content = Icon(
        FluentIcons
            .backspace_24_regular, // Using regular for consistency, filled is also an option
        size: btnSize * 0.45,
        color: fgColor,
      );
    } else {
      content = Text(
        text,
        style: TextStyle(
          fontSize: _getButtonTextSize(text, btnSize),
          color: fgColor,
          fontWeight: FontWeight.w500, // Standard weight
          fontFamily: 'Inter',
        ),
      );
    }

    final bool applyShadow = true; // All keypad buttons have shadow

    VoidCallback actualOnPressed;
    if (onPressedOverride != null) {
      actualOnPressed = onPressedOverride;
    } else if (text == 'AC') {
      actualOnPressed = _clearInputs;
    } else if (text == 'del') {
      actualOnPressed = () => _onKeypadPress('⌫');
    } else {
      actualOnPressed = () => _onKeypadPress(text);
    }

    return Container(
      width: btnSize,
      height: height ?? screenHeight * 0.065, // Standard button height
      margin: EdgeInsets.all(btnSize * 0.035), // Slightly reduced margin
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(btnSize * 0.25), // More rounded
        boxShadow: applyShadow
            ? [
                BoxShadow(
                  color: CupertinoColors.systemGrey
                      .withOpacity(0.15), // Softer shadow
                  spreadRadius: 0.5,
                  blurRadius: 2,
                  offset:
                      const Offset(0, 1.5), // Slightly more pronounced offset
                ),
              ]
            : null,
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(btnSize * 0.25),
        onPressed: actualOnPressed,
        child: Center(child: content),
      ),
    );
  }

  Widget _buildCustomKeypad(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final safeAreaPadding = mediaQuery.padding;
    final effectiveScreenWidth = screenWidth -
        safeAreaPadding.left -
        safeAreaPadding.right -
        (16 * 2); // Account for page padding

    final double approxButtonSpacing =
        screenWidth * 0.02; // Spacing between buttons
    // For a 4-column layout (3 digit columns + 1 side button column)
    final double btnSize =
        ((effectiveScreenWidth - (3 * approxButtonSpacing)) / 4)
            .clamp(50.0, 85.0);
    final double singleButtonHeight =
        MediaQuery.of(context).size.height * 0.065;
    final double doubleButtonHeight = (2 * singleButtonHeight) +
        (btnSize * 0.035 * 2); // Height of two buttons + one margin

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 4.0), // Match base unit picker
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4x3 Digit Grid
          Expanded(
            flex: 3, // Takes 3 parts of the width
            child: Column(
              children: _keypadRows.map((row) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: row
                      .map((text) => _buildKeypadButton(context, text, btnSize,
                          height: singleButtonHeight))
                      .toList(),
                );
              }).toList(),
            ),
          ),
          // Spacer
          SizedBox(width: approxButtonSpacing),
          // AC and Del Column
          Expanded(
            flex: 1, // Takes 1 part of the width
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildKeypadButton(context, 'AC', btnSize,
                    height: doubleButtonHeight,
                    onPressedOverride: _clearInputs),
                _buildKeypadButton(context, 'del', btnSize,
                    height: doubleButtonHeight,
                    onPressedOverride: () => _onKeypadPress('⌫')),
              ],
            ),
          ),
        ],
      ),
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
        child: Column(
          // Main layout is now a Column
          children: [
            Expanded(
              // Parameter cards take available space and scroll
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16)
                    .copyWith(bottom: 8), // Reduce bottom padding
                child: Column(
                  children: [
                    ...widget.parameters
                        .map((param) => _buildParameterCard(context, param)),
                  ],
                ),
              ),
            ),
            // Base Unit Picker and Keypad at the bottom
            _buildBaseUnitPicker(),
            const SizedBox(height: 8),
            _buildCustomKeypad(context),
            const SizedBox(height: 8), // Some padding at the very bottom
          ],
        ),
      ),
    );
  }
}
