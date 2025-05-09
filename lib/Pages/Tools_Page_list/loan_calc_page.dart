// lib/pages/calculators/loan_calc_page.dart
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';

enum LoanTermUnit { years, months }

class LoanCalcPage extends StatefulWidget {
  const LoanCalcPage({super.key});

  @override
  State<LoanCalcPage> createState() => _LoanCalcPageState();
}

class _LoanCalcPageState extends State<LoanCalcPage> {
  final TextEditingController _principalController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _termController = TextEditingController();

  LoanTermUnit _termUnit = LoanTermUnit.years;

  String _emiResult = '';
  String _totalInterestResult = '';
  String _totalPaymentResult = '';

  final NumberFormat _currencyFormatter = NumberFormat.currency(symbol: '', decimalDigits: 2); // Adjust symbol as needed
  final NumberFormat _numberFormatter = NumberFormat.decimalPattern();


  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _termController.dispose();
    super.dispose();
  }

  void _calculateLoan() {
    final double principal = double.tryParse(_principalController.text.replaceAll(',', '')) ?? 0;
    final double annualRate = double.tryParse(_rateController.text) ?? 0;
    final int term = int.tryParse(_termController.text) ?? 0;

    if (principal <= 0 || annualRate <= 0 || term <= 0) {
      setState(() {
        _emiResult = '';
        _totalInterestResult = '';
        _totalPaymentResult = 'Please enter valid inputs.';
      });
      return;
    }

    double monthlyRate = (annualRate / 100) / 12;
    int numberOfMonths = _termUnit == LoanTermUnit.years ? term * 12 : term;

    if (numberOfMonths == 0) {
       setState(() {
        _emiResult = '';
        _totalInterestResult = '';
        _totalPaymentResult = 'Term cannot be zero.';
      });
      return;
    }

    double emi;
    if (monthlyRate == 0) { // Edge case for 0% interest
        emi = principal / numberOfMonths;
    } else {
        emi = (principal * monthlyRate * math.pow(1 + monthlyRate, numberOfMonths)) /
              (math.pow(1 + monthlyRate, numberOfMonths) - 1);
    }


    double totalPayment = emi * numberOfMonths;
    double totalInterest = totalPayment - principal;

    setState(() {
      _emiResult = 'EMI: ${_currencyFormatter.format(emi)}';
      _totalInterestResult = 'Total Interest: ${_currencyFormatter.format(totalInterest)}';
      _totalPaymentResult = 'Total Payment: ${_currencyFormatter.format(totalPayment)}';
    });
  }

  Widget _buildInputRow(String label, TextEditingController controller, {String? placeholder, String? suffix}) {
     final currentTheme = CupertinoTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          const SizedBox(width: 10),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: currentTheme.barBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CupertinoColors.systemGrey4, width: 0.5)
              ),
              onChanged: (_) => _calculateLoan(),
            ),
          ),
          if (suffix != null) ...[
            const SizedBox(width: 8),
            Text(suffix, style: TextStyle(color: currentTheme.textTheme.tabLabelTextStyle.color?.withOpacity(0.7))),
          ]
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final currentTheme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Loan Calculator'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildInputRow('Loan Amount:', _principalController, placeholder: 'e.g., 100000'),
              _buildInputRow('Annual Interest Rate:', _rateController, placeholder: 'e.g., 5.5', suffix: '%'),
              _buildInputRow('Loan Term:', _termController, placeholder: 'e.g., 10'),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Term Unit:', style: TextStyle(color: currentTheme.textTheme.tabLabelTextStyle.color?.withOpacity(0.7))),
                  const SizedBox(width: 8),
                  CupertinoSlidingSegmentedControl<LoanTermUnit>(
                    groupValue: _termUnit,
                    children: const {
                      LoanTermUnit.years: Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Text('Years')),
                      LoanTermUnit.months: Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Text('Months')),
                    },
                    onValueChanged: (LoanTermUnit? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _termUnit = newValue;
                          _calculateLoan();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Calculate Button (optional, as it calculates on change)
              // CupertinoButton.filled(
              //   onPressed: _calculateLoan,
              //   child: const Text('Calculate'),
              // ),
              // const SizedBox(height: 24),
              if (_emiResult.isNotEmpty || _totalInterestResult.isNotEmpty || _totalPaymentResult.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: currentTheme.brightness == Brightness.dark
                        ? CupertinoColors.darkBackgroundGray
                        : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       if (_emiResult.isNotEmpty) Text(_emiResult, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                       if (_emiResult.isNotEmpty) const SizedBox(height: 8),
                       if (_totalInterestResult.isNotEmpty) Text(_totalInterestResult, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                       if (_totalInterestResult.isNotEmpty) const SizedBox(height: 8),
                       if (_totalPaymentResult.isNotEmpty) Text(_totalPaymentResult, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    ],
                  )
                ),
            ],
          ),
        ),
      ),
    );
  }
}