import 'dart:math';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart'; // Keep commented unless specific Material colors are needed
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
  static const double _inputFontScale = 0.042;
  static const double _answerFontScale = 0.045;
  static const double _minFontSize = 24.0;
  static const double _maxFontSize = 55.0;

  // --- Regular Expressions ---
  final isDigit = RegExp(r'[0-9]$');
  final isLogFun = RegExp(r'log\($'); // Matches log(
  final isTrigFun = RegExp(r'(sin|cos|tan)\($');
  final isEndingWithOperator = RegExp(r'[+\-*/×÷%^]$');
  final isEndingWithOpenParen = RegExp(r'\($');
  final isOperator = RegExp(r'[+\-*/×÷%^]');
  final endsWithNumberOrParenOrConst = RegExp(r'([\d.)eπXY])$');
  final endsWithFunctionName = RegExp(r'(sin|cos|tan|log|sqrt)$'); // Added log

  // --- Calculation Context & Variables ---
  final ContextModel cm = ContextModel();
  final Map<String, double> variables = {'X': 0, 'Y': 0};

  // --- History ---
  final List<CalculationHistory> history = [];
  final int maxHistoryEntries = 100;
  static const _historyKey = 'calculator_history_v8'; // Increment version

  // --- Button Layout ---
  final List<String> stringList = [
    'X',
    'Y',
    'deg',
    'hist',
    'AC',
    'sin',
    'cos',
    'tan',
    'π',
    'del',
    'e',
    '(',
    ')',
    '%',
    '÷',
    '!',
    '7',
    '8',
    '9',
    '×',
    '^',
    '4',
    '5',
    '6',
    '-',
    '√',
    '1',
    '2',
    '3',
    '+',
    'log',
    '10ˣ',
    '0',
    '.',
    '=',
  ];

  // --- Initialization & Disposal ---
  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _inputTextSizeAnimation = const AlwaysStoppedAnimation(36.0);
    _answerTextSizeAnimation = const AlwaysStoppedAnimation(32.0);
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final double baseInputSize =
        (screenHeight * _inputFontScale).clamp(_minFontSize, _maxFontSize);
    final double baseAnswerSize =
        (screenHeight * _answerFontScale).clamp(_minFontSize, _maxFontSize);
    final double initialInputSize = baseInputSize * 1.1;
    final double finalInputSize = baseInputSize * 0.9;
    final double initialAnswerSize = baseAnswerSize * 0.9;
    final double finalAnswerSize = baseAnswerSize * 1.1;

    _inputTextSizeAnimation = Tween<double>(
      begin: initialInputSize,
      end: finalInputSize,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _answerTextSizeAnimation = Tween<double>(
      begin: initialAnswerSize,
      end: finalAnswerSize,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _inputController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // --- History Management ---
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = history.reversed.map((entry) => entry.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  void addToHistory(String expr, String res) {
    if (expr.isEmpty || res.isEmpty || res == "Error" || expr == res) return;
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
    if (mounted) {
      setState(() {
        history.clear();
      });
      await _saveHistory();
    }
  }

  // --- Calculation Logic ---
  Future<void> _evaluateExpression({bool finalEvaluation = false}) async {
    String expression = _inputController.text.trim();

    // --- Early Exit Conditions for Intermediate Evaluation ---
    if (!finalEvaluation) {
      bool endsWithOp = isEndingWithOperator.hasMatch(expression);
      if (endsWithOp &&
          expression.length > 1 &&
          expression[expression.length - 2] == '(' &&
          expression.endsWith('-')) {
        endsWithOp = false;
      } // Allow unary minus after (
      bool endsWithOpenParenCheck = isEndingWithOpenParen.hasMatch(expression);
      int openParenCount = '('.allMatches(expression).length;
      int closeParenCount = ')'.allMatches(expression).length;
      bool parenthesisUnbalanced = openParenCount != closeParenCount;
      bool potentiallyUnclosedFunction = false;
      if (parenthesisUnbalanced) {
        // Added 'log(' to the check
        final funcPatterns = ['sin(', 'cos(', 'tan(', 'log(', 'sqrt(', 'pow('];
        int lastFuncOpenIndex = -1;
        for (var pattern in funcPatterns) {
          lastFuncOpenIndex =
              max(lastFuncOpenIndex, expression.lastIndexOf(pattern));
        }
        // If the last open paren seems to belong to a function call, don't eval yet
        if (lastFuncOpenIndex != -1 &&
            expression.lastIndexOf('(') >
                expression.lastIndexOf(')', lastFuncOpenIndex)) {
          potentiallyUnclosedFunction = true;
        }
      }
      if (expression.isEmpty ||
          endsWithOp ||
          endsWithOpenParenCheck ||
          potentiallyUnclosedFunction) {
        // Clear answer if intermediate state is definitely invalid
        if (answer.isNotEmpty &&
            mounted &&
            (endsWithOp ||
                endsWithOpenParenCheck ||
                potentiallyUnclosedFunction)) {
          // setState(() => answer = ''); // Optional: uncomment to clear answer visually
        }
        return; // Don't evaluate intermediate results for these cases
      }
    }
    if (expression.isEmpty) {
      if (answer.isNotEmpty && mounted) setState(() => answer = '');
      return;
    }
    // --- End of Early Exit ---

    String resultString = '';
    String preparedExpression = expression;
    debugPrint("Original Expression: $expression");
    try {
      const double degToRad = pi / 180.0;
      preparedExpression = preparedExpression.replaceAll('×', '*');
      preparedExpression = preparedExpression.replaceAll('÷', '/');
      preparedExpression = preparedExpression.replaceAll('π', '($pi)');
      preparedExpression = preparedExpression.replaceAll('e', '($e)');
      preparedExpression = preparedExpression.replaceAll('√', 'sqrt');

      // --- Corrected log replacement ---
      preparedExpression = preparedExpression.replaceAll('log(', 'log(10,');
      // ---

      debugPrint("After symbol/func replace: $preparedExpression");
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
      if (isDeg) {
        /* Degree conversion */ preparedExpression = preparedExpression
            .replaceAllMapped(RegExp(r'(sin|cos|tan)\((.*?)\)'), (match) {
          String functionName = match.group(1)!;
          String innerExpression = match.group(2)!;
          if (!innerExpression.contains('* $degToRad')) {
            return '$functionName(($innerExpression) * $degToRad)';
          }
          return match.group(0)!;
        });
      }

      int openParenCount = '('.allMatches(preparedExpression).length;
      int closeParenCount = ')'.allMatches(preparedExpression).length;
      if (openParenCount > closeParenCount) {
        if (finalEvaluation) {
          preparedExpression += ')' * (openParenCount - closeParenCount);
          debugPrint(
              "Attempted parenthesis fix for final eval: $preparedExpression");
        }
      }

      debugPrint("Final expression for parser: $preparedExpression");

      cm.bindVariable(Variable('X'), Number(variables['X'] ?? 0));
      cm.bindVariable(Variable('Y'), Number(variables['Y'] ?? 0));
      ExpressionParser p = GrammarParser(); // Use standard parser
      Expression exp = p.parse(preparedExpression);
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
      resultString = finalEvaluation ? 'Error' : '';
    }

    if (mounted) {
      bool shouldUpdate = false;
      if (finalEvaluation) {
        shouldUpdate = true;
      } else if (resultString.isNotEmpty && resultString != answer) {
        shouldUpdate = true;
      } else if (resultString.isEmpty &&
          answer.isNotEmpty &&
          !finalEvaluation) {
        shouldUpdate = true;
      } // Clear answer on intermediate error/empty

      if (shouldUpdate) {
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
  }

  // --- Input Handling ---
  void buttonPressed(String buttonText) {
    String currentText = _inputController.text;
    TextSelection currentSelection = _inputController.selection;
    int cursorPos = currentSelection.baseOffset >= 0
        ? currentSelection.baseOffset
        : currentText.length;
    cursorPos = cursorPos.clamp(0, currentText.length);
    StringBuffer buffer = StringBuffer();
    int newCursorPos = cursorPos;
    bool evaluateAfter = true; // Evaluate after insertion by default

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
        // Allow evaluation even if ending with ')'
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
        if (currentSelection.isValid &&
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
          // Re-evaluate after delete if it's potentially valid
          if (newText.isNotEmpty &&
              !isEndingWithOperator.hasMatch(newText) &&
              !(isEndingWithOpenParen.hasMatch(newText) &&
                  !newText.endsWith(')'))) {
            _evaluateExpression();
          } else if (mounted) {
            setState(() {
              answer = '';
            });
          } // Clear answer if deletion makes it invalid
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

    // Handle functions (inc log)
    if (isTrigFun.hasMatch('$buttonText(') ||
        isLogFun.hasMatch('$buttonText(') ||
        buttonText == '√') {
      if (endsWithNumberOrParenOrConst.hasMatch(textBeforeCursor.trim())) {
        textToInsert = '*$buttonText(';
      } else {
        textToInsert = '$buttonText(';
      }
      evaluateAfter = false; // Don't eval right after func name
    }
    // Handle 10ˣ
    else if (buttonText == "10ˣ") {
      if (endsWithNumberOrParenOrConst.hasMatch(textBeforeCursor.trim())) {
        textToInsert = "*10^(";
      } else {
        textToInsert = "10^(";
      }
      evaluateAfter = false; // Don't eval right after 10^(
    }
    // Handle dot
    else if (buttonText == '.') {
      final numberSegment =
          RegExp(r'(\d*\.?\d*)$').firstMatch(textBeforeCursor)?.group(0) ?? '';
      if (numberSegment.contains('.'))
        textToInsert = ''; // No double dots
      else if (cursorPos == 0 ||
          isOperator.hasMatch(charBefore) ||
          charBefore == '(')
        textToInsert = '0.'; // Prepend 0.
      else
        textToInsert = '.';
      evaluateAfter = false; // Usually don't eval just after dot
    }
    // Handle zero
    else if (buttonText == '0') {
      final numberSegment =
          RegExp(r'(\d*\.?\d*)$').firstMatch(textBeforeCursor)?.group(0) ?? '';
      if (numberSegment == '0')
        textToInsert = ''; // Prevent 00
      else
        textToInsert = '0';
      evaluateAfter = true; // Evaluate after zero if part of a valid number
    }
    // Handle % and !
    else if (buttonText == '%' || buttonText == '!') {
      if (!endsWithNumberOrParenOrConst.hasMatch(textBeforeCursor.trim()))
        textToInsert = '';
      else
        textToInsert = buttonText;
      evaluateAfter = true; // Try evaluating after these
    }
    // Handle Operators (including ^)
    else if (isOperator.hasMatch(buttonText)) {
      evaluateAfter = false;
      String trimmedBefore = textBeforeCursor.trim();
      // Replace last operator if not after ( or start of unary minus
      if (isEndingWithOperator.hasMatch(trimmedBefore) &&
          !(trimmedBefore.endsWith('(') &&
              (buttonText == '+' || buttonText == '-'))) {
        buffer.write(currentText.substring(0, trimmedBefore.length - 1));
        buffer.write(buttonText);
        buffer.write(currentText.substring(cursorPos));
        newCursorPos = trimmedBefore.length;
        textToInsert = '';
      }
      // Prevent non +/- operators immediately after (
      else if (charBefore == '(' && buttonText != '-' && buttonText != '+') {
        textToInsert = '';
      }
      // Allow leading +/-
      else if (currentText.isEmpty &&
          (buttonText == '-' || buttonText == '+')) {
        textToInsert = buttonText;
      }
      // Allow operator after number/paren/constant/variable, or allow unary minus
      else if (endsWithNumberOrParenOrConst.hasMatch(trimmedBefore) ||
          buttonText == '-') {
        textToInsert = buttonText;
      }
      // Disallow starting with other operators
      else if (currentText.isEmpty) {
        textToInsert = '';
      }
      // Default: insert if valid position
      else {
        textToInsert = buttonText;
      }
    }
    // Handle opening parenthesis
    else if (buttonText == '(') {
      evaluateAfter = false;
      if (endsWithNumberOrParenOrConst.hasMatch(textBeforeCursor.trim()))
        textToInsert = '*('; // Implicit multiplication
      else
        textToInsert = '(';
    }
    // Handle closing parenthesis
    else if (buttonText == ')') {
      if ('('.allMatches(currentText).length >
              ')'.allMatches(currentText).length &&
          !isEndingWithOperator.hasMatch(textBeforeCursor.trim()) &&
          !textBeforeCursor.trim().endsWith('(')) {
        textToInsert = ')';
        evaluateAfter = true; // Evaluate after closing
      } else {
        textToInsert = '';
        evaluateAfter = false;
      }
    }
    // Handle constants π, e
    else if (buttonText == 'π' || buttonText == 'e') {
      if (endsWithNumberOrParenOrConst.hasMatch(textBeforeCursor.trim()))
        textToInsert = '*$buttonText';
      else
        textToInsert = buttonText;
      evaluateAfter = true; // Evaluate after constants
    }
    // Digits are the default case
    else {
      evaluateAfter = true; // Evaluate after inserting a digit
    }

    // Perform insertion if textToInsert is valid
    if (textToInsert.isNotEmpty) {
      if (buffer.isEmpty) {
        // If buffer wasn't used (e.g., for operator replacement)
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
          // Evaluate if flag is set and expression is potentially valid
          if (evaluateAfter) {
            _evaluateExpression(); // Let evaluate function handle validity checks
          } else if (answer.isNotEmpty) {
            // If not evaluating, maybe clear previous answer? Optional.
            // answer = '';
          }
        });
      }
    } else if (!evaluateAfter && mounted && answer.isNotEmpty) {
      // If insertion was blocked and not evaluating, maybe clear answer? Optional.
      // setState(() { answer = ''; });
    }
  }

  // --- Variable Handling ---
  void handleVariableInput(String varName) {
    if (answer.isNotEmpty &&
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

  // --- Helper Functions ---
  String formatNumber(double number) {
    if (number.isNaN) return 'Error';
    if (number.isInfinite) return number.isNegative ? '-Infinity' : 'Infinity';
    String formatted = number.toString();
    if (formatted.contains('e')) {
      // Handle scientific notation more gracefully
      // Format scientific notation to a fixed number of significant digits if desired
      // Or just return it as is for now.
      return formatted;
    }
    if (formatted.contains('.')) {
      formatted = number.toStringAsFixed(10); // Max 10 decimal places
      formatted =
          formatted.replaceAll(RegExp(r'0+$'), ''); // Trim trailing zeros
      formatted = formatted.replaceAll(RegExp(r'\.$'), ''); // Trim trailing dot
    }
    return formatted;
  }

  // --- UI Building ---
  final Map<String, Color> _buttonColors = {
    'deg': CupertinoColors.systemGreen.withOpacity(0.3),
    'rad': CupertinoColors.systemOrange.withOpacity(0.3),
    'X': CupertinoColors.systemPurple.withOpacity(0.3),
    'Y': CupertinoColors.systemTeal.withOpacity(0.3),
    'hist': CupertinoColors.systemIndigo.withOpacity(0.3),
    'sin': CupertinoColors.systemGrey5,
    'cos': CupertinoColors.systemGrey5,
    'tan': CupertinoColors.systemGrey5,
    'log': CupertinoColors.systemGrey5,
    '10ˣ': CupertinoColors.white,
    '√': CupertinoColors.systemGrey5,
    '(': CupertinoColors.systemGrey5,
    ')': CupertinoColors.systemGrey5,
    '%': CupertinoColors.systemGrey5,
    '!': CupertinoColors.systemGrey5,
    '^': CupertinoColors.systemGrey5,
    'π': CupertinoColors.systemGrey5,
    'e': CupertinoColors.systemGrey5,
    'AC': CupertinoColors.systemRed.withOpacity(0.3),
    'del': CupertinoColors.systemGrey5,
    '=': CupertinoColors.systemBlue.withOpacity(0.5),
    '+': CupertinoColors.systemGrey5,
    '-': CupertinoColors.systemGrey5,
    '×': CupertinoColors.systemGrey5,
    '÷': CupertinoColors.systemGrey5,
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
    if (text == '10ˣ') return btnSize * 0.32;
    if (text.length > 1 && !RegExp(r'^\d+$').hasMatch(text))
      return btnSize * 0.32;
    if (isDigit.hasMatch(text) || text == '.') return btnSize * 0.4;
    if (text == '=' || text == '+' || text == '-' || text == '×' || text == '÷')
      return btnSize * 0.45;
    return btnSize * 0.38;
  }

  Widget buildButton(String text, double btnSize) {
    Color buttonColor = _buttonColors[text] ?? CupertinoColors.white;
    Color fgColor = (text == 'del')
        ? CupertinoColors.systemRed
        : CupertinoColors.label; // AC handled by background
    if (text == '=') fgColor = CupertinoColors.white;
    Widget content;
    if (text == 'hist') {
      content = Icon(FluentIcons.history_24_regular,
          size: btnSize * 0.45, color: fgColor);
    } else if (text == 'del') {
      content = Icon(FluentIcons.backspace_24_filled,
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
          borderRadius: BorderRadius.circular(btnSize * 0.33), // Button radius
          boxShadow: [
            BoxShadow(
                color: CupertinoColors.systemGrey.withOpacity(0.1),
                spreadRadius: 0.5,
                blurRadius: 2,
                offset: const Offset(0, 1))
          ]),
      child: CupertinoButton(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(btnSize * 0.33), // Match radius
          onPressed: () => buttonPressed(text),
          child: Center(child: content)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final safeAreaPadding = mediaQuery.padding;
    final effectiveScreenHeight =
        screenHeight - safeAreaPadding.top - safeAreaPadding.bottom;
    final double horizontalPadding = screenWidth * 0.04;
    final double verticalPadding = effectiveScreenHeight * 0.01;
    final double displayButtonGap = effectiveScreenHeight * 0.015;
    final double buttonGridVerticalSpacing = effectiveScreenHeight * 0.01;
    final double approxButtonSpacing = screenWidth * 0.025;
    final double btnSize =
        ((screenWidth - horizontalPadding - (4 * approxButtonSpacing)) / 5.8)
            .clamp(45.0, 75.0);

    if (_inputTextSizeAnimation is AlwaysStoppedAnimation) {
      _initializeAnimations();
    }

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding / 2,
            vertical: verticalPadding,
          ),
          child: Column(
            children: <Widget>[
              // --- Display Area ---
              Expanded(
                flex: 3,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: effectiveScreenHeight * 0.01,
                  ),
                  alignment: Alignment.bottomRight,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Mini History
                        ...history
                            .take(2)
                            .map((entry) => Padding(
                                padding: EdgeInsets.only(
                                    bottom: effectiveScreenHeight * 0.008),
                                child: Text(
                                    "${entry.expression} = ${entry.result}",
                                    style: TextStyle(
                                        fontSize: (screenHeight * 0.018)
                                            .clamp(12.0, 18.0),
                                        color: CupertinoColors.secondaryLabel,
                                        fontFamily: 'Inter'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)))
                            .toList()
                            .reversed,
                        const Spacer(),
                        // Input Field
                        AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return CupertinoTextField(
                                  controller: _inputController,
                                  readOnly: true,
                                  showCursor: true,
                                  cursorColor: CupertinoColors.activeBlue,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: _inputTextSizeAnimation.value,
                                      color: CupertinoColors.label,
                                      fontWeight: FontWeight.w300,
                                      fontFamily: 'Inter'),
                                  decoration: null,
                                  maxLines: 2,
                                  minLines: 1,
                                  onTap: () {
                                    if (_inputController.selection.baseOffset <
                                            0 ||
                                        _inputController
                                                .selection.extentOffset <
                                            0) {
                                      _inputController.selection =
                                          TextSelection.collapsed(
                                              offset:
                                                  _inputController.text.length);
                                    }
                                  });
                            }),
                        SizedBox(height: effectiveScreenHeight * 0.01),
                        // Answer Text
                        AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              final bool isError = answer == "Error" ||
                                  answer.contains("Infinity");
                              return Opacity(
                                  opacity:
                                      0.7 + (_animationController.value * 0.3),
                                  child: Transform.translate(
                                      offset: Offset(
                                          0,
                                          10 *
                                              (1 - _animationController.value)),
                                      child: Text(answer,
                                          style: TextStyle(
                                              fontSize: _answerTextSizeAnimation
                                                  .value,
                                              color: isError
                                                  ? CupertinoColors.systemRed
                                                  : CupertinoColors.label,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Inter'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis)));
                            }),
                        SizedBox(height: effectiveScreenHeight * 0.01),
                      ]),
                ),
              ),
              SizedBox(height: displayButtonGap),
              // --- Button Grid ---
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    (stringList.length / 5).ceil(),
                    (rowIndex) => Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: buttonGridVerticalSpacing / 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(5, (columnIndex) {
                          final index = rowIndex * 5 + columnIndex;
                          if (index >= stringList.length) {
                            return SizedBox(
                                width: btnSize + (btnSize * 0.04 * 2));
                          }
                          return buildButton(stringList[index], btnSize);
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- History Modal ---
  void _showHistory(BuildContext parentContext) {
    showCupertinoModalPopup(
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
              child: Column(children: [
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
                    // Modified callback
                    if (mounted) {
                      setState(() {
                        _inputController.text =
                            resultFromHistory; // Use result as input
                        _inputController.selection = TextSelection.collapsed(
                            offset: resultFromHistory.length);
                        answer = ''; // Clear answer field
                        _animationController.reset();
                        _evaluateExpression(); // Try evaluating the result
                      });
                      Navigator.pop(modalContext); // Close modal
                    }
                  },
                  onClear: () {
                    _clearHistory();
                  },
                )),
              ]),
            ),
          );
        });
  }
} // End of _CalcPageState
