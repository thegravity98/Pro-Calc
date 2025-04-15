import 'dart:math';
import 'package:eval_ex/expression.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:eval_ex/eval_ex.dart';
// import 'package:flutter/material.dart'; // Keep commented unless specific Material colors are needed
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// import 'package:math_expressions/math_expressions.dart';
import 'history_page.dart'; // Ensure this path is correct
import '../models/calculation_history.dart'; // Ensure this path is correct
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

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
  bool isShift = false; // Track shift state
  bool _lastActionWasEval = false;

  final NumberFormat _numberFormat = NumberFormat(
    "#,##0.###",
    "en_US",
  ); // Flexible decimal places
  String _rawExpression = ''; // Store unformatted expression

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
  final isTrigFun = RegExp(r'(sin|cos|tan|asin|acos|atan)\($');
  final isEndingWithOperator = RegExp(r'[+\-*/×÷%^]$');
  final isEndingWithOpenParen = RegExp(r'\($');
  final isOperator = RegExp(r'[+\-*/×÷%^]');
  final endsWithNumberOrParenOrConst = RegExp(r'([\d.)eπXY])$');
  final endsWithFunctionName = RegExp(
    r'(sin|cos|tan|asin|acos|atan|log|sqrt)$',
  );
  final percentagePattern = RegExp(r'(\d+\.?\d*)\s*%\s*$'); // e.g., "90 + 2 %"
  final moduloPattern = RegExp(r'(\d+\.?\d*)\s*%\s*(\d+\.?\d*)'); // Added log

  // --- Calculation Context & Variables ---
  // final ContextModel cm = ContextModel();
  final Map<String, double> variables = {'X': 0, 'Y': 0};

  // --- History ---
  final List<CalculationHistory> history = [];
  final int maxHistoryEntries = 100;
  static const _historyKey = 'calculator_history_v8'; // Increment version

  // --- Button Layout ---
  final List<String> stringList = [
    'shft',
    'X',
    'Y',
    'DEG',
    // 'hist',
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
    // '10ˣ',
    '00',

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
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
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
    final double baseInputSize = (screenHeight * _inputFontScale).clamp(
      _minFontSize,
      _maxFontSize,
    );
    final double baseAnswerSize = (screenHeight * _answerFontScale).clamp(
      _minFontSize,
      _maxFontSize,
    );
    final double initialInputSize = baseInputSize * 1.2; // Larger initial size
    final double finalInputSize = baseInputSize * 0.8; // Smaller final size
    final double initialAnswerSize = baseAnswerSize * 0.8; // Smaller initial
    final double finalAnswerSize = baseAnswerSize * 1.2; // Larger final

    _inputTextSizeAnimation = Tween<double>(
      begin: initialInputSize,
      end: finalInputSize,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _answerTextSizeAnimation = Tween<double>(
      begin: initialAnswerSize,
      end: finalAnswerSize,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
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
  // Future<void> _evaluateExpression({bool finalEvaluation = false}) async {
  //   String expression = _rawExpression.trim();
  //   debugPrint("Original Expression: '$expression'");

  //   // Skip evaluation for empty or invalid expressions unless finalEvaluation is true
  //   if (expression.isEmpty) {
  //     if (answer.isNotEmpty && mounted) setState(() => answer = '');
  //     return;
  //   }

  //   // Check for incomplete expressions
  //   bool endsWithOp =
  //       isEndingWithOperator.hasMatch(expression) && !expression.endsWith('%');
  //   if (endsWithOp &&
  //       expression.length > 1 &&
  //       expression[expression.length - 2] == '(' &&
  //       expression.endsWith('-')) {
  //     endsWithOp = false;
  //   }
  //   bool endsWithOpenParenCheck = isEndingWithOpenParen.hasMatch(expression);
  //   int openParenCount = '('.allMatches(expression).length;
  //   int closeParenCount = ')'.allMatches(expression).length;
  //   bool parenthesisUnbalanced = openParenCount != closeParenCount;
  //   bool potentiallyUnclosedFunction = false;
  //   if (parenthesisUnbalanced) {
  //     final funcPatterns = ['sin(', 'cos(', 'tan(', 'log(', 'sqrt(', 'pow('];
  //     int lastFuncOpenIndex = -1;
  //     for (var pattern in funcPatterns) {
  //       lastFuncOpenIndex =
  //           max(lastFuncOpenIndex, expression.lastIndexOf(pattern));
  //     }
  //     if (lastFuncOpenIndex != -1 &&
  //         expression.lastIndexOf('(') >
  //             expression.lastIndexOf(')', lastFuncOpenIndex)) {
  //       potentiallyUnclosedFunction = true;
  //     }
  //   }
  //   debugPrint(
  //       "Checks: endsWithOp=$endsWithOp, endsWithOpenParen=$endsWithOpenParenCheck, "
  //       "unbalanced=$parenthesisUnbalanced, unclosedFunc=$potentiallyUnclosedFunction");

  //   // Skip auto-update for incomplete expressions unless final evaluation
  //   if (!finalEvaluation &&
  //       (endsWithOp ||
  //           endsWithOpenParenCheck ||
  //           potentiallyUnclosedFunction ||
  //           expression.isEmpty)) {
  //     if (answer.isNotEmpty && mounted) setState(() => answer = '');
  //     return;
  //   }

  //   String resultString = '';
  //   String preparedExpression = expression;

  //   try {
  //     const double degToRad = pi / 180.0;
  //     preparedExpression = preparedExpression.replaceAll('×', '*');
  //     preparedExpression = preparedExpression.replaceAll('÷', '/');
  //     preparedExpression = preparedExpression.replaceAll('π', '($pi)');
  //     preparedExpression = preparedExpression.replaceAllMapped(
  //         RegExp(r'(?<![\d.])e'), (match) => '($e)');
  //     preparedExpression = preparedExpression.replaceAll('√', 'sqrt');
  //     preparedExpression = preparedExpression.replaceAll('log(', 'log(10,');
  //     debugPrint("After symbol/func replace: '$preparedExpression'");

  //     preparedExpression =
  //         preparedExpression.replaceAllMapped(RegExp(r'(\d+)!'), (match) {
  //       int n = int.parse(match.group(1)!);
  //       if (n > 170) return 'Infinity';
  //       if (n < 0) return 'NaN';
  //       if (n == 0 || n == 1) return '1';
  //       double fact = 1;
  //       for (int i = 2; i <= n; i++) {
  //         fact *= i;
  //       }
  //       return fact.toString();
  //     });

  //     if (preparedExpression.contains('%')) {
  //       debugPrint("Processing % in: '$preparedExpression'");
  //       if (RegExp(r'^\s*(\d+\.?\d*)%$', caseSensitive: false)
  //           .hasMatch(preparedExpression)) {
  //         preparedExpression = preparedExpression.replaceAllMapped(
  //             RegExp(r'(\d+\.?\d*)%$', caseSensitive: false), (match) {
  //           final val = double.parse(match.group(1)!);
  //           final result = val / 100.0;
  //           debugPrint("Standalone %: $val % = $result");
  //           return result.toString();
  //         });
  //       } else if (RegExp(r'(\d+\.?\d*)[+\-](\d+\.?\d*)%$',
  //               caseSensitive: false)
  //           .hasMatch(preparedExpression)) {
  //         debugPrint("Percentage pattern matched: '$preparedExpression'");
  //         preparedExpression = preparedExpression.replaceAllMapped(
  //             RegExp(r'(\d+\.?\d*)[+\-](\d+\.?\d*)%$', caseSensitive: false),
  //             (match) {
  //           final baseValue = double.parse(match.group(1)!);
  //           final percentValue = double.parse(match.group(2)!);
  //           final operator = preparedExpression.contains('+') ? '+' : '-';
  //           final percentage = percentValue / 100 * baseValue;
  //           final result = operator == '+'
  //               ? baseValue + percentage
  //               : baseValue - percentage;
  //           debugPrint(
  //               "Percentage: $baseValue $operator ($percentValue / 100 * $baseValue) = $result");
  //           return result.toString();
  //         });
  //       } else if (moduloPattern.hasMatch(preparedExpression)) {
  //         debugPrint("Modulo pattern matched: '$preparedExpression'");
  //         preparedExpression =
  //             preparedExpression.replaceAllMapped(moduloPattern, (match) {
  //           final left = double.parse(match.group(1)!);
  //           final right = double.parse(match.group(2)!);
  //           final result = (left / 100 * right);
  //           debugPrint("Modulo: $left % $right = $result");
  //           return result.toString();
  //         });
  //       } else {
  //         debugPrint("Unmatched % pattern in: '$preparedExpression'");
  //       }
  //     } else {
  //       debugPrint("No % found in: '$preparedExpression'");
  //     }

  //     if (isDeg) {
  //       preparedExpression = preparedExpression
  //           .replaceAllMapped(RegExp(r'(sin|cos|tan)\((.*?)\)'), (match) {
  //         String functionName = match.group(1)!;
  //         String innerExpression = match.group(2)!;
  //         if (!innerExpression.contains('* $degToRad')) {
  //           return '$functionName(($innerExpression) * $degToRad)';
  //         }
  //         return match.group(0)!;
  //       });
  //     }

  //     int openParenCount = '('.allMatches(preparedExpression).length;
  //     int closeParenCount = ')'.allMatches(preparedExpression).length;
  //     if (openParenCount > closeParenCount && finalEvaluation) {
  //       preparedExpression += ')' * (openParenCount - closeParenCount);
  //     }

  //     debugPrint("Final expression for parser: '$preparedExpression'");
  //     if (preparedExpression.contains('%')) {
  //       throw Exception("Unprocessed '%' found");
  //     }

  //     cm.bindVariable(Variable('X'), Number(variables['X'] ?? 0));
  //     cm.bindVariable(Variable('Y'), Number(variables['Y'] ?? 0));
  //     ExpressionParser p = GrammarParser();
  //     Expression exp = p.parse(preparedExpression);
  //     double result = exp.evaluate(EvaluationType.REAL, cm);
  //     debugPrint("Parsed result: $result");
  //     if (result.isNaN) {
  //       resultString = 'Error';
  //     } else if (result.isInfinite) {
  //       resultString = result.isNegative ? '-Infinity' : 'Infinity';
  //     } else {
  //       resultString = formatNumber(result);
  //     }
  //   } catch (e) {
  //     debugPrint('Evaluation Error: $e');
  //     resultString = finalEvaluation ? 'Error' : '';
  //   }

  //   debugPrint("Result string: '$resultString'");
  //   if (mounted) {
  //     bool shouldUpdate = finalEvaluation ||
  //         (resultString.isNotEmpty && resultString != answer) ||
  //         (resultString.isEmpty && answer.isNotEmpty && !finalEvaluation);
  //     debugPrint("Should update: $shouldUpdate");
  //     if (shouldUpdate) {
  //       final bool resultIsSameAsInput = (resultString == expression);
  //       setState(() {
  //         if (!finalEvaluation &&
  //             resultIsSameAsInput &&
  //             resultString != "Error") {
  //           answer = '';
  //         } else {
  //           answer = resultString;
  //         }
  //       });
  //     }
  //   }
  // }

  Future<void> evaluateExpression({bool finalEvaluation = false}) async {
    String expression = _rawExpression.trim();
    debugPrint("Original Expression: '$expression'");

    // Skip evaluation for empty or invalid expressions unless finalEvaluation is true
    if (expression.isEmpty) {
      if (answer.isNotEmpty && mounted) setState(() => answer = '');
      return;
    }

    // Check for incomplete expressions
    bool endsWithOp =
        isEndingWithOperator.hasMatch(expression) && !expression.endsWith('%');
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
        lastFuncOpenIndex = max(
          lastFuncOpenIndex,
          expression.lastIndexOf(pattern),
        );
      }
      if (lastFuncOpenIndex != -1 &&
          expression.lastIndexOf('(') >
              expression.lastIndexOf(')', lastFuncOpenIndex)) {
        potentiallyUnclosedFunction = true;
      }
    }
    debugPrint(
      "Checks: endsWithOp=$endsWithOp, endsWithOpenParen=$endsWithOpenParenCheck, "
      "unbalanced=$parenthesisUnbalanced, unclosedFunc=$potentiallyUnclosedFunction",
    );

    // Skip auto-update for incomplete expressions unless final evaluation
    if (!finalEvaluation &&
        (endsWithOp ||
            endsWithOpenParenCheck ||
            potentiallyUnclosedFunction ||
            expression.isEmpty)) {
      if (answer.isNotEmpty && mounted) setState(() => answer = '');
      return;
    }

    String resultString = '';
    String preparedExpression = expression;

    try {
      const double degToRad = pi / 180.0;
      preparedExpression = preparedExpression.replaceAll('×', '*');
      preparedExpression = preparedExpression.replaceAll('÷', '/');
      preparedExpression = preparedExpression.replaceAll(
        'π',
        '3.141592653589793',
      );
      preparedExpression = preparedExpression.replaceAllMapped(
        RegExp(r'(?<![\d.])e'),
        (match) => '2.718281828459045',
      );
      preparedExpression = preparedExpression.replaceAll('√', 'SQRT');
      preparedExpression = preparedExpression.replaceAll(
        'log(',
        'LOG10(',
      ); // eval_ex uses LOG10

      debugPrint("After symbol/func replace: '$preparedExpression'");

      // Handle factorial
      preparedExpression = preparedExpression.replaceAllMapped(
        RegExp(r'(\d+)!'),
        (match) {
          int n = int.parse(match.group(1)!);
          if (n > 170) return 'Infinity';
          if (n < 0) return 'NaN';
          if (n == 0 || n == 1) return '1';
          double fact = 1;
          for (int i = 2; i <= n; i++) {
            fact *= i;
          }
          return fact.toString();
        },
      );

      // Handle percentage
      if (preparedExpression.contains('%')) {
        debugPrint("Processing % in: '$preparedExpression'");
        if (RegExp(
          r'^\s*(\d+\.?\d*)%$',
          caseSensitive: false,
        ).hasMatch(preparedExpression)) {
          preparedExpression = preparedExpression.replaceAllMapped(
            RegExp(r'(\d+\.?\d*)%$', caseSensitive: false),
            (match) {
              final val = double.parse(match.group(1)!);
              final result = val / 100.0;
              debugPrint("Standalone %: $val % = $result");
              return result.toString();
            },
          );
        } else if (RegExp(
          r'(\d+\.?\d*)[+\-](\d+\.?\d*)%$',
          caseSensitive: false,
        ).hasMatch(preparedExpression)) {
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
                "Percentage: $baseValue $operator ($percentValue / 100 * $baseValue) = $result",
              );
              return result.toString();
            },
          );
        } else if (moduloPattern.hasMatch(preparedExpression)) {
          debugPrint("Modulo pattern matched: '$preparedExpression'");
          preparedExpression = preparedExpression.replaceAllMapped(
            moduloPattern,
            (match) {
              final left = double.parse(match.group(1)!);
              final right = double.parse(match.group(2)!);
              final result = (left / 100 * right);
              debugPrint("Modulo: $left % $right = $result");
              return result.toString();
            },
          );
        } else {
          debugPrint("Unmatched % pattern in: '$preparedExpression'");
        }
      } else {
        debugPrint("No % found in: '$preparedExpression'");
      }

      // Convert degrees to radians for trig functions
      if (isDeg) {
        preparedExpression = preparedExpression.replaceAllMapped(
          RegExp(r'(SIN|COS|TAN)\((.*?)\)'),
          (match) {
            String functionName = match.group(1)!;
            String innerExpression = match.group(2)!;
            if (!innerExpression.contains('* $degToRad')) {
              return '$functionName(($innerExpression) * $degToRad)';
            }
            return match.group(0)!;
          },
        );
      }

      // Balance parentheses
      int openParenCount = '('.allMatches(preparedExpression).length;
      int closeParenCount = ')'.allMatches(preparedExpression).length;
      if (openParenCount > closeParenCount && finalEvaluation) {
        preparedExpression += ')' * (openParenCount - closeParenCount);
      }

      debugPrint("Final expression for parser: '$preparedExpression'");
      if (preparedExpression.contains('%')) {
        throw Exception("Unprocessed '%' found");
      }

      // Use eval_ex to evaluate the expression
      Expression exp = Expression(preparedExpression);
      // Set variables X and Y
      exp.setStringVariable("X", variables['X'].toString());
      exp.setStringVariable("Y", variables['Y'].toString());
      // Evaluate
      double result = double.parse(exp.eval()!.toString());
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

  void buttonPressed(String buttonText) {
    final currentText = _rawExpression; // Use raw expression internally
    final currentSelection = _inputController.selection;
    final cursorPos = currentSelection.baseOffset >= 0
        ? currentSelection.baseOffset.clamp(0, currentText.length)
        : currentText.length;
    final textBeforeCursor = currentText.substring(0, cursorPos);
    final charBefore = cursorPos > 0 ? currentText[cursorPos - 1] : '';
    final buffer = StringBuffer();
    int newCursorPos = cursorPos;
    bool evaluateAfter = false; // Default to false to prevent auto-evaluation

    debugPrint(
      "Button Pressed: '$buttonText', Raw Text: '$currentText', Cursor: $cursorPos",
    );

    // Helper to update text and cursor position
    // Modify the updateText helper function to ensure raw expression is correctly updated
    void updateText(String newRawText, [int? cursorOffset]) {
      if (mounted) {
        setState(() {
          _rawExpression = newRawText;
          String formattedText = formatExpression(newRawText);
          // Always set cursor to end of formatted text unless specified
          int adjustedCursorPos = formattedText.length;
          debugPrint("Setting TextField to: '$formattedText'");
          _inputController.value = TextEditingValue(
            text: formattedText,
            selection: TextSelection.collapsed(offset: adjustedCursorPos),
          );
          _lastActionWasEval = false;
          if (evaluateAfter) {
            evaluateExpression();
          } else if (answer.isNotEmpty) {
            answer = '';
          }
        });
      }
    }

    // Handle special buttons
    switch (buttonText) {
      case 'AC':
        if (mounted) {
          setState(() {
            _rawExpression = '';
            _inputController.clear();
            answer = '';
            _animationController.reset();
            _lastActionWasEval = false; // Reset flag
          });
        }
        return;
      case '=':
        debugPrint("Evaluating: '$currentText'");
        if (currentText.isNotEmpty &&
            (!isEndingWithOperator.hasMatch(currentText.trim()) ||
                currentText.trim().endsWith('%')) &&
            !isEndingWithOpenParen.hasMatch(
              currentText.trim().replaceAll(RegExp(r'\)+$'), ''),
            )) {
          evaluateExpression(finalEvaluation: true).then((_) {
            if (mounted &&
                answer.isNotEmpty &&
                answer != "Error" &&
                !answer.contains("Infinity")) {
              addToHistory(_inputController.text.trim(), answer);
              setState(() {
                _lastActionWasEval = true;
                debugPrint(
                  "Starting animation: ${_animationController.status}",
                );
                _animationController.forward().then((_) {
                  debugPrint(
                    "Animation completed: ${_animationController.status}",
                  );
                });
              });
            } else if (mounted) {
              setState(() {
                debugPrint("Resetting animation on error");
                _animationController.reset();
              });
            }
          });
        } else {
          debugPrint("Evaluation skipped: invalid expression");
          if (mounted) _animationController.reset();
        }
        return;
      case 'DEG':
      case 'RAD':
        if (mounted) {
          setState(() {
            isDeg = !isDeg;
            _lastActionWasEval = false; // Reset flag
            evaluateAfter =
                currentText.isNotEmpty; // Evaluate only if there's input
            if (evaluateAfter) evaluateExpression();
          });
        }
        return;
      case 'hist':
        showHistory(context);
        _lastActionWasEval = false; // Reset flag
        return;
      case 'Home':
      case 'Unit':
      case 'Settings':
        showHistory(context);
        _lastActionWasEval = false; // Reset flag
        return;
      case 'Calc':
        _lastActionWasEval = false; // Reset flag
        return;
      case 'X':
      case 'Y':
        handleVariableInput(buttonText);
        return;
      case 'Copy':
        if (answer.isNotEmpty &&
            answer != 'Error' &&
            !answer.contains('Infinity')) {
          Clipboard.setData(ClipboardData(text: answer));
          showInfoSnackbar(context, 'Answer copied to clipboard');
        } else {
          showErrorSnackbar(context, 'No valid answer to copy');
        }
        return;
      case 'Paste':
        debugPrint("Starting paste operation");
        validateAndPasteClipboard(context).then((isValid) {
          debugPrint("Validation result: $isValid");
          if (!isValid) {
            debugPrint("Paste aborted due to invalid clipboard content");
            return;
          }
          if (mounted) {
            Clipboard.getData(Clipboard.kTextPlain).then((clipboardData) {
              String pastedText = clipboardData?.text?.trim() ?? '';
              debugPrint("Pasting text: '$pastedText'");
              if (pastedText.isEmpty) {
                debugPrint("Clipboard empty after validation");
                return;
              }
              // Process the expression to clean numbers and preserve operators
              final numberFormat = NumberFormat("#,##0.###", "en_US");
              final tokenPattern = RegExp(
                r'(\d{1,3}(?:,\d{3})*(?:\.\d+)?|[+\-*/×÷%^()]|\b(sin|cos|tan|log|sqrt|π|e|X|Y)\b)',
              );
              final tokens = <String>[];
              int index = 0;
              pastedText = pastedText.replaceAll(
                ' ',
                '',
              ); // Normalize spaces
              while (index < pastedText.length) {
                final substring = pastedText.substring(index);
                final match = tokenPattern.firstMatch(substring);
                if (match == null) {
                  index++;
                  continue;
                }
                tokens.add(match.group(0)!);
                index += match.end;
              }
              debugPrint("Tokens: $tokens");
              // Clean numbers and rebuild expression
              final buffer = StringBuffer();
              for (var token in tokens) {
                if (RegExp(r'^[+\-*/×÷%^()]+$').hasMatch(token)) {
                  // Operator or parenthesis
                  buffer.write(token);
                } else if (RegExp(
                  r'^(sin|cos|tan|log|sqrt|π|e|X|Y)$',
                ).hasMatch(token)) {
                  // Function or constant
                  buffer.write(token);
                } else {
                  // Number: Parse and clean
                  try {
                    final number = numberFormat.parse(token);
                    buffer.write(
                      number
                          .toStringAsFixed(
                            number.truncateToDouble() == number ? 0 : 3,
                          )
                          .replaceAll(RegExp(r'0+$'), '')
                          .replaceAll(RegExp(r'\.$'), ''),
                    );
                  } catch (e) {
                    debugPrint("Failed to parse number '$token': $e");
                    showOverlayMessage('Invalid number in clipboard');
                    return;
                  }
                }
              }
              final cleanedText = buffer.toString();
              debugPrint("Cleaned pasted text: '$cleanedText'");
              buffer.clear();
              buffer.write(currentText.substring(0, cursorPos));
              // Insert multiplication if pasting after a number/constant
              // if (endsWithNumberOrParenOrConst.hasMatch(textBeforeCursor)) {
              //   buffer.write('*');
              //   newCursorPos += 1;
              //   debugPrint("Inserted multiplication operator before paste");
              // }
              buffer.write(cleanedText);
              buffer.write(currentText.substring(cursorPos));
              newCursorPos += cleanedText.length;
              evaluateAfter = !isEndingWithOperator.hasMatch(cleanedText) &&
                  !isEndingWithOpenParen.hasMatch(cleanedText);
              debugPrint("Updating text with pasted content");
              updateText(buffer.toString(), newCursorPos);
            }).catchError((e, stackTrace) {
              debugPrint("Clipboard access error: $e");
              debugPrint("Stack trace: $stackTrace");
              if (mounted) {
                showOverlayMessage('Error pasting from clipboard');
              }
            });
          }
        }).catchError((e, stackTrace) {
          debugPrint("Validation error: $e");
          debugPrint("Stack trace: $stackTrace");
          if (mounted) {
            showOverlayMessage('Error validating clipboard');
          }
        });
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
          '√(',
        ];
        String? matchedToken;
        for (final token in functionTokens) {
          if (textBeforeCursor.endsWith(token)) {
            matchedToken = token;
            break;
          }
        }
        if (matchedToken != null) {
          buffer.write(
            currentText.substring(0, cursorPos - matchedToken.length),
          );
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
      evaluateAfter = newText.isNotEmpty &&
          !isEndingWithOperator.hasMatch(newText) &&
          !isEndingWithOpenParen.hasMatch(newText);
      updateText(newText, newCursorPos);
      return;
    }

    // Handle input after successful evaluation
    if (_lastActionWasEval &&
        answer.isNotEmpty &&
        answer != "Error" &&
        !answer.contains("Infinity")) {
      if (isOperator.hasMatch(buttonText)) {
        // Operator: Start with answer
        buffer.write(answer);
        buffer.write(buttonText);
        newCursorPos = answer.length + buttonText.length;
        evaluateAfter = false;
        setState(() {
          _rawExpression = buffer.toString();
          String formattedText = formatExpression(_rawExpression);
          _inputController.value = TextEditingValue(
            text: formattedText,
            selection: TextSelection.collapsed(offset: formattedText.length),
          );
          _lastActionWasEval = false;
          _animationController.reset(); // Reset for new input
          if (evaluateAfter) {
            evaluateExpression();
          } else if (answer.isNotEmpty) answer = '';
        });
        return;
      } else if (![
        '(',
        ')',
        'hist',
        'Home',
        'Unit',
        'Settings',
        'Calc',
        'Copy',
        'Paste',
      ].contains(buttonText)) {
        // Non-operator: Start fresh
        buffer.write(buttonText);
        newCursorPos = buttonText.length;
        evaluateAfter = false;
        setState(() {
          _rawExpression = buffer.toString();
          String formattedText = formatExpression(_rawExpression);
          _inputController.value = TextEditingValue(
            text: formattedText,
            selection: TextSelection.collapsed(offset: formattedText.length),
          );
          _lastActionWasEval = false;
          _animationController.reset(); // Reset for new input
          if (evaluateAfter) {
            evaluateExpression();
          } else if (answer.isNotEmpty) answer = '';
        });
        return;
      }
    }

    // Reset animation if completed
    if (_animationController.status == AnimationStatus.completed) {
      _animationController.reset();
      if (answer.isNotEmpty && mounted) setState(() => answer = '');
    }

    // Determine text to insert
    String textToInsert = buttonText;
    final trimmedBefore = textBeforeCursor.trim();
    final endsWithNumOrParenOrConst = endsWithNumberOrParenOrConst.hasMatch(
      trimmedBefore,
    );
    final endsWithFactorial = textBeforeCursor.endsWith('!');

    // Handle '00' button
    // Handle '00' button
    // In the buttonPressed method, modify the handling of the "00" button:
    // In the buttonPressed method, modify the handling of the "00" button:
    if (buttonText == '00') {
      // Get the number segment before the cursor
      final numberSegment =
          RegExp(r'(\d*\.?\d*)$').firstMatch(textBeforeCursor)?.group(0) ?? '';
      debugPrint("Number segment for '00': '$numberSegment'");

      if (currentText.isEmpty || textBeforeCursor.isEmpty) {
        // Empty input: Insert single "0"
        textToInsert = '0';
        evaluateAfter = false;
      } else if (numberSegment.isEmpty && !textBeforeCursor.endsWith('.')) {
        // After operators, parentheses, or functions: Do nothing
        textToInsert = '';
        evaluateAfter = false;
      } else if (textBeforeCursor.endsWith('.')) {
        // After decimal point (e.g., "0.", "1."): Append "00"
        textToInsert = '00';
        evaluateAfter = true;
      } else if (RegExp(r'^\d*\.?\d+$').hasMatch(numberSegment) &&
          numberSegment != '0') {
        // After a digit or decimal number ending in digit (e.g., "1", "1.0"): Append "00"
        textToInsert = '00';
        evaluateAfter = true;
      } else if (numberSegment == '0' && !textBeforeCursor.endsWith('0.')) {
        // Single "0" (not "0."): Do nothing
        textToInsert = '';
        evaluateAfter = false;
      } else {
        // Other cases: Do nothing
        textToInsert = '';
        evaluateAfter = false;
      }
    } else if (endsWithFactorial && !isOperator.hasMatch(buttonText)) {
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
      if (numberSegment.contains('.')) {
        textToInsert = ''; // Prevent multiple decimals
      } else if (cursorPos == 0 ||
          isOperator.hasMatch(charBefore) ||
          charBefore == '(') {
        textToInsert = '0.'; // Start with 0. for empty, operator, or (
      } else if (numberSegment == '0' && cursorPos == textBeforeCursor.length) {
        textToInsert = '.'; // After single 0 at end, append . to make 0.
      } else {
        textToInsert = '.'; // Append decimal after other digits
      }
      evaluateAfter = false;
    } else if (buttonText == '0') {
      final numberSegment =
          RegExp(r'(\d*\.?\d*)$').firstMatch(textBeforeCursor)?.group(0) ?? '';
      textToInsert = numberSegment == '0' ? '' : '0';
      evaluateAfter = false; // Don’t evaluate for single digits
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
      evaluateAfter = true;
      if (buttonText == 'π') {
        textToInsert = endsWithNumOrParenOrConst ? '*\u03C0' : '\u03C0';
        debugPrint("Pi text to insert: '$textToInsert'");
        evaluateAfter = true;
      }
      // Constants can trigger evaluation
    } else if (RegExp(r'^\d+$').hasMatch(buttonText)) {
      final numberSegment =
          RegExp(r'(\d*\.?\d*)$').firstMatch(textBeforeCursor)?.group(0) ?? '';
      if (numberSegment == '0' &&
          !textBeforeCursor.endsWith('0.') &&
          cursorPos == textBeforeCursor.length) {
        textToInsert = buttonText; // Replace leading 0 with digit (e.g., 0 → 2)
        buffer.write(currentText.substring(0, cursorPos - 1)); // Remove the 0
        buffer.write(textToInsert);
        buffer.write(currentText.substring(cursorPos));
        newCursorPos = cursorPos;
      } else {
        textToInsert = buttonText;
        buffer.write(currentText.substring(0, cursorPos));
        buffer.write(textToInsert);
        buffer.write(currentText.substring(cursorPos));
        newCursorPos = cursorPos + textToInsert.length;
      }
      evaluateAfter = false;
      updateText(buffer.toString(), newCursorPos);
      return;
    }

    // Insert text if applicable
    if (textToInsert.isNotEmpty) {
      buffer.write(currentText.substring(0, cursorPos));
      buffer.write(textToInsert);
      buffer.write(currentText.substring(cursorPos));
      newCursorPos = cursorPos + textToInsert.length;
      updateText(buffer.toString(), newCursorPos);
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
            _rawExpression = '';
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
      String currentText = _rawExpression;
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
          _rawExpression = buffer.toString();
          String formattedText = formatExpression(_rawExpression);
          _inputController.value = TextEditingValue(
            text: formattedText,
            selection: TextSelection.collapsed(offset: formattedText.length),
          );
          _animationController.reset();
          evaluateExpression();
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
      String exponential = value.toStringAsExponential(
        15,
      ); // Use high precision

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

  // Add this before formatNumber
  // String addCommasToNumberString(String numString) {
  //   bool isNegative = numString.startsWith('-');
  //   String absString = isNegative ? numString.substring(1) : numString;
  //   int dotIndex = absString.indexOf('.');
  //   String intPart =
  //       dotIndex >= 0 ? absString.substring(0, dotIndex) : absString;
  //   String decPart = dotIndex >= 0 ? absString.substring(dotIndex + 1) : '';

  //   String formattedInt = '';
  //   int count = 0;
  //   for (int i = intPart.length - 1; i >= 0; i--) {
  //     if (count == 3 && i > 0) {
  //       formattedInt = ',$formattedInt';
  //       count = 0;
  //     }
  //     formattedInt = intPart[i] + formattedInt;
  //     count++;
  //   }

  //   String result = formattedInt;
  //   if (decPart.isNotEmpty) {
  //     result += '.$decPart';
  //   }
  //   if (isNegative) {
  //     result = '-$result';
  //   }
  //   return result;
  // }

  String formatExpression(String rawExpression) {
    if (rawExpression.isEmpty) return '';

    debugPrint("Formatting raw expression: '$rawExpression'");
    final tokens = <String>[];
    final allPatterns = RegExp(
      r'(-?\d*\.?\d*|[+\-*/×÷%^()]|[\u03C0]|\b(sin|cos|tan|log|sqrt|e|X|Y)\b)',
      unicode: true,
    );

    String remaining = rawExpression;
    while (remaining.isNotEmpty) {
      final match = allPatterns.firstMatch(remaining);
      if (match == null) {
        debugPrint("No match for: '$remaining'");
        tokens.add(remaining[0]);
        remaining = remaining.substring(1);
        continue;
      }
      final token = match.group(0)!;
      if (token.isEmpty) {
        debugPrint("Empty token detected, skipping");
        remaining = remaining.substring(1);
        continue;
      }
      tokens.add(token);
      debugPrint("Adding token: '$token'");
      remaining = remaining.substring(match.end);
    }
    debugPrint("Total tokens: ${tokens.length}");
    debugPrint("Tokens: $tokens");

    final numberFormat = NumberFormat("#,##0.###", "en_US");
    final functionPattern = RegExp(r'\b(sin|cos|tan|log|sqrt)\b');
    final constantPattern = RegExp(r'[\u03C0eXY]', unicode: true);

    for (int i = 0; i < tokens.length; i++) {
      if (RegExp(r'^-?\d*\.?\d*$').hasMatch(tokens[i]) &&
          !functionPattern.hasMatch(tokens[i]) &&
          !constantPattern.hasMatch(tokens[i]) &&
          tokens[i].isNotEmpty &&
          tokens[i] != '-') {
        String token = tokens[i];
        bool hasTrailingDecimal = token.endsWith('.') && !token.endsWith('..');
        try {
          if (token.contains('.')) {
            final parts = token.split('.');
            String intPart = parts[0].isEmpty ? '0' : parts[0];
            String decPart =
                parts.length > 1 && parts[1].isNotEmpty ? parts[1] : '';
            if (intPart == '0' || intPart == '-0') {
              // Preserve leading 0 for decimals like 0.2
              tokens[i] = '$intPart.$decPart';
            } else {
              // Format integer part with commas
              final number = double.parse(intPart);
              tokens[i] = '${numberFormat.format(number)}.$decPart';
            }
          } else {
            // Handle integers
            double number = double.parse(token);
            tokens[i] = numberFormat.format(number);
          }
          // Append trailing decimal only if the token is just a number ending with .
          if (hasTrailingDecimal && !token.contains('.')) {
            tokens[i] += '.';
          }
        } catch (e) {
          debugPrint("Failed to parse number '${tokens[i]}': $e");
          tokens[i] = token; // Preserve original on error
        }
      }
    }

    final result = StringBuffer();
    for (int i = 0; i < tokens.length; i++) {
      result.write(tokens[i]);
      if (i < tokens.length - 1 && tokens[i] != '(' && tokens[i + 1] != ')') {
        result.write(' ');
      }
    }
    debugPrint("Formatted expression: '${result.toString()}'");
    return result.toString();
  }

  // --- Helper Functions ---

  // Validate pasted content and show snackbar if invalid
  // Validate pasted content and show snackbar if invalid
  Future<bool> validateAndPasteClipboard(BuildContext context) async {
    debugPrint("Entering _validateAndPasteClipboard");

    try {
      debugPrint("Attempting to access clipboard");
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      debugPrint("Clipboard data retrieved: $clipboardData");
      final pastedText = clipboardData?.text?.trim() ?? '';
      debugPrint("Clipboard content: '$pastedText'");

      if (pastedText.isEmpty) {
        debugPrint("Clipboard is empty, showing overlay message");
        showOverlayMessage('Clipboard is empty');
        debugPrint("Validation failed: Clipboard is empty");
        return false;
      }

      // Simplified: Allow digits, commas, decimal points, operators, parentheses, spaces, and specific functions/constants
      final validPattern = RegExp(
        r'^[0-9,\.\+\-*/×÷%^()\s]*(sin|cos|tan|log|sqrt|π|e|X|Y)?$',
        caseSensitive: false,
      );

      if (!validPattern.hasMatch(pastedText)) {
        debugPrint("Invalid characters detected, showing overlay message");
        showOverlayMessage('Invalid characters in clipboard');
        debugPrint("Validation failed: Invalid characters in '$pastedText'");
        return false;
      }

      // Check for invalid sequences (e.g., multiple operators, multiple dots)
      final invalidSequence = RegExp(r'[+*\/×÷%^]{2,}|[-]{3,}|[\.]{2,}');
      if (invalidSequence.hasMatch(pastedText)) {
        debugPrint("Invalid sequence detected, showing overlay message");
        showOverlayMessage('Invalid expression format');
        debugPrint("Validation failed: Invalid sequence in '$pastedText'");
        return false;
      }

      // Split by operators/parentheses to validate numbers and functions
      final parts = pastedText.split(RegExp(r'([+\-*/×÷%^()]+)'));
      final numberFormat = NumberFormat(
        "#,##0.###",
        "en_US",
      ); // Matches _numberFormat
      for (var part in parts) {
        final trimmedPart = part.trim();
        if (trimmedPart.isEmpty) continue;
        // Allow operators/parentheses
        if (RegExp(r'^[+\-*/×÷%^()]+$').hasMatch(trimmedPart)) {
          continue;
        }
        // Allow functions and constants
        if (RegExp(r'^(sin|cos|tan|log|sqrt|π|e|X|Y)$').hasMatch(trimmedPart)) {
          continue;
        }
        // Validate as number
        try {
          numberFormat.parse(trimmedPart);
        } catch (e) {
          debugPrint("Invalid number format: '$trimmedPart', error: $e");
          showOverlayMessage('Invalid number format in clipboard');
          debugPrint("Validation failed: Invalid number in '$trimmedPart'");
          return false;
        }
      }

      debugPrint("Validation passed for: '$pastedText'");
      return true;
    } catch (e, stackTrace) {
      debugPrint("Error accessing clipboard: $e");
      debugPrint("Stack trace: $stackTrace");
      showOverlayMessage('Error accessing clipboard');
      return false;
    }
  }

  // Show a Cupertino-style snackbar
  // Show a Cupertino-style snackbar for errors
  void showErrorSnackbar(BuildContext context, String message) {
    debugPrint("Showing error overlay: $message");
    if (mounted) {
      showOverlayMessage(message);
    } else {
      debugPrint("Widget not mounted, overlay not shown");
    }
  }

  void showInfoSnackbar(BuildContext context, String message) {
    debugPrint("Showing info overlay: $message");
    if (mounted) {
      showOverlayMessage(message);
    } else {
      debugPrint("Widget not mounted, overlay not shown");
    }
  }

  String formatNumber(double number) {
    if (number.isNaN) return 'Error';
    if (number.isInfinite) return number.isNegative ? '-Infinity' : 'Infinity';

    const double largeThreshold = 1e12;
    const double smallThreshold = 1e-9;
    const int exponentialPrecision = 6;
    const int fixedPrecision = 10;

    if (number != 0 &&
        (number.abs() >= largeThreshold || number.abs() < smallThreshold)) {
      return number.toStringAsExponential(exponentialPrecision);
    } else {
      String formatted;
      if (number == number.truncateToDouble()) {
        formatted = number.truncate().toString();
      } else {
        formatted = number
            .toStringAsFixed(fixedPrecision)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '');
      }
      return _numberFormat.format(double.parse(formatted));
    }
  }

  // --- UI Building ---
  final Map<String, Color> buttonColors = {
    'DEG': CupertinoColors.systemGreen.withOpacity(0.3),
    'RAD': CupertinoColors.systemOrange.withOpacity(0.3),
    'X': CupertinoColors.systemPurple.withOpacity(0.3),
    'Y': CupertinoColors.systemTeal.withOpacity(0.3),
    'shft': CupertinoColors.systemIndigo.withOpacity(0.4),
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
    'hist': CupertinoColors.systemGroupedBackground,
    'unit': CupertinoColors.systemGroupedBackground,
    'Settings': CupertinoColors.systemGroupedBackground,
    'Calc': CupertinoColors.systemGroupedBackground,
    'Copy': CupertinoColors.systemGroupedBackground,
    'Paste': CupertinoColors.systemGroupedBackground,
  };

  double getButtonTextSize(String text, double btnSize) {
    if (text == '00') return btnSize * 0.36;
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
    if (text == 'X' || text == 'Y') {
      return btnSize * 0.35;
    }
    return btnSize * 0.38;
  }

  Widget buildButton(BuildContext context, String text, double btnSize) {
    final mediaQueryData = MediaQuery.of(context);
    final screenHeight = mediaQueryData.size.height;

    Color buttonColor = buttonColors[text] ?? CupertinoColors.white;
    Color fgColor = (text == 'del')
        ? CupertinoColors.systemRed
        : CupertinoColors.label; // AC handled by background
    if (text == '=') fgColor = CupertinoColors.white;
    Widget content;
    if (text == 'shft') {
      content = Icon(
        FluentIcons.keyboard_shift_uppercase_24_filled,
        size: btnSize * 0.40,
        color: fgColor,
      );
    } else if (text == 'unit') {
      content = Icon(
        FluentIcons.diversity_24_regular,
        size: btnSize * 0.45,
        color: CupertinoColors.systemGrey3,
      );
    } else if (text == 'Calc') {
      content = Icon(
        FluentIcons.calculator_24_filled,
        size: btnSize * 0.45,
        color: CupertinoColors.systemGrey3,
      );
    } else if (text == 'hist') {
      content = Icon(
        FluentIcons.history_24_regular,
        size: btnSize * 0.45,
        color: CupertinoColors.systemGrey3,
      );
    } else if (text == 'Settings') {
      content = Icon(
        FluentIcons.settings_24_regular,
        size: btnSize * 0.45,
        color: CupertinoColors.systemGrey3,
      );
    } else if (text == 'Copy') {
      content = Icon(
        FluentIcons.copy_24_regular,
        size: btnSize * 0.40,
        color: CupertinoColors.systemGrey,
      );
    } else if (text == 'Paste') {
      content = Icon(
        FluentIcons.clipboard_paste_24_regular,
        size: btnSize * 0.40,
        color: CupertinoColors.systemGrey,
      );
    } else if (text == 'del') {
      content = Icon(
        FluentIcons.backspace_24_filled,
        size: btnSize * 0.45,
        color: fgColor,
      );
    } else {
      final String displayText =
          (text == 'DEG') ? (isDeg ? 'DEG' : 'RAD') : text;
      if (text == 'DEG') {
        buttonColor = isDeg ? buttonColors['DEG']! : buttonColors['RAD']!;
      }
      content = Text(
        displayText,
        style: TextStyle(
          fontSize: getButtonTextSize(displayText, btnSize),
          color: fgColor,
          fontWeight: (text == '=') ? FontWeight.bold : FontWeight.w500,
          fontFamily: 'Inter',
        ),
      );
    }

    final bool applyShadow = !(text == 'hist' ||
        text == 'Unit' ||
        text == 'Calc' ||
        text == 'Copy' ||
        text == 'Paste' ||
        text ==
            'Settings'); // Apply shadow ONLY if it's NOT one of these buttons
    final bool isEnabled = text != 'Calc';
    return Container(
      width: btnSize,
      height: screenHeight * 0.055,
      margin: EdgeInsets.all(btnSize * 0.04),
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(btnSize * 0.33), // Button radius
        boxShadow: applyShadow // Use the boolean flag here
            ? [
                // Apply shadow if flag is true
                BoxShadow(
                  color: CupertinoColors.systemGrey.withOpacity(0.1),
                  spreadRadius: 0.5,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ]
            : null, // No shadow if flag is false
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(btnSize * 0.33), // Match radius
        onPressed: isEnabled ? () => buttonPressed(text) : null,
        child: Center(child: content),
      ),
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
    final double bottomBtnSize = btnSize;
    final double buttonWidthWithMargin = btnSize + (btnSize * 0.04 * 2);

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
                flex: 4,
                child: Container(
                  // color: CupertinoColors.systemGreen,
                  // color: CupertinoColors.systemGroupedBackground,
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
                          .take(3)
                          .map(
                            (entry) => Padding(
                              padding: EdgeInsets.only(
                                bottom: effectiveScreenHeight * 0.008,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  // When tapped, reset or append the result to the expression
                                  String cleanedResult =
                                      entry.result.replaceAll(',', '');
                                  String textForInput =
                                      formatScientificForInput(cleanedResult);
                                  setState(() {
                                    String newExpression;
                                    // Check if expression ends with an operator
                                    if (_rawExpression.isNotEmpty &&
                                        isEndingWithOperator
                                            .hasMatch(_rawExpression.trim())) {
                                      newExpression = _rawExpression +
                                          textForInput; // Append after operator
                                    } else {
                                      newExpression =
                                          textForInput; // Reset for numbers, constants, parentheses, or empty
                                    }
                                    _rawExpression = newExpression;
                                    _inputController.text =
                                        formatExpression(newExpression);
                                    _inputController.selection =
                                        TextSelection.collapsed(
                                      offset: _inputController.text.length,
                                    );
                                    answer = '';
                                    _animationController.reset();
                                    evaluateExpression();
                                  });
                                },
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  ),
                                  child: Text(
                                    "${entry.expression} = ${entry.result}",
                                    style: TextStyle(
                                      fontSize: (screenHeight * 0.020).clamp(
                                        12.0,
                                        18.0,
                                      ),
                                      color: CupertinoColors.secondaryLabel,
                                      fontFamily: 'Inter',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          )
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
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
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
                                      _inputController.selection.extentOffset <
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
                          final bool isError =
                              answer == "Error" || answer.contains("Infinity");
                          return Opacity(
                            opacity: 0.7 + (_animationController.value * 0.3),
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                10 * (1 - _animationController.value),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                reverse: true, // Show end of the answer
                                physics: const BouncingScrollPhysics(
                                  // Optional: Add physics
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                child: IntrinsicWidth(
                                  child: Text(
                                    answer,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: _answerTextSizeAnimation.value,
                                      color: isError
                                          ? CupertinoColors.systemRed
                                          : CupertinoColors.label,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Inter',
                                    ),
                                    // maxLines: 1,
                                    // overflow: TextOverflow.ellipsis
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: effectiveScreenHeight * 0.01),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: screenHeight * 0.048,
                // color: CupertinoColors.activeBlue,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Add your four buttons here. You can reuse buildButton or create new ones.
                    buildButton(context, "Copy", btnSize),
                    buildButton(context, "Paste", btnSize),

                    for (int i = 0; i < 3; i++)
                      SizedBox(width: buttonWidthWithMargin),
                  ],
                ),
              ),
              // --- Button Grid ---
              Expanded(
                flex: 6,
                child: Container(
                  // color: CupertinoColors.activeBlue,
                  // color: CupertinoColors.systemCyan,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      (stringList.length / 5).ceil(),
                      (rowIndex) => Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: buttonGridVerticalSpacing / 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(5, (columnIndex) {
                            final index = rowIndex * 5 + columnIndex;
                            if (index >= stringList.length) {
                              return SizedBox(
                                width: btnSize + (btnSize * 0.04 * 2),
                              );
                            }
                            return buildButton(
                              context,
                              stringList[index],
                              btnSize,
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: screenHeight * 0.048,
                // padding: const EdgeInsets.symmetric(
                //     vertical: 16.0, horizontal: 8.0),
                // color: CupertinoColors.activeBlue.withOpacity(0.3),
                color: CupertinoColors.systemGroupedBackground,

                child: Row(
                  mainAxisAlignment: MainAxisAlignment
                      .spaceAround, // Distribute the 4 buttons evenly
                  children: [
                    // Add your four buttons here. You can reuse buildButton or create new ones.
                    buildButton(context, "Calc", bottomBtnSize),
                    buildButton(context, "hist", bottomBtnSize),
                    buildButton(context, "unit", bottomBtnSize),
                    buildButton(context, "Settings", bottomBtnSize),
                    // ElevatedButton(onPressed: () {}, child: Text("Action 4")),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- History Modal ---
  void showHistory(BuildContext parentContext) {
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
                    color: CupertinoColors.systemGrey4,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                Expanded(
                  child: HistoryPage(
                    history: history,
                    onExpressionTap: (String resultFromHistory) {
                      // Clean the result by removing commas
                      String cleanedResult =
                          resultFromHistory.replaceAll(',', '');
                      // Handle scientific notation if needed
                      String textForInput =
                          formatScientificForInput(cleanedResult);
                      debugPrint(
                        "History tapped. Original result: '$resultFromHistory', "
                        "Cleaned: '$cleanedResult', Using for input: '$textForInput'",
                      );
                      if (mounted) {
                        setState(() {
                          String newExpression;
                          // Check if expression ends with an operator
                          if (_rawExpression.isNotEmpty &&
                              isEndingWithOperator
                                  .hasMatch(_rawExpression.trim())) {
                            newExpression = _rawExpression +
                                textForInput; // Append after operator
                          } else {
                            newExpression =
                                textForInput; // Reset for numbers, constants, parentheses, or empty
                          }
                          _rawExpression = newExpression;
                          _inputController.text =
                              formatExpression(newExpression);
                          _inputController.selection = TextSelection.collapsed(
                            offset: _inputController.text.length,
                          );
                          answer = '';
                          _animationController.reset();
                          evaluateExpression();
                        });
                        Navigator.pop(modalContext);
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
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Center(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16),
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
} // End of _CalcPageState
