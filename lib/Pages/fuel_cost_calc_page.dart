// lib/pages/calculators/fuel_cost_calc_page.dart
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

// For more complex unit handling, consider dedicated enums and conversion factors
// enum DistanceUnit { km, miles }
// enum VolumeUnit { liters, gallonsUS, gallonsImperial }
// enum EfficiencyUnit { kmPerLiter, litersPer100Km, mpgUS, mpgImperial }

class FuelCostCalcPage extends StatefulWidget {
  const FuelCostCalcPage({super.key});

  @override
  State<FuelCostCalcPage> createState() => _FuelCostCalcPageState();
}

class _FuelCostCalcPageState extends State<FuelCostCalcPage> {
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _efficiencyController =
      TextEditingController(); // Assuming km/L
  final TextEditingController _priceController =
      TextEditingController(); // Assuming price per Liter

  // Basic unit labels for now
  final String _distanceUnitLabel = "km";
  final String _efficiencyUnitLabel = "km/L";
  final String _priceUnitLabel = "/L";
  final String _volumeUnitLabel = "Liters";

  String _totalFuelNeededResult = '';
  String _totalCostResult = '';
  String _calculationMessage = 'Enter all values to calculate fuel cost.';

  final NumberFormat _decimalFormatter =
      NumberFormat.decimalPatternDigits(decimalDigits: 2);
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2); // Adjust symbol

  @override
  void dispose() {
    _distanceController.dispose();
    _efficiencyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _calculateFuelCost() {
    final double distance =
        double.tryParse(_distanceController.text.replaceAll(',', '')) ?? 0;
    final double efficiency =
        double.tryParse(_efficiencyController.text.replaceAll(',', '')) ??
            0; // km/L
    final double pricePerLiter =
        double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;

    if (distance <= 0 || efficiency <= 0 || pricePerLiter <= 0) {
      setState(() {
        _totalFuelNeededResult = '';
        _totalCostResult = '';
        _calculationMessage =
            'Please enter valid positive values for all fields.';
      });
      return;
    }

    // --- Basic Calculation (assuming km, km/L, price/L) ---
    // For a real app, you'd implement unit conversions here based on selected units.
    // Example: if distance is in miles, convert to km: distanceInKm = distanceInMiles * 1.60934;
    // Example: if efficiency is MPG, convert to km/L: efficiencyInKmL = efficiencyMPG * 0.425144;

    double totalFuelNeeded = distance / efficiency; // Liters
    double totalCost = totalFuelNeeded * pricePerLiter;

    setState(() {
      _totalFuelNeededResult =
          'Total Fuel: ${_decimalFormatter.format(totalFuelNeeded)} $_volumeUnitLabel';
      _totalCostResult = 'Total Cost: ${_currencyFormatter.format(totalCost)}';
      _calculationMessage = 'Estimated fuel cost for your trip.';
    });
  }

  Widget _buildInputRow(
      String label, TextEditingController controller, String unitLabel,
      {String? placeholder}) {
    final currentTheme = CupertinoTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 140, // Adjusted width for longer labels
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: currentTheme.barBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: CupertinoColors.systemGrey4, width: 0.5)),
              onChanged: (_) => _calculateFuelCost(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50, // Width for unit label
            child: Text(
              unitLabel,
              style: TextStyle(
                  color: currentTheme.textTheme.tabLabelTextStyle.color
                      ?.withOpacity(0.7)),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder for unit selection UI - This would be more complex
  // Widget _buildUnitSelector(String title, String currentValue, Function(String) onSelected) { ... }

  @override
  Widget build(BuildContext context) {
    final currentTheme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Fuel Cost Calculator'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Info Text (optional)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Enter your trip details to estimate fuel consumption and cost. (Units: $_distanceUnitLabel, $_efficiencyUnitLabel, Price $_priceUnitLabel)',
                  style: TextStyle(
                      fontSize: 14,
                      color: currentTheme.textTheme.tabLabelTextStyle.color
                          ?.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
              ),

              _buildInputRow(
                  'Distance:', _distanceController, _distanceUnitLabel,
                  placeholder: 'e.g., 500'),
              _buildInputRow('Fuel Efficiency:', _efficiencyController,
                  _efficiencyUnitLabel,
                  placeholder: 'e.g., 15'),
              _buildInputRow('Fuel Price:', _priceController, _priceUnitLabel,
                  placeholder: 'e.g., 1.50'),

              // TODO: Add Unit Pickers here if you want to support multiple units
              // Example: _buildUnitSelector("Distance Unit", _distanceUnit, (newUnit) => setState(() => _distanceUnit = newUnit));

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: currentTheme.brightness == Brightness.dark
                      ? CupertinoColors.darkBackgroundGray
                      : CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _calculationMessage,
                      style: TextStyle(
                        fontSize: 16,
                        color: currentTheme.textTheme.textStyle.color
                            ?.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    if (_totalFuelNeededResult.isNotEmpty)
                      Text(
                        _totalFuelNeededResult,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    if (_totalFuelNeededResult.isNotEmpty)
                      const SizedBox(height: 8),
                    if (_totalCostResult.isNotEmpty)
                      Text(
                        _totalCostResult,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
