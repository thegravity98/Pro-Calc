import 'dart:math';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:math_expressions/math_expressions.dart';
import 'history_page.dart';
import '../models/calculation_history.dart';

class CalcPage extends StatefulWidget {
  const CalcPage({super.key});

  @override
  State<CalcPage> createState() => _CalcPageState();
}

class _CalcPageState extends State<CalcPage>
    with SingleTickerProviderStateMixin {
  late TextEditingController _inputController;
  late AnimationController _animationController;
  late Animation<double> _inputTextSizeAnimation;
  late Animation<double> _answerTextSizeAnimation;

  // No separate userInput/fakeUserInput needed, use _inputController.text
  String answer = '';
  bool isDeg = true;

  // Default text sizes - can be final if not changed elsewhere
  final double initialInputTextSize = 36.0;
  final double finalInputTextSize = 32.0;
  final double initialAnswerTextSize = 32.0;
  final double finalAnswerTextSize = 36.0;

  // Regular Expressions (keep as final for performance)
  final isDigit = RegExp(r'[0-9]$');
  final isTrigFun = RegExp(r'(sin|cos|tan)');
  final isDot = RegExp(r'(\.)$');
  final isDotBetween =
      RegExp(r'(\.\d+)$'); // Checks if a dot exists followed by digits
  final isEndingWithOperator = RegExp(r'[+*/×÷%^-]$'); // Combined operators
  final isFirstZero = RegExp(r'^0$'); // Check if input is just '0'
  final isSQRT = RegExp(r'√(\d+|(?<=\()\d+(?=\)))'); // Improved sqrt matching
  final isLog = RegExp(r'(log)|(ln)');
  final hasNumber = RegExp(r'[\dπe]'); // Simplified number check
  final isOperator = RegExp(r'[+*/%^-]'); // Simplified operator check

  // Variables (consider if X/Y are truly needed or if 'ans' is sufficient)
  final Map<String, double> variables = {'X': 0, 'Y': 0};
  final ContextModel cm = ContextModel();

  final List<CalculationHistory> history = [];
  final int maxHistoryEntries = 100;
  static const _historyKey = 'calculator_history';

  // Button layout remains the same
  final List<String> stringList = [
    'X', 'Y', 'deg', 'hist', 'AC',
    'sin', 'cos', 'tan', 'π', 'del',
    'e', '(', ')', '%', '/', // Using '/' directly
    '!', '7', '8', '9', '×', // Using '×' directly
    '^', '4', '5', '6', '-',
    '√', '1', '2', '3', '+',
    'log', '10ˣ', '0', '.', '=',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controller without text initially
    _inputController = TextEditingController();
    // Listener not strictly needed if we update cursor manually on change
    // _inputController.addListener(() {
    //   // Cursor position handled within buttonPressed
    // });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400), // Increased from 300ms
      vsync: this,
    );

    // Use final variables for Tween definition
    _inputTextSizeAnimation = Tween<double>(
      begin: initialInputTextSize,
      end: finalInputTextSize,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic, // Changed from easeInOut
    ));

    _answerTextSizeAnimation = Tween<double>(
      begin: initialAnswerTextSize,
      end: finalAnswerTextSize,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic, // Changed from easeInOut
    ));

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
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        // Use setState only once after processing
        final loadedHistory =
            jsonList.map((json) => CalculationHistory.fromJson(json)).toList();
        if (mounted) {
          // Check if the widget is still in the tree
          setState(() {
            history.addAll(loadedHistory);
          });
        }
      } catch (e) {
        debugPrint('Error loading history: $e');
        // Optionally clear corrupted history
        // await prefs.remove(_historyKey);
      }
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = history.map((entry) => entry.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  void addToHistory(String expr, String res) {
    if (res.isEmpty || res == "Error") return;

    // setState updates history and triggers UI refresh
    setState(() {
      history.insert(
          0,
          CalculationHistory(
            expression: expr,
            result: res,
          ));
      if (history.length > maxHistoryEntries) {
        history.removeLast();
      }
    });
    _saveHistory(); // Save after state update
  }

  Future<void> _clearHistory() async {
    setState(() {
      history.clear();
    });
    await _saveHistory();
  }

  // --- Calculation Logic ---
  Future<void> _evaluateExpression({bool finalEvaluation = false}) async {
    String expression = _inputController.text;
    if (expression.isEmpty ||
        (!finalEvaluation && isEndingWithOperator.hasMatch(expression))) {
      // Don't evaluate if empty or ending with operator (unless '=' was pressed)
      if (answer.isNotEmpty) {
        setState(() {
          answer = '';
        }); // Clear previous answer if input becomes invalid
      }
      return;
    }

    String resultString = '';
    String tempInput = expression; // Moved this declaration outside try block

    try {
      // --- Pre-processing ---
      // Use const for efficiency
      const double degToRad = pi / 180.0;

      // Replace display characters with evaluatable ones
      tempInput = tempInput.replaceAll('×', '*');
      tempInput = tempInput.replaceAll('÷', '/'); // Assuming ÷ might be used
      tempInput = tempInput.replaceAll(
          'π', '($pi)'); // Parentheses ensure correct precedence
      tempInput = tempInput.replaceAll('e', '($e)');

      // Handle Degree/Radian Conversion
      if (isDeg) {
        // More robust regex for nested functions or complex arguments
        tempInput = tempInput
            .replaceAllMapped(RegExp(r'(sin|cos|tan)\((.*?)\)'), (match) {
          // Basic balancing check - might need more complex parsing for truly nested cases
          String arg = match.group(2)!;
          int openParen = '('.allMatches(arg).length;
          int closeParen = ')'.allMatches(arg).length;
          // Avoid converting if argument itself contains trig functions improperly
          if (openParen == closeParen) {
            // Check if already multiplied by degToRad (less likely but possible)
            if (!arg.contains('* $degToRad')) {
              return '${match.group(1)}(($arg) * $degToRad)';
            }
          }
          return match.group(0)!; // Return original if unsure
        });
      }

      // Handle Percentage (Improved Logic)
      // Case 1: Simple percentage (e.g., 50% -> 0.5)
      tempInput = tempInput.replaceAllMapped(RegExp(r'(\d+\.?\d*)%'), (match) {
        double val = double.parse(match.group(1)!) / 100.0;
        return val.toString();
      });
      // Case 2: Percentage operation (e.g., 100 + 10% -> 100 + 100 * 0.1)
      // This requires careful parsing order, often better handled by dedicated logic
      // or by requiring explicit multiplication (e.g., 100 + 100 * 10%)
      // Current simple replacement might not cover all cases like 100+10%+5
      // Let's stick to the previous modulo/percentage split for clarity here,
      // but acknowledge its limitations.

      // Modulo calculation (ensure % is not misinterpreted from percentage)
      // Needs to occur *after* simple % replacement and *before* +/- percentage op
      tempInput = tempInput
          .replaceAllMapped(RegExp(r'(\d+\.?\d*)\s*%\s*(\d+\.?\d*)'), (match) {
        double a = double.parse(match.group(1)!);
        double b = double.parse(match.group(2)!);
        return (a % b).toString(); // Standard modulo
      });

      // Handle +/- percentage calculation (like original code)
      tempInput = tempInput.replaceAllMapped(
          RegExp(r'(\d+\.?\d*)\s*([+-])\s*(\d+\.?\d*)\s*\*?\s*\/100\.0'),
          (match) {
        // Match the replaced %
        double baseNumber = double.parse(match.group(1)!);
        String operator = match.group(2)!;
        double percentageValue =
            double.parse(match.group(3)!) / 100.0; // Already divided
        double change = baseNumber * percentageValue;

        return operator == '+'
            ? (baseNumber + change).toString()
            : (baseNumber - change).toString();
      });

      // Handle Square Root (√) -> sqrt()
      // Use lookbehind/lookahead for sqrt surrounding numbers or parentheses
      tempInput = tempInput.replaceAllMapped(
          RegExp(r'√\(([^)]+)\)'), // Matches √(...)
          (match) =>
              'sqrt((${match.group(1)}))' // Ensure inner expression is evaluated first
          );
      tempInput = tempInput.replaceAllMapped(
          RegExp(r'√(\d+\.?\d*)'), // Matches √number
          (match) => 'sqrt(${match.group(1)})');

      // Handle log/ln (ensure parentheses are added if missing - basic case)
      // This might need refinement if users type log 10 instead of log(10)
      tempInput = tempInput.replaceAllMapped(
          RegExp(
              r'(log|ln)(?!\()(\d+\.?\d*)'), // log followed by number, no parenthesis
          (match) => '${match.group(1)}(${match.group(2)})');
      // Handle 10^x -> pow(10, x)
      tempInput = tempInput.replaceAllMapped(
          RegExp(
              r'10\^(\(?.*\)?|\d+\.?\d*)'), // Match 10^ followed by number or (...)
          (match) => 'pow(10, ${match.group(1)})');
      // Handle general power x^y -> pow(x, y)
      tempInput = tempInput.replaceAllMapped(
          RegExp(
              r'(?<!10\^)([\w.)]+)\^(\(?.*\)?|\d+\.?\d*)'), // Match base^exponent, avoid 10^
          (match) => 'pow(${match.group(1)}, ${match.group(2)})');

      // Handle Factorial (!) - implement factorial calculation
      tempInput = tempInput.replaceAllMapped(RegExp(r'(\d+)!'), (match) {
        int n = int.parse(match.group(1)!);
        if (n > 170) return '1.7976931348623157e+308'; // double.infinity
        if (n < 0) return '0.0/0.0'; // double.nan
        double result = 1;
        for (int i = 2; i <= n; i++) {
          result *= i;
        }
        return result.toString();
      });

      // --- Evaluation ---
      // Consider adding variables from the map
      cm.bindVariable(Variable('X'), Number(variables['X'] ?? 0));
      cm.bindVariable(Variable('Y'), Number(variables['Y'] ?? 0));

      Parser p = Parser();
      Expression exp = p.parse(tempInput);
      double result = exp.evaluate(EvaluationType.REAL, cm);

      // Format result: remove trailing .0
      if (result.isInfinite || result.isNaN) {
        resultString = 'Error';
      } else {
        resultString = result == result.toInt()
            ? result.toInt().toString()
            : result
                .toStringAsFixed(10)
                .replaceAll(RegExp(r'0+$'), '')
                .replaceAll(RegExp(r'\.$'),
                    ''); // Limit precision and trim trailing zeros/dot
      }
    } catch (e) {
      debugPrint('Evaluation error for "$tempInput": $e');
      resultString = 'Error'; // Keep error state internal until setState
    }

    // Update state only if result changed or it's a final evaluation
    if (finalEvaluation || answer != resultString) {
      setState(() {
        answer = (resultString == _inputController.text) ? '' : resultString;
      });
    }
  }

  // --- Input Handling ---
  void buttonPressed(String buttonText) {
    String currentText = _inputController.text;
    TextSelection currentSelection = _inputController.selection;
    int cursorPos = currentSelection.baseOffset >= 0
        ? currentSelection.baseOffset
        : currentText.length;

    // Use a temporary buffer for modifications
    StringBuffer buffer = StringBuffer(currentText);
    int newCursorPos = cursorPos; // Default to current position

    // Handle state reset/special actions first
    switch (buttonText) {
      case 'AC':
        setState(() {
          _inputController.clear();
          answer = '';
          _animationController.reset(); // Reset animation state
        });
        return; // Exit early

      case '=':
        if (currentText.isNotEmpty &&
            !isEndingWithOperator.hasMatch(currentText)) {
          _evaluateExpression(finalEvaluation: true).then((_) {
            if (answer.isNotEmpty && answer != "Error") {
              addToHistory(currentText, answer);
              _animationController.forward().then((_) {
                // Clear input *after* animation, keep answer
                if (mounted) {
                  // Check if widget is still mounted
                  setState(() {
                    _inputController.clear();
                    // Keep 'answer' visible
                  });
                }
              });
            } else {
              // If evaluation resulted in error or no answer, reset animation
              _animationController.reset();
            }
          });
        } else {
          _animationController.reset(); // Reset if input is invalid for '='
        }
        return; // Exit early

      case 'del':
        if (currentSelection.isValid &&
            currentSelection.isCollapsed &&
            cursorPos > 0) {
          // Delete character before cursor
          buffer.clear();
          buffer.write(currentText.substring(0, cursorPos - 1));
          buffer.write(currentText.substring(cursorPos));
          newCursorPos = cursorPos - 1;
        } else if (currentSelection.isValid && !currentSelection.isCollapsed) {
          // Delete selected range
          buffer.clear();
          buffer.write(currentText.substring(0, currentSelection.start));
          buffer.write(currentText.substring(currentSelection.end));
          newCursorPos = currentSelection.start;
        } else if (currentText.isNotEmpty) {
          // Fallback: delete last character if no selection/cursor info
          buffer.clear();
          buffer.write(currentText.substring(0, currentText.length - 1));
          newCursorPos = buffer.length;
        }
        // Update state after modification
        setState(() {
          _inputController.value = TextEditingValue(
            text: buffer.toString(),
            selection: TextSelection.collapsed(offset: newCursorPos),
          );
          // Evaluate immediately after delete if valid
          _evaluateExpression();
        });
        return; // Exit early

      case 'deg':
      case 'rad':
        setState(() {
          isDeg = !isDeg;
          // Re-evaluate if expression exists
          if (_inputController.text.isNotEmpty) {
            _evaluateExpression();
          }
        });
        return; // Exit early

      case 'hist':
        _showHistory(context);
        return; // Exit early

      // Handle Variable Assignment (X, Y)
      case 'X':
      case 'Y':
        handleVariableInput(buttonText); // Keep separate logic for clarity
        return; // Exit early
    }

    // --- Handle regular button presses ---

    // Reset animation if it was completed (e.g., after '=')
    if (_animationController.status == AnimationStatus.completed) {
      _animationController.reset();
      // If user starts typing after '=', clear the answer
      if (answer.isNotEmpty) {
        setState(() {
          answer = '';
        });
      }
    }

    String textToInsert = '';
    bool evaluateAfterInsert = true; // Evaluate by default

    // Determine text to insert based on button
    if (isTrigFun.hasMatch(buttonText) ||
        buttonText == 'log' ||
        buttonText == 'ln') {
      textToInsert = '$buttonText(';
    } else if (buttonText == "10ˣ") {
      textToInsert = "10^";
    } else if (buttonText == "√") {
      textToInsert = "√(";
    } else if (buttonText == ".") {
      // Prevent leading dot or multiple dots in a number segment
      final String textBeforeCursor = currentText.substring(0, cursorPos);
      final String? lastNumberSegment =
          RegExp(r'(\d*\.?\d*)$').firstMatch(textBeforeCursor)?.group(0);

      if (lastNumberSegment == null || !lastNumberSegment.contains('.')) {
        // Allow dot if: empty, after operator, or in a number without a dot yet
        if (currentText.isEmpty ||
            isEndingWithOperator.hasMatch(textBeforeCursor.isNotEmpty
                ? textBeforeCursor[textBeforeCursor.length - 1]
                : '')) {
          textToInsert = "0."; // Prepend 0 if starting or after operator
        } else {
          textToInsert = ".";
        }
      } else {
        textToInsert = ""; // Do not insert dot
        evaluateAfterInsert = false;
      }
    } else if (buttonText == '0') {
      // Prevent leading multiple zeros unless it's "0."
      final String textBeforeCursor = currentText.substring(0, cursorPos);
      if (textBeforeCursor == '0') {
        // Don't allow 00
        textToInsert = "";
        evaluateAfterInsert = false;
      } else {
        textToInsert = buttonText;
      }
    } else if (isOperator.hasMatch(buttonText) ||
        buttonText == '(' ||
        buttonText == ')' ||
        buttonText == '%') {
      // Allow operator if input not empty and not ending with an operator (basic check)
      // More complex validation (e.g. duplicate operators) can be added
      if (currentText.isNotEmpty &&
          !isEndingWithOperator.hasMatch(
              currentText.substring(max(0, cursorPos - 1), cursorPos))) {
        textToInsert = buttonText;
        evaluateAfterInsert = false; // Don't evaluate intermediate operators
      } else if (buttonText == '(') {
        textToInsert = buttonText; // Always allow opening parenthesis
        evaluateAfterInsert = false;
      } else if (buttonText == ')') {
        // Basic check: only allow if there's a matching open parenthesis count
        if ('('.allMatches(currentText).length >
            ')'.allMatches(currentText).length) {
          textToInsert = buttonText;
        } else {
          textToInsert = "";
          evaluateAfterInsert = false;
        }
      } else if (currentText.isEmpty &&
          (buttonText == '-' || buttonText == '+')) {
        // Allow leading minus/plus
        textToInsert = buttonText;
        evaluateAfterInsert = false;
      } else {
        textToInsert = ""; // Prevent invalid operator placement
        evaluateAfterInsert = false;
      }
    } else {
      // Default case (digits, π, e, etc.)
      textToInsert = buttonText;
    }

    // Insert the text and update state
    if (textToInsert.isNotEmpty) {
      buffer.clear();
      // Ensure cursor position is valid before inserting
      cursorPos = cursorPos.clamp(0, currentText.length);
      buffer.write(currentText.substring(0, cursorPos));
      buffer.write(textToInsert);
      buffer.write(currentText.substring(cursorPos));
      newCursorPos = cursorPos + textToInsert.length;

      setState(() {
        _inputController.value = TextEditingValue(
          text: buffer.toString(),
          selection: TextSelection.collapsed(offset: newCursorPos),
        );
        // Evaluate if the insertion is valid and doesn't end with operator
        if (evaluateAfterInsert) {
          _evaluateExpression();
        } else if (answer.isNotEmpty) {
          // Clear answer if inserting an operator/invalid char
          answer = '';
        }
      });
    }
  }

  // Separate function for variable handling (potentially more complex logic later)
  void handleVariableInput(String varName) {
    String currentText = _inputController.text;
    TextSelection currentSelection = _inputController.selection;
    int cursorPos = currentSelection.baseOffset >= 0
        ? currentSelection.baseOffset
        : currentText.length;
    StringBuffer buffer = StringBuffer(currentText);
    int newCursorPos = cursorPos;

    // Option 1: Store current answer to variable if answer exists
    if (answer.isNotEmpty && answer != "Error") {
      try {
        double valueToStore = double.parse(answer);
        variables[varName] = valueToStore;
        setState(() {
          // Briefly show assignment confirmation in answer field
          answer =
              "$varName = ${valueToStore == valueToStore.toInt() ? valueToStore.toInt() : valueToStore}";
          _inputController.clear(); // Clear input after storing
          _animationController.reset();
        });
      } catch (e) {
        setState(() {
          answer = "Error storing $varName";
        });
      }
    } else {
      // Option 2: Insert variable name into the expression
      buffer.clear();
      cursorPos = cursorPos.clamp(0, currentText.length);
      buffer.write(currentText.substring(0, cursorPos));
      buffer.write(varName);
      buffer.write(currentText.substring(cursorPos));
      newCursorPos = cursorPos + varName.length;

      setState(() {
        _inputController.value = TextEditingValue(
          text: buffer.toString(),
          selection: TextSelection.collapsed(offset: newCursorPos),
        );
        // Evaluate if the expression remains valid
        _evaluateExpression();
      });
    }
  }

  // --- UI Building ---

  // Memoized button colors (keep as final)
  final Map<String, Color?> _buttonColors = {
    'deg': Colors.blue[100],
    'rad': Colors.orange[100],
    'X': Colors.purple[100],
    'Y': Colors.teal[100],
    'hist': Colors.amber[100],
    'AC': const Color.fromARGB(255, 255, 200, 200),
    '=': Colors.green[200], // Example: Highlight equals
  };

  // Button Text Size calculation can be simplified or kept as is
  double getButtonTextSize(String text, double btnSize) {
    // Simpler logic: smaller for longer text, larger for digits
    if (text.length > 1 && !RegExp(r'^\d+$').hasMatch(text))
      return btnSize * 0.3; // Smaller for sin, cos, log etc.
    if (isDigit.hasMatch(text) || text == '.')
      return btnSize * 0.4; // Larger for digits/dot
    return btnSize * 0.35; // Default
  }

  Widget buildButton(String text, double btnSize) {
    // Determine background color
    Color buttonColor = Colors.white; // Default for digits
    if (_buttonColors.containsKey(text)) {
      buttonColor = _buttonColors[text]!;
    } else if (RegExp(r'[+\-*/×÷%=]').hasMatch(text)) {
      // Removed ^ from operators
      buttonColor = Colors.grey[300]!; // Operators
    } else if (!isDigit.hasMatch(text) && text != '.') {
      buttonColor = const Color.fromARGB(255, 245, 245, 245); // Other functions
    }

    // Determine text/icon color
    final Color fgColor = (text == 'AC' || text == 'del')
        ? const Color.fromARGB(255, 220, 0, 0)
        : const Color.fromARGB(255, 51, 51, 51);

    // Special Icons
    if (text == 'hist') {
      return _buildElevatedButton(
        FluentIcons.history_24_regular,
        btnSize,
        buttonColor,
        fgColor,
        () => buttonPressed(text),
        isIcon: true,
      );
    }
    if (text == 'del') {
      return _buildElevatedButton(
        FluentIcons.backspace_24_filled,
        btnSize,
        buttonColor,
        fgColor,
        () => buttonPressed(text),
        isIcon: true,
      );
    }

    // Handle deg/rad toggle display
    final String displayText = (text == 'deg') ? (isDeg ? 'deg' : 'rad') : text;
    if (text == 'deg') {
      buttonColor = isDeg ? _buttonColors['deg']! : _buttonColors['rad']!;
    }

    return _buildElevatedButton(
      displayText,
      btnSize,
      buttonColor,
      fgColor,
      () => buttonPressed(text),
      isIcon: false,
    );
  }

  Widget _buildElevatedButton(
    dynamic content,
    double btnSize,
    Color bgColor,
    Color fgColor,
    VoidCallback onPressed, {
    bool isIcon = false,
  }) {
    return Container(
      width: btnSize,
      height: btnSize * 0.8, // Reduced height by 20%
      margin: EdgeInsets.all(btnSize * 0.05),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(btnSize * 0.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(btnSize * 0.3),
        color: bgColor,
        onPressed: onPressed,
        child: isIcon
            ? Icon(
                content as IconData,
                size: btnSize * 0.45,
                color: fgColor,
              )
            : Text(
                content as String,
                style: TextStyle(
                  fontSize: getButtonTextSize(content, btnSize),
                  color: fgColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldSize = MediaQuery.of(context).size;
    final btnSize = (scaffoldSize.width / 5.2).clamp(50.0, 65.0);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Pro Calc'),
      ),
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            children: <Widget>[
              // Display Area
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  margin: const EdgeInsets.only(bottom: 8.0),
                  alignment: Alignment.bottomRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // History display at the top (last 3 entries)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ...history.take(3).map((entry) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 8.0), // Increased from 4.0
                                child: Text(
                                  "${entry.expression} = ${entry.result}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: CupertinoColors.secondaryLabel,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                        ],
                      ),

                      // Current calculation area
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Input field animation
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
                                ),
                                decoration: null,
                                maxLines: 2,
                                minLines: 1,
                                enableInteractiveSelection: true,
                                onTap: () {
                                  if (_inputController.selection.baseOffset <
                                      0) {
                                    _inputController.selection =
                                        TextSelection.collapsed(
                                            offset:
                                                _inputController.text.length);
                                  }
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 8),

                          // Answer text animation
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _animationController.value * 0.3 + 0.7,
                                child: Text(
                                  answer,
                                  style: TextStyle(
                                    fontSize: _answerTextSizeAnimation.value,
                                    color: CupertinoColors.label,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Button Grid with improved spacing
              Expanded(
                flex: 5,
                child: Container(
                  // decoration: BoxDecoration(
                  //   color: CupertinoColors.systemBackground.withOpacity(0.5),
                  //   borderRadius: BorderRadius.circular(16),
                  // ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      (stringList.length / 5).ceil(),
                      (rowIndex) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(
                          5,
                          (columnIndex) {
                            final index = rowIndex * 5 + columnIndex;
                            if (index >= stringList.length) {
                              return SizedBox(width: btnSize);
                            }
                            final String buttonText = stringList[index];
                            return buildButton(buttonText, btnSize);
                          },
                        ),
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

  // --- History Modal (Unchanged, but ensure context is valid) ---
  void _showHistory(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (modalContext) => GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            Navigator.pop(modalContext);
          }
        },
        child: Container(
          height: MediaQuery.of(context).size.height * 0.65,
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
              const Padding(
                padding: EdgeInsets.only(bottom: 10.0),
                child: Text(
                  'History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              // Removed the Divider here
              Expanded(
                child: HistoryPage(
                  history: history,
                  onExpressionTap: (result) {
                    setState(() {
                      _inputController.text = result;
                      _inputController.selection =
                          TextSelection.collapsed(offset: result.length);
                      answer = '';
                      _animationController.reset();
                      _evaluateExpression();
                    });
                    Navigator.pop(modalContext);
                  },
                  onClear: () {
                    _clearHistory();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
