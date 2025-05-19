import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Class to hold calculator layout settings
class SettingsState {
  final bool enablePhoneKeypad;
  final bool changeOperatorOrder;

  SettingsState({
    required this.enablePhoneKeypad,
    required this.changeOperatorOrder,
  });

  SettingsState copyWith({
    bool? enablePhoneKeypad,
    bool? changeOperatorOrder,
  }) {
    return SettingsState(
      enablePhoneKeypad: enablePhoneKeypad ?? this.enablePhoneKeypad,
      changeOperatorOrder: changeOperatorOrder ?? this.changeOperatorOrder,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
      : super(SettingsState(
          enablePhoneKeypad: false,
          changeOperatorOrder: false,
        )) {
    _loadSettings();
  }

  static const _phoneKeypadKey = 'enablePhoneKeypad';
  static const _operatorOrderKey = 'changeOperatorOrder';

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = SettingsState(
        enablePhoneKeypad: prefs.getBool(_phoneKeypadKey) ?? false,
        changeOperatorOrder: prefs.getBool(_operatorOrderKey) ?? false,
      );
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> setEnablePhoneKeypad(bool value) async {
    state = state.copyWith(enablePhoneKeypad: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_phoneKeypadKey, value);
  }

  Future<void> setChangeOperatorOrder(bool value) async {
    state = state.copyWith(changeOperatorOrder: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_operatorOrderKey, value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
