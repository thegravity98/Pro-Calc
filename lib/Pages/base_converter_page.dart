import 'package:flutter/cupertino.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/calculation_history.dart';

class BaseConverterPage extends StatefulWidget {
  final String title;
  final List<String> units;
  final Function(String, String, String) onConvert;
  final Map<String, double> conversionRates;

  const BaseConverterPage({
    super.key,
    required this.title,
    required this.units,
    required this.onConvert,
    required this.conversionRates,
  });

  @override
  State<BaseConverterPage> createState() => _BaseConverterPageState();
}

class _BaseConverterPageState extends State<BaseConverterPage> {
  final TextEditingController _inputController = TextEditingController();
  String _fromUnit = '';
  String _toUnit = '';
  String _result = '';
  List<CalculationHistory> history = [];
  static const _historyKey = 'converter_history_';

  // Numpad buttons in 4x3 layout
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
    '00',
    '.',
    '0',
  ];

  @override
  void initState() {
    super.initState();
    _fromUnit = widget.units.first;
    _toUnit = widget.units[1];
    _loadHistory();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _convert() {
    if (_inputController.text.isEmpty) {
      setState(() => _result = '');
      return;
    }
    String result = widget.onConvert(_inputController.text, _fromUnit, _toUnit);
    setState(() => _result = result);
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_historyKey + widget.title);
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final loadedHistory =
            jsonList.map((json) => CalculationHistory.fromJson(json)).toList();
        if (mounted) {
          setState(() {
            history = loadedHistory;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = history.map((entry) => entry.toJson()).toList();
      await prefs.setString(_historyKey + widget.title, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  void addToHistory(String expr, String res) {
    if (expr.isEmpty || res.isEmpty) return;
    setState(() {
      history.insert(0, CalculationHistory(expression: expr, result: res));
      if (history.length > 100) {
        // Limit to 100 entries
        history.removeLast();
      }
    });
    _saveHistory();
  }

  void _onDigitPress(String digit) {
    final currentText = _inputController.text;
    if (digit == '.' && currentText.contains('.')) return;
    if (digit == '00' && (currentText.isEmpty || currentText == '0')) {
      digit = '0';
    }
    final newText = currentText + digit;
    _inputController.text = newText;
    _inputController.selection =
        TextSelection.collapsed(offset: newText.length);
    _convert(); // Call convert after updating text
  }

  void _onDelete() {
    final text = _inputController.text;
    if (text.isNotEmpty) {
      _inputController.text = text.substring(0, text.length - 1);
      _inputController.selection = TextSelection.collapsed(
        offset: _inputController.text.length,
      );
      _convert(); // Call convert after deleting
    }
  }

  void _onEqual() {
    if (_inputController.text.isNotEmpty) {
      final expression =
          '${_inputController.text} $_fromUnit = $_result $_toUnit';
      addToHistory(_inputController.text, _result);
      showOverlayMessage('Conversion added to history');
    }
  }

  void showOverlayMessage(String message) {
    final overlay = Navigator.of(context).overlay!;
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 32,
        right: 32,
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CupertinoColors.label,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  void _handleCalcButton() {
    // Close any open modals first
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildDigitButton(String text) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.tertiarySystemBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CupertinoColors.systemGrey4),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
      onPressed: () => _onDigitPress(text),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed,
      {Color? color, IconData? icon}) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? CupertinoColors.tertiarySystemBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CupertinoColors.systemGrey4),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: CupertinoColors.label)
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: 20,
                    color: text == 'AC'
                        ? CupertinoColors.systemRed
                        : CupertinoColors.label,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
      ),
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Input area with unit pickers
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Input Field
                    CupertinoTextField(
                      controller: _inputController,
                      placeholder: 'Enter value',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 24),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      readOnly: true,
                      showCursor: true,
                      decoration: BoxDecoration(
                        color: CupertinoColors.tertiarySystemBackground,
                        border: Border.all(color: CupertinoColors.systemGrey4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                    const SizedBox(height: 16),

                    // Unit Pickers
                    Row(
                      children: [
                        _buildUnitPicker(isFromUnit: true),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              setState(() {
                                final temp = _fromUnit;
                                _fromUnit = _toUnit;
                                _toUnit = temp;
                                _convert();
                              });
                            },
                            child: const Icon(
                              CupertinoIcons.arrow_right_arrow_left_circle,
                              size: 28,
                              color: CupertinoColors.activeBlue,
                            ),
                          ),
                        ),
                        _buildUnitPicker(isFromUnit: false),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Result Display
                    if (_result.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CupertinoColors.tertiarySystemBackground,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: CupertinoColors.systemGrey4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _result,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Spacer(),
                  ],
                ),
              ),
            ),

            // Number Pad (fixed height)
            Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.4, // Fixed height
              child: Row(
                children: [
                  // Left side: 4x3 digit grid
                  Expanded(
                    flex: 3,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          childAspectRatio: (constraints.maxWidth / 3) /
                              (constraints.maxHeight / 4),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          children:
                              digitButtons.map(_buildDigitButton).toList(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Right side: Action buttons column
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'AC',
                            () {
                              setState(() {
                                _inputController.clear();
                                _result = '';
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _buildActionButton(
                            'del',
                            _onDelete,
                            icon: FluentIcons.backspace_24_filled,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _buildActionButton(
                            'Calc',
                            _handleCalcButton,
                            icon: FluentIcons.calculator_24_filled,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _buildActionButton(
                            '=',
                            _onEqual,
                            color: CupertinoColors.activeBlue.withOpacity(0.8),
                          ),
                        ),
                      ],
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

  Widget _buildUnitPicker({required bool isFromUnit}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.tertiarySystemBackground,
          border: Border.all(color: CupertinoColors.systemGrey4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isFromUnit ? _fromUnit : _toUnit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                FluentIcons.chevron_down_24_regular,
                size: 20,
                color: CupertinoColors.systemGrey,
              ),
            ],
          ),
          onPressed: () {
            showCupertinoModalPopup(
              context: context,
              builder: (context) => CupertinoActionSheet(
                actions: widget.units
                    .map((unit) => CupertinoActionSheetAction(
                          onPressed: () {
                            setState(() {
                              if (isFromUnit) {
                                _fromUnit = unit;
                              } else {
                                _toUnit = unit;
                              }
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
      ),
    );
  }
}
