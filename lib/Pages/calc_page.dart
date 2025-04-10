import 'dart:math';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:math_expressions/math_expressions.dart';
import 'history_page.dart'; // Ensure this path is correct
import '../models/calculation_history.dart'; // Ensure this path is correct

class CalcPage extends StatefulWidget {
  const CalcPage({super.key});

  @override
  State<CalcPage> createState() => _CalcPageState();
}

class _CalcPageState extends State<CalcPage>
    with SingleTickerProviderStateMixin {
  // --- State Variables ---
  late TextEditingController _inputController;
  late AnimationController _animationController;
  late Animation<double> _inputTextSizeAnimation;
  late Animation<double> _answerTextSizeAnimation;

  String answer = '';
  bool isDeg = true;

  // --- Constants ---
  final double initialInputTextSize = 36.0;
  final double finalInputTextSize = 32.0;
  final double initialAnswerTextSize = 32.0;
  final double finalAnswerTextSize = 40.0;

  // --- Regular Expressions ---
  final isDigit = RegExp(r'[0-9]$');
  final isLogFun = RegExp(r'log\($');
  final isTrigFun = RegExp(r'(sin|cos|tan)\($');
  final isEndingWithOperator = RegExp(r'[+\-*/×÷%^]$');
  final isEndingWithOpenParen = RegExp(r'\($');
  final isOperator = RegExp(r'[+\-*/×÷%^]');
  final endsWithNumberOrParenOrConst = RegExp(r'([\d.)eπXY])$');
  final endsWithFunctionName = RegExp(r'(sin|cos|tan|log|sqrt)$');

  // --- Calculation Context & Variables ---
  final ContextModel cm = ContextModel();
  final Map<String, double> variables = {'X': 0, 'Y': 0};

  // --- History ---
  final List<CalculationHistory> history = [];
  final int maxHistoryEntries = 100;
  static const _historyKey = 'calculator_history_v7'; // Increment key

  // --- Button Layout ---
  final List<String> stringList = [
    'X', 'Y', 'deg', 'hist', 'AC',
    'sin', 'cos', 'tan', 'π', 'del',
    'e', '(', ')', '%', '÷',
    '!', '7', '8', '9', '×',
    '^', '4', '5', '6', '-', // Keep the ^ button
    '√', '1', '2', '3', '+',
    'log', '10ˣ', '0', '.', '=', // Keep the 10x button (inserts 10^)
  ];

  // --- Initialization & Disposal (Unchanged) ---
  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _animationController = AnimationController(
        /*...*/ vsync: this, duration: const Duration(milliseconds: 350));
    _inputTextSizeAnimation =
        Tween<double>(begin: initialInputTextSize, end: finalInputTextSize)
            .animate(CurvedAnimation(
                parent: _animationController, curve: Curves.easeOut));
    _answerTextSizeAnimation =
        Tween<double>(begin: initialAnswerTextSize, end: finalAnswerTextSize)
            .animate(CurvedAnimation(
                parent: _animationController, curve: Curves.easeOut));
    _loadHistory();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // --- History Management (Unchanged) ---
  Future<void> _loadHistory() async {
    /* ... */ try {
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
            history.clear();
            history.addAll(loadedHistory);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _saveHistory() async {
    /* ... */ try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = history.reversed.map((entry) => entry.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  void addToHistory(String expr, String res) {
    /* ... */ if (expr.isEmpty || res.isEmpty || res == "Error" || expr == res)
      return;
    if (history.isNotEmpty &&
        history.first.expression == expr &&
        history.first.result == res) return;
    if (mounted) {
      setState(() {
        history.insert(0, CalculationHistory(expression: expr, result: res));
        if (history.length > maxHistoryEntries) {
          history.removeLast();
        }
      });
      _saveHistory();
    }
  }

  Future<void> _clearHistory() async {
    /* ... */ if (mounted) {
      setState(() {
        history.clear();
      });
      await _saveHistory();
    }
  }

  // --- Calculation Logic ---
  Future<void> _evaluateExpression({bool finalEvaluation = false}) async {
    String expression = _inputController.text.trim();
    if (expression.isEmpty) {
      if (answer.isNotEmpty && mounted)
        setState(() {
          answer = '';
        });
      return;
    }
    if (!finalEvaluation &&
        (isEndingWithOperator.hasMatch(expression) ||
            (isEndingWithOpenParen.hasMatch(expression) &&
                !expression.endsWith(')')))) {
      return;
    }
    String resultString = '';
    String preparedExpression = expression;
    debugPrint("Original Expression: $expression");
    try {
      const double degToRad = pi / 180.0;
      // 1. Replace display symbols ONLY
      preparedExpression = preparedExpression.replaceAll('×', '*');
      preparedExpression = preparedExpression.replaceAll('÷', '/');
      preparedExpression =
          preparedExpression.replaceAll('π', '($pi)'); // Keep pi wrapped
      preparedExpression =
          preparedExpression.replaceAll('e', '($e)'); // Keep e wrapped

      // 2. Replace function names users type with internal names IF DIFFERENT
      preparedExpression = preparedExpression.replaceAll('√', 'sqrt');
      // Replace 'log(' with 'lg(' if math_expressions uses lg for base 10
      // (Confirm this in math_expressions docs or test)
      preparedExpression = preparedExpression.replaceAll('log(', 'lg(');

      debugPrint("After symbol/func replace: $preparedExpression");

      // 3. Handle Factorial and Percentage (as these need value calculation/replacement)
      preparedExpression =
          preparedExpression.replaceAllMapped(RegExp(r'(\d+)!'), (match) {
        /* Factorial */ int n = int.parse(match.group(1)!);
        if (n > 170) return 'Infinity';
        if (n < 0) return 'NaN';
        if (n == 0 || n == 1) return '1';
        double fact = 1;
        for (int i = 2; i <= n; i++) {
          fact *= i;
        }
        return fact.toString();
      });
      preparedExpression =
          preparedExpression.replaceAllMapped(RegExp(r'(\d*\.?\d+)%'), (match) {
        /* Percentage */ try {
          double val = double.parse(match.group(1)!);
          return '(${val / 100.0})';
        } catch (_) {
          return match.group(0)!;
        }
      });

      // 4. Handle Modulo (using '%') - Do this AFTER simple percentage replacement
      // Ensure it doesn't conflict if math_expressions uses % differently
      preparedExpression = preparedExpression
          .replaceAllMapped(RegExp(r'(\d+\.?\d*)\s*%\s*(\d+\.?\d*)'), (match) {
        /* Modulo */ try {
          double left = double.parse(match.group(1)!);
          double right = double.parse(match.group(2)!);
          return (left % right).toString();
        } catch (_) {
          return match.group(0)!;
        }
      });

      // 5. Handle Degree Conversion (BEFORE parsing)
      if (isDeg) {
        /* Degree conversion */
        preparedExpression = preparedExpression
            .replaceAllMapped(RegExp(r'(sin|cos|tan)\((.*?)\)'), (match) {
          String functionName = match.group(1)!;
          String innerExpression = match.group(2)!;
          // Check if inner expression already looks converted - basic check
          if (!innerExpression.contains('* $degToRad')) {
            // Ensure the argument expression itself is valid before multiplying
            // Wrapping the inner expression ensures it's evaluated first
            return '$functionName(($innerExpression) * $degToRad)';
          }
          return match.group(0)!; // Already converted or complex, leave it
        });
      }

      // *** REMOVED Power Handling Replacement ***
      // Let the parser handle the '^' operator directly.
      // debugPrint("Before power replace: $preparedExpression");
      // preparedExpression = preparedExpression.replaceAllMapped( ... ); // NO LONGER NEEDED
      // debugPrint("After power replace: $preparedExpression");
      // *** END REMOVAL ***

      // 6. Attempt Parenthesis Balancing (as before)
      int openParenCount = '('.allMatches(preparedExpression).length;
      int closeParenCount = ')'.allMatches(preparedExpression).length;
      if (openParenCount > closeParenCount) {
        preparedExpression += ')' * (openParenCount - closeParenCount);
        debugPrint("Attempted parenthesis fix: $preparedExpression");
      }

      debugPrint(
          "Final expression for parser: $preparedExpression"); // Final check

      // 7. Parse and Evaluate
      cm.bindVariable(Variable('X'), Number(variables['X'] ?? 0));
      cm.bindVariable(Variable('Y'), Number(variables['Y'] ?? 0));
      Parser p = Parser();
      Expression exp = p.parse(preparedExpression); // PARSE the prepared string
      double result = exp.evaluate(EvaluationType.REAL, cm);
      if (result.isNaN) {
        resultString = 'Error';
      } else if (result.isInfinite) {
        resultString = result.isNegative ? '-Infinity' : 'Infinity';
      } else {
        resultString = formatNumber(result);
      }
    } catch (e) {
      debugPrint(
          'Eval Error for expression: "$preparedExpression" (original: "$expression")\nError: $e');
      resultString = 'Error';
    }
    if (mounted && (finalEvaluation || answer != resultString)) {
      final bool resultIsSameAsInput = (resultString == expression);
      setState(() {
        if (!finalEvaluation &&
            resultIsSameAsInput &&
            resultString != "Error") {
          answer = '';
        } else {
          answer = resultString;
        }
      });
    }
  }

  // --- Input Handling (Unchanged) ---
  // Pressing '^' or '10ˣ' (which inserts '10^(') is handled correctly here.
  void buttonPressed(String buttonText) {
    /* ... same as before ... */
    String currentText = _inputController.text;
    TextSelection currentSelection = _inputController.selection;
    int cursorPos = currentSelection.baseOffset >= 0
        ? currentSelection.baseOffset
        : currentText.length;
    cursorPos = cursorPos.clamp(0, currentText.length);
    StringBuffer buffer = StringBuffer();
    int newCursorPos = cursorPos;
    bool evaluateAfter = true;
    switch (buttonText) {
      case 'AC':
        if (mounted)
          setState(() {
            _inputController.clear();
            answer = '';
            _animationController.reset();
          });
        return;
      case '=':
        if (currentText.isNotEmpty &&
            !isEndingWithOperator.hasMatch(currentText.trim()) &&
            !isEndingWithOpenParen
                .hasMatch(currentText.trim().replaceAll(RegExp(r'\)+$'), ''))) {
          _evaluateExpression(finalEvaluation: true).then((_) {
            if (mounted &&
                answer.isNotEmpty &&
                answer != "Error" &&
                !answer.contains("Infinity")) {
              addToHistory(currentText.trim(), answer);
              _animationController.forward();
            } else if (mounted) {
              _animationController.reset();
            }
          });
        } else if (mounted) {
          _animationController.reset();
        }
        return;
      case 'del':
        /* ... delete logic ... */ if (currentSelection.isValid &&
            currentSelection.isCollapsed &&
            cursorPos > 0) {
          buffer.write(currentText.substring(0, cursorPos - 1));
          buffer.write(currentText.substring(cursorPos));
          newCursorPos = cursorPos - 1;
        } else if (currentSelection.isValid && !currentSelection.isCollapsed) {
          buffer.write(currentText.substring(0, currentSelection.start));
          buffer.write(currentText.substring(currentSelection.end));
          newCursorPos = currentSelection.start;
        } else if (currentText.isNotEmpty && cursorPos == currentText.length) {
          buffer.write(currentText.substring(0, currentText.length - 1));
          newCursorPos = buffer.length;
        } else {
          buffer.write(currentText);
          newCursorPos = cursorPos;
        }
        if (mounted) {
          final newText = buffer.toString();
          _inputController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newCursorPos),
          );
          _animationController.reset();
          if (newText.isNotEmpty &&
              !isEndingWithOperator.hasMatch(newText) &&
              !(isEndingWithOpenParen.hasMatch(newText) &&
                  !newText.endsWith(')'))) {
            _evaluateExpression();
          } else if (mounted) {
            setState(() {
              answer = '';
            });
          }
        }
        return;
      case 'deg':
      case 'rad':
        if (mounted)
          setState(() {
            isDeg = !isDeg;
            _evaluateExpression();
          });
        return;
      case 'hist':
        _showHistory(context);
        return;
      case 'X':
      case 'Y':
        handleVariableInput(buttonText);
        return;
    }
    if (_animationController.status == AnimationStatus.completed) {
      _animationController.reset();
      if (answer.isNotEmpty && mounted)
        setState(() {
          answer = '';
        });
    }
    String textToInsert = buttonText;
    String charBefore = cursorPos > 0 ? currentText[cursorPos - 1] : '';
    String textBeforeCursor = currentText.substring(0, cursorPos);
    if (isTrigFun.hasMatch('$buttonText(') ||
        isLogFun.hasMatch('$buttonText(') ||
        buttonText == '√') {
      if (endsWithNumberOrParenOrConst.hasMatch(textBeforeCursor.trim())) {
        textToInsert = '*$buttonText(';
      } else {
        textToInsert = '$buttonText(';
      }
      evaluateAfter = false;
    } else if (buttonText == "10ˣ") {
      if (endsWithNumberOrParenOrConst.hasMatch(textBeforeCursor.trim())) {
        textToInsert = "*10^(";
      } else {
        textToInsert = "10^(";
      }
      evaluateAfter = false;
    } // Inserts 10^(
    else if (buttonText == '.') {
      final numberSegment =
          RegExp(r'(\d*\.?\d*)$').firstMatch(textBeforeCursor)?.group(0) ?? '';
      if (numberSegment.contains('.'))
        textToInsert = '';
      else if (cursorPos == 0 ||
          isOperator.hasMatch(charBefore) ||
          charBefore == '(')
        textToInsert = '0.';
      else
        textToInsert = '.';
      evaluateAfter = numberSegment.isNotEmpty;
    } else if (buttonText == '0') {
      final numberSegment =
          RegExp(r'(\d*\.?\d*)$').firstMatch(textBeforeCursor)?.group(0) ?? '';
      if (numberSegment == '0')
        textToInsert = '';
      else
        textToInsert = '0';
    } else if (buttonText == '%' || buttonText == '!') {
      if (!endsWithNumberOrParenOrConst.hasMatch(textBeforeCursor.trim()))
        textToInsert = '';
      else
        textToInsert = buttonText;
      evaluateAfter = true;
    }
    // The '^' button inserts '^' directly, no special logic needed here anymore
    else if (isOperator.hasMatch(buttonText)) {
      evaluateAfter = false;
      String trimmedBefore = textBeforeCursor.trim();
      if (isEndingWithOperator.hasMatch(trimmedBefore) &&
          !(trimmedBefore.endsWith('(') &&
              (buttonText == '+' || buttonText == '-'))) {
        buffer.write(currentText.substring(0, trimmedBefore.length - 1));
        buffer.write(buttonText);
        buffer.write(currentText.substring(cursorPos));
        newCursorPos = trimmedBefore.length;
        textToInsert = '';
      } else if (charBefore == '(' && buttonText != '-' && buttonText != '+') {
        textToInsert = '';
      } else if (currentText.isEmpty &&
          (buttonText == '-' || buttonText == '+')) {
        textToInsert = buttonText;
      } else if (endsWithNumberOrParenOrConst.hasMatch(trimmedBefore) ||
          buttonText == '-') {
        textToInsert = buttonText;
      } else if (currentText.isEmpty) {
        textToInsert = '';
      } else {
        textToInsert = buttonText;
      }
    } else if (buttonText == '(') {
      evaluateAfter = false;
      if (endsWithNumberOrParenOrConst.hasMatch(textBeforeCursor.trim()))
        textToInsert = '*(';
      else
        textToInsert = '(';
    } else if (buttonText == ')') {
      if ('('.allMatches(currentText).length >
              ')'.allMatches(currentText).length &&
          !isEndingWithOperator.hasMatch(textBeforeCursor.trim()) &&
          !textBeforeCursor.trim().endsWith('(')) {
        textToInsert = ')';
        evaluateAfter = true;
      } else {
        textToInsert = '';
        evaluateAfter = false;
      }
    } else if (buttonText == 'π' || buttonText == 'e') {
      if (endsWithNumberOrParenOrConst.hasMatch(textBeforeCursor.trim()))
        textToInsert = '*$buttonText';
      else
        textToInsert = buttonText;
      evaluateAfter = true;
    }
    if (textToInsert.isNotEmpty) {
      if (buffer.isEmpty) {
        buffer.write(currentText.substring(0, cursorPos));
        buffer.write(textToInsert);
        buffer.write(currentText.substring(cursorPos));
        newCursorPos = cursorPos + textToInsert.length;
      }
      final newText = buffer.toString();
      if (mounted) {
        setState(() {
          _inputController.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: newCursorPos));
          if (evaluateAfter &&
              !isEndingWithOperator.hasMatch(newText.trim()) &&
              !(isEndingWithOpenParen.hasMatch(newText.trim()) &&
                  !newText.endsWith(')'))) {
            _evaluateExpression();
          }
        });
      }
    }
  }

  // --- Variable Handling (Unchanged) ---
  void handleVariableInput(String varName) {
    /* ... */ if (answer.isNotEmpty &&
        answer != "Error" &&
        !answer.contains("Infinity")) {
      try {
        double valueToStore = double.parse(answer);
        if (mounted) {
          setState(() {
            variables[varName] = valueToStore;
            _inputController.clear();
            _animationController.reset();
            answer = "$varName = ${formatNumber(valueToStore)}";
          });
        }
      } catch (e) {
        debugPrint("Var assign error '$answer': $e");
        if (mounted)
          setState(() {
            answer = "Error storing $varName";
          });
      }
    } else {
      String currentText = _inputController.text;
      TextSelection currentSelection = _inputController.selection;
      int cursorPos = currentSelection.baseOffset >= 0
          ? currentSelection.baseOffset
          : currentText.length;
      cursorPos = cursorPos.clamp(0, currentText.length);
      StringBuffer buffer = StringBuffer();
      int newCursorPos = cursorPos;
      String textToInsert = varName;
      String textBeforeCursor = currentText.substring(0, cursorPos);
      if (endsWithNumberOrParenOrConst.hasMatch(textBeforeCursor.trim())) {
        textToInsert = '*$varName';
      }
      buffer.write(currentText.substring(0, cursorPos));
      buffer.write(textToInsert);
      buffer.write(currentText.substring(cursorPos));
      newCursorPos = cursorPos + textToInsert.length;
      if (mounted) {
        setState(() {
          _inputController.value = TextEditingValue(
              text: buffer.toString(),
              selection: TextSelection.collapsed(offset: newCursorPos));
          _animationController.reset();
          _evaluateExpression();
        });
      }
    }
  }

  // --- Helper Functions (Unchanged) ---
  String formatNumber(double number) {
    /* ... */ if (number.isNaN) return 'Error';
    if (number.isInfinite) return number.isNegative ? '-Infinity' : 'Infinity';
    String formatted = number.toString();
    if (formatted.contains('.')) {
      formatted = number.toStringAsFixed(10);
      formatted = formatted.replaceAll(RegExp(r'0+$'), '');
      formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    }
    return formatted;
  }

  // --- UI Building (Unchanged) ---
  final Map<String, Color> _buttonColors = {
    /* ... */ 'deg': CupertinoColors.systemBlue.withOpacity(0.3),
    'rad': CupertinoColors.systemOrange.withOpacity(0.3),
    'X': CupertinoColors.systemPurple.withOpacity(0.3),
    'Y': CupertinoColors.systemTeal.withOpacity(0.3),
    'hist': CupertinoColors.systemIndigo.withOpacity(0.3),
    'sin': CupertinoColors.systemGrey4,
    'cos': CupertinoColors.systemGrey4,
    'tan': CupertinoColors.systemGrey4,
    'log': CupertinoColors.systemGrey4,
    '10ˣ': CupertinoColors.systemGrey4,
    '√': CupertinoColors.systemGrey4,
    '(': CupertinoColors.systemGrey4,
    ')': CupertinoColors.systemGrey4,
    '%': CupertinoColors.systemGrey4,
    '!': CupertinoColors.systemGrey4,
    '^': CupertinoColors.systemGrey4,
    'π': CupertinoColors.systemGrey4,
    'e': CupertinoColors.systemGrey4,
    'AC': CupertinoColors.systemRed.withOpacity(0.3),
    'del': CupertinoColors.systemRed.withOpacity(0.3),
    '=': CupertinoColors.systemGreen.withOpacity(0.5),
    '+': CupertinoColors.systemGrey2,
    '-': CupertinoColors.systemGrey2,
    '×': CupertinoColors.systemGrey2,
    '÷': CupertinoColors.systemGrey2,
    '.': CupertinoColors.white,
    '0': CupertinoColors.white,
    '1': CupertinoColors.white,
    '2': CupertinoColors.white,
    '3': CupertinoColors.white,
    '4': CupertinoColors.white,
    '5': CupertinoColors.white,
    '6': CupertinoColors.white,
    '7': CupertinoColors.white,
    '8': CupertinoColors.white,
    '9': CupertinoColors.white,
  };
  double getButtonTextSize(String text, double btnSize) {
    /* ... */ if (text == '10ˣ') return btnSize * 0.32;
    if (text.length > 1 && !RegExp(r'^\d+$').hasMatch(text))
      return btnSize * 0.32;
    if (isDigit.hasMatch(text) || text == '.') return btnSize * 0.4;
    if (text == '=' || text == '+' || text == '-' || text == '×' || text == '÷')
      return btnSize * 0.45;
    return btnSize * 0.38;
  }

  Widget buildButton(String text, double btnSize) {
    /* ... */ Color buttonColor = _buttonColors[text] ?? CupertinoColors.white;
    Color fgColor = (text == 'AC' || text == 'del')
        ? CupertinoColors.systemRed
        : CupertinoColors.label;
    if (text == '=') fgColor = CupertinoColors.white;
    Widget content;
    if (text == 'hist') {
      content = Icon(FluentIcons.history_24_regular,
          size: btnSize * 0.45, color: fgColor);
    } else if (text == 'del') {
      content = Icon(FluentIcons.backspace_24_regular,
          size: btnSize * 0.45, color: fgColor);
    } else {
      final String displayText =
          (text == 'deg') ? (isDeg ? 'deg' : 'rad') : text;
      if (text == 'deg')
        buttonColor = isDeg ? _buttonColors['deg']! : _buttonColors['rad']!;
      content = Text(displayText,
          style: TextStyle(
              fontSize: getButtonTextSize(displayText, btnSize),
              color: fgColor,
              fontWeight: (text == '=') ? FontWeight.bold : FontWeight.w500,
              fontFamily: 'Inter'));
    }
    return Container(
      width: btnSize,
      height: btnSize * 0.8,
      margin: EdgeInsets.all(btnSize * 0.04),
      decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(btnSize * 0.25),
          boxShadow: [
            BoxShadow(
                color: CupertinoColors.systemGrey.withOpacity(0.1),
                spreadRadius: 0.5,
                blurRadius: 2,
                offset: const Offset(0, 1))
          ]),
      child: CupertinoButton(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(btnSize * 0.25),
          onPressed: () => buttonPressed(text),
          child: Center(child: content)),
    );
  }

  @override
  Widget build(BuildContext context) {
    /* ... */ final screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = 24.0;
    final double buttonSpacing = 8.0;
    final double availableWidth =
        screenWidth - horizontalPadding - (4 * buttonSpacing);
    final double btnSize = (availableWidth / 5.0).clamp(55.0, 70.0);
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding / 2, vertical: 8.0),
          child: Column(
            children: <Widget>[
              Expanded(
                  flex: 3,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      alignment: Alignment.bottomRight,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            /* History Preview */ ...history
                                .take(2)
                                .map((entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: Text(
                                        "${entry.expression} = ${entry.result}",
                                        style: const TextStyle(
                                            fontSize: 16,
                                            color:
                                                CupertinoColors.secondaryLabel,
                                            fontFamily: 'Inter'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis)))
                                .toList()
                                .reversed,
                            const Spacer(),
                            /* Input Field */ AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return CupertinoTextField(
                                      controller: _inputController,
                                      readOnly: true,
                                      showCursor: true,
                                      cursorColor: CupertinoColors.activeBlue,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontSize:
                                              _inputTextSizeAnimation.value,
                                          color: CupertinoColors.label,
                                          fontWeight: FontWeight.w300,
                                          fontFamily: 'Inter'),
                                      decoration: null,
                                      maxLines: 2,
                                      minLines: 1,
                                      onTap: () {
                                        if (_inputController
                                                    .selection.baseOffset <
                                                0 ||
                                            _inputController
                                                    .selection.extentOffset <
                                                0) {
                                          _inputController.selection =
                                              TextSelection.collapsed(
                                                  offset: _inputController
                                                      .text.length);
                                        }
                                      });
                                }),
                            const SizedBox(height: 8),
                            /* Answer Text */ AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  final bool isError = answer == "Error" ||
                                      answer.contains("Infinity");
                                  return Opacity(
                                      opacity: 0.7 +
                                          (_animationController.value * 0.3),
                                      child: Transform.translate(
                                          offset: Offset(
                                              0,
                                              10 *
                                                  (1 -
                                                      _animationController
                                                          .value)),
                                          child: Text(answer,
                                              style: TextStyle(
                                                  fontSize:
                                                      _answerTextSizeAnimation
                                                          .value,
                                                  color: isError
                                                      ? CupertinoColors
                                                          .systemRed
                                                      : CupertinoColors.label,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: 'Inter'),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis)));
                                }),
                            const SizedBox(height: 10),
                          ]))),
              const SizedBox(height: 8),
              Expanded(
                  flex: 5,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                          (stringList.length / 5).ceil(),
                          (rowIndex) => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(5, (columnIndex) {
                                final index = rowIndex * 5 + columnIndex;
                                if (index >= stringList.length)
                                  return SizedBox(width: btnSize);
                                return buildButton(stringList[index], btnSize);
                              }))))),
            ],
          ),
        ),
      ),
    );
  }

  // --- History Modal (Unchanged) ---
  void _showHistory(BuildContext parentContext) {
    /* ... */ showCupertinoModalPopup(
      context: parentContext,
      builder: (modalContext) {
        return GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! > 200) {
              Navigator.pop(modalContext);
            }
          },
          child: Container(
            height: MediaQuery.of(modalContext).size.height * 0.65,
            decoration: const BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20))),
            child: Column(
              children: [
                Container(
                    height: 5,
                    width: 35,
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey4,
                        borderRadius: BorderRadius.circular(2.5))),
                Expanded(
                  child: HistoryPage(
                    history: history,
                    onExpressionTap: (String resultFromHistory) {
                      if (mounted) {
                        setState(() {
                          _inputController.text = resultFromHistory;
                          _inputController.selection = TextSelection.collapsed(
                              offset: resultFromHistory.length);
                          answer = '';
                          _animationController.reset();
                          _evaluateExpression();
                        });
                        Navigator.pop(modalContext);
                      }
                    },
                    onClear: () {
                      _clearHistory();
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
} // End of _CalcPageState
