import 'dart:math';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:function_tree/function_tree.dart';
import 'package:math_expressions/math_expressions.dart';
// import 'package:pro_calc/Pages/history_page.dart';

class CalcPage extends StatefulWidget {
  const CalcPage({super.key});

  @override
  State<CalcPage> createState() => _CalcPageState();
}

class _CalcPageState extends State<CalcPage> {
  String userInput = '';
  String fakeUserInput = '';
  bool isDeg = true;
  String answer = '';

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

  Future<void> _evaluateExpression() async {
    try {
      String tempInput = userInput;

      // Handle degree to radian conversion for trig functions when isDeg is true
      if (isDeg) {
        tempInput = tempInput.replaceAllMapped(
          RegExp(r'(sin|cos|tan)\(([^)]+)\)'),
          (match) {
            final func = match.group(1);
            final angle = match.group(2);
            // Convert degree to radian by multiplying with pi/180
            return '$func(($angle) * ${pi / 180})';
          },
        );
      }

      // Replace special characters
      tempInput = tempInput.replaceAll("%", "*0.01*");
      tempInput = tempInput.replaceAll("π", pi.toString());
      tempInput = tempInput.replaceAll("e", e.toString());
      tempInput = tempInput.replaceAll("\u00d7", "*");

      // Handle square root
      if (isSQRT.hasMatch(tempInput)) {
        tempInput = tempInput.replaceAllMapped(isSQRT, (match) {
          final number = match.group(1);
          return "sqrt($number)";
        });
      }

      // Create context and bind variables
      ContextModel cm = ContextModel();
      variables.forEach((key, value) {
        cm.bindVariable(Variable(key), Number(value));
      });

      // Parse and evaluate expression
      ExpressionParser p = GrammarParser();
      Expression exp = p.parse(tempInput);
      double result = exp.evaluate(EvaluationType.REAL, cm);

      // Format result
      if (result == result.toInt()) {
        answer = result.toInt().toString();
      } else {
        answer = result.toString();
      }

      // Clear answer if it's the same as input
      if (answer == userInput) {
        answer = "";
      }
    } catch (e) {
      print('Evaluation error: $e'); // For debugging
      answer = "Error";
    }
  }

  void buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'AC') {
        fakeUserInput = '';
        userInput = fakeUserInput;
        answer = '';
      } else if (buttonText == '=') {
        _evaluateExpression().then((_) {
          // Only add to history when equals is pressed and we have a valid result
          if (answer.isNotEmpty && answer != "Error" && userInput.isNotEmpty) {
            addToHistory(userInput, answer);
          }
        });
      } else {
        if (buttonText == 'del') {
          if (fakeUserInput.isNotEmpty) {
            fakeUserInput =
                fakeUserInput.substring(0, fakeUserInput.length - 1);
            userInput = fakeUserInput;
            answer = "";
            // if (userInput.contains(isOperator2)) {
            //   _evaluateExpression();
            // }
            _evaluateExpression();
          } else {
            //If string isEmpty and del is pressed, it throws error in debug so..
            return;
          }
        } else if (buttonText == 'deg' || buttonText == 'rad') {
          isDeg = !isDeg;
        } else if (isTrigFun.hasMatch(buttonText)) {
          buttonText += "(";
          fakeUserInput += buttonText;
        } else if (buttonText == "10ˣ") {
          buttonText = "10^";
          fakeUserInput += buttonText;
        } else if (buttonText == ".") {
          if (fakeUserInput.isEmpty || isOperator.hasMatch(fakeUserInput)) {
            buttonText = "0.";
          }
          if (isDot.hasMatch(fakeUserInput) ||
              isDotBetween.hasMatch(fakeUserInput)) {
            buttonText = "";
          }
          fakeUserInput += buttonText;
        } else if (buttonText == "x²") {
          if (isDigit.hasMatch(fakeUserInput)) {
            fakeUserInput += "^2";
          }
          evaluate();
        } else if (buttonText == "x³") {
          if (isDigit.hasMatch(fakeUserInput)) {
            fakeUserInput += "^3";
          }
          evaluate();
        } else if (buttonText == "log") {
          buttonText = "log(";
          fakeUserInput += buttonText;
        } else if (buttonText == "ln") {
          buttonText = "ln(";
          fakeUserInput += buttonText;
        } else if (isOperator.hasMatch(buttonText)) {
          if (fakeUserInput.isEmpty) {
            return;
          }
          if (isDot.hasMatch(fakeUserInput)) {
            return;
          }
          if (isOperator.hasMatch(fakeUserInput)) {
            fakeUserInput =
                fakeUserInput.substring(0, fakeUserInput.length - 1);
            fakeUserInput += buttonText;
            return;
          }
          fakeUserInput += buttonText;
        } else if (variables.containsKey(buttonText)) {
          if (answer.isNotEmpty && answer != "Error") {
            try {
              double value = double.parse(answer);
              variables[buttonText] = value;
              answer = "$buttonText = ${variables[buttonText]}";
              fakeUserInput = '';
              userInput = '';
            } catch (e) {
              answer = "Error storing variable";
            }
          } else {
            // Use the variable in expression
            fakeUserInput += buttonText;
            userInput = fakeUserInput;
          }
        } else {
          fakeUserInput += buttonText;

          if (isFirstZero.hasMatch(fakeUserInput)) {
            fakeUserInput = fakeUserInput.substring(1);
          }
          if (isOperatorZero.hasMatch(fakeUserInput)) {
            fakeUserInput =
                fakeUserInput.substring(0, fakeUserInput.length - 2);
            fakeUserInput += buttonText;
          }

          // userInput = fakeUserInput;
          // if (userInput.contains(isOperator2)) {
          //   _evaluateExpression();
          // }
          evaluate();
        }
      }
    });
  }

  double getButtonTextSize(String text) {
    if (isDigit.hasMatch(text)) {
      return 24;
    }
    if (isDot.hasMatch(text)) {
      return 25;
    }
    return 22;
  }

  void evaluate() {
    userInput = fakeUserInput;
    // if (userInput.contains(isOperator2)) {
    //   _evaluateExpression();
    // }
    _evaluateExpression();
  }

  void addToHistory(String expr, String res) {
    if (res.isEmpty || res == "Error") return;

    setState(() {
      history.insert(0, CalculationHistory(expression: expr, result: res));

      if (history.length > maxHistoryEntries) {
        history.removeLast();
      }
    });
  }

//Buttons List
  final List<String> stringList = [
    'X',
    'Y',
    'A',
    'B',
    'AC',

    'sin',
    'cos',
    'tan',
    'deg',
    'del',

    'π',
    '(',
    ')',
    '%',
    '/',

    '!',
    '7',
    '8',
    '9',
    '\u00d7',

    // 'ln',
    '^',
    '4',
    '5',
    '6',
    '-',
    //Row 5
    // 'x²',
    '√',
    '1',
    '2',
    '3',
    '+',
    //Row 6
    'log',
    '10ˣ',
    '.',
    '0',
    // 'ans',
    '=',
    //Row 7
  ];

  @override
  Widget build(BuildContext context) {
    Size scaffoldsize = MediaQuery.of(context).size;
    // Size of bottom Nav Bar is 40
    double layoutHeight = scaffoldsize.height - 40;
    double btnsize = scaffoldsize.width / 7;

    return CupertinoPageScaffold(
      child: SizedBox(
        height: layoutHeight,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          //Main Column
          child: Column(
            children: <Widget>[
              //Display Screen
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ...history.take(2).map(
                              (entry) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  "${entry.expression} = ${entry.result}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                        const Spacer(),
                        Text(
                          fakeUserInput,
                          style: const TextStyle(
                            fontSize: 24,
                            letterSpacing: 0.89,
                          ),
                        ),
                        Text(
                          answer,
                          style: const TextStyle(
                            fontSize: 24,
                            letterSpacing: 0.89,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              //Button Screen
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(7, (rowIndex) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          5,
                          (columnIndex) {
                            final index = rowIndex * 5 + columnIndex;
                            // if (index == 0) {
                            //   return cupNewButton("sin", btnsize);
                            // }
                            // if (index == 1) {
                            //   return cupNewButton("cos", btnsize);
                            // }
                            // if (index == 2) {
                            //   return cupNewButton("tan", btnsize);
                            // }
                            // if (index == 3) {
                            //   return cupNewButton(
                            //       isDeg ? "deg" : "rad", btnsize);
                            // }
                            // if (index == 4) {
                            //   return delButton(btnsize);
                            // }
                            if (stringList[index] == 'deg') {
                              return cupNewButton(
                                  isDeg ? "deg" : "rad", btnsize);
                            }
                            if (stringList[index] == 'del') {
                              return delButton(btnsize);
                            }
                            return cupNewButton(stringList[index], btnsize);
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SizedBox delButton(double btnsize) {
    return SizedBox(
      width: btnsize,
      child: CupertinoButton(
        padding: const EdgeInsets.all(0),
        onPressed: () {
          buttonPressed("del");
        },
        child: const Icon(
          FluentIcons.backspace_24_filled,
          size: 30,
          color: Color.fromARGB(255, 220, 0, 0),
        ),
      ),
    );
  }

  SizedBox cupNewButton(String text, double btnsize) {
    // Get the button color based on the text and current mode
    Color? buttonColor = Colors.grey[200];
    Color textColor = Colors.black;

    // Handle special button colors
    switch (text) {
      case "deg":
        buttonColor = Colors.blue[100];
        break;
      case "rad":
        buttonColor = Colors.orange[100];
        break;
      case "X":
        buttonColor = Colors.purple[100];
        break;
      case "Y":
        buttonColor = Colors.teal[100];
        break;
      case "A":
        buttonColor = Colors.indigo[100];
        break;
      case "B":
        buttonColor = Colors.deepOrange[100];
        break;
      case "AC":
        textColor = const Color.fromARGB(255, 220, 0, 0);
        break;
    }

    return SizedBox(
      width: btnsize,
      child: CupertinoButton(
        onPressed: () {
          buttonPressed(text);
        },
        padding: const EdgeInsets.symmetric(horizontal: 5),
        borderRadius: BorderRadius.circular(20),
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
}

class CalculationHistory {
  final String expression;
  final String result;

  CalculationHistory({required this.expression, required this.result});
}
