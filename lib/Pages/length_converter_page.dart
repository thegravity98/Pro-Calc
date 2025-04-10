import 'package:flutter/cupertino.dart';
// Keep for Colors if needed, but prefer CupertinoColors
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class LengthConverterPage extends StatefulWidget {
  const LengthConverterPage({super.key});

  @override
  State<LengthConverterPage> createState() => _LengthConverterPageState();
}

class _LengthConverterPageState extends State<LengthConverterPage> {
  final TextEditingController _inputController = TextEditingController();
  String _fromUnit = 'Meters';
  String _toUnit = 'Kilometers';
  String _result = '';

  // Available units for conversion
  final List<String> _units = [
    'Meters',
    'Kilometers',
    'Centimeters',
    'Millimeters',
    'Miles',
    'Yards',
    'Feet',
    'Inches',
    'Nautical Miles'
  ];

  // Numpad buttons (excluding 'del' which is now a tall button)
  final List<String> digitButtons = [
    '7', '8', '9',
    '4', '5', '6',
    '1', '2', '3',
    '00', '0', '.', // Rearranged slightly for a 4x3 grid
  ];

  // Conversion rates based on 1 unit = X Meters
  // Using inverse for calculation clarity (Value / Rate = Meters)
  final Map<String, double> _conversionRatesFromMeters = {
    'Meters': 1.0,
    'Kilometers': 1000.0,
    'Centimeters': 0.01,
    'Millimeters': 0.001,
    'Miles': 1609.34,
    'Yards': 0.9144,
    'Feet': 0.3048,
    'Inches': 0.0254,
    'Nautical Miles': 1852.0,
  };

  @override
  void initState() {
    super.initState();
    // Add listener to convert automatically on text change
    _inputController.addListener(_convert);
  }

  @override
  void dispose() {
    _inputController.removeListener(_convert); // Clean up listener
    _inputController.dispose();
    super.dispose();
  }

  // --- Input & Conversion Logic ---

  void _handleDigitPress(String digit) {
    final selection = _inputController.selection;
    final cursorPos = selection.baseOffset >= 0
        ? selection.baseOffset
        : _inputController.text.length;

    if (digit == '.') {
      if (!_inputController.text.contains('.')) {
        // Insert '0.' if empty, otherwise just '.'
        final textToInsert = _inputController.text.isEmpty ? '0.' : '.';
        final newText = _inputController.text.substring(0, cursorPos) +
            textToInsert +
            _inputController.text.substring(cursorPos);
        _inputController.value = TextEditingValue(
          text: newText,
          selection:
              TextSelection.collapsed(offset: cursorPos + textToInsert.length),
        );
      }
    } else {
      // Insert digit at cursor position
      final newText = _inputController.text.substring(0, cursorPos) +
          digit +
          _inputController.text.substring(cursorPos);
      _inputController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursorPos + digit.length),
      );
    }
  }

  void _handleBackspace() {
    final selection = _inputController.selection;

    if (selection.isCollapsed) {
      // If cursor is not at the beginning, delete character before it
      if (selection.start > 0) {
        _inputController.value = _inputController.value.replaced(
          TextRange(start: selection.start - 1, end: selection.start),
          '',
        );
        // Move cursor back
        _inputController.selection =
            TextSelection.collapsed(offset: selection.start - 1);
      }
    } else {
      // If text is selected, delete the selection
      _inputController.value = _inputController.value.replaced(selection, '');
      _inputController.selection =
          TextSelection.collapsed(offset: selection.start);
    }
  }

  void _handleACPress() {
    _inputController.clear(); // Clears text and triggers listener -> _convert
    // setState(() { // No longer needed here as listener handles UI update
    //   _result = '';
    // });
  }

  void _convert() {
    final String inputText = _inputController.text;
    if (inputText.isEmpty || inputText == '0.') {
      // Handle empty or intermediate state
      if (_result.isNotEmpty) {
        // Clear result only if it had a value
        setState(() {
          _result = '';
        });
      }
      return;
    }

    try {
      final double inputValue = double.parse(inputText);
      // Convert input value from '_fromUnit' to Meters
      final double valueInMeters =
          inputValue * _conversionRatesFromMeters[_fromUnit]!;
      // Convert value in Meters to '_toUnit'
      final double convertedValue =
          valueInMeters / _conversionRatesFromMeters[_toUnit]!;

      // Use toStringAsFixed initially, then trim unnecessary trailing zeros/dots
      String formattedResult = convertedValue.toStringAsFixed(6);
      formattedResult = formattedResult.replaceAll(
          RegExp(r'0+$'), ''); // Remove trailing zeros
      formattedResult = formattedResult.replaceAll(
          RegExp(r'\.$'), ''); // Remove trailing dot if result is integer

      // Update state only if result changed to avoid unnecessary rebuilds
      if (_result != formattedResult) {
        setState(() {
          _result = formattedResult;
        });
      }
    } catch (e) {
      // Handle cases like "." or invalid intermediate states during typing
      if (_result != 'Invalid input') {
        // Update only if not already showing error
        setState(() {
          _result = 'Invalid input';
        });
      }
      debugPrint("Conversion Error: $e"); // Log error for debugging
    }
  }

  // --- UI Building ---

  Widget _buildDigitButton(String digit) {
    final scaffoldSize = MediaQuery.of(context).size;
    // Make buttons slightly wider relative to screen width
    final btnWidth = (scaffoldSize.width / 4.5).clamp(60.0, 80.0);
    final btnHeight = btnWidth * 0.7; // Adjust height ratio if needed

    const Color bgColor = CupertinoColors.white; // Standard digit background
    const Color fgColor = CupertinoColors.black; // Standard digit text color

    return Container(
      width: btnWidth,
      height: btnHeight,
      margin: EdgeInsets.all(btnWidth * 0.04), // Adjust margin based on width
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(btnWidth * 0.25), // Adjust radius
        color: bgColor, // Set color here for shadow effect
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 3,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(btnWidth * 0.25),
        // color: bgColor, // Color moved to Container for shadow
        onPressed: () => _handleDigitPress(digit),
        child: Text(
          digit,
          style: TextStyle(
            // Adjust font size based on button size
            fontSize: (digit.length > 1 ? btnHeight * 0.35 : btnHeight * 0.45),
            color: fgColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTallButton(String text,
      {required VoidCallback onPressed,
      bool isDelete = false,
      bool isAC = false}) {
    final scaffoldSize = MediaQuery.of(context).size;
    final btnWidth = (scaffoldSize.width / 4.5).clamp(60.0, 80.0);
    final digitBtnHeight = btnWidth * 0.7;
    final vMargin = btnWidth * 0.04;
    const rowGap = 8.0;

    // Adjust height calculation to account for proper spacing
    final double targetHeight = (digitBtnHeight * 2) + rowGap;

    final Color bgColor = isAC
        ? CupertinoColors.systemRed.withOpacity(0.8)
        : CupertinoColors.systemGrey5;
    final Color fgColor =
        isAC ? CupertinoColors.white : CupertinoColors.systemRed;

    return Container(
      width: btnWidth,
      height: targetHeight,
      margin: EdgeInsets.all(vMargin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(btnWidth * 0.25),
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 3,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(btnWidth * 0.25),
        onPressed: onPressed,
        child: isDelete
            ? Icon(
                FluentIcons.backspace_24_filled,
                size: btnWidth * 0.4,
                color: fgColor,
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: btnWidth * 0.35,
                  color: fgColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  // Helper to build rows of buttons
  Widget _buildButtonRow(List<String> buttons) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons.map(_buildDigitButton).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Length Converter'),
      ),
      backgroundColor:
          CupertinoColors.systemGroupedBackground, // Use themed background
      child: SafeArea(
        child: Column(
          children: [
            // --- Top Conversion Area ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Input Field
                    CupertinoTextField(
                      controller: _inputController,
                      placeholder: 'Enter value',
                      textAlign: TextAlign.right, // Align input text right
                      style: const TextStyle(fontSize: 24), // Larger font
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      readOnly: true, // Input only via custom numpad
                      showCursor: true, // Still show cursor
                      cursorColor: CupertinoColors.activeBlue,
                      decoration: BoxDecoration(
                        color: CupertinoColors
                            .tertiarySystemBackground, // Subtle background
                        border: Border.all(color: CupertinoColors.systemGrey4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                    const SizedBox(height: 16),

                    // Unit Pickers
                    Row(
                      children: [
                        _buildUnitPicker(isFromUnit: true), // From Unit
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: CupertinoButton(
                              // Swap Button
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                setState(() {
                                  final temp = _fromUnit;
                                  _fromUnit = _toUnit;
                                  _toUnit = temp;
                                  _convert(); // Re-convert after swap
                                });
                              }, minimumSize: const Size(0, 0),
                              child: const Icon(
                                CupertinoIcons.arrow_right_arrow_left_circle,
                                size: 28,
                                color: CupertinoColors.activeBlue,
                              )),
                        ),
                        _buildUnitPicker(isFromUnit: false), // To Unit
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Result Display
                    if (_result.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: CupertinoColors
                                .secondarySystemGroupedBackground, // Different background
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: CupertinoColors.systemGrey4)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Result',
                              style: TextStyle(
                                color: CupertinoColors.secondaryLabel,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              // Ensure result fits if very large
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                '$_result $_toUnit',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.label,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Spacer(), // Pushes numpad down if no result yet
                  ],
                ),
              ),
            ),

            // --- Numpad Area ---
            Container(
              color: CupertinoColors.systemGrey6, // Numpad background
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start, // Align tops
                children: [
                  // Left side: 3 columns of digit buttons (4 rows)
                  Expanded(
                    flex: 3, // Takes 3/4 of the width
                    child: Column(
                      children: [
                        _buildButtonRow(digitButtons.sublist(0, 3)), // 7, 8, 9
                        const SizedBox(height: rowGap),
                        _buildButtonRow(digitButtons.sublist(3, 6)), // 4, 5, 6
                        const SizedBox(height: rowGap),
                        _buildButtonRow(digitButtons.sublist(6, 9)), // 1, 2, 3
                        const SizedBox(height: rowGap),
                        _buildButtonRow(
                            digitButtons.sublist(9, 12)), // 00, 0, .
                      ],
                    ),
                  ),
                  // Right side: del and AC buttons (vertically aligned)
                  Expanded(
                    flex: 1, // Takes 1/4 of the width
                    child: Column(
                      children: [
                        _buildTallButton(
                          'del',
                          onPressed: _handleBackspace,
                          isDelete: true,
                        ),
                        const SizedBox(
                            height: rowGap), // Add consistent spacing
                        _buildTallButton(
                          'AC',
                          onPressed: _handleACPress,
                          isAC: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for Unit Pickers to reduce repetition
  Widget _buildUnitPicker({required bool isFromUnit}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isFromUnit ? 'From:' : 'To:',
              style: const TextStyle(
                  fontSize: 12, color: CupertinoColors.secondaryLabel)),
          const SizedBox(height: 4),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemBackground,
                border: Border.all(color: CupertinoColors.systemGrey4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    // Allow text to take space and ellipsis if needed
                    child: Text(
                      isFromUnit ? _fromUnit : _toUnit,
                      style: const TextStyle(color: CupertinoColors.label),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(CupertinoIcons.chevron_down,
                      size: 16, color: CupertinoColors.secondaryLabel),
                ],
              ),
            ),
            onPressed: () => _showUnitPicker(isFromUnit: isFromUnit),
          ),
        ],
      ),
    );
  }

  // Helper function to show the Action Sheet for unit selection
  void _showUnitPicker({required bool isFromUnit}) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: _units
            .map((unit) => CupertinoActionSheetAction(
                  onPressed: () {
                    setState(() {
                      if (isFromUnit) {
                        _fromUnit = unit;
                      } else {
                        _toUnit = unit;
                      }
                      _convert(); // Re-convert when unit changes
                    });
                    Navigator.pop(context);
                  },
                  child: Text(unit),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true, // Makes Cancel visually distinct
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

// Define the constant row gap used in layout
const double rowGap = 8.0;
