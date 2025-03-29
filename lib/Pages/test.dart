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