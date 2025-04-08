import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class LengthConverterPage extends StatefulWidget {
  const LengthConverterPage({super.key});

  @override
  State<LengthConverterPage> createState() => _LengthConverterPageState();
}

class _LengthConverterPageState extends State<LengthConverterPage> {
  final TextEditingController _inputController = TextEditingController();
  String _fromUnit = 'Meters';
  String _toUnit = 'Kilometers';
  String _result = '';

  final List<String> _units = [
    'Meters',
    'Kilometers',
    'Centimeters',
    'Millimeters',
    'Miles',
    'Yards',
    'Feet',
    'Inches',
    'Nautical Miles'
  ];

  final List<String> digitButtons = [
    '7',
    '8',
    '9',
    '4',
    '5',
    '6',
    '1',
    '2',
    '3',
    '0',
    '.',
    'del',
  ];

  final Map<String, double> _conversionRatesToMeters = {
    'Meters': 1.0,
    'Kilometers': 0.001,
    'Centimeters': 100.0,
    'Millimeters': 1000.0,
    'Miles': 0.000621371,
    'Yards': 1.09361,
    'Feet': 3.28084,
    'Inches': 39.3701,
    'Nautical Miles': 0.000539957,
  };

  void _handleDigitPress(String digit) {
    final currentText = _inputController.text;
    if (digit == 'del') {
      if (currentText.isNotEmpty) {
        _inputController.text =
            currentText.substring(0, currentText.length - 1);
      }
    } else if (digit == '.') {
      if (!currentText.contains('.')) {
        _inputController.text = currentText.isEmpty ? '0.' : '$currentText.';
      }
    } else {
      _inputController.text = currentText + digit;
    }
    _convert();
  }

  void _convert() {
    if (_inputController.text.isEmpty) {
      setState(() {
        _result = '';
      });
      return;
    }

    try {
      final double inputValue = double.parse(_inputController.text);
      final double toMeters = inputValue / _conversionRatesToMeters[_fromUnit]!;
      final double result = toMeters * _conversionRatesToMeters[_toUnit]!;

      setState(() {
        _result = result.toStringAsFixed(6);
      });
    } catch (e) {
      setState(() {
        _result = 'Invalid input';
      });
    }
  }

  Widget _buildDigitButton(String digit) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(20),
          color: digit == 'del' ? CupertinoColors.systemGrey5 : Colors.white,
          onPressed: () => _handleDigitPress(digit),
          child: digit == 'del'
              ? const Icon(
                  FluentIcons.backspace_24_filled,
                  size: 24,
                  color: Color.fromARGB(255, 220, 0, 0),
                )
              : Text(
                  digit,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Color.fromARGB(255, 51, 51, 51),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Length Converter'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CupertinoTextField(
                      controller: _inputController,
                      placeholder: 'Enter value',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      readOnly:
                          true, // Make it read-only since we're using digit buttons
                      decoration: BoxDecoration(
                        border: Border.all(color: CupertinoColors.systemGrey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('From:',
                                  style: TextStyle(
                                      color: CupertinoColors.systemGrey)),
                              const SizedBox(height: 8),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: CupertinoColors.systemGrey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_fromUnit),
                                      const Icon(CupertinoIcons.chevron_down),
                                    ],
                                  ),
                                ),
                                onPressed: () {
                                  showCupertinoModalPopup(
                                    context: context,
                                    builder: (context) => CupertinoActionSheet(
                                      actions: _units
                                          .map((unit) =>
                                              CupertinoActionSheetAction(
                                                onPressed: () {
                                                  setState(() {
                                                    _fromUnit = unit;
                                                    _convert();
                                                  });
                                                  Navigator.pop(context);
                                                },
                                                child: Text(unit),
                                              ))
                                          .toList(),
                                      cancelButton: CupertinoActionSheetAction(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('To:',
                                  style: TextStyle(
                                      color: CupertinoColors.systemGrey)),
                              const SizedBox(height: 8),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: CupertinoColors.systemGrey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_toUnit),
                                      const Icon(CupertinoIcons.chevron_down),
                                    ],
                                  ),
                                ),
                                onPressed: () {
                                  showCupertinoModalPopup(
                                    context: context,
                                    builder: (context) => CupertinoActionSheet(
                                      actions: _units
                                          .map((unit) =>
                                              CupertinoActionSheetAction(
                                                onPressed: () {
                                                  setState(() {
                                                    _toUnit = unit;
                                                    _convert();
                                                  });
                                                  Navigator.pop(context);
                                                },
                                                child: Text(unit),
                                              ))
                                          .toList(),
                                      cancelButton: CupertinoActionSheetAction(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (_result.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Result',
                              style: TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_result $_toUnit',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              color: CupertinoColors.systemGrey6,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: digitButtons
                        .sublist(0, 3)
                        .map(_buildDigitButton)
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: digitButtons
                        .sublist(3, 6)
                        .map(_buildDigitButton)
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: digitButtons
                        .sublist(6, 9)
                        .map(_buildDigitButton)
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: digitButtons
                        .sublist(9, 12)
                        .map(_buildDigitButton)
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      borderRadius: BorderRadius.circular(20),
                      color: const Color.fromARGB(255, 220, 0, 0),
                      onPressed: () {
                        setState(() {
                          _inputController.clear();
                          _result = '';
                        });
                      },
                      child: const Text(
                        'AC',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
