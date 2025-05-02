import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/calculation_history.dart';
import 'history_page.dart';

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
  static const _historyKey = 'calculator_history_v8'; // Shared with CalcPage

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

  // Define unit size ranking (smallest to largest)
  final Map<String, int> _unitRank = {
    'mm': 1,
    'cm': 2,
    'm': 3,
    'km': 4,
    'miles': 5,
    'mm²': 1,
    'cm²': 2,
    'm²': 3,
    'km²': 4,
    'mi²': 5,
    'ml': 1,
    'l': 2,
    'm³': 3,
    'pa': 1,
    'kpa': 2,
    'bar': 3,
    'w': 1,
    'kw': 2,
    'mw': 3,
    '°C': 1,
    '°F': 2,
    'K': 3,
    'm/s': 1,
    'km/h': 2,
    'mph': 3,
    's': 1,
    'min': 2,
    'h': 3,
    'd': 4,
    'B': 1,
    'KB': 2,
    'MB': 3,
    'GB': 4,
    '°': 1,
    'rad': 2,
    'USD': 1,
    'EUR': 2,
    'mpg': 1,
    'L/100km': 2,
    'Hz': 1,
    'kHz': 2,
    'MHz': 3,
    'N': 1,
    'kgf': 2,
    'lbf': 3,
    'dB': 1,
    'Np': 2,
    'lx': 1,
    'fc': 2
  };

  // Copy and paste functionality
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    showOverlayMessage('Copied to clipboard');
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData != null && clipboardData.text != null) {
      final pastedText = clipboardData.text!;
      // Check if the pasted text is a valid number
      if (RegExp(r'^[0-9]*\.?[0-9]*$').hasMatch(pastedText)) {
        setState(() {
          _inputController.text = pastedText;
          _inputController.selection =
              TextSelection.collapsed(offset: pastedText.length);
          _convert();
        });
      } else {
        showOverlayMessage('Invalid number format');
      }
    }
  }

  void _showHistoryModal() {
    showCupertinoModalPopup(
      context: context,
      builder: (modalContext) {
        final currentTheme = CupertinoTheme.of(modalContext);
        return GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! > 200) {
              Navigator.pop(modalContext);
            }
          },
          child: Container(
            height: MediaQuery.of(modalContext).size.height * 0.65,
            decoration: BoxDecoration(
              color: currentTheme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  height: 5,
                  width: 35,
                  margin: const EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    color: currentTheme.primaryColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                Expanded(
                  child: HistoryPage(
                    history: history,
                    onExpressionTap: (String result) {
                      // Remove commas from the result
                      final cleanedResult = result.replaceAll(',', '');
                      // Validate that the cleaned result is a valid number
                      if (RegExp(r'^[0-9]*\.?[0-9]*$')
                          .hasMatch(cleanedResult)) {
                        setState(() {
                          _inputController.text = cleanedResult;
                          _inputController.selection = TextSelection.collapsed(
                              offset: cleanedResult.length);
                          _convert();
                        });
                        Navigator.pop(modalContext);
                      } else {
                        showOverlayMessage('Invalid number format');
                      }
                    },
                    onClear: () {
                      _clearHistory();
                      Navigator.pop(modalContext);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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

  // Convert value from input unit to all other units
  Map<String, String> _convertToAllUnits() {
    Map<String, String> results = {};
    if (_inputController.text.isEmpty) return results;

    try {
      for (String unit in widget.units) {
        if (unit != _fromUnit) {
          String result =
              widget.onConvert(_inputController.text, _fromUnit, unit);
          results[unit] = result;
        }
      }
    } catch (e) {
      debugPrint('Error converting to all units: $e');
    }

    return results;
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_historyKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final loadedHistory = jsonList
            .map((json) => CalculationHistory.fromJson(json))
            .toList()
            .reversed
            .toList();
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
      final jsonList = history.reversed.map((entry) => entry.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  Future<void> _clearHistory() async {
    if (mounted) {
      setState(() {
        history.clear();
      });
      await _saveHistory();
      showOverlayMessage('History Cleared');
    }
  }

  void addToHistory(String expr, String res) {
    if (expr.isEmpty || res.isEmpty) return;
    if (history.isNotEmpty &&
        history.first.expression == expr &&
        history.first.result == res) {
      return;
    }
    setState(() {
      history.insert(0, CalculationHistory(expression: expr, result: res));
      if (history.length > 100) {
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
    _convert();
    setState(() {});
  }

  void _onDelete() {
    final text = _inputController.text;
    if (text.isNotEmpty) {
      _inputController.text = text.substring(0, text.length - 1);
      _inputController.selection = TextSelection.collapsed(
        offset: _inputController.text.length,
      );
      _convert();
      setState(() {});
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
            decoration: BoxDecoration(
              color: const Color.fromRGBO(20, 20, 20, 0.60),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              child: Text(
                message,
                style: const TextStyle(color: Color(0xFFFF9000), fontSize: 16),
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
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildDigitButton(String text) {
    final currentTheme = CupertinoTheme.of(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          color: currentTheme.barBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CupertinoColors.systemGrey4),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'Inter',
              color: currentTheme.textTheme.textStyle.color,
            ),
          ),
        ),
      ),
      onPressed: () => _onDigitPress(text),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed,
      {Color? color, IconData? icon}) {
    final currentTheme = CupertinoTheme.of(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? currentTheme.barBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CupertinoColors.systemGrey4),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: currentTheme.textTheme.textStyle.color)
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Inter',
                    color: text == 'AC'
                        ? CupertinoColors.systemRed
                        : currentTheme.textTheme.textStyle.color,
                  ),
                ),
        ),
      ),
    );
  }

  Widget buildButton(BuildContext context, String text, double size) {
    final currentTheme = CupertinoTheme.of(context);
    VoidCallback onPressed;
    IconData iconData;

    switch (text) {
      case "Paste":
        onPressed = _pasteFromClipboard;
        iconData = FluentIcons.clipboard_paste_24_regular;
        break;
      case "Hist":
        onPressed = _showHistoryModal;
        iconData = FluentIcons.history_24_regular;
        break;
      case "Calc":
        onPressed = _handleCalcButton;
        iconData = FluentIcons.calculator_24_filled;
        break;
      default:
        onPressed = () {};
        iconData = FluentIcons.question_circle_24_regular;
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: currentTheme.barBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CupertinoColors.systemGrey4),
        ),
        child: Center(
          child: Icon(
            iconData,
            color: currentTheme.primaryColor,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildUnitCard(
      BuildContext context, String unit, String value, bool isInputCard) {
    final currentTheme = CupertinoTheme.of(context);
    return GestureDetector(
      onTap: isInputCard
          ? null
          : () {
              setState(() {
                _fromUnit = unit;
                _convert();
              });
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: currentTheme.barBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.systemGrey4),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: currentTheme.textTheme.textStyle.color,
                  ),
                ),
                if (!isInputCard && value.isNotEmpty)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _copyToClipboard(value),
                    child: Icon(
                      FluentIcons.copy_24_regular,
                      size: 20,
                      color: currentTheme.primaryColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (isInputCard)
              CupertinoTextField(
                controller: _inputController,
                placeholder: 'Enter value',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Inter',
                  color: currentTheme.textTheme.textStyle.color,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                readOnly: true,
                showCursor: true,
                decoration: const BoxDecoration(),
                padding: const EdgeInsets.all(12),
              )
            else
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                  color: currentTheme.textTheme.textStyle.color,
                ),
                textAlign: TextAlign.right,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = CupertinoTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final btnSize = screenWidth * 0.18;
    final buttonWidthWithMargin = screenWidth * 0.05;

    final allConversions = _convertToAllUnits();

    final sortedUnits = widget.units.where((unit) => unit != _fromUnit).toList()
      ..sort((a, b) {
        // Extract unit abbreviations for ranking
        String aKey = a
            .toLowerCase()
            .replaceAll(' ', '')
            .replaceAll('(', '')
            .replaceAll(')', '')
            .replaceAll('per', '/')
            .substring(0, a.length > 3 ? 3 : a.length);
        String bKey = b
            .toLowerCase()
            .replaceAll(' ', '')
            .replaceAll('(', '')
            .replaceAll(')', '')
            .replaceAll('per', '/')
            .substring(0, b.length > 3 ? 3 : b.length);
        return (_unitRank[aKey] ?? 999).compareTo(_unitRank[bKey] ?? 999);
      });

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
      ),
      backgroundColor: currentTheme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildUnitCard(
                        context, _fromUnit, _inputController.text, true),
                    Expanded(
                      child: ListView(
                        children: [
                          ...sortedUnits.map((unit) {
                            return _buildUnitCard(
                              context,
                              unit,
                              allConversions[unit] ?? '',
                              false,
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: screenHeight * 0.048,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  buildButton(context, "Paste", btnSize),
                  buildButton(context, "Hist", btnSize),
                  buildButton(context, "Calc", btnSize),
                  for (int i = 0; i < 2; i++)
                    SizedBox(width: buttonWidthWithMargin),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.4,
              child: Row(
                children: [
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
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final digitButtonHeight =
                            (constraints.maxHeight - 24) / 4;
                        final twoRowHeight = digitButtonHeight * 2 + 8;
                        return Column(
                          children: [
                            SizedBox(
                              height: twoRowHeight,
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
                            SizedBox(
                              height: twoRowHeight,
                              child: _buildActionButton(
                                'del',
                                _onDelete,
                                icon: FluentIcons.backspace_24_filled,
                              ),
                            ),
                          ],
                        );
                      },
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
