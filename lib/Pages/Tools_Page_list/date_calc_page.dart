// lib/pages/calculators/date_calc_page.dart
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

enum DateCalcMode { difference, addSubtract }

class DateCalcPage extends StatefulWidget {
  const DateCalcPage({super.key});

  @override
  State<DateCalcPage> createState() => _DateCalcPageState();
}

class _DateCalcPageState extends State<DateCalcPage> {
  DateCalcMode _currentMode = DateCalcMode.difference;

  // For Difference Mode
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now().add(const Duration(days: 30));

  // For Add/Subtract Mode
  DateTime _initialDate = DateTime.now();
  final TextEditingController _yearsController = TextEditingController(text: '0');
  final TextEditingController _monthsController = TextEditingController(text: '0');
  final TextEditingController _daysController = TextEditingController(text: '0');
  bool _isSubtract = false;

  String _resultText = '';

  final DateFormat _dateFormatter = DateFormat('EEE, MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _calculateResult(); // Initial calculation
  }

  @override
  void dispose() {
    _yearsController.dispose();
    _monthsController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  void _showDatePicker(BuildContext context,
      {required DateTime initialDate,
      required Function(DateTime) onDateChanged}) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: CupertinoTheme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                initialDateTime: initialDate,
                mode: CupertinoDatePickerMode.date,
                onDateTimeChanged: onDateChanged,
              ),
            ),
            CupertinoButton(
              child: const Text('Done'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      ),
    );
  }

  void _calculateResult() {
    setState(() {
      if (_currentMode == DateCalcMode.difference) {
        if (_toDate.isBefore(_fromDate)) {
          _resultText = 'Error: "To Date" must be after "From Date".';
          return;
        }
        Duration difference = _toDate.difference(_fromDate);
        int totalDays = difference.inDays;

        // Calculate years, months, days difference
        int years = _toDate.year - _fromDate.year;
        int months = _toDate.month - _fromDate.month;
        int days = _toDate.day - _fromDate.day;

        if (days < 0) {
          months--;
          // Get days in the previous month of _toDate
          DateTime prevMonth = DateTime(_toDate.year, _toDate.month, 0);
          days += prevMonth.day;
        }
        if (months < 0) {
          years--;
          months += 12;
        }
        _resultText =
            'Difference:\n$years Years, $months Months, $days Days\nTotal: $totalDays Days';
      } else {
        // Add/Subtract Mode
        int years = int.tryParse(_yearsController.text) ?? 0;
        int months = int.tryParse(_monthsController.text) ?? 0;
        int days = int.tryParse(_daysController.text) ?? 0;

        if (_isSubtract) {
          years = -years;
          months = -months;
          days = -days;
        }

        DateTime resultDate = DateTime(
          _initialDate.year + years,
          _initialDate.month + months,
          _initialDate.day + days,
        );
        _resultText = 'Result Date: ${_dateFormatter.format(resultDate)}';
      }
    });
  }

  Widget _buildDifferenceModeUI() {
    return Column(
      children: [
        _buildDateRow(
          label: 'From Date:',
          date: _fromDate,
          onTap: () => _showDatePicker(
            context,
            initialDate: _fromDate,
            onDateChanged: (newDate) {
              setState(() {
                _fromDate = newDate;
                _calculateResult();
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildDateRow(
          label: 'To Date:',
          date: _toDate,
          onTap: () => _showDatePicker(
            context,
            initialDate: _toDate,
            onDateChanged: (newDate) {
              setState(() {
                _toDate = newDate;
                _calculateResult();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddSubtractModeUI() {
    return Column(
      children: [
        _buildDateRow(
          label: 'Initial Date:',
          date: _initialDate,
          onTap: () => _showDatePicker(
            context,
            initialDate: _initialDate,
            onDateChanged: (newDate) {
              setState(() {
                _initialDate = newDate;
                _calculateResult();
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoSlidingSegmentedControl<bool>(
              groupValue: _isSubtract,
              children: const {
                false: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Add')),
                true: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Subtract')),
              },
              onValueChanged: (bool? newValue) {
                if (newValue != null) {
                  setState(() {
                    _isSubtract = newValue;
                    _calculateResult();
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDurationInputRow('Years:', _yearsController),
        _buildDurationInputRow('Months:', _monthsController),
        _buildDurationInputRow('Days:', _daysController),
      ],
    );
  }

  Widget _buildDateRow({required String label, required DateTime date, required VoidCallback onTap}) {
    return CupertinoListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Text(
          _dateFormatter.format(date),
          style: TextStyle(color: CupertinoTheme.of(context).primaryColor),
        ),
      ),
      backgroundColor: CupertinoTheme.of(context).barBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

   Widget _buildDurationInputRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          const SizedBox(width: 10),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).barBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CupertinoColors.systemGrey4, width: 0.5)
              ),
              onChanged: (_) => _calculateResult(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Date Calculator'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CupertinoSegmentedControl<DateCalcMode>(
                children: const {
                  DateCalcMode.difference: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8), child: Text('Difference')),
                  DateCalcMode.addSubtract: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8), child: Text('Add/Subtract')),
                },
                onValueChanged: (DateCalcMode? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _currentMode = newValue;
                      _calculateResult();
                    });
                  }
                },
                groupValue: _currentMode,
              ),
              const SizedBox(height: 24),
              if (_currentMode == DateCalcMode.difference)
                _buildDifferenceModeUI()
              else
                _buildAddSubtractModeUI(),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoTheme.of(context).brightness == Brightness.dark
                      ? CupertinoColors.darkBackgroundGray
                      : CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _resultText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}