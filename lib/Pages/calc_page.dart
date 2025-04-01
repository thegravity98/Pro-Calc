import 'dart:math';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart'; // ADD this line

class CalcPage extends StatefulWidget {
  const CalcPage({super.key});

  @override
  State<CalcPage> createState() => _CalcPageState();
}

// --- Define Custom Functions for Degree Trigonometry ---
// We need these because math_expressions defaults to radians
double _degreesToRadians(double degrees) => degrees * pi / 180.0;

final Func sind = Func('sind', 1, (args) => sin(_degreesToRadians(args[0])));
final Func cosd = Func('cosd', 1, (args) => cos(_degreesToRadians(args[0])));
final Func tand = Func('tand', 1, (args) => tan(_degreesToRadians(args[0])));
// Add inverse functions if needed (e.g., asind, acosd, atand)
// final Func asind = Func('asind', 1, (args) => asin(args[0]) * 180.0 / pi);

// ---------------------------------------------------------

class _CalcPageState extends State<CalcPage> {
  String userInput = ''; // This will hold the expression to be evaluated
  String fakeUserInput = ''; // This is shown in the display as user types
  bool isDeg = true; // Tracks if the calculator is in Degree or Radian mode
  String answer = ''; // Stores the calculated answer or errors

  final isDigit = RegExp(r'[0-9]$');

  // Identify trig function buttons (used for display logic)
  // Note: 'sinr', 'cosr', 'tanr' are for display when in Radian mode
  final isTrigFun = RegExp('(sin)|(sinr)|(cos)|(cosr)|(tan)|(tanr)');

  //Handle Dots
  final isDot = RegExp(r'(\.)$');
  // Check if a number already contains a decimal point to prevent multiple dots
  final containsDot = RegExp(r'\d+\.\d*$'); // Checks if the last number has a dot
  final isOperator = RegExp(r'([+*/%^ -])$'); // Added ^ and space for clarity, ensure minus is last or escaped

  //Handle Zero - Prevents leading zeros like 05 -> 5, or 5+05 -> 5+5
  final isOperatorZero = RegExp(r'([+*/%^ -]0)$'); // Check for operator followed by 0
  final isFirstZero = RegExp(r'^0(\d)'); // Check for 0 at the very beginning

  final isLog = RegExp(r'(log)|(ln)');
  final isOtherText = RegExp(r'(rad)|(deg)|(AC)|(ans)');

  // Evaluate expression using math_expressions
  Future<void> _evaluateExpression() async {
    if (fakeUserInput.isEmpty) {
      setState(() {
        answer = '';
      });
      return;
    }

    // Use fakeUserInput as the base for evaluation
    String expressionToEvaluate = fakeUserInput;

    // --- Preprocessing for math_expressions ---
    expressionToEvaluate = expressionToEvaluate.replaceAll("π", pi.toString());
    expressionToEvaluate = expressionToEvaluate.replaceAll("e", e.toString());
    expressionToEvaluate = expressionToEvaluate.replaceAll("%", "/100"); // Use division for percentage

    // Replace display trig function names with evaluatable ones
    // math_expressions uses 'sin', 'cos', 'tan' for radians (default)
    // We use 'sind', 'cosd', 'tand' for degrees via custom functions
    if (isDeg) {
      // If in Degree mode, map 'sin(' to 'sind(' etc.
      expressionToEvaluate = expressionToEvaluate.replaceAll("sin(", "sind(");
      expressionToEvaluate = expressionToEvaluate.replaceAll("cos(", "cosd(");
      expressionToEvaluate = expressionToEvaluate.replaceAll("tan(", "tand(");
      // Add inverse replacements if needed (e.g., asin -> asind)
    } else {
      // If in Radian mode, the display might show 'sinr(', but evaluation needs 'sin('
      expressionToEvaluate = expressionToEvaluate.replaceAll("sinr(", "sin(");
      expressionToEvaluate = expressionToEvaluate.replaceAll("cosr(", "cos(");
      expressionToEvaluate = expressionToEvaluate.replaceAll("tanr(", "tan(");
       // Add inverse replacements if needed (e.g., asinr -> asin)
    }

     // Prevent evaluation if ending with an operator (causes parsing error)
     // Trim any trailing spaces that might interfere with the regex
    if (isOperator.hasMatch(expressionToEvaluate.trim())) {
      // Don't evaluate yet, maybe clear previous answer or just return
      // setState(() => answer = ''); // Option: clear answer preview
      return;
    }
    // -------------------------------------------

    try {
      Parser p = Parser();
      Expression exp = p.parse(expressionToEvaluate);
      ContextModel cm = ContextModel();

      // Bind custom degree functions if Degree mode is active
      // Standard radian functions are built-in
      if (isDeg) {
        cm.bindFunction(sind);
        cm.bindFunction(cosd);
        cm.bindFunction(tand);
        // Bind inverse degree functions if implemented
      }

      // Bind built-in constants/functions if needed (many are default)
      // cm.bindVariableName('pi', Number(pi)); // pi is usually built-in
      // cm.bindVariableName('e', Number(e));   // e is usually built-in
      cm.bindFunction(Log(MathFunction.ln, 1)); // Bind ln if needed
      cm.bindFunction(Log(MathFunction.log, 1)); // Bind log (base 10) if needed - check docs
      cm.bindFunction(Sqrt(MathFunction.sqrt, 1)); // Bind sqrt


      double result = exp.evaluate(EvaluationType.REAL, cm);

      // Format the result nicely
      String formattedResult = result.toString();
      if (formattedResult.endsWith('.0')) {
        formattedResult = formattedResult.substring(0, formattedResult.length - 2);
      }
       // Handle very small/large numbers if needed (exponential notation)
      // if (result.abs() < 1e-10 || result.abs() > 1e12) {
      //   formattedResult = result.toStringAsExponential(5);
      // }

      setState(() {
        // Don't show the result if it's identical to the input (e.g., user typed just "5")
        // This check might be too simple, consider edge cases.
        // Maybe only update answer if an actual calculation happened?
        // Or always show the evaluated result. For now, let's always show it.
        answer = formattedResult;
        userInput = expressionToEvaluate; // Update the evaluatable expression state
      });

    } catch (e) {
      // print("Evaluation Error: $e"); // For debugging
      // print("Expression causing error: $expressionToEvaluate"); // For debugging
      setState(() {
        answer = 'Error'; // Show error to the user
      });
    }
  }


  void buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'AC') {
        fakeUserInput = '';
        userInput = '';
        answer = '';
      } else if (buttonText == 'del') {
        if (fakeUserInput.isNotEmpty) {
          fakeUserInput = fakeUserInput.substring(0, fakeUserInput.length - 1);
          // Optionally, re-evaluate after delete if you want immediate feedback
          // Be cautious as deleting might leave an invalid expression (e.g., "5+")
           _evaluateExpression(); // Evaluate after deleting
        }
         // No return needed here, state will update UI
      } else if (buttonText == '=') {
         _evaluateExpression(); // Final evaluation on '='
         // TODO: Add History Functionality here if needed
         // Store 'userInput' and 'answer'
      } else if (buttonText == 'deg' || buttonText == 'rad') {
        isDeg = !isDeg;
        // Re-evaluate if the mode changes, as trig results will differ
        _evaluateExpression();
      }
      // --- Input Handling ---
      else if (isTrigFun.hasMatch(buttonText)) {
        // Append the correct function name based on the button *display text*
        // The actual evaluation mapping (e.g., sin -> sind) happens in _evaluateExpression
        fakeUserInput += "$buttonText(";
      } else if (buttonText == "10ˣ") {
        fakeUserInput += "10^";
      } else if (buttonText == ".") {
         // Prevent dot if input is empty or ends with operator/opening parenthesis
         if (fakeUserInput.isEmpty || isOperator.hasMatch(fakeUserInput) || fakeUserInput.endsWith('(')) {
             fakeUserInput += "0."; // Start with "0."
         } else {
             // Check if the *last number segment* already has a dot
             final segments = fakeUserInput.split(RegExp(r'[+*/%^() -]')); // Split by operators/parentheses
             if (segments.isNotEmpty && !segments.last.contains('.')) {
                 fakeUserInput += ".";
             }
             // Else: do nothing, prevent multiple dots in one number
         }
      } else if (buttonText == "x²") {
        // Append power operator, assumes something valid precedes it
        if (fakeUserInput.isNotEmpty && !isOperator.hasMatch(fakeUserInput) && !fakeUserInput.endsWith('(')) {
           fakeUserInput += "^2";
           _evaluateExpression(); // Evaluate immediately
        }
      } else if (buttonText == "x³") {
         if (fakeUserInput.isNotEmpty && !isOperator.hasMatch(fakeUserInput) && !fakeUserInput.endsWith('(')) {
            fakeUserInput += "^3";
            _evaluateExpression(); // Evaluate immediately
         }
      } else if (buttonText == "√") {
         fakeUserInput += "sqrt("; // Use 'sqrt(' directly
      }
       else if (buttonText == "log") {
         fakeUserInput += "log("; // Assumes base 10, ensure math_expressions handles log(x) as base 10
      } else if (buttonText == "ln") {
         fakeUserInput += "ln("; // Natural log
      }
      else if (isOperator.hasMatch(buttonText) || buttonText == '^' || buttonText == '(' || buttonText == ')') {
         // Handle Operators, Exponent, Parentheses
         if (buttonText == '(' && fakeUserInput.isNotEmpty && (isDigit.hasMatch(fakeUserInput) || fakeUserInput.endsWith(')'))) {
            // Implicit multiplication: 5( -> 5*( , (3+4)( -> (3+4)*(
            fakeUserInput += "*(";
         } else if (isOperator.hasMatch(buttonText)) {
             // Prevent adding operator if input is empty or ends with '('
             if (fakeUserInput.isEmpty && buttonText != '-') { // Allow starting with minus
                 return;
             }
             if (fakeUserInput.endsWith('(') && buttonText != '-') { // Allow '(' followed by minus
                return;
             }
             // Replace last operator if another operator is pressed (e.g., 5+* -> 5*)
             if (isOperator.hasMatch(fakeUserInput)) {
                 fakeUserInput = fakeUserInput.substring(0, fakeUserInput.length - 1);
             }
             fakeUserInput += buttonText;
         }
          else {
             // Just append for other cases like '^', ')', or '(' at start/after operator
             fakeUserInput += buttonText;
         }

      } else if (buttonText == '!') {
          // Factorial: Append '!' - math_expressions handles this
          if (fakeUserInput.isNotEmpty && (isDigit.hasMatch(fakeUserInput) || fakeUserInput.endsWith(')'))) {
             fakeUserInput += buttonText;
             _evaluateExpression(); // Evaluate factorial immediately if desired
          }
      }
      else { // Likely a digit, pi, e, or 'ans'
        // Handle 'ans' button - replace 'ans' with the last valid answer
         if (buttonText == 'ans') {
            // Ensure 'answer' is a valid number string before inserting
            if (answer.isNotEmpty && double.tryParse(answer) != null) {
               // Handle implicit multiplication if needed: 5ans -> 5*ansValue
               if (fakeUserInput.isNotEmpty && (isDigit.hasMatch(fakeUserInput) || fakeUserInput.endsWith(')') || fakeUserInput.endsWith('!'))) {
                  fakeUserInput += "*${answer}";
               } else {
                 fakeUserInput += answer;
               }
            }
         }
         // Handle implicit multiplication: )digit -> )*digit, πdigit -> π*digit, edigit -> e*digit
         else if (fakeUserInput.isNotEmpty && (fakeUserInput.endsWith(')') || fakeUserInput.endsWith('π') || fakeUserInput.endsWith('e') || fakeUserInput.endsWith('!'))) {
            fakeUserInput += "*$buttonText";
         }
          // Prevent leading zeros (05 -> 5) and operator-followed zeros (5+05 -> 5+5)
         else if (buttonText == '0' && fakeUserInput.isNotEmpty && isOperatorZero.hasMatch(fakeUserInput)) {
             // Do nothing, prevents 5 + 00
         } else if (buttonText != '0' && fakeUserInput.isNotEmpty && isOperatorZero.hasMatch(fakeUserInput)) {
             // Replace the trailing 0: 5 + 0 -> 5 + (new digit)
             fakeUserInput = fakeUserInput.substring(0, fakeUserInput.length - 1) + buttonText;
         } else if (buttonText != '0' && fakeUserInput == '0') {
              // Replace initial 0: 0 -> (new digit)
              fakeUserInput = buttonText;
         }
         else {
             // Default: just append digit/constant
             fakeUserInput += buttonText;
         }

        // --- Live Evaluation (Optional) ---
        // Decide if you want the 'answer' to update as the user types valid intermediate expressions.
        // Can be computationally intensive and might show intermediate errors.
        // Only evaluating on '=', 'x²', 'x³', '!', 'del', mode change might be sufficient.
         _evaluateExpression(); // Evaluate after appending digit/constant etc.
         //------------------------------------
      }
    });
  }


  // Determine button text size (remains the same)
  double getButtonTextSize(String text) {
    // Simplified this slightly, adjust numbers as needed
    if (isDigit.hasMatch(text) || text == '.') return 24;
    if (isLog.hasMatch(text) || isTrigFun.hasMatch(text) || isOtherText.hasMatch(text)) return 18;
    if (text == 'π' || text == 'e' || text == '√' || text == '^' || text == '!') return 20;
    // Default for operators etc.
    return 22;
  }

  // Removed the separate evaluate() function, using _evaluateExpression directly

  // Buttons List (Added '!' and adjusted based on logic changes)
  final List<String> stringList = [
    //Row 1
    'sin', // Base name, display adapts
    'cos', // Base name, display adapts
    'tan', // Base name, display adapts
    'deg', // Toggles isDeg, display adapts
    'AC',
    'del',
    //Row 2
    'π',
    'e',
    '(',
    ')',
    '%',
    '/',
    //Row 3
    'log', // Assumes base 10
    '!',   // Factorial
    '7',
    '8',
    '9',
    '*',
    //Row 4
    'ln', // Natural log
    '^',  // Power
    '4',
    '5',
    '6',
    '-',
    //Row 5
    'x²', // Shortcut for ^2
    '√',  // Square root function
    '1',
    '2',
    '3',
    '+',
    //Row 6
    'x³', // Shortcut for ^3
    '10ˣ', // Shortcut for 10^
    '.',
    '0',
    'ans', // Use last answer
    '='
  ];

  @override
  Widget build(BuildContext context) {
    Size scaffoldsize = MediaQuery.of(context).size;
    double layoutHeight = scaffoldsize.height - (Scaffold.of(context).appBarMaxHeight ?? 0) - kBottomNavigationBarHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom ; // Adjust for potential AppBar and padding
     // Ensure layoutHeight is not negative
    layoutHeight = layoutHeight > 0 ? layoutHeight : MediaQuery.of(context).size.height * 0.8; // Fallback height

    double displayHeight = layoutHeight * (3 / 7); // 3 parts for display
    double buttonAreaHeight = layoutHeight * (4 / 7); // 4 parts for buttons

    // Calculate button size based on available width
    double totalHorizontalPadding = 16.0; // padding L+R in Button Screen Padding
    double availableWidth = scaffoldsize.width - totalHorizontalPadding;
    int buttonsPerRow = 6;
    double buttonSpacing = 8.0; // Estimated spacing between buttons
    double btnsize = (availableWidth - (buttonSpacing * (buttonsPerRow -1))) / buttonsPerRow;
    // Ensure btnsize is positive
    btnsize = btnsize > 10 ? btnsize : 50; // Minimum button size fallback


    return CupertinoPageScaffold(
      // navigationBar: CupertinoNavigationBar( // Optional: Add a nav bar if needed
      //   middle: Text('Calculator'),
      // ),
      child: SafeArea( // Use SafeArea to avoid OS intrusions
        child: SizedBox(
          height: layoutHeight, // Use calculated height
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Consistent padding
            child: Column(
              children: <Widget>[
                //Display Screen
                Container(
                   height: displayHeight, // Assign calculated height
                   width: double.infinity,
                   decoration: BoxDecoration(
                    // color: Colors.grey[100], // Lighter background
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0), // Increased padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end, // Align text to bottom
                      children: [
                        // TODO: Implement History Display (e.g., using a ListView)
                        // Expanded(
                        //   child: ListView(
                        //     reverse: true, // Show latest history first
                        //     children: [ /* History items */ ],
                        //   ),
                        // ),
                        // SingleChildScrollView for User Input to allow scrolling if long
                         SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true, // Keeps end of input visible
                          child: Text(
                            fakeUserInput.isEmpty ? '0' : fakeUserInput, // Show 0 if empty
                            style: TextStyle(
                              fontSize: fakeUserInput.length > 20 ? 28 : 36, // Adjust size based on length
                              color: Colors.black87,
                              letterSpacing: 0.89,
                            ),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 10), // Spacing
                        // Answer Display
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                           reverse: true, // Keeps end of answer visible
                          child: Text(
                            answer,
                            style: TextStyle(
                              fontSize: answer.length > 15 ? 30: 40, // Adjust size
                              fontWeight: FontWeight.bold, // Make answer prominent
                              color: answer == 'Error' ? Colors.red : Colors.black, // Error color
                              letterSpacing: 0.89,
                            ),
                             textAlign: TextAlign.end,
                             maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Spacer between display and buttons
                // const SizedBox(height: 10),

                //Button Screen
                Container(
                   height: buttonAreaHeight, // Assign calculated height
                   padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0), // Padding for button area
                   child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute rows evenly
                    children: List.generate(6, (rowIndex) {
                      return Flexible( // Allow rows to share space
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            6,
                            (columnIndex) {
                              final index = rowIndex * 6 + columnIndex;
                              String buttonText = stringList[index];
                              Widget buttonWidget;

                              // --- Dynamic Button Display ---
                              if (index == 0) { // Sin button
                                buttonWidget = cupNewButton(isDeg ? "sin" : "sinr", btnsize);
                              } else if (index == 1) { // Cos button
                                buttonWidget = cupNewButton(isDeg ? "cos" : "cosr", btnsize);
                              } else if (index == 2) { // Tan button
                                buttonWidget = cupNewButton(isDeg ? "tan" : "tanr", btnsize);
                              } else if (index == 3) { // Deg/Rad toggle button
                                buttonWidget = cupNewButton(isDeg ? "Rad" : "deg", btnsize, isModeToggle: true); // Pass toggle flag
                              } else if (index == 5) { // Delete button
                                buttonWidget = delButton(btnsize);
                              } else if (index == 17) { // Multiply Button (using custom icon)
                                buttonWidget = multiplyButton(btnsize);
                              }
                              // Add other special button cases if needed (like '=')
                               else if (index == 35) { // Equals button styling
                                buttonWidget = cupNewButton(buttonText, btnsize, isEqualButton: true);
                              }
                              else { // Standard button
                                buttonWidget = cupNewButton(buttonText, btnsize);
                              }
                              // -----------------------------

                              // Add horizontal spacing between buttons within a row
                              return Padding(
                                padding: EdgeInsets.only(left: columnIndex == 0 ? 0 : buttonSpacing / 2, right: columnIndex == buttonsPerRow -1 ? 0: buttonSpacing / 2), // Add spacing
                                child: buttonWidget,
                              );

                            },
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Button Widgets ---

  // Generic Button
  Widget cupNewButton(String text, double btnsize, {bool isEqualButton = false, bool isModeToggle = false}) {
    Color buttonColor = Colors.grey[200]!; // Default
    Color textColor = Colors.black;

    if (isEqualButton) {
      buttonColor = Colors.blue; // Make equals button stand out
      textColor = Colors.white;
    } else if (isOperator.hasMatch(text) || text == '/' || text == '^' || text == '%') {
      buttonColor = Colors.orangeAccent; // Color for operators
      textColor = Colors.white;
    } else if (text == 'AC' || text == 'del') {
       buttonColor = Colors.redAccent.withOpacity(0.8);
       textColor = Colors.white;
    } else if (isModeToggle || text == 'ln' || text == 'log' || text == '!' || isTrigFun.hasMatch(text) || text=='√' || text=='x²' || text=='x³' || text=='10ˣ') {
       buttonColor = Colors.grey[400]!; // Slightly darker grey for functions
    }


    return SizedBox(
      width: btnsize,
      height: btnsize * 0.8, // Make buttons slightly less tall than wide
      child: CupertinoButton(
        onPressed: () {
          buttonPressed(text);
        },
        padding: const EdgeInsets.all(0), // Let SizedBox control size
        borderRadius: BorderRadius.circular(btnsize / 2), // Circular buttons
        color: buttonColor,
        child: Center( // Center the text
          child: Text(
            text,
            style: TextStyle(
              fontSize: getButtonTextSize(text),
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }


  // Delete Button (Specific Styling)
  Widget delButton(double btnsize) {
    return SizedBox(
      width: btnsize,
      height: btnsize * 0.8,
      child: CupertinoButton(
        padding: const EdgeInsets.all(0),
         borderRadius: BorderRadius.circular(btnsize / 2),
         color: Colors.redAccent.withOpacity(0.8),
        onPressed: () {
          buttonPressed("del");
        },
        child: const Icon(
          // FluentIcons.backspace_24_regular, // Or filled
          CupertinoIcons.delete_left, // Using Cupertino icon
          size: 28, // Adjust size as needed
          color: Colors.white,
        ),
      ),
    );
  }

  // Multiply Button (Specific Styling/Icon)
  Widget multiplyButton(double btnsize) {
     return SizedBox(
      width: btnsize,
      height: btnsize * 0.8,
      child: CupertinoButton(
        onPressed: () {
          buttonPressed("*");
        },
        padding: const EdgeInsets.all(0),
        borderRadius: BorderRadius.circular(btnsize / 2),
        color: Colors.orangeAccent, // Operator color
        child: const Center(
          child: Icon(
           // FluentIcons.dismiss_24_regular, // Alternative icon
            CupertinoIcons.multiply,
            size: 26,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}