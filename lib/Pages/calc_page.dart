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

  String userInput = ''; // Keep for internal calculations
  String fakeUserInput = ''; // Display text
  bool isDeg = true;
  String answer = '';

  // Default text sizes
  double inputTextSize = 28.0;
  double answerTextSize = 28.0;

  // Keep track of cursor position
  int _cursorPosition = 0;

  final isDigit = RegExp(r'[0-9]$');

  //Handle Trig Fun
  final isTrigFun = RegExp(r'(sin|cos|tan)');

  //Handle Dots
  final isDot = RegExp(r'(\.)$');
  final isDotBetween = RegExp(r'(\.\d+)$');
  final isOperator = RegExp(r'([+*/%-])$');

  //Handle answer as it trims zero and shows the output initially
  final isDigitZero = RegExp(r'(\d+\.[1-9]0*)$');
  // final isOperator2 = RegExp(r'([+*/%-])');

  //Handle Zero
  final isOperatorZero = RegExp(r'(\d[+*/%-]0\d)$');
  final isFirstZero = RegExp(r'^0(\d+)$');

  // Handle Square Root
  final isSQRT = RegExp(r'√(\d+)');

  final isLog = RegExp(r'(log)|(ln)');

  final isOtherText = RegExp(r'(rad)|(deg)|(AC)|(ans)');

  // Add these variables
  final Map<String, double> variables = {'X': 0, 'Y': 0, 'A': 0, 'B': 0};
  ContextModel cm = ContextModel();

  final List<CalculationHistory> history = [];
  final int maxHistoryEntries = 100;

  // Cache for history operations
  static const _historyKey = 'calculator_history';

  // Add this list at the class level with the other variables
  final List<String> stringList = [
    'X',
    'Y',
    'deg',
    'hist', // Replaced 'B' with 'hist'
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
    '/',
    '!',
    '7',
    '8',
    '9',
    '\u00d7',
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

  // Add this regex pattern at class level with other patterns
  final hasNumber = RegExp(r'[\dπe]');
  final hasOperatorInMiddle = RegExp(r'[+\-*/×÷%]');
  final lastCharIsOperator = RegExp(r'[+\-*/×÷%]$');

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController(text: fakeUserInput);
    _inputController.addListener(() {
      _cursorPosition = _inputController.selection.baseOffset;
    });

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Create animations for text sizes
    _inputTextSizeAnimation = Tween<double>(
      begin: 32.0,
      end: 28.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _answerTextSizeAnimation = Tween<double>(
      begin: 28.0,
      end: 32.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _loadHistory();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);

    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        setState(() {
          history.addAll(jsonList
              .map((json) => CalculationHistory.fromJson(json))
              .toList());
        });
      } catch (e) {
        debugPrint('Error loading history: $e');
      }
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = history.map((entry) => entry.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  Future<void> _evaluateExpression() async {
    if (fakeUserInput.isEmpty) return;

    try {
      String tempInput = userInput;
      const double degToRad = pi / 180;

      // Handle degree to radian conversion for trig functions when isDeg is true
      if (isDeg) {
        tempInput = tempInput.replaceAllMapped(
          RegExp(r'(sin|cos|tan)\(([^)]+)\)'),
          (match) => '${match.group(1)}((${match.group(2)}) * $degToRad)',
        );
      }

      // Handle percentage calculations (e.g., "10 + 3%" means 10 + 3% of 10)
      tempInput = tempInput.replaceAllMapped(
          RegExp(r'(\d+\.?\d*)\s*([+-])\s*(\d+\.?\d*)\s*%'), (match) {
        double baseNumber = double.parse(match.group(1)!);
        String operator = match.group(2)!;
        double percentage = double.parse(match.group(3)!) / 100;
        double change = baseNumber * percentage;

        return operator == '+'
            ? (baseNumber + change).toString()
            : (baseNumber - change).toString();
      });

      // Handle regular modulo operations (e.g., 10%3 means 10 mod 3)
      tempInput = tempInput
          .replaceAllMapped(RegExp(r'(\d+\.?\d*)\s*%\s*(\d+\.?\d*)'), (match) {
        double a = double.parse(match.group(1)!);
        double b = double.parse(match.group(2)!);
        return (a % b).toString();
      });

      // Replace special characters with const values where possible
      const replacements = {
        'π': '$pi',
        'e': '$e',
        '\u00d7': '*',
      };

      for (final entry in replacements.entries) {
        tempInput = tempInput.replaceAll(entry.key, entry.value);
      }

      // Handle square root with more efficient pattern
      if (isSQRT.hasMatch(tempInput)) {
        tempInput = tempInput.replaceAllMapped(
          isSQRT,
          (match) => 'sqrt(${match.group(1)})',
        );
      }

      // Parse and evaluate expression with cached context
      final exp = GrammarParser().parse(tempInput);
      final result = exp.evaluate(EvaluationType.REAL, cm);

      // Format result more efficiently
      setState(() {
        answer = result == result.toInt()
            ? result.toInt().toString()
            : result.toString();

        // Clear answer if it's the same as input
        if (answer == fakeUserInput) {
          answer = '';
        }
      });
    } catch (e) {
      debugPrint('Evaluation error: $e');
      setState(() {
        answer = 'Error';
      });
    }
  }

  void buttonPressed(String buttonText) {
    setState(() {
      switch (buttonText) {
        case 'AC':
          _inputController.clear();
          fakeUserInput = '';
          userInput = '';
          answer = '';
          _animationController.reset();
          return;
        case '=':
          if (!lastCharIsOperator.hasMatch(fakeUserInput)) {
            _evaluateExpression().then((_) {
              if (answer.isNotEmpty &&
                  answer != "Error" &&
                  fakeUserInput.isNotEmpty) {
                addToHistory(fakeUserInput, answer);
                // Start the animation
                _animationController.forward().then((_) {
                  // After animation completes, reset input and keep answer visible
                  setState(() {
                    fakeUserInput = '';
                    userInput = '';
                  });
                });
              }
            });
          }
          return;
        case 'del':
          if (fakeUserInput.isNotEmpty) {
            final cursorPos = _inputController.selection.baseOffset;
            // If there's a valid cursor position and it's not at the start
            if (cursorPos > 0 && cursorPos <= fakeUserInput.length) {
              // Delete character before cursor and maintain cursor position
              fakeUserInput = fakeUserInput.substring(0, cursorPos - 1) +
                  fakeUserInput.substring(cursorPos);
              userInput = fakeUserInput;
              _inputController.value = TextEditingValue(
                text: fakeUserInput,
                selection: TextSelection.collapsed(offset: cursorPos - 1),
              );
            } else {
              // Fall back to deleting from the end
              fakeUserInput =
                  fakeUserInput.substring(0, fakeUserInput.length - 1);
              userInput = fakeUserInput;
              _inputController.value = TextEditingValue(
                text: fakeUserInput,
                selection:
                    TextSelection.collapsed(offset: fakeUserInput.length),
              );
            }
            if (!lastCharIsOperator.hasMatch(fakeUserInput)) {
              evaluate();
            } else {
              answer = '';
            }
          }
          return;
        case 'deg':
        case 'rad':
          isDeg = !isDeg;
          return;
        case 'hist':
          _showHistory(context);
          return;
      }

      // Reset animation when starting a new calculation
      if (_animationController.status == AnimationStatus.completed) {
        _animationController.reset();
      }

      String textToInsert = '';

      if (isTrigFun.hasMatch(buttonText)) {
        textToInsert = '$buttonText(';
      } else if (buttonText == "10ˣ") {
        textToInsert = "10^";
      } else if (buttonText == ".") {
        if (fakeUserInput.isEmpty ||
            isOperator.hasMatch(fakeUserInput[fakeUserInput.length - 1])) {
          textToInsert = "0.";
        } else if (!isDot.hasMatch(fakeUserInput) &&
            !isDotBetween.hasMatch(fakeUserInput)) {
          textToInsert = buttonText;
        }
      } else if (buttonText == "x²" && isDigit.hasMatch(fakeUserInput)) {
        textToInsert = "^2";
      } else if (buttonText == "x³" && isDigit.hasMatch(fakeUserInput)) {
        textToInsert = "^3";
      } else if (buttonText == "log") {
        textToInsert = "log(";
      } else if (buttonText == "ln") {
        textToInsert = "ln(";
      } else if (buttonText == '\u00d7' || isOperator.hasMatch(buttonText)) {
        if (fakeUserInput.isNotEmpty &&
            hasNumber.hasMatch(fakeUserInput) &&
            !lastCharIsOperator.hasMatch(fakeUserInput)) {
          textToInsert = buttonText == '\u00d7' ? '×' : buttonText;
        }
      } else if (variables.containsKey(buttonText)) {
        handleVariableInput(buttonText);
      } else {
        textToInsert = buttonText;
        if (fakeUserInput.isEmpty && buttonText == '0') {
          return; // Don't allow leading zeros
        }
      }

      if (textToInsert.isNotEmpty) {
        fakeUserInput = fakeUserInput + textToInsert;
        userInput = fakeUserInput;
        _inputController.value = TextEditingValue(
          text: fakeUserInput,
          selection: TextSelection.collapsed(offset: fakeUserInput.length),
        );
        evaluate();
      }
    });
  }

  void handleVariableInput(String varName) {
    if (answer.isNotEmpty && answer != "Error") {
      try {
        variables[varName] = double.parse(answer);
        answer = "$varName = ${variables[varName]}";
        fakeUserInput = '';
        userInput = '';
      } catch (e) {
        answer = "Error storing variable";
      }
    } else {
      fakeUserInput += varName;
      userInput = fakeUserInput;
    }
  }

  void evaluate() {
    userInput = fakeUserInput;
    // Only evaluate if we have a valid expression
    if (!lastCharIsOperator.hasMatch(fakeUserInput)) {
      _evaluateExpression();
    } else {
      // Clear answer when expression is incomplete
      setState(() {
        answer = '';
      });
    }
  }

  void addToHistory(String expr, String res) {
    if (res.isEmpty || res == "Error") return;

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

      _saveHistory(); // Save after each update
    });
  }

  Future<void> _clearHistory() async {
    setState(() {
      history.clear();
    });
    await _saveHistory();
  }

  // Memoized button colors
  final Map<String, Color?> _buttonColors = {
    'deg': Colors.blue[100],
    'rad': Colors.orange[100],
    'X': Colors.purple[100],
    'Y': Colors.teal[100],
    'A': Colors.indigo[100],
    'B': Colors.deepOrange[100],
    'hist': Colors.amber[100], // Added history button color
    'AC': const Color.fromARGB(255, 255, 200, 200), // Added AC button color
  };

  // Memoized text sizes
  final Map<String, double> _textSizes = {};

  double getButtonTextSize(String text) {
    return _textSizes.putIfAbsent(text, () {
      if (isDigit.hasMatch(text)) return 24;
      if (isDot.hasMatch(text)) return 25;
      return 22;
    });
  }

  Widget cupNewButton(String text, double btnsize) {
    // Get memoized colors with specific rules for different button types
    Color? buttonColor;

    // Check if it's a digit button (0-9)
    if (RegExp(r'^[0-9]$').hasMatch(text)) {
      buttonColor = Colors.white;
    }
    // Use existing colors for special buttons
    else if (_buttonColors.containsKey(text)) {
      buttonColor = _buttonColors[text];
    }
    // For other buttons, use off-white color
    else {
      buttonColor = const Color.fromARGB(255, 245, 245, 245);
    }

    final textColor = text == 'AC'
        ? const Color.fromARGB(255, 220, 0, 0)
        : const Color.fromARGB(255, 51, 51, 51);

    // Special case for history button
    if (text == 'hist') {
      return SizedBox(
        width: btnsize,
        child: CupertinoButton(
          onPressed: () => buttonPressed(text),
          padding: const EdgeInsets.symmetric(horizontal: 5),
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          color: buttonColor,
          child: const Icon(
            FluentIcons.history_24_regular,
            size: 24,
            color: Color.fromARGB(255, 51, 51, 51),
          ),
        ),
      );
    }

    return SizedBox(
      width: btnsize,
      child: CupertinoButton(
        onPressed: () => buttonPressed(text),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        color: buttonColor,
        child: Text(
          text,
          style: TextStyle(
            fontSize: getButtonTextSize(text),
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget delButton(double btnsize) {
    return SizedBox(
      width: btnsize,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => buttonPressed("del"),
        child: const Icon(
          FluentIcons.backspace_24_filled,
          size: 30,
          color: Color.fromARGB(255, 220, 0, 0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure TextEditingController is in sync with fakeUserInput
    if (_inputController.text != fakeUserInput) {
      _inputController.value = TextEditingValue(
        text: fakeUserInput,
        selection: TextSelection.collapsed(
            offset: _cursorPosition.clamp(0, fakeUserInput.length)),
      );
    }

    final scaffoldsize = MediaQuery.of(context).size;
    final layoutHeight = scaffoldsize.height - 40;
    final btnsize = scaffoldsize.width / 7;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Pro Calculator',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
            ),
          ),
        ),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[200],
      child: SizedBox(
        height: layoutHeight,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: <Widget>[
              // Display Screen with inverted colors
              Expanded(
                flex: 2,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) {
                    final RenderBox box =
                        context.findRenderObject() as RenderBox;
                    final localOffset =
                        box.globalToLocal(details.globalPosition);
                    // Get the height of this expanded section
                    final resultAreaHeight = box.size.height;
                    // Only process taps in the result area
                    if (localOffset.dy <= resultAreaHeight) {
                      setState(() {
                        _inputController.selection = TextSelection.collapsed(
                            offset: fakeUserInput.length);
                        _cursorPosition = fakeUserInput.length;
                      });
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // History entries with updated colors
                          ...history.take(2).map(
                                (entry) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5.0),
                                  child: Text(
                                    "${entry.expression} = ${entry.result}",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                          const Spacer(),
                          CupertinoTextField(
                            controller: _inputController,
                            style: TextStyle(
                              fontSize: _inputTextSizeAnimation.value,
                              letterSpacing: 0.89,
                              color: const Color.fromARGB(255, 51, 51, 51),
                            ),
                            textAlign: TextAlign.right,
                            showCursor: true,
                            readOnly: true,
                            enableInteractiveSelection: true,
                            decoration: null,
                            cursorColor: CupertinoColors.activeBlue,
                          ),
                          Text(
                            answer,
                            style: TextStyle(
                              fontSize: _answerTextSizeAnimation.value,
                              letterSpacing: 0.89,
                              color: const Color.fromARGB(255, 51, 51, 51),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Button Screen - Using ListView.builder for better performance
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 15.0),
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (stringList.length / 5)
                        .ceil(), // Calculate exact number of rows needed
                    itemBuilder: (context, rowIndex) {
                      return Padding(
                        padding: EdgeInsets.only(
                          top: rowIndex == 0 ? 0 : 4.0,
                          bottom: rowIndex == (stringList.length / 5).ceil() - 1
                              ? 0
                              : 4.0, // Remove padding from last row
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            5,
                            (columnIndex) {
                              final index = rowIndex * 5 + columnIndex;
                              if (index >= stringList.length) {
                                return const SizedBox.shrink();
                              }

                              final text = stringList[index];
                              if (text == 'deg') {
                                return cupNewButton(
                                    isDeg ? "deg" : "rad", btnsize);
                              }
                              if (text == 'del') {
                                return delButton(btnsize);
                              }
                              return cupNewButton(text, btnsize);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistory(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (modalContext) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
              height: 6,
              width: 40,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text(
                'History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: HistoryPage(
                history: history,
                onExpressionTap: (result) {
                  setState(() {
                    fakeUserInput = result;
                    userInput = result;
                    answer = '';
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
    );
  }
}
