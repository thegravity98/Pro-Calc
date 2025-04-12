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
  late ScrollController _inputScrollController;

  String answer = '';
  bool isDeg = true;

  // --- Constants ---
  static const double _inputFontScale = 0.042;
  static const double _answerFontScale = 0.045;
  static const double _minFontSize = 24.0;
  static const double _maxFontSize = 55.0;

  // double _calculateInputFontSize(String inputText, double baseFontSize) {
  //   const int maxLengthBeforeShrink = 15; // Start shrinking after 15 chars
  //   const double minFontSize = 20.0; // Minimum font size
  //   const double scaleFactor = 0.95; // Shrink by 5% per extra character

  //   if (inputText.length <= maxLengthBeforeShrink) {
  //     return baseFontSize; // Use base font size for short inputs
  //   } else {
  //     // Calculate scaled font size
  //     final excessLength = inputText.length - maxLengthBeforeShrink;
  //     final scaledSize = baseFontSize * pow(scaleFactor, excessLength);
  //     return scaledSize.clamp(minFontSize, baseFontSize);
  //   }
  // }

  // --- Regular Expressions ---
  final isDigit = RegExp(r'[0-9]$');
  final isLogFun = RegExp(r'log\($'); // Matches log(
  final isTrigFun = RegExp(r'(sin|cos|tan)\($');
  final isEndingWithOperator = RegExp(r'[+\-*/×÷%^]$');
  final isEndingWithOpenParen = RegExp(r'\($');
  final isOperator = RegExp(r'[+\-*/×÷%^]');
  final endsWithNumberOrParenOrConst = RegExp(r'([\d.)eπXY])$');
  final endsWithFunctionName = RegExp(r'(sin|cos|tan|log|sqrt)$');
  final percentagePattern = RegExp(r'(\d+\.?\d*)\s*%\s*$'); // e.g., "90 + 2 %"
  final moduloPattern = RegExp(r'(\d+\.?\d*)\s*%\s*(\d+\.?\d*)'); // Added log

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
    _inputScrollController = ScrollController();
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
    _inputScrollController.dispose();
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
        history.first.result == res) {
      return;
    }
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
    debugPrint("Original Expression: '$expression'");

    if (!finalEvaluation) {
      bool endsWithOp = isEndingWithOperator.hasMatch(expression) &&
          !expression.endsWith('%');
      if (endsWithOp &&
          expression.length > 1 &&
          expression[expression.length - 2] == '(' &&
          expression.endsWith('-')) {
        endsWithOp = false;
      }
      bool endsWithOpenParenCheck = isEndingWithOpenParen.hasMatch(expression);
      int openParenCount = '('.allMatches(expression).length;
      int closeParenCount = ')'.allMatches(expression).length;
      bool parenthesisUnbalanced = openParenCount != closeParenCount;
      bool potentiallyUnclosedFunction = false;
      if (parenthesisUnbalanced) {
        final funcPatterns = ['sin(', 'cos(', 'tan(', 'log(', 'sqrt(', 'pow('];
        int lastFuncOpenIndex = -1;
        for (var pattern in funcPatterns) {
          lastFuncOpenIndex =
              max(lastFuncOpenIndex, expression.lastIndexOf(pattern));
        }
        if (lastFuncOpenIndex != -1 &&
            expression.lastIndexOf('(') >
                expression.lastIndexOf(')', lastFuncOpenIndex)) {
          potentiallyUnclosedFunction = true;
        }
      }
      debugPrint(
          "Checks: endsWithOp=$endsWithOp, endsWithOpenParen=$endsWithOpenParenCheck, unbalanced=$parenthesisUnbalanced, unclosedFunc=$potentiallyUnclosedFunction");
      if (expression.isEmpty ||
          endsWithOp ||
          endsWithOpenParenCheck ||
          potentiallyUnclosedFunction) {
        if (answer.isNotEmpty && mounted) setState(() => answer = '');
        return;
      }
    }
    if (expression.isEmpty) {
      if (answer.isNotEmpty && mounted) setState(() => answer = '');
      return;
    }

    String resultString = '';
    String preparedExpression = expression;

    try {
      const double degToRad = pi / 180.0;
      preparedExpression = preparedExpression.replaceAll('×', '*');
      preparedExpression = preparedExpression.replaceAll('÷', '/');
      preparedExpression = preparedExpression.replaceAll('π', '($pi)');
      // preparedExpression = preparedExpression.replaceAll('e', '($e)');
      preparedExpression = preparedExpression.replaceAllMapped(
          RegExp(r'(?<![\d.])e'),
          (match) => '($e)' // Replace with Euler's number in parentheses
          );
      preparedExpression = preparedExpression.replaceAll('√', 'sqrt');
      preparedExpression = preparedExpression.replaceAll('log(', 'log(10,');
      debugPrint("After symbol/func replace: '$preparedExpression'");

      preparedExpression =
          preparedExpression.replaceAllMapped(RegExp(r'(\d+)!'), (match) {
        int n = int.parse(match.group(1)!);
        if (n > 170) return 'Infinity';
        if (n < 0) return 'NaN';
        if (n == 0 || n == 1) return '1';
        double fact = 1;
        for (int i = 2; i <= n; i++) {
          fact *= i;
        }
        return fact.toString();
      });

      if (preparedExpression.contains('%')) {
        debugPrint("Processing % in: '$preparedExpression'");
        // 1. Standalone % (e.g., "8%")
        if (RegExp(r'^\s*(\d+\.?\d*)%$', caseSensitive: false)
            .hasMatch(preparedExpression)) {
          preparedExpression = preparedExpression.replaceAllMapped(
              RegExp(r'(\d+\.?\d*)%$', caseSensitive: false), (match) {
            final val = double.parse(match.group(1)!);
            final result = val / 100.0;
            debugPrint("Standalone %: $val % = $result");
            return result.toString();
          });
        }
        // 2. Percentage addition/subtraction (e.g., "90+2%")
        else if (RegExp(r'(\d+\.?\d*)[+\-](\d+\.?\d*)%$', caseSensitive: false)
            .hasMatch(preparedExpression)) {
          debugPrint("Percentage pattern matched: '$preparedExpression'");
          preparedExpression = preparedExpression.replaceAllMapped(
              RegExp(r'(\d+\.?\d*)[+\-](\d+\.?\d*)%$', caseSensitive: false),
              (match) {
            final baseValue = double.parse(match.group(1)!);
            final percentValue = double.parse(match.group(2)!);
            final operator = preparedExpression.contains('+') ? '+' : '-';
            final percentage = percentValue / 100 * baseValue;
            final result = operator == '+'
                ? baseValue + percentage
                : baseValue - percentage;
            debugPrint(
                "Percentage: $baseValue $operator ($percentValue / 100 * $baseValue) = $result");
            return result.toString();
          });
        }
        // 3. Modulo (e.g., "8%3")
        else if (moduloPattern.hasMatch(preparedExpression)) {
          debugPrint("Modulo pattern matched: '$preparedExpression'");
          preparedExpression =
              preparedExpression.replaceAllMapped(moduloPattern, (match) {
            final left = double.parse(match.group(1)!);
            final right = double.parse(match.group(2)!);
            final result = (left / 100 * right);
            debugPrint("Modulo: $left % $right = $result");
            return result.toString();
          });
        } else {
          debugPrint("Unmatched % pattern in: '$preparedExpression'");
        }
      } else {
        debugPrint("No % found in: '$preparedExpression'");
      }

      if (isDeg) {
        preparedExpression = preparedExpression
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
      if (openParenCount > closeParenCount && finalEvaluation) {
        preparedExpression += ')' * (openParenCount - closeParenCount);
      }

      debugPrint("Final expression for parser: '$preparedExpression'");
      if (preparedExpression.contains('%')) {
        throw Exception("Unprocessed '%' found");
      }

      cm.bindVariable(Variable('X'), Number(variables['X'] ?? 0));
      cm.bindVariable(Variable('Y'), Number(variables['Y'] ?? 0));
      ExpressionParser p = GrammarParser();
      Expression exp = p.parse(preparedExpression);
      double result = exp.evaluate(EvaluationType.REAL, cm);
      debugPrint("Parsed result: $result");
      if (result.isNaN) {
        resultString = 'Error';
      } else if (result.isInfinite) {
        resultString = result.isNegative ? '-Infinity' : 'Infinity';
      } else {
        resultString = formatNumber(result);
      }
    } catch (e) {
      debugPrint('Evaluation Error: $e');
      resultString = finalEvaluation ? 'Error' : '';
    }

    debugPrint("Result string: '$resultString'");
    if (mounted) {
      bool shouldUpdate = finalEvaluation ||
          (resultString.isNotEmpty && resultString != answer) ||
          (resultString.isEmpty && answer.isNotEmpty && !finalEvaluation);
      debugPrint("Should update: $shouldUpdate");
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
    final currentText = _inputController.text;
    final currentSelection = _inputController.selection;
    final cursorPos = currentSelection.baseOffset >= 0
        ? currentSelection.baseOffset.clamp(0, currentText.length)
        : currentText.length;
    final textBeforeCursor = currentText.substring(0, cursorPos);
    final charBefore = cursorPos > 0 ? currentText[cursorPos - 1] : '';
    final buffer = StringBuffer();
    int newCursorPos = cursorPos;
    bool evaluateAfter = true;

    debugPrint(
        "Button Pressed: '$buttonText', Current Text: '$currentText', Cursor: $cursorPos");

    // Helper to update text and cursor position
    void updateText(String newText, [int? cursorOffset]) {
      if (mounted) {
        setState(() {
          _inputController.value = TextEditingValue(
            text: newText,
            selection:
                TextSelection.collapsed(offset: cursorOffset ?? newCursorPos),
          );
          if (evaluateAfter) {
            _evaluateExpression();
          } else if (answer.isNotEmpty) {
            answer = '';
          }
        });
      }
    }

    // Handle special buttons that don't insert text
    switch (buttonText) {
      case 'AC':
        if (mounted) {
          setState(() {
            _inputController.clear();
            answer = '';
            _animationController.reset();
          });
        }
        return;
      case '=':
        debugPrint("Evaluating: '$currentText'");
        if (currentText.isNotEmpty &&
            (!isEndingWithOperator.hasMatch(currentText.trim()) ||
                currentText.trim().endsWith('%')) &&
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
        } else {
          debugPrint("Evaluation skipped: invalid expression");
          if (mounted) _animationController.reset();
        }
        return;
      case 'deg':
      case 'rad':
        if (mounted) {
          setState(() {
            isDeg = !isDeg;
            _evaluateExpression();
          });
        }
        return;
      case 'hist':
        _showHistory(context);
        return;
      case 'X':
      case 'Y':
        handleVariableInput(buttonText);
        return;
    }

    // Handle deletion
    if (buttonText == 'del') {
      if (currentSelection.isValid && !currentSelection.isCollapsed) {
        buffer.write(currentText.substring(0, currentSelection.start));
        buffer.write(currentText.substring(currentSelection.end));
        newCursorPos = currentSelection.start;
      } else if (cursorPos > 0) {
        const functionTokens = [
          'sin(',
          'cos(',
          'tan(',
          'log(',
          'sqrt(',
          '10^(',
          '√('
        ];
        String? matchedToken;
        for (final token in functionTokens) {
          if (textBeforeCursor.endsWith(token)) {
            matchedToken = token;
            break;
          }
        }
        if (matchedToken != null) {
          buffer
              .write(currentText.substring(0, cursorPos - matchedToken.length));
          buffer.write(currentText.substring(cursorPos));
          newCursorPos = cursorPos - matchedToken.length;
        } else {
          buffer.write(currentText.substring(0, cursorPos - 1));
          buffer.write(currentText.substring(cursorPos));
          newCursorPos = cursorPos - 1;
        }
      } else {
        buffer.write(currentText);
      }

      final newText = buffer.toString();
      if (mounted) {
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
        } else {
          setState(() => answer = '');
        }
      }
      return;
    }

    // Reset animation if completed
    if (_animationController.status == AnimationStatus.completed) {
      _animationController.reset();
      if (answer.isNotEmpty && mounted) setState(() => answer = '');
    }

    // Determine text to insert
    String textToInsert = buttonText;
    final trimmedBefore = textBeforeCursor.trim();
    final endsWithNumOrParenOrConst =
        endsWithNumberOrParenOrConst.hasMatch(trimmedBefore);
    final endsWithFactorial = textBeforeCursor.endsWith('!');

    // Restrict input to operators after '!'
    if (endsWithFactorial && !isOperator.hasMatch(buttonText)) {
      textToInsert = '';
      evaluateAfter = false;
    } else if (isTrigFun.hasMatch('$buttonText(') ||
        isLogFun.hasMatch('$buttonText(') ||
        buttonText == '√') {
      textToInsert =
          endsWithNumOrParenOrConst ? '*$buttonText(' : '$buttonText(';
      evaluateAfter = false;
    } else if (buttonText == '10ˣ') {
      textToInsert = endsWithNumOrParenOrConst ? '*10^(' : '10^(';
      evaluateAfter = false;
    } else if (buttonText == '.') {
      final numberSegment =
          RegExp(r'(\d*\.?\d*)$').firstMatch(textBeforeCursor)?.group(0) ?? '';
      textToInsert = numberSegment.contains('.')
          ? ''
          : (cursorPos == 0 ||
                  isOperator.hasMatch(charBefore) ||
                  charBefore == '(')
              ? '0.'
              : '.';
      evaluateAfter = false;
    } else if (buttonText == '0') {
      final numberSegment =
          RegExp(r'(\d*\.?\d*)$').firstMatch(textBeforeCursor)?.group(0) ?? '';
      textToInsert = numberSegment == '0' ? '' : '0';
    } else if (buttonText == '%') {
      textToInsert = (endsWithNumOrParenOrConst ||
              isOperator.hasMatch(charBefore) ||
              charBefore.isEmpty)
          ? '%'
          : '';
      evaluateAfter = textToInsert.isNotEmpty;
    } else if (buttonText == '!') {
      textToInsert = endsWithNumOrParenOrConst ? '!' : '';
      evaluateAfter = textToInsert.isNotEmpty;
    } else if (isOperator.hasMatch(buttonText)) {
      evaluateAfter = false;
      if (isEndingWithOperator.hasMatch(trimmedBefore) &&
          !(trimmedBefore.endsWith('(') &&
              (buttonText == '+' || buttonText == '-'))) {
        buffer.write(currentText.substring(0, trimmedBefore.length - 1));
        buffer.write(buttonText);
        buffer.write(currentText.substring(cursorPos));
        newCursorPos = trimmedBefore.length;
        updateText(buffer.toString(), newCursorPos);
        return;
      } else if (charBefore == '(' && buttonText != '-' && buttonText != '+') {
        textToInsert = '';
      } else if (currentText.isEmpty &&
          (buttonText == '-' || buttonText == '+')) {
        textToInsert = buttonText;
      } else if (endsWithNumOrParenOrConst || buttonText == '-') {
        textToInsert = buttonText;
      } else {
        textToInsert = currentText.isEmpty ? '' : buttonText;
      }
    } else if (buttonText == '(') {
      textToInsert = endsWithNumOrParenOrConst ? '*(' : '(';
      evaluateAfter = false;
    } else if (buttonText == ')') {
      textToInsert = ('('.allMatches(currentText).length >
                  ')'.allMatches(currentText).length &&
              !isEndingWithOperator.hasMatch(trimmedBefore) &&
              !trimmedBefore.endsWith('('))
          ? ')'
          : '';
      evaluateAfter = textToInsert.isNotEmpty;
    } else if (buttonText == 'π' || buttonText == 'e') {
      textToInsert = endsWithNumOrParenOrConst ? '*$buttonText' : buttonText;
    }

    // Insert text if applicable
    if (textToInsert.isNotEmpty) {
      buffer.write(currentText.substring(0, cursorPos));
      buffer.write(textToInsert);
      buffer.write(currentText.substring(cursorPos));
      newCursorPos = cursorPos + textToInsert.length;
      updateText(buffer.toString());
    } else if (!evaluateAfter && mounted && answer.isNotEmpty) {
      setState(() => answer = '');
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
        if (mounted) {
          setState(() {
            answer = "Error storing $varName";
          });
        }
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

  // Helper to convert numbers potentially in scientific notation (as string)
  // into a parser-friendly format like (mantissa * 10^exponent)
  String formatScientificForInput(String scientificString) {
    if (!scientificString.contains('e')) {
      // If it's not scientific, return as is
      return scientificString;
    }
    try {
      // Attempt to parse the scientific string back to a double
      double value = double.parse(scientificString);

      // Use toStringAsExponential to reliably get mantissa and exponent
      // We might choose a high precision here to avoid losing info
      String exponential =
          value.toStringAsExponential(15); // Use high precision

      // Split into mantissa and exponent parts
      List<String> parts = exponential.toLowerCase().split('e');
      if (parts.length == 2) {
        String mantissa = parts[0];
        String exponent = parts[1];
        // Remove leading '+' from exponent if present
        if (exponent.startsWith('+')) {
          exponent = exponent.substring(1);
        }
        // Ensure exponent is treated as integer (it should be)
        int expValue = int.parse(exponent);

        // Construct the string for the parser
        // Handle mantissa=1.0 cases simply as 10^exp
        if (double.tryParse(mantissa) == 1.0) {
          return '(10^($expValue))'; // Parser understands negative exponent here
        } else {
          return '($mantissa * 10^($expValue))';
        }
      }
      // Fallback if splitting fails
      return scientificString;
    } catch (e) {
      // Fallback if parsing fails
      debugPrint("Error converting scientific string '$scientificString': $e");
      return scientificString; // Return original on error
    }
  }

  // --- Helper Functions ---
  String formatNumber(double number) {
    if (number.isNaN) return 'Error';
    if (number.isInfinite) return number.isNegative ? '-Infinity' : 'Infinity';

    // --- Configuration for Scientific Notation ---
    // Threshold for switching to scientific notation (e.g., 1 trillion)
    const double largeThreshold = 1e12;
    // Threshold for switching for very small numbers (e.g., 1 billionth)
    const double smallThreshold = 1e-9;
    // Number of significant digits after the decimal in scientific notation
    const int exponentialPrecision = 6;
    // Max decimal places for regular numbers
    const int fixedPrecision = 10;
    // --------------------------------------------

    // Check if the number's magnitude warrants scientific notation
    if (number != 0 &&
        (number.abs() >= largeThreshold || number.abs() < smallThreshold)) {
      // Use exponential format
      return number.toStringAsExponential(exponentialPrecision);
    } else {
      // Handle numbers within the "normal" range
      String formatted;
      // Check if it's effectively an integer to avoid unnecessary decimals
      if (number == number.truncateToDouble()) {
        formatted = number.truncate().toString();
      } else {
        // Use toStringAsFixed for potentially better control over decimals
        // for numbers that *don't* need scientific notation.
        // Use the default toString first to potentially preserve precision
        // for numbers that might have many digits but are below the threshold.
        formatted = number.toString();
        // If default toString used scientific notation unexpectedly (can happen
        // for numbers slightly outside double precision limits), reformat.
        if (formatted.contains('e')) {
          formatted = number.toStringAsExponential(exponentialPrecision);
        } else if (formatted.contains('.')) {
          // If it has a decimal, format and trim
          formatted = number.toStringAsFixed(fixedPrecision);
          formatted =
              formatted.replaceAll(RegExp(r'0+$'), ''); // Trim trailing zeros
          formatted =
              formatted.replaceAll(RegExp(r'\.$'), ''); // Trim trailing dot
        }
        // If no decimal (was already integer string), keep as is.
      }
      return formatted;
    }
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
    if (text.length > 1 && !RegExp(r'^\d+$').hasMatch(text)) {
      return btnSize * 0.32;
    }
    if (isDigit.hasMatch(text) || text == '.') return btnSize * 0.4;
    if (text == '=' ||
        text == '+' ||
        text == '-' ||
        text == '×' ||
        text == '÷') {
      return btnSize * 0.45;
    }
    return btnSize * 0.38;
  }

  Widget buildButton(BuildContext context, String text, double btnSize) {
    final mediaQueryData = MediaQuery.of(context);
    final screenHeight = mediaQueryData.size.height;

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
      if (text == 'deg') {
        buttonColor = isDeg ? _buttonColors['deg']! : _buttonColors['rad']!;
      }
      content = Text(displayText,
          style: TextStyle(
              fontSize: getButtonTextSize(displayText, btnSize),
              color: fgColor,
              fontWeight: (text == '=') ? FontWeight.bold : FontWeight.w500,
              fontFamily: 'Inter'));
    }
    return Container(
      width: btnSize,
      height: screenHeight * 0.055,
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
                            return SingleChildScrollView(
                              controller:
                                  _inputScrollController, // Assign the controller
                              scrollDirection: Axis.horizontal,
                              reverse:
                                  true, // Keep the end of the text visible initially
                              physics: const BouncingScrollPhysics(
                                  // Use bouncing physics like iOS
                                  parent: AlwaysScrollableScrollPhysics()),
                              child: IntrinsicWidth(
                                child: CupertinoTextField(
                                  controller: _inputController,
                                  readOnly: true,
                                  showCursor: true,
                                  cursorColor: CupertinoColors.activeBlue,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: _inputTextSizeAnimation.value,
                                    color: CupertinoColors.label,
                                    fontWeight: FontWeight.w300,
                                    fontFamily: 'Inter',
                                  ),
                                  decoration: null,
                                  maxLines: 1, // Ensure single line
                                  onTap: () {
                                    if (_inputController.selection.baseOffset <
                                            0 ||
                                        _inputController
                                                .selection.extentOffset <
                                            0) {
                                      _inputController.selection =
                                          TextSelection.collapsed(
                                        offset: _inputController.text.length,
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
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
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        reverse: true, // Show end of the answer
                                        physics: const BouncingScrollPhysics(
                                            // Optional: Add physics
                                            parent:
                                                AlwaysScrollableScrollPhysics()),
                                        child: IntrinsicWidth(
                                          child: Text(
                                            answer,
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                                fontSize:
                                                    _answerTextSizeAnimation
                                                        .value,
                                                color: isError
                                                    ? CupertinoColors.systemRed
                                                    : CupertinoColors.label,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: 'Inter'),
                                            // maxLines: 1,
                                            // overflow: TextOverflow.ellipsis
                                          ),
                                        ),
                                      )));
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
                          return buildButton(
                              context, stringList[index], btnSize);
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
                    // --- Start Change ---
                    // Convert the result string if needed before setting input
                    final String textForInput =
                        formatScientificForInput(resultFromHistory);
                    debugPrint(
                        "History tapped. Original result: '$resultFromHistory', Using for input: '$textForInput'");
                    // --- End Change ---

                    if (mounted) {
                      setState(() {
                        // Use the potentially converted string
                        _inputController.text = textForInput;
                        _inputController.selection = TextSelection.collapsed(
                            offset: textForInput
                                .length); // Use length of converted string
                        answer = ''; // Clear answer field
                        _animationController.reset();
                        _evaluateExpression(); // Try evaluating immediately
                      });
                      // _scrollToEnd(); // Scroll after state update
                      Navigator.pop(modalContext); // Close modal
                    }
                  },
                  onClear: () {
                    _clearHistory();
                    Navigator.pop(modalContext);
                  },
                )),
              ]),
            ),
          );
        });
  }
} // End of _CalcPageState
