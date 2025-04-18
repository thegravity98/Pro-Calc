import 'dart:math';
import 'package:eval_ex/expression.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/calculation_history.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'tools_page.dart';
import 'history_page.dart';

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

  // Add these variables to the state class
  int _rawCursorPosition = 0;
  Map<int, int> _formattedToRawPositionMap = {};
  Map<int, int> _rawToFormattedPositionMap = {};

  String answer = '';
  bool isDeg = true;
  bool isShift = false; // Track shift state
  bool _lastActionWasEval = false;

  bool isDarkThemeEnabled = false;

  final NumberFormat _numberFormat = NumberFormat(
    "#,##0.########",
    "en_US",
  ); // Flexible decimal places
  String _rawExpression = ''; // Store unformatted expression

  // --- Constants ---
  static const double _inputFontScale = 0.042;
  static const double _answerFontScale = 0.045;
  static const double _minFontSize = 24.0;
  static const double _maxFontSize = 55.0;

  // --- Regular Expressions ---
  final isDigit = RegExp(r'[0-9]$');
  final isEndingWithOperator = RegExp(r'[+\-*/×÷%^]$');
  final isEndingWithOpenParen = RegExp(r'\($');
  final endsWithNumberOrParenOrConst = RegExp(r'([\d.)eπXY])$');

  // --- Calculation Context & Variables ---
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
    '00',
    '0',
    '.',
    '=',
  ];

  // --- Initialization & Disposal ---
  @override
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

    // Initialize position tracking
    _rawCursorPosition = 0;
    _formattedToRawPositionMap = {};
    _rawToFormattedPositionMap = {};

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
  Future<void> evaluateExpression({bool finalEvaluation = false}) async {
    String expression = _rawExpression.trim();
    debugPrint("Original Expression: '$expression'");

    if (expression.isEmpty) {
      if (mounted) setState(() => answer = '');
      return;
    }

    try {
      // Check for incomplete expressions
      bool endsWithOp = isEndingWithOperator.hasMatch(expression);
      bool endsWithOpenParen = isEndingWithOpenParen.hasMatch(expression);
      int openCount = '('.allMatches(expression).length;
      int closeCount = ')'.allMatches(expression).length;
      bool unbalancedParens = openCount != closeCount;
      bool hasOperator = RegExp(r'[+\-*/×÷%^]').hasMatch(expression);
      bool hasFunction = RegExp(r'(sin|cos|tan|log|ln|√)').hasMatch(expression);

      // Don't show answer for incomplete expressions
      if (!finalEvaluation &&
          (!hasOperator && !hasFunction ||
              endsWithOp ||
              endsWithOpenParen ||
              unbalancedParens)) {
        debugPrint(
            "Skipping evaluation: hasOperator=$hasOperator, hasFunction=$hasFunction, endsWithOp=$endsWithOp, unbalancedParens=$unbalancedParens");
        if (mounted) setState(() => answer = '');
        return;
      }

      // IMPORTANT: Remove commas from the expression before evaluation
      String expressionWithoutCommas = expression.replaceAll(',', '');

      // Handle inverse trig functions in degree mode
      String preparedExpression = expressionWithoutCommas;

      if (expression.contains('%')) {
        try {
          // Replace percentages with their decimal equivalents based on context
          expression = _handlePercentageCalculations(expression);
          preparedExpression = expression.replaceAll(',', '');
          debugPrint("Expression after percentage handling: '$expression'");
        } catch (e) {
          debugPrint("Error handling percentages: $e");
          // Continue with original expression if percentage handling fails
        }
      }

      if (isDeg && isShift && expression.contains('⁻¹')) {
        // Find all inverse trig functions in the expression
        RegExp inverseTrigPattern =
            RegExp(r'(sin|cos|tan)⁻¹\s*\(\s*([^()]+)\s*\)');
        Iterable<RegExpMatch> matches =
            inverseTrigPattern.allMatches(expression);

        // Process each match
        for (RegExpMatch match in matches) {
          String fullMatch = match.group(0)!;
          String funcType = match.group(1)!;
          String argExpr = match.group(2)!;

          debugPrint(
              "Found inverse trig function: $fullMatch, type: $funcType, arg: $argExpr");

          // Prepare the argument expression
          String preparedArgExpr = argExpr
              .replaceAll('×', '*')
              .replaceAll('÷', '/')
              .replaceAll('π', '3.141592653589793')
              .replaceAllMapped(
                  RegExp(r'(?<![\d.])e'), (m) => '2.718281828459045');

          // Evaluate the argument
          try {
            Expression argExpression = Expression(preparedArgExpr);
            var argResult = argExpression.eval();

            if (argResult != null) {
              double argValue = argResult.toDouble();
              double resultInRadians;

              // Apply the appropriate inverse trig function
              switch (funcType) {
                case "sin":
                  resultInRadians = asin(argValue);
                  break;
                case "cos":
                  resultInRadians = acos(argValue);
                  break;
                case "tan":
                  resultInRadians = atan(argValue);
                  break;
                default:
                  throw Exception("Unknown inverse trig function");
              }

              // Convert from radians to degrees
              double resultInDegrees = resultInRadians * (180 / pi);
              debugPrint(
                  "Calculated $funcType⁻¹($argValue) = $resultInDegrees degrees");

              // Replace the inverse trig function with its numeric result
              preparedExpression = preparedExpression.replaceFirst(
                  fullMatch, resultInDegrees.toString());

              debugPrint("Expression after substitution: $preparedExpression");
            }
          } catch (e) {
            debugPrint("Error evaluating inverse trig argument: $e");
            // If we can't evaluate this part, continue with the original expression
          }
        }
      }

      // Now process the expression with substituted values
      preparedExpression = preparedExpression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', '3.141592653589793')
          .replaceAllMapped(
              RegExp(r'(?<![\d.])e'), (match) => '2.718281828459045');

      // Handle remaining trig functions
      if (isShift) {
        if (isDeg) {
          preparedExpression = preparedExpression
              .replaceAll('sin⁻¹(', 'ASIN(')
              .replaceAll('cos⁻¹(', 'ACOS(')
              .replaceAll('tan⁻¹(', 'ATAN(');
        } else {
          preparedExpression = preparedExpression
              .replaceAll('sin⁻¹(', 'ASINR(')
              .replaceAll('cos⁻¹(', 'ACOSR(')
              .replaceAll('tan⁻¹(', 'ATANR(');
        }
      } else {
        if (isDeg) {
          preparedExpression = preparedExpression
              .replaceAllMapped(RegExp(r'sin\s*\(((?:[^()]*|\([^()]*\))*)\)'),
                  (match) => 'SIN(${match.group(1)})')
              .replaceAllMapped(RegExp(r'cos\s*\(((?:[^()]*|\([^()]*\))*)\)'),
                  (match) => 'COS(${match.group(1)})')
              .replaceAllMapped(RegExp(r'tan\s*\(((?:[^()]*|\([^()]*\))*)\)'),
                  (match) => 'TAN(${match.group(1)})');
        } else {
          preparedExpression = preparedExpression
              .replaceAllMapped(RegExp(r'sin\s*\(((?:[^()]*|\([^()]*\))*)\)'),
                  (match) => 'SINR(${match.group(1)})')
              .replaceAllMapped(RegExp(r'cos\s*\(((?:[^()]*|\([^()]*\))*)\)'),
                  (match) => 'COSR(${match.group(1)})')
              .replaceAllMapped(RegExp(r'tan\s*\(((?:[^()]*|\([^()]*\))*)\)'),
                  (match) => 'TANR(${match.group(1)})');
        }
      }

      // Handle sqrt and logarithms
      // Handle sqrt and logarithms
      // Handle sqrt and logarithms
      preparedExpression = preparedExpression
          .replaceAllMapped(RegExp(r'√\s*\(((?:[^()]*|\([^()]*\))*)\)'),
              (match) => 'SQRT(${match.group(1)})')
          .replaceAllMapped(
              RegExp(r'ln\s*\(((?:[^()]*|\([^()]*\))*)\)'),
              (match) =>
                  'LOG(${match.group(1)})') // Use LOG for natural logarithm
          .replaceAllMapped(
              RegExp(r'log\s*\(((?:[^()]*|\([^()]*\))*)\)'),
              (match) =>
                  'LOG10(${match.group(1)})'); // Use LOG10 for base-10 logarithm

      debugPrint("Final expression for evaluation: '$preparedExpression'");

      for (var entry in variables.entries) {
        preparedExpression =
            preparedExpression.replaceAll(entry.key, entry.value.toString());
      }
      debugPrint(
          "Expression with variables substituted: '$preparedExpression'");

      if (preparedExpression.isNotEmpty) {
        Expression exp = Expression(preparedExpression);
        var evalResult = exp.eval();

        if (evalResult != null) {
          double result = evalResult.toDouble();

          if (result.isFinite) {
            if (mounted) {
              setState(() {
                answer = formatNumber(result);
              });
            }
          } else {
            throw Exception("Result is not finite: $result");
          }
        } else {
          throw Exception("Evaluation returned null");
        }
      }
    } catch (e) {
      debugPrint('Evaluation Error: $e');
      if (mounted) {
        setState(() {
          answer = finalEvaluation ? 'Error' : '';
        });
      }
    }
  }

  void buttonPressed(String buttonText) {
    switch (buttonText) {
      case 'hist':
        showHistory(context);
        _lastActionWasEval = false; // Reset flag
        return;
      case 'Settings':
        showSettings(context);
        // _lastActionWasEval = false; // Reset flag
        return;
      case 'unit':
        _showToolsModal(context);
        _lastActionWasEval = false; // Reset flag
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
        handlePaste();
        return;

      case 'AC':
        if (mounted) {
          setState(() {
            _rawExpression = '';
            _inputController.clear();
            answer = '';
            _animationController.reset();
            _validatePositionMaps();
          });
        }
        return;

      case 'del':
        if (_rawExpression.isNotEmpty) {
          final currentText = _rawExpression;
          final currentSelection = _inputController.selection;
          final cursorPos = currentSelection.baseOffset >= 0
              ? currentSelection.baseOffset
                  .clamp(0, _inputController.text.length)
              : _inputController.text.length;

          // Convert from formatted position to raw position
          final rawCursorPos =
              _formattedToRawPositionMap[cursorPos] ?? currentText.length;

          if (rawCursorPos > 0) {
            // Get the text before and after cursor
            String textBeforeCursor = currentText.substring(0, rawCursorPos);
            String textAfterCursor = currentText.substring(rawCursorPos);

            // Remove one character before cursor
            String newTextBeforeCursor =
                textBeforeCursor.substring(0, textBeforeCursor.length - 1);
            String newText = newTextBeforeCursor + textAfterCursor;

            int newRawCursorPos = rawCursorPos - 1;

            if (mounted) {
              setState(() {
                _rawExpression = newText;
                _rawCursorPosition = newRawCursorPos;

                String formattedText = formatExpression(newText);
                int formattedCursorPos =
                    _rawToFormattedPositionMap[_rawCursorPosition] ?? 0;

                _inputController.value = TextEditingValue(
                  text: formattedText,
                  selection: TextSelection.collapsed(
                    offset: formattedCursorPos,
                  ),
                );
                _lastActionWasEval = false;
                evaluateExpression();
              });
            }
          }
        }
        return;

      // case '%':
      //   String currentText = _rawExpression;
      //   debugPrint(
      //       "Percentage button pressed. Current expression: '$currentText'");

      //   // If expression is empty, do nothing
      //   if (currentText.isEmpty) {
      //     return;
      //   }

      //   // If last action was evaluation, start fresh with the answer
      //   if (_lastActionWasEval) {
      //     if (answer.isNotEmpty &&
      //         answer != "Error" &&
      //         !answer.contains("Infinity")) {
      //       // Use the answer as the base value
      //       String cleanAnswer = answer.replaceAll(',', '');
      //       double value = double.tryParse(cleanAnswer) ?? 0;
      //       value = value / 100; // Convert to percentage

      //       setState(() {
      //         _rawExpression = value.toString();
      //         _inputController.text = formatExpression(_rawExpression);
      //         _inputController.selection = TextSelection.collapsed(
      //           offset: _inputController.text.length,
      //         );
      //         _lastActionWasEval = false;
      //         _animationController.reset();
      //         answer = '';
      //         evaluateExpression();
      //       });
      //     }
      //     return;
      //   }

      //   // Process the percentage calculation immediately
      //   try {
      //     // Create a temporary expression to evaluate
      //     String tempExpression = currentText;

      //     // Remove commas for calculation
      //     tempExpression = tempExpression.replaceAll(',', '');

      //     // Prepare the expression for evaluation
      //     tempExpression = tempExpression
      //         .replaceAll('×', '*')
      //         .replaceAll('÷', '/')
      //         .replaceAll('π', '3.141592653589793')
      //         .replaceAllMapped(
      //             RegExp(r'(?<![\d.])e'), (m) => '2.718281828459045');

      //     // Check if we have a binary operation
      //     RegExp binaryOpPattern = RegExp(r'(.+)([\+\-\*\/])([0-9.]+)$');
      //     Match? match = binaryOpPattern.firstMatch(tempExpression);

      //     double result;

      //     if (match != null) {
      //       // We have a binary operation like "8+3"
      //       String leftExpr = match.group(1) ?? '';
      //       String operator = match.group(2) ?? '';
      //       String rightExpr = match.group(3) ?? '';

      //       double rightNum = double.parse(rightExpr);
      //       double percentValue = rightNum / 100;

      //       // For + and -, calculate percentage of left operand
      //       if (operator == '+' || operator == '-') {
      //         try {
      //           Expression exp = Expression(leftExpr);
      //           var evalResult = exp.eval();

      //           if (evalResult != null) {
      //             double leftValue = evalResult.toDouble();
      //             double percentOfLeft = leftValue * percentValue;

      //             if (operator == '+') {
      //               result = leftValue + percentOfLeft;
      //             } else {
      //               result = leftValue - percentOfLeft;
      //             }
      //           } else {
      //             // Fallback to simple percentage
      //             result = percentValue;
      //           }
      //         } catch (e) {
      //           // Fallback to simple percentage
      //           result = percentValue;
      //         }
      //       } else {
      //         // For * and /, evaluate the complete expression with the percentage value
      //         try {
      //           // Create the expression with the percentage value
      //           String evalExpr = leftExpr + operator + percentValue.toString();
      //           Expression exp = Expression(evalExpr);
      //           var evalResult = exp.eval();

      //           if (evalResult != null) {
      //             result = evalResult.toDouble();
      //           } else {
      //             // Fallback to simple percentage
      //             result = percentValue;
      //           }
      //         } catch (e) {
      //           debugPrint("Error evaluating * or / with percentage: $e");
      //           // Fallback to simple percentage
      //           result = percentValue;
      //         }
      //       }
      //     } else {
      //       // Simple percentage: just divide by 100
      //       double value = double.parse(tempExpression);
      //       result = value / 100;
      //     }

      //     // Update the UI
      //     setState(() {
      //       // Keep the original expression and add %
      //       _rawExpression = '$currentText%';
      //       _inputController.text = formatExpression(_rawExpression);
      //       _inputController.selection = TextSelection.collapsed(
      //         offset: _inputController.text.length,
      //       );

      //       // Show the result immediately
      //       answer = formatNumber(result);
      //     });
      //   } catch (e) {
      //     debugPrint("Error calculating percentage: $e");
      //     // If there's an error, just append % and don't calculate
      //     setState(() {
      //       _rawExpression = '$currentText%';
      //       _inputController.text = formatExpression(_rawExpression);
      //       _inputController.selection = TextSelection.collapsed(
      //         offset: _inputController.text.length,
      //       );
      //     });
      //   }
      //   return;

      // case '%':
      //   String currentText = _rawExpression;
      //   debugPrint(
      //       "Percentage button pressed. Current expression: '$currentText'");

      //   // If expression is empty, do nothing
      //   if (currentText.isEmpty) {
      //     return;
      //   }

      //   // If last action was evaluation, start fresh with the answer
      //   if (_lastActionWasEval) {
      //     if (answer.isNotEmpty &&
      //         answer != "Error" &&
      //         !answer.contains("Infinity")) {
      //       // Use the answer as the base value
      //       String cleanAnswer = answer.replaceAll(',', '');
      //       double value = double.tryParse(cleanAnswer) ?? 0;
      //       value = value / 100; // Convert to percentage

      //       setState(() {
      //         _rawExpression = value.toString();
      //         _inputController.text = formatExpression(_rawExpression);
      //         _inputController.selection = TextSelection.collapsed(
      //           offset: _inputController.text.length,
      //         );
      //         _lastActionWasEval = false;
      //         _animationController.reset();
      //         answer = '';
      //         evaluateExpression();
      //       });
      //     }
      //     return;
      //   }

      //   // Process the percentage calculation immediately
      //   try {
      //     // Create a temporary expression to evaluate
      //     String tempExpression = currentText;

      //     // Remove commas for calculation
      //     tempExpression = tempExpression.replaceAll(',', '');

      //     // Prepare the expression for evaluation
      //     tempExpression = tempExpression
      //         .replaceAll('×', '*')
      //         .replaceAll('÷', '/')
      //         .replaceAll('π', '3.141592653589793')
      //         .replaceAllMapped(
      //             RegExp(r'(?<![\d.])e'), (m) => '2.718281828459045');

      //     // Check if we have a binary operation
      //     RegExp binaryOpPattern = RegExp(r'(.+)([\+\-\*\/])([0-9.]+)$');
      //     Match? match = binaryOpPattern.firstMatch(tempExpression);

      //     double result;

      //     if (match != null) {
      //       // We have a binary operation like "8+3"
      //       String leftExpr = match.group(1) ?? '';
      //       String operator = match.group(2) ?? '';
      //       String rightExpr = match.group(3) ?? '';

      //       double rightNum = double.parse(rightExpr);
      //       double percentValue = rightNum / 100;

      //       // For + and -, calculate percentage of left operand
      //       if (operator == '+' || operator == '-') {
      //         try {
      //           Expression exp = Expression(leftExpr);
      //           var evalResult = exp.eval();

      //           if (evalResult != null) {
      //             double leftValue = evalResult.toDouble();
      //             double percentOfLeft = leftValue * percentValue;

      //             if (operator == '+') {
      //               result = leftValue + percentOfLeft;
      //             } else {
      //               result = leftValue - percentOfLeft;
      //             }
      //           } else {
      //             // Fallback to simple percentage
      //             result = percentValue;
      //           }
      //         } catch (e) {
      //           // Fallback to simple percentage
      //           result = percentValue;
      //         }
      //       } else {
      //         // For * and /, evaluate the complete expression with the percentage value
      //         try {
      //           // Create the expression with the percentage value
      //           String evalExpr = leftExpr + operator + percentValue.toString();
      //           Expression exp = Expression(evalExpr);
      //           var evalResult = exp.eval();

      //           if (evalResult != null) {
      //             result = evalResult.toDouble();
      //           } else {
      //             // Fallback to simple percentage
      //             result = percentValue;
      //           }
      //         } catch (e) {
      //           debugPrint("Error evaluating * or / with percentage: $e");
      //           // Fallback to simple percentage
      //           result = percentValue;
      //         }
      //       }
      //     } else {
      //       // Simple percentage: just divide by 100
      //       double value = double.parse(tempExpression);
      //       result = value / 100;
      //     }

      //     // Update the UI
      //     setState(() {
      //       // Keep the original expression and add %
      //       _rawExpression = '$currentText%';
      //       _inputController.text = formatExpression(_rawExpression);
      //       _inputController.selection = TextSelection.collapsed(
      //         offset: _inputController.text.length,
      //       );

      //       // Show the result immediately
      //       answer = formatNumber(result);
      //     });
      //   } catch (e) {
      //     debugPrint("Error calculating percentage: $e");
      //     // If there's an error, just append % and don't calculate
      //     setState(() {
      //       _rawExpression = '$currentText%';
      //       _inputController.text = formatExpression(_rawExpression);
      //       _inputController.selection = TextSelection.collapsed(
      //         offset: _inputController.text.length,
      //       );
      //     });
      //   }
      //   return;

      case '%':
        String currentText = _rawExpression;
        debugPrint(
            "Percentage button pressed. Current expression: '$currentText'");

        // If expression is empty, do nothing
        if (currentText.isEmpty) {
          return;
        }

        // If last action was evaluation, start fresh with the answer
        if (_lastActionWasEval) {
          if (answer.isNotEmpty &&
              answer != "Error" &&
              !answer.contains("Infinity")) {
            // Use the answer as the base value
            String cleanAnswer = answer.replaceAll(',', '');
            double value = double.tryParse(cleanAnswer) ?? 0;
            value = value / 100; // Convert to percentage

            setState(() {
              _rawExpression = value.toString();
              _inputController.text = formatExpression(_rawExpression);
              _inputController.selection = TextSelection.collapsed(
                offset: _inputController.text.length,
              );
              _lastActionWasEval = false;
              _animationController.reset();
              answer = '';
              evaluateExpression();
            });
          }
          return;
        }

        // Process the percentage calculation immediately
        try {
          // Create a temporary expression to evaluate
          String tempExpression = currentText;

          // Remove commas for calculation
          tempExpression = tempExpression.replaceAll(',', '');

          // Prepare the expression for evaluation
          tempExpression = tempExpression
              .replaceAll('×', '*')
              .replaceAll('÷', '/')
              .replaceAll('π', '3.141592653589793')
              .replaceAllMapped(
                  RegExp(r'(?<![\d.])e'), (m) => '2.718281828459045');

          // Check if we have a binary operation
          RegExp binaryOpPattern = RegExp(r'(.+)([\+\-\*\/])([0-9.]+)$');
          Match? match = binaryOpPattern.firstMatch(tempExpression);

          double result;

          if (match != null) {
            // We have a binary operation like "8+3"
            String leftExpr = match.group(1) ?? '';
            String operator = match.group(2) ?? '';
            String rightExpr = match.group(3) ?? '';

            double rightNum = double.parse(rightExpr);
            double percentValue = rightNum / 100;

            // For + and -, calculate percentage of left operand
            if (operator == '+' || operator == '-') {
              try {
                Expression exp = Expression(leftExpr);
                var evalResult = exp.eval();

                if (evalResult != null) {
                  double leftValue = evalResult.toDouble();
                  double percentOfLeft = leftValue * percentValue;

                  if (operator == '+') {
                    result = leftValue + percentOfLeft;
                  } else {
                    result = leftValue - percentOfLeft;
                  }
                } else {
                  // Fallback to simple percentage
                  result = percentValue;
                }
              } catch (e) {
                // Fallback to simple percentage
                result = percentValue;
              }
            } else {
              // For * and /, evaluate the complete expression with the percentage value
              try {
                // Create the expression with the percentage value
                String evalExpr = leftExpr + operator + percentValue.toString();
                Expression exp = Expression(evalExpr);
                var evalResult = exp.eval();

                if (evalResult != null) {
                  result = evalResult.toDouble();
                } else {
                  // Fallback to simple percentage
                  result = percentValue;
                }
              } catch (e) {
                debugPrint("Error evaluating * or / with percentage: $e");
                // Fallback to simple percentage
                result = percentValue;
              }
            }
          } else {
            // Simple percentage: just divide by 100
            double value = double.parse(tempExpression);
            result = value / 100;
          }

          // Update the UI
          setState(() {
            // Keep the original expression and add %
            _rawExpression = '$currentText%';
            _inputController.text = formatExpression(_rawExpression);
            _inputController.selection = TextSelection.collapsed(
              offset: _inputController.text.length,
            );

            // Show the result immediately
            answer = formatNumber(result);
          });
        } catch (e) {
          debugPrint("Error calculating percentage: $e");
          // If there's an error, just append % and don't calculate
          setState(() {
            _rawExpression = '$currentText%';
            _inputController.text = formatExpression(_rawExpression);
            _inputController.selection = TextSelection.collapsed(
              offset: _inputController.text.length,
            );
          });
        }
        return;

      // case '%':
      //   String currentText = _rawExpression;
      //   debugPrint(
      //       "Percentage button pressed. Current expression: '$currentText'");

      //   // If expression is empty, do nothing
      //   if (currentText.isEmpty) {
      //     return;
      //   }

      //   // If last action was evaluation, start fresh with the answer
      //   if (_lastActionWasEval) {
      //     if (answer.isNotEmpty &&
      //         answer != "Error" &&
      //         !answer.contains("Infinity")) {
      //       // Use the answer as the base value
      //       String cleanAnswer = answer.replaceAll(',', '');
      //       double value = double.tryParse(cleanAnswer) ?? 0;
      //       value = value / 100; // Convert to percentage

      //       setState(() {
      //         _rawExpression = value.toString();
      //         _inputController.text = formatExpression(_rawExpression);
      //         _inputController.selection = TextSelection.collapsed(
      //           offset: _inputController.text.length,
      //         );
      //         _lastActionWasEval = false;
      //         _animationController.reset();
      //         answer = '';
      //         evaluateExpression();
      //       });
      //     }
      //     return;
      //   }

      //   // Process the percentage calculation immediately
      //   try {
      //     // Create a temporary expression to evaluate
      //     String tempExpression = currentText;

      //     // Remove commas for calculation
      //     tempExpression = tempExpression.replaceAll(',', '');

      //     // Prepare the expression for evaluation
      //     tempExpression = tempExpression
      //         .replaceAll('×', '*')
      //         .replaceAll('÷', '/')
      //         .replaceAll('π', '3.141592653589793')
      //         .replaceAllMapped(
      //             RegExp(r'(?<![\d.])e'), (m) => '2.718281828459045');

      //     // Check if we have a binary operation
      //     RegExp binaryOpPattern = RegExp(r'(.+)([\+\-\*\/])([0-9.]+)$');
      //     Match? match = binaryOpPattern.firstMatch(tempExpression);

      //     double result;

      //     if (match != null) {
      //       // We have a binary operation like "8+3"
      //       String leftExpr = match.group(1) ?? '';
      //       String operator = match.group(2) ?? '';
      //       String rightExpr = match.group(3) ?? '';

      //       double rightNum = double.parse(rightExpr);
      //       double percentValue = rightNum / 100;

      //       // For + and -, calculate percentage of left operand
      //       if (operator == '+' || operator == '-') {
      //         try {
      //           Expression exp = Expression(leftExpr);
      //           var evalResult = exp.eval();

      //           if (evalResult != null) {
      //             double leftValue = evalResult.toDouble();
      //             double percentOfLeft = leftValue * percentValue;

      //             if (operator == '+') {
      //               result = leftValue + percentOfLeft;
      //             } else {
      //               result = leftValue - percentOfLeft;
      //             }
      //           } else {
      //             // Fallback to simple percentage
      //             result = percentValue;
      //           }
      //         } catch (e) {
      //           // Fallback to simple percentage
      //           result = percentValue;
      //         }
      //       } else {
      //         // For * and /, evaluate the complete expression with the percentage value
      //         try {
      //           // Create the expression with the percentage value
      //           String evalExpr = leftExpr + operator + percentValue.toString();
      //           Expression exp = Expression(evalExpr);
      //           var evalResult = exp.eval();

      //           if (evalResult != null) {
      //             result = evalResult.toDouble();
      //           } else {
      //             // Fallback to simple percentage
      //             result = percentValue;
      //           }
      //         } catch (e) {
      //           debugPrint("Error evaluating * or / with percentage: $e");
      //           // Fallback to simple percentage
      //           result = percentValue;
      //         }
      //       }
      //     } else {
      //       // Simple percentage: just divide by 100
      //       double value = double.parse(tempExpression);
      //       result = value / 100;
      //     }

      //     // Update the UI
      //     setState(() {
      //       // Keep the original expression and add %
      //       _rawExpression = '$currentText%';
      //       _inputController.text = formatExpression(_rawExpression);
      //       _inputController.selection = TextSelection.collapsed(
      //         offset: _inputController.text.length,
      //       );

      //       // Show the result immediately
      //       answer = formatNumber(result);
      //     });
      //   } catch (e) {
      //     debugPrint("Error calculating percentage: $e");
      //     // If there's an error, just append % and don't calculate
      //     setState(() {
      //       _rawExpression = '$currentText%';
      //       _inputController.text = formatExpression(_rawExpression);
      //       _inputController.selection = TextSelection.collapsed(
      //         offset: _inputController.text.length,
      //       );
      //     });
      //   }
      //   return;

      case '=':
        if (_rawExpression.isNotEmpty) {
          evaluateExpression(finalEvaluation: true).then((_) {
            if (answer != "Error" &&
                answer != "" &&
                !answer.contains("Infinity")) {
              addToHistory(_rawExpression, answer);
              if (mounted) {
                setState(() {
                  _animationController.forward();
                  _lastActionWasEval = true;
                });
              }
            }
          });
        }
        return;

      // Handle digits (0-9)
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
        // If last action was evaluation and there's a valid answer, start fresh
        if (_lastActionWasEval &&
            answer.isNotEmpty &&
            answer != "Error" &&
            !answer.contains("Infinity")) {
          if (mounted) {
            setState(() {
              _rawExpression = buttonText;
              _inputController.text = buttonText;
              _inputController.selection =
                  const TextSelection.collapsed(offset: 1);
              _lastActionWasEval = false;
              _animationController.reset();
              answer = '';
              evaluateExpression();
            });
          }
          return;
        }
        break; // Continue with normal digit handling if not after evaluation

      // Handle operators
      case '+':
      case '-':
      case '×':
      case '÷':
      case '^':
        // If last action was evaluation, use the answer as the base for next operation
        if (_lastActionWasEval &&
            answer != "Error" &&
            !answer.contains("Infinity")) {
          if (mounted) {
            setState(() {
              _rawExpression = answer.replaceAll(',', '') + buttonText;
              _inputController.text = formatExpression(_rawExpression);
              _inputController.selection =
                  TextSelection.collapsed(offset: _inputController.text.length);
              _lastActionWasEval = false;
              _animationController.reset();
              answer = '';
              evaluateExpression();
            });
          }
          return;
        }
        break;

      case 'X':
      case 'Y':
        handleVariableInput(buttonText);
        return;

      case 'shft':
        debugPrint("Shift button pressed. Current state: isShift=$isShift");
        if (mounted) {
          setState(() {
            isShift = !isShift;
            debugPrint("Shift state changed to: isShift=$isShift");
            evaluateExpression();
          });
        }
        return;

      case 'DEG':
        if (mounted) {
          setState(() {
            isDeg = !isDeg;
            evaluateExpression();
          });
        }
        return;

      case '.':
        // Check if the current number already has a decimal point
        final parts = _rawExpression.split(RegExp(r'[+\-*/×÷]'));
        if (parts.isEmpty || !parts.last.contains('.')) {
          final currentText = _rawExpression;
          final buffer = StringBuffer();
          // If expression is empty or ends with an operator, add "0." instead of just "."
          if (currentText.isEmpty ||
              isEndingWithOperator.hasMatch(currentText)) {
            buffer.write(currentText);
            buffer.write('0.');
          } else {
            buffer.write(currentText);
            buffer.write('.');
          }
          if (mounted) {
            setState(() {
              _rawExpression = buffer.toString();
              String formattedText = formatExpression(_rawExpression);
              _inputController.text = formattedText;
              _inputController.selection = TextSelection.collapsed(
                offset: formattedText.length,
              );
              evaluateExpression();
            });
          }
        }
        return;

      // Example for sqrt - apply similar changes to other function handlers
      case '√':
        String currentText = _rawExpression;
        final currentSelection = _inputController.selection;
        final cursorPos = currentSelection.baseOffset >= 0
            ? currentSelection.baseOffset.clamp(0, _inputController.text.length)
            : _inputController.text.length;

        // Convert from formatted position to raw position
        final rawCursorPos =
            _formattedToRawPositionMap[cursorPos] ?? currentText.length;

        final buffer = StringBuffer();
        debugPrint("sqrt button pressed. Current expression: '$currentText'");

        // If last action was evaluation, we should start fresh
        if (_lastActionWasEval) {
          // If there's an answer, use it as the input for the square root
          if (answer.isNotEmpty &&
              answer != "Error" &&
              !answer.contains("Infinity")) {
            // Use the answer as the input for square root
            buffer.write('√(');
            buffer.write(
                answer.replaceAll(',', '')); // Remove commas from the answer
            buffer.write(')');
          } else {
            // Just start a new square root expression
            buffer.write('√(');
          }
          _lastActionWasEval = false; // Reset the flag
        } else {
          // Normal behavior when not following an evaluation
          String textBeforeCursor = currentText.substring(0, rawCursorPos);
          String textAfterCursor = currentText.substring(rawCursorPos);

          if (currentText.isEmpty) {
            buffer.write('√(');
          }
          // If there's a number before √, add multiplication
          else if (endsWithNumberOrParenOrConst.hasMatch(textBeforeCursor)) {
            buffer.write(textBeforeCursor);
            buffer.write('*√(');
            buffer.write(textAfterCursor);
          } else {
            buffer.write(textBeforeCursor);
            buffer.write('√(');
            buffer.write(textAfterCursor);
          }
        }

        String newExpression = buffer.toString();
        int newRawCursorPos = _lastActionWasEval
            ? newExpression.length - 1
            : rawCursorPos + (newExpression.length - currentText.length);

        if (mounted) {
          setState(() {
            _rawExpression = newExpression;
            _rawCursorPosition = newRawCursorPos;

            String formattedText = formatExpression(_rawExpression);
            int formattedCursorPos =
                _rawToFormattedPositionMap[_rawCursorPosition] ??
                    formattedText.length;

            _inputController.value = TextEditingValue(
              text: formattedText,
              selection: TextSelection.collapsed(offset: formattedCursorPos),
            );
            debugPrint("Updated sqrt expression: '$_rawExpression'");
            evaluateExpression();
          });
        }
        return;

      case 'log':
        String currentText = _rawExpression;
        final buffer = StringBuffer();
        debugPrint("Log button pressed. Current state: isShift=$isShift");

        if (isShift) {
          // Natural log (ln)
          if (currentText.isNotEmpty &&
              endsWithNumberOrParenOrConst.hasMatch(currentText)) {
            buffer.write(currentText);
            buffer.write('*ln(');
          } else {
            buffer.write(currentText);
            buffer.write('ln(');
          }
        } else {
          // Common log (log10)
          if (currentText.isNotEmpty &&
              endsWithNumberOrParenOrConst.hasMatch(currentText)) {
            buffer.write(currentText);
            buffer.write('*log(');
          } else {
            buffer.write(currentText);
            buffer.write('log(');
          }
        }

        if (mounted) {
          setState(() {
            _rawExpression = buffer.toString();
            _inputController.text = formatExpression(_rawExpression);
            _inputController.selection =
                TextSelection.collapsed(offset: _inputController.text.length);
            debugPrint("Updated log expression: '$_rawExpression'");
            evaluateExpression();
          });
        }
        return;

      case 'sin':
      case 'cos':
      case 'tan':
        String currentText = _rawExpression;
        final buffer = StringBuffer();
        debugPrint("Trig button pressed: $buttonText, isShift=$isShift");

        String functionName = isShift ? "$buttonText⁻¹" : buttonText;

        if (currentText.isNotEmpty &&
            endsWithNumberOrParenOrConst.hasMatch(currentText)) {
          buffer.write(currentText);
          buffer.write('*$functionName(');
        } else {
          buffer.write(currentText);
          buffer.write('$functionName(');
        }

        if (mounted) {
          setState(() {
            _rawExpression = buffer.toString();
            _inputController.text = formatExpression(_rawExpression);
            _inputController.selection =
                TextSelection.collapsed(offset: _inputController.text.length);
            debugPrint("Updated trig expression: '$_rawExpression'");
            evaluateExpression();
          });
        }
        return;
    }

    // Handle regular button input
    final currentText = _rawExpression;
    final currentSelection = _inputController.selection;
    final buffer = StringBuffer();

    // Get the current cursor position in raw expression
    final cursorPos = currentSelection.baseOffset >= 0
        ? currentSelection.baseOffset.clamp(0, _inputController.text.length)
        : _inputController.text.length;

    // Convert from formatted position to raw position
    final rawCursorPos =
        _formattedToRawPositionMap[cursorPos] ?? currentText.length;

    // If last action was evaluation and we're starting a new number
    if (_lastActionWasEval && isDigit.hasMatch(buttonText)) {
      // Clear the expression and reset
      _rawExpression = '';
      buffer.clear();
      buffer.write(buttonText);

      if (mounted) {
        setState(() {
          _rawExpression = buffer.toString();
          _rawCursorPosition = 1; // Set cursor after the digit

          String formattedText = formatExpression(_rawExpression);
          int formattedCursorPos =
              _rawToFormattedPositionMap[_rawCursorPosition] ??
                  formattedText.length;

          _inputController.value = TextEditingValue(
            text: formattedText,
            selection: TextSelection.collapsed(
              offset: formattedCursorPos,
            ),
          );
          _lastActionWasEval = false;
          _animationController.reset();
          answer = '';
          evaluateExpression();
        });
      }
      return;
    }

    // Check if the button is an operator
    final isOperator = RegExp(r'[+\-*/×÷]').hasMatch(buttonText);
    if (isOperator) {
      // Get text before cursor and check if it ends with an operator
      String textBeforeCursor = currentText.substring(0, rawCursorPos);
      String trimmedBefore = textBeforeCursor.trim();

      // Allow minus after another operator for negative numbers, but prevent double minus
      if (isEndingWithOperator.hasMatch(trimmedBefore)) {
        if (buttonText == '-' && !trimmedBefore.endsWith('-')) {
          // Allow minus for negative numbers
          buffer.write(currentText.substring(0, rawCursorPos));
          buffer.write(buttonText);
          buffer.write(currentText.substring(rawCursorPos));
        } else {
          // Replace existing operator with new one
          buffer.write(currentText.substring(0, rawCursorPos - 1));
          buffer.write(buttonText);
          buffer.write(currentText.substring(rawCursorPos));
        }
      } else {
        // Normal operator insertion
        buffer.write(currentText.substring(0, rawCursorPos));
        buffer.write(buttonText);
        buffer.write(currentText.substring(rawCursorPos));
      }
    } else {
      // For non-operators, proceed with normal insertion
      buffer.write(currentText.substring(0, rawCursorPos));
      buffer.write(buttonText);
      buffer.write(currentText.substring(rawCursorPos));
    }

    int newRawCursorPos = rawCursorPos + buttonText.length;

    if (mounted) {
      setState(() {
        _rawExpression = buffer.toString();
        _rawCursorPosition = newRawCursorPos;

        String formattedText = formatExpression(_rawExpression);
        int formattedCursorPos =
            _rawToFormattedPositionMap[_rawCursorPosition] ??
                formattedText.length;

        _inputController.value = TextEditingValue(
          text: formattedText,
          selection: TextSelection.collapsed(
            offset: formattedCursorPos,
          ),
        );
        _lastActionWasEval = false;
        evaluateExpression();
      });
    }
  }

  String _handlePercentageCalculations(String expression) {
    // Handle simple cases first (no operators)
    if (!RegExp(r'[+\-*/×÷]').hasMatch(expression) &&
        expression.endsWith('%')) {
      // Simple percentage: 8% -> 0.08
      String numStr = expression.substring(0, expression.length - 1);
      double num = double.parse(numStr);
      return (num / 100).toString();
    }

    // For expressions with operators, we need to parse them carefully
    List<String> tokens = [];
    String currentToken = '';
    bool hasPercent = false;

    // Tokenize the expression
    for (int i = 0; i < expression.length; i++) {
      String char = expression[i];

      if (RegExp(r'[+\-*/×÷]').hasMatch(char)) {
        if (currentToken.isNotEmpty) {
          tokens.add(currentToken);
          currentToken = '';
        }
        tokens.add(char);
      } else if (char == '%') {
        hasPercent = true;
        // Process the percentage
        if (currentToken.isNotEmpty) {
          double value = double.parse(currentToken);
          value = value / 100;

          // Check if we need to apply the percentage to a previous value
          if (tokens.length >= 2 &&
              RegExp(r'[+\-]').hasMatch(tokens[tokens.length - 1])) {
            // For + and -, apply percentage to the previous number
            // String operator = tokens[tokens.length - 1];
            String prevNumStr = tokens[tokens.length - 2];

            if (RegExp(r'^[0-9.]+$').hasMatch(prevNumStr)) {
              double prevNum = double.parse(prevNumStr);
              value =
                  prevNum * value; // Calculate percentage of previous number
            }
          }

          currentToken = value.toString();
          tokens.add(currentToken);
          currentToken = '';
        }
      } else {
        currentToken += char;
      }
    }

    // Add any remaining token
    if (currentToken.isNotEmpty) {
      tokens.add(currentToken);
    }

    // If no percentage was found, return the original expression
    if (!hasPercent) {
      return expression;
    }

    // Rebuild the expression
    return tokens.join('');
  }

  String formatExpression(String rawExpression) {
    if (rawExpression.isEmpty) return '';

    debugPrint("Formatting raw expression: '$rawExpression'");

    // First, remove any existing commas to avoid double-formatting
    String cleanExpression = rawExpression;

    // Reset position maps
    _formattedToRawPositionMap.clear();
    _rawToFormattedPositionMap.clear();

    // Initialize buffers for building the formatted expression
    StringBuffer formattedBuffer = StringBuffer();
    int rawPos = 0;
    int formattedPos = 0;
    StringBuffer currentNumberBuffer = StringBuffer();

    void formatAndAppendNumber() {
      if (currentNumberBuffer.isEmpty) return;

      String numberStr = currentNumberBuffer.toString();
      String formattedNumber;

      // Handle decimal numbers
      if (numberStr.contains('.')) {
        List<String> parts = numberStr.split('.');
        String integerPart = parts[0];
        String decimalPart = parts[1];

        // Format integer part with commas
        try {
          if (integerPart.isEmpty) {
            formattedNumber = "0.$decimalPart";
          } else {
            double value = double.parse(integerPart);
            String formattedInt = _numberFormat.format(value);
            formattedNumber = "$formattedInt.$decimalPart";
          }
        } catch (e) {
          formattedNumber = numberStr;
        }
      } else {
        // Format integer
        try {
          double value = double.parse(numberStr);
          formattedNumber = _numberFormat.format(value);
        } catch (e) {
          formattedNumber = numberStr;
        }
      }

      // Map positions taking into account added commas
      int originalLength = numberStr.length;
      int formattedLength = formattedNumber.length;

      // Create position mappings for the number
      for (int i = 0; i < originalLength; i++) {
        int adjustedFormattedPos = formattedPos + i;
        for (int j = 0; j < formattedLength; j++) {
          if (formattedNumber[j] == ',' && j <= adjustedFormattedPos) {
            adjustedFormattedPos++;
          }
        }
        int currentRawPos = rawPos - originalLength + i;
        _rawToFormattedPositionMap[currentRawPos] = adjustedFormattedPos;
        _formattedToRawPositionMap[adjustedFormattedPos] = currentRawPos;
      }

      formattedBuffer.write(formattedNumber);
      formattedPos += formattedLength;
      currentNumberBuffer.clear();
    }

    // Process each character
    for (int i = 0; i < cleanExpression.length; i++) {
      String char = cleanExpression[i];

      if (RegExp(r'[0-9.]').hasMatch(char)) {
        // Accumulate digits and decimals
        currentNumberBuffer.write(char);
      } else {
        // Format and append any accumulated number
        formatAndAppendNumber();

        // Handle operators and other characters with 1:1 mapping
        formattedBuffer.write(char);
        _rawToFormattedPositionMap[i] = formattedPos;
        _formattedToRawPositionMap[formattedPos] = i;
        formattedPos++;
      }
      rawPos++;
    }

    // Format and append any remaining number
    formatAndAppendNumber();

    // Add final position mapping if needed
    if (!_rawToFormattedPositionMap.containsKey(rawExpression.length)) {
      _rawToFormattedPositionMap[rawExpression.length] = formattedPos;
    }
    if (!_formattedToRawPositionMap.containsKey(formattedPos)) {
      _formattedToRawPositionMap[formattedPos] = rawExpression.length;
    }

    final result = formattedBuffer.toString();
    debugPrint("Final formatted expression: '$result'");
    debugPrint("Raw to formatted map: $_rawToFormattedPositionMap");
    debugPrint("Formatted to raw map: $_formattedToRawPositionMap");

    return result;
  }

  void handleVariableInput(String varName) {
    if (answer.isNotEmpty &&
        answer != "Error" &&
        !answer.contains("Infinity")) {
      try {
        // Remove commas from the answer before parsing
        double valueToStore = double.parse(answer.replaceAll(',', ''));
        if (mounted) {
          setState(() {
            variables[varName] = valueToStore;
            _rawExpression = '';
            _rawCursorPosition = 0;
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
      // Using the variable in an expression
      String currentText = _rawExpression;
      TextSelection currentSelection = _inputController.selection;
      int cursorPos = currentSelection.baseOffset >= 0
          ? currentSelection.baseOffset.clamp(0, _inputController.text.length)
          : _inputController.text.length;

      // Convert from formatted position to raw position
      final rawCursorPos =
          _formattedToRawPositionMap[cursorPos] ?? currentText.length;

      StringBuffer buffer = StringBuffer();
      String textToInsert = varName;
      String textBeforeCursor = currentText.substring(0, rawCursorPos);

      if (endsWithNumberOrParenOrConst.hasMatch(textBeforeCursor.trim())) {
        textToInsert = '*$varName';
      }

      buffer.write(currentText.substring(0, rawCursorPos));
      buffer.write(textToInsert);
      buffer.write(currentText.substring(rawCursorPos));

      int newRawCursorPos = rawCursorPos + textToInsert.length;

      if (mounted) {
        setState(() {
          _rawExpression = buffer.toString();
          _rawCursorPosition = newRawCursorPos;

          String formattedText = formatExpression(_rawExpression);
          int formattedCursorPos =
              _rawToFormattedPositionMap[_rawCursorPosition] ??
                  formattedText.length;

          _inputController.value = TextEditingValue(
            text: formattedText,
            selection: TextSelection.collapsed(offset: formattedCursorPos),
          );
          _validatePositionMaps();
          _animationController.reset();
          evaluateExpression();
        });
      }
    }
  }

  void handlePaste() async {
    try {
      // Validate clipboard content
      bool isValid = await validateAndPasteClipboard(context);
      if (!isValid || !mounted) {
        return;
      }

      // Get clipboard data
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      String pastedText = clipboardData?.text?.trim() ?? '';
      if (pastedText.isEmpty) {
        showOverlayMessage('Clipboard is empty');
        return;
      }

      // Clean the pasted text
      pastedText = pastedText.replaceAll(' ', '');

      // Get current state
      final currentText = _rawExpression;
      final currentSelection = _inputController.selection;
      final cursorPos = currentSelection.baseOffset >= 0
          ? currentSelection.baseOffset.clamp(0, _inputController.text.length)
          : _inputController.text.length;

      // Convert from formatted position to raw position
      final rawCursorPos =
          _formattedToRawPositionMap[cursorPos] ?? currentText.length;

      // Determine if we need to insert a multiplication operator
      String textBeforeCursor = currentText.substring(0, rawCursorPos);
      String textToInsert = pastedText;

      // If pasting after a number/constant/closing parenthesis, add multiplication
      if (rawCursorPos > 0 &&
          endsWithNumberOrParenOrConst.hasMatch(textBeforeCursor) &&
          (isDigit.hasMatch(pastedText[0]) ||
              pastedText[0] == '(' ||
              RegExp(r'[πe]').hasMatch(pastedText[0]))) {
        textToInsert = '*$pastedText';
      }

      // Create new expression
      String newExpression = currentText.substring(0, rawCursorPos) +
          textToInsert +
          currentText.substring(rawCursorPos);

      int newRawCursorPos = rawCursorPos + textToInsert.length;

      // Update UI
      setState(() {
        _rawExpression = newExpression;
        _rawCursorPosition = newRawCursorPos;

        String formattedText = formatExpression(newExpression);
        int formattedCursorPos =
            _rawToFormattedPositionMap[_rawCursorPosition] ??
                formattedText.length;

        _inputController.value = TextEditingValue(
          text: formattedText,
          selection: TextSelection.collapsed(
            offset: formattedCursorPos,
          ),
        );

        _validatePositionMaps();
        _lastActionWasEval = false;
        evaluateExpression();
      });

      // Show success message
      showOverlayMessage('Expression pasted');
    } catch (e, stackTrace) {
      debugPrint("Paste error: $e");
      debugPrint("Stack trace: $stackTrace");
      showOverlayMessage('Error pasting from clipboard');
    }
  }

  Future<bool> validateAndPasteClipboard(BuildContext context) async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final pastedText = clipboardData?.text?.trim() ?? '';

      if (pastedText.isEmpty) {
        showOverlayMessage('Clipboard is empty');
        return false;
      }

      // Allow digits, operators, parentheses, decimal points, and specific functions/constants
      final validChars = RegExp(
          r'^[0-9,\.\+\-*/×÷%^()\s]*(sin|cos|tan|log|ln|sqrt|π|e|X|Y)?$');
      if (!validChars.hasMatch(pastedText)) {
        showOverlayMessage('Invalid characters in clipboard');
        return false;
      }

      // Check for invalid sequences
      final invalidSequences = [
        RegExp(r'[+*\/×÷%^]{2,}'), // Multiple operators
        RegExp(r'[-]{3,}'), // More than two minus signs
        RegExp(r'[\.]{2,}') // Multiple decimal points
      ];

      for (var pattern in invalidSequences) {
        if (pattern.hasMatch(pastedText)) {
          showOverlayMessage('Invalid expression format');
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint("Clipboard validation error: $e");
      showOverlayMessage('Error accessing clipboard');
      return false;
    }
  }

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
    if (number.isInfinite || number.isNaN) {
      return 'Error';
    }

    // Handle very large or very small numbers with scientific notation
    if (number.abs() > 1e9 || (number != 0 && number.abs() < 1e-9)) {
      return number.toStringAsExponential(9);
    }

    return _numberFormat.format(number);
  }

  String formatScientificForInput(String scientificNumber) {
    // Convert scientific notation to a regular decimal string
    try {
      double number = double.parse(scientificNumber);
      if (number.abs() > 1e9 || (number != 0 && number.abs() < 1e-9)) {
        return number.toStringAsExponential(9);
      }
      return _numberFormat.format(number);
    } catch (e) {
      debugPrint('Error formatting scientific number: $e');
      return scientificNumber;
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
    if (text == 'shft') {
      buttonColor = isShift
          ? CupertinoColors.systemIndigo.withOpacity(0.4)
          : CupertinoColors.systemIndigo.withOpacity(0.3);
    }

    Color fgColor = (text == 'del')
        ? CupertinoColors.systemRed
        : CupertinoColors.label; // AC handled by background
    if (text == '=') fgColor = CupertinoColors.white;

    Widget content;
    if (text == 'shft') {
      content = Icon(
          isShift
              ? FluentIcons.keyboard_shift_uppercase_24_filled
              : FluentIcons.keyboard_shift_uppercase_24_regular,
          size: btnSize * 0.40,
          color: fgColor);
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
      String displayText = (text == 'DEG') ? (isDeg ? 'DEG' : 'RAD') : text;
      if (isShift && {'sin', 'cos', 'tan', 'log'}.contains(displayText)) {
        switch (displayText) {
          case 'sin':
            displayText = 'sin⁻¹'; // Unicode superscript -1
            break;
          case 'cos':
            displayText = 'cos⁻¹';
            break;
          case 'tan':
            displayText = 'tan⁻¹';
            break;
          case 'log':
            displayText = 'ln';
            break;
        }
      }
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
        text == 'unit' ||
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
                                  // Replace the existing onTap handler in the mini history section with this corrected version

                                  // Simply use the result directly without any special processing
                                  String cleanedResult =
                                      entry.result.replaceAll(',', '');

                                  setState(() {
                                    String newExpression;
                                    if (_rawExpression.isNotEmpty &&
                                        isEndingWithOperator
                                            .hasMatch(_rawExpression.trim())) {
                                      newExpression =
                                          _rawExpression + cleanedResult;
                                    } else {
                                      newExpression = cleanedResult;
                                    }
                                    _rawExpression = newExpression;
                                    String formattedText =
                                        formatExpression(newExpression);
                                    _rawCursorPosition = newExpression.length;
                                    int formattedCursorPos =
                                        _rawToFormattedPositionMap[
                                                _rawCursorPosition] ??
                                            formattedText.length;

                                    _inputController.value = TextEditingValue(
                                      text: formattedText,
                                      selection: TextSelection.collapsed(
                                          offset: formattedCursorPos),
                                    );
                                    _validatePositionMaps();
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
                              child: // In the build method, update the onTap handler for the CupertinoTextField
                                  CupertinoTextField(
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
                                  } else {
                                    // Update raw cursor position when user taps
                                    int formattedPos =
                                        _inputController.selection.baseOffset;
                                    _rawCursorPosition =
                                        _formattedToRawPositionMap[
                                                formattedPos] ??
                                            _rawExpression.length;
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
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
              Container(
                height: screenHeight * 0.048,
                color: CupertinoColors.systemGroupedBackground,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    buildButton(context, "Calc", bottomBtnSize),
                    buildButton(context, "hist", bottomBtnSize),
                    buildButton(context, "unit", bottomBtnSize),
                    buildButton(context, "Settings", bottomBtnSize),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                    // In the showHistory method, modify the onExpressionTap callback:
                    // In the onExpressionTap callback in showHistory method:
                    onExpressionTap: (String resultFromHistory) {
                      // Remove commas for calculation purposes
                      String rawResult = resultFromHistory.replaceAll(',', '');

                      debugPrint(
                          "History tapped. Original result: '$resultFromHistory', "
                          "Raw for calculation: '$rawResult'");

                      if (mounted) {
                        setState(() {
                          String newExpression;
                          // Check if expression ends with an operator
                          if (_rawExpression.isNotEmpty &&
                              isEndingWithOperator
                                  .hasMatch(_rawExpression.trim())) {
                            newExpression = _rawExpression +
                                rawResult; // Use raw version for calculation
                          } else {
                            newExpression =
                                rawResult; // Use raw version for calculation
                          }

                          _rawExpression = newExpression;

                          // Format the expression for display
                          String formattedText =
                              formatExpression(newExpression);
                          _inputController.value = TextEditingValue(
                            text: formattedText,
                            selection: TextSelection.collapsed(
                              offset: formattedText.length,
                            ),
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

  void showSettings(BuildContext parentContext) {
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
            height: MediaQuery.of(modalContext).size.height * 0.35,
            decoration: const BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Modal Handle
                Container(
                  height: 5,
                  width: 35,
                  margin: const EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey4,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                // Settings List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    children: [
                      // Enable Dark Theme Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Enable Dark Theme",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          CupertinoSwitch(
                            value:
                                isDarkThemeEnabled, // Assuming you have this state variable
                            onChanged: (bool value) {
                              if (mounted) {
                                setState(() {
                                  isDarkThemeEnabled = value;
                                });
                              }
                              Navigator.pop(
                                  modalContext); // Close modal on change
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showToolsModal(BuildContext parentContext) {
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
                // Modal Handle
                Container(
                  height: 5,
                  width: 35,
                  margin: const EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey4,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Unit Converter',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: CupertinoColors.systemGrey,
                        ),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                ),
                // Grid Content
                Expanded(
                  child: ToolsGridContent(),
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

// Add this method to help debug cursor positioning issues
// Add this method to validate position maps
  void _validatePositionMaps() {
    if (_rawExpression.isEmpty) {
      _formattedToRawPositionMap = {0: 0};
      _rawToFormattedPositionMap = {0: 0};
      return;
    }

    // Ensure every position in raw expression has a mapping
    for (int i = 0; i <= _rawExpression.length; i++) {
      if (!_rawToFormattedPositionMap.containsKey(i)) {
        debugPrint("Warning: Missing mapping for raw position $i");
        // Add a fallback mapping
        _rawToFormattedPositionMap[i] =
            i.clamp(0, _inputController.text.length);
      }
    }

    // Ensure every position in formatted text has a mapping
    for (int i = 0; i <= _inputController.text.length; i++) {
      if (!_formattedToRawPositionMap.containsKey(i)) {
        debugPrint("Warning: Missing mapping for formatted position $i");
        // Add a fallback mapping
        _formattedToRawPositionMap[i] = i.clamp(0, _rawExpression.length);
      }
    }
  }

// Call this after formatting in setState blocks
} // End of _CalcPageState
