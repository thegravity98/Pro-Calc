import 'dart:async';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BaseShapePage extends StatefulWidget {
  final String title;
  final List<String> parameters;
  final Function(
    Map<String, String> inputs,
    String? activeParameter,
    Map<String, bool> isInputEnabled,
    Function(String, String)? addToHistory,
  ) onCalculate;
  final Map<String, TextEditingController> controllers;

  const BaseShapePage({
    super.key,
    required this.title,
    required this.parameters,
    required this.onCalculate,
    required this.controllers,
  });

  @override
  State<BaseShapePage> createState() => _BaseShapePageState();
}

class _BaseShapePageState extends State<BaseShapePage> {
  final Map<String, bool> _isInputEnabled = {};
  String? _activeParameter;
  Timer? _debounce;
  final List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    for (var param in widget.parameters) {
      _isInputEnabled[param] = true;
    }
    _activeParameter = widget.parameters.first;
    for (var param in widget.parameters) {
      widget.controllers[param]!
          .addListener(() => _calculate(_activeParameter));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (var param in widget.parameters) {
      widget.controllers[param]!
          .removeListener(() => _calculate(_activeParameter));
    }
    super.dispose();
  }

  void _calculate(String? activeParameter) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final inputs = <String, String>{};
      for (var param in widget.parameters) {
        if (_isInputEnabled[param]! &&
            widget.controllers[param]!.text.isNotEmpty) {
          inputs[param] = widget.controllers[param]!.text;
        }
      }
      widget.onCalculate(
          inputs, activeParameter, _isInputEnabled, addToHistory);
    });
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
        widget.controllers[param]!.clear();
        _isInputEnabled[param] = true;
      }
      _activeParameter = widget.parameters.first;
      _calculate(_activeParameter);
    });
  }

  void _onKeypadPress(String value) {
    if (_activeParameter != null && _isInputEnabled[_activeParameter]!) {
      final controller = widget.controllers[_activeParameter]!;
      if (value == '⌫') {
        // Backspace: Remove the last character
        if (controller.text.isNotEmpty) {
          controller.text =
              controller.text.substring(0, controller.text.length - 1);
        }
      } else {
        // Append digit or decimal point
        if (value == '.' && controller.text.contains('.')) {
          // Prevent multiple decimal points
          return;
        }
        controller.text += value;
      }
      // Trigger calculation
      _calculate(_activeParameter);
    }
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

  Widget _buildParameterCard(BuildContext context, String parameter) {
    final currentTheme = CupertinoTheme.of(context);
    final bool isInput = _isInputEnabled[parameter] ?? true;

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
                    widget.controllers[parameter]!.clear();
                    _activeParameter = parameter;
                  } else {
                    widget.controllers[parameter]!.text = '';
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
                      Text(
                        parameter,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: currentTheme.textTheme.textStyle.color,
                        ),
                      ),
                      if (!isInput &&
                          widget.controllers[parameter]!.text.isNotEmpty)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _copyToClipboard(
                              widget.controllers[parameter]!.text),
                          child: Icon(
                            FluentIcons.copy_24_regular,
                            size: 20,
                            color: currentTheme.primaryColor,
                          ),
                        ),
                    ],
                  ),
                  if (isInput)
                    CupertinoTextField(
                      controller: widget.controllers[parameter],
                      placeholder: 'Enter value',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'Inter',
                        color: currentTheme.textTheme.textStyle.color,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      readOnly: true, // Keep readOnly to rely on keypad
                      showCursor: true,
                      decoration: const BoxDecoration(),
                      padding: const EdgeInsets.all(12),
                    )
                  else
                    Text(
                      widget.controllers[parameter]!.text.isNotEmpty
                          ? widget.controllers[parameter]!.text
                          : '',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                        color: widget.controllers[parameter]!.text.isNotEmpty
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
              // Parameter Cards
              ...widget.parameters
                  .map((param) => _buildParameterCard(context, param)),
              // Action Buttons
              const SizedBox(height: 16),
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
              // Numeric Keypad
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
