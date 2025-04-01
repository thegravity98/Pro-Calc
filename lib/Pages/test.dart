// if (isMOD.hasMatch(fakeUserInput)) {
//           String calculateSumFromString(String expression) {
//             // Split the expression into two parts based on the "+" sign
//             List<String> parts = expression.split(RegExp(r'([+-])'));
//             double sumValue = 0;
//             // print(parts);
//             // Extract the first number
//             double firstNumber = double.parse(parts[0]);
//             // Extract the second number, removing the "%" sign and dividing by 100
//             double secondNumber =
//                 double.parse(parts[1].substring(0, parts[1].length - 1)) / 100;
//             // Calculate the sum and format it with two decimal places
//             if (expression.contains("+")) {
//               sumValue = firstNumber + firstNumber * secondNumber;
//             }
//             if (expression.contains("-")) {
//               sumValue = firstNumber - firstNumber * secondNumber;
//             }
//             return sumValue.toStringAsFixed(2);
//           }

// // Example usage:
// // String expression = "9+5%";
//           answer = calculateSumFromString(fakeUserInput);
//           return;
//         }


// --- from here

// import 'dart:math';
// import 'package:fluentui_system_icons/fluentui_system_icons.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:function_tree/function_tree.dart';

// class CalcPage extends StatefulWidget {
//   const CalcPage({super.key});

//   @override
//   State<CalcPage> createState() => _CalcPageState();
// }

// class _CalcPageState extends State<CalcPage> {
//   String userInput = '';
//   String fakeUserInput = '';
//   bool isDeg = true;
//   String answer = '';

//   final isDigit = RegExp(r'[0-9]$');

//   //Handle Trig Fun
//   final isTrigFun = RegExp('(sin)|(sinr)|(cos)|(cosr)|(tan)|(tanr)');

//   //Handle Dots
//   final isDot = RegExp(r'(\.)$');
//   final isDotBetween = RegExp(r'(\.\d+)$');
//   final isOperator = RegExp(r'([+*/%-])$');

//   //Handle answer as it trims zero and shows the output initially
//   final isDigitZero = RegExp(r'(\d+\.[1-9]0*)$');
//   // final isOperator2 = RegExp(r'([+*/%-])');

//   //Handle Zero
//   final isOperatorZero = RegExp(r'(\d[+*/%-]0\d)$');
//   final isFirstZero = RegExp(r'^0(\d+)$');

//   // Handle Square Root
//   final isSQRT = RegExp(r'√(\d+)');

//   final isLog = RegExp(r'(log)|(ln)');

//   final isOtherText = RegExp(r'(rad)|(deg)|(AC)|(ans)');

//   Future<void> _evaluateExpression() async {
//     // print("user: $userInput");
//     userInput = userInput.replaceAll("%", "*0.01*");
//     userInput = userInput.replaceAll("π", pi.toString());
//     userInput = userInput.replaceAll("e", e.toString());

//     if (isSQRT.hasMatch(userInput)) {
//       userInput = userInput.replaceAllMapped(isSQRT, (match) {
//         final number = match.group(1);
//         return "sqrt($number)";
//       });
//     }

//     try {
//       answer = userInput.interpret().toString();
//       answer == userInput ? answer = "" : answer;
//     } catch (e) {
//       answer = e.toString();
//       // return;
//     }
//   }

//   // void evaluateExpression() {
//   //   Parser p = Parser();
//   //   Expression exp = p.parse(userInput);
//   //   ContextModel cm = ContextModel();
//   //   answer = exp.evaluate(EvaluationType.REAL, cm).toString();
//   // }
//   void buttonPressed(String buttonText) {
//     setState(() {
//       if (buttonText == 'AC') {
//         fakeUserInput = '';
//         userInput = fakeUserInput;
//         answer = '';
//       } else if (buttonText == 'del') {
//         if (fakeUserInput.isNotEmpty) {
//           fakeUserInput = fakeUserInput.substring(0, fakeUserInput.length - 1);
//           userInput = fakeUserInput;
//           answer = "";
//           // if (userInput.contains(isOperator2)) {
//           //   _evaluateExpression();
//           // }
//           _evaluateExpression();
//         } else {
//           //If string isEmpty and del is pressed, it throws error in debug so..
//           return;
//         }
//       } else if (buttonText == '=') {
//         //todo Add History Function
//         _evaluateExpression();
//       } else if (buttonText == 'deg' || buttonText == 'rad') {
//         isDeg = !isDeg;
//       } else if (isTrigFun.hasMatch(buttonText)) {
//         buttonText += "(";
//         fakeUserInput += buttonText;
//       } else if (buttonText == "10ˣ") {
//         buttonText = "10^";
//         fakeUserInput += buttonText;
//       } else if (buttonText == ".") {
//         if (fakeUserInput.isEmpty || isOperator.hasMatch(fakeUserInput)) {
//           buttonText = "0.";
//         }
//         if (isDot.hasMatch(fakeUserInput) ||
//             isDotBetween.hasMatch(fakeUserInput)) {
//           buttonText = "";
//         }
//         fakeUserInput += buttonText;
//       } else if (buttonText == "x²") {
//         if (isDigit.hasMatch(fakeUserInput)) {
//           fakeUserInput += "^2";
//         }
//         evaluate();
//       } else if (buttonText == "x³") {
//         if (isDigit.hasMatch(fakeUserInput)) {
//           fakeUserInput += "^3";
//         }
//         evaluate();
//       } else if (buttonText == "log") {
//         buttonText = "log(";
//         fakeUserInput += buttonText;
//       } else if (buttonText == "ln") {
//         buttonText = "ln(";
//         fakeUserInput += buttonText;
//       } else if (isOperator.hasMatch(buttonText)) {
//         if (fakeUserInput.isEmpty) {
//           return;
//         }
//         if (isDot.hasMatch(fakeUserInput)) {
//           return;
//         }
//         if (isOperator.hasMatch(fakeUserInput)) {
//           fakeUserInput = fakeUserInput.substring(0, fakeUserInput.length - 1);
//           fakeUserInput += buttonText;
//           return;
//         }
//         fakeUserInput += buttonText;
//       } else {
//         fakeUserInput += buttonText;

//         if (isFirstZero.hasMatch(fakeUserInput)) {
//           fakeUserInput = fakeUserInput.substring(1);
//         }
//         if (isOperatorZero.hasMatch(fakeUserInput)) {
//           fakeUserInput = fakeUserInput.substring(0, fakeUserInput.length - 2);
//           fakeUserInput += buttonText;
//         }

//         // userInput = fakeUserInput;
//         // if (userInput.contains(isOperator2)) {
//         //   _evaluateExpression();
//         // }
//         evaluate();
//       }
//     });
//   }

//   double getButtonTextSize(String text) {
//     if (isDigit.hasMatch(text)) {
//       return 22;
//     }
//     if (isDot.hasMatch(text)) {
//       return 25;
//     }
//     if (isLog.hasMatch(text) ||
//         isTrigFun.hasMatch(text) ||
//         isOtherText.hasMatch(text)) {
//       return 18;
//     }
//     return 20;
//   }

//   void evaluate() {
//     userInput = fakeUserInput;
//     // if (userInput.contains(isOperator2)) {
//     //   _evaluateExpression();
//     // }
//     _evaluateExpression();
//   }

// //Buttons List
//   final List<String> stringList = [
//     //Row 1
//     'sin',
//     'cos',
//     'tan',
//     'deg',
//     'AC',
//     'del',
//     //Row 2
//     'π',
//     'e',
//     '(',
//     ')',
//     '%',
//     '/',
//     //Row 3
//     'log',
//     '!',
//     '7',
//     '8',
//     '9',
//     '*',
//     //Row 4
//     'ln',
//     '^',
//     '4',
//     '5',
//     '6',
//     '-',
//     //Row 5
//     'x²',
//     '√',
//     '1',
//     '2',
//     '3',
//     '+',
//     //Row 6
//     'x³',
//     '10ˣ',
//     '.',
//     '0',
//     'ans',
//     '='
//   ];

//   @override
//   Widget build(BuildContext context) {
//     Size scaffoldsize = MediaQuery.of(context).size;
//     // Size of bottom Nav Bar is 40
//     double layoutHeight = scaffoldsize.height - 40;
//     double btnsize = scaffoldsize.width / 7.5;

//     return CupertinoPageScaffold(
//       child: SizedBox(
//         height: layoutHeight,
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           //Main Column
//           child: Column(
//             children: <Widget>[
//               //Display Screen
//               Expanded(
//                 flex: 3,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.blue[50],
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   width: double.infinity,
//                   child: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: [
//                         const Text("History Text #1"),
//                         const Text("This is text #2"),
//                         const Text("These also text #3"),
//                         Text(
//                           fakeUserInput,
//                           style: const TextStyle(
//                             fontSize: 24,
//                             letterSpacing: 0.89,
//                           ),
//                         ),
//                         Text(
//                           answer,
//                           style: const TextStyle(
//                             fontSize: 24,
//                             letterSpacing: 0.89,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               //Button Screen
//               Expanded(
//                 flex: 4,
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     children: List.generate(6, (rowIndex) {
//                       return Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: List.generate(
//                           6,
//                           (columnIndex) {
//                             final index = rowIndex * 6 + columnIndex;
//                             if (index == 0) {
//                               return isDeg
//                                   ? cupNewButton("sin", btnsize)
//                                   : cupNewButton("sinr", btnsize);
//                             }
//                             if (index == 1) {
//                               return isDeg
//                                   ? cupNewButton("cos", btnsize)
//                                   : cupNewButton("cosr", btnsize);
//                             }
//                             if (index == 2) {
//                               return isDeg
//                                   ? cupNewButton("tan", btnsize)
//                                   : cupNewButton("tanr", btnsize);
//                             }
//                             if (index == 3) {
//                               return isDeg
//                                   ? cupNewButton("rad", btnsize)
//                                   : cupNewButton("deg", btnsize);
//                             }
//                             if (index == 5) {
//                               return delButton(btnsize);
//                             }
//                             if (index == 17) {
//                               return multiplyButton(btnsize);
//                             }
//                             return cupNewButton(stringList[index], btnsize);
//                           },
//                         ),
//                       );
//                     }),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   SizedBox delButton(double btnsize) {
//     return SizedBox(
//       width: btnsize,
//       child: CupertinoButton(
//         padding: const EdgeInsets.all(0),
//         onPressed: () {
//           buttonPressed("del");
//         },
//         child: const Icon(
//           FluentIcons.backspace_24_filled,
//           size: 30,
//           color: Color.fromARGB(255, 220, 0, 0),
//         ),
//       ),
//     );
//   }

//   Container multiplyButton(double btnsize) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.grey[200],
//         borderRadius: BorderRadius.circular(20),
//       ),
//       width: btnsize,
//       child: CupertinoButton(
//         padding: const EdgeInsets.all(0),
//         onPressed: () {
//           buttonPressed("*");
//         },
//         child: const Icon(
//           FluentIcons.dismiss_24_filled,
//           size: 26,
//           color: Color.fromARGB(255, 0, 0, 0),
//         ),
//       ),
//     );
//   }

//   SizedBox cupNewButton(String text, double btnsize) {
//     return SizedBox(
//       width: btnsize,
//       child: CupertinoButton(
//         onPressed: () {
//           buttonPressed(text);
//         },
//         padding: const EdgeInsets.symmetric(horizontal: 5),
//         borderRadius: BorderRadius.circular(20),
//         color: Colors.grey[200],
//         child: Text(
//           text,
//           style: TextStyle(
//             fontSize: getButtonTextSize(text),
//             color: Colors.black,
//           ),
//         ),
//       ),
//     );
//   }
// }
