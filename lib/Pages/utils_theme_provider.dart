import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum to represent the current theme mode
enum ThemeMode {
  light,
  dark,
}

// Class to hold theme preferences
class ThemePreferences {
  final ThemeMode themeMode;
  final bool followSystemTheme;

  ThemePreferences({
    required this.themeMode,
    required this.followSystemTheme,
  });
}

// Provider for managing the theme preferences
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
    (ref) => ThemeModeNotifier());

// Provider for accessing follow system theme setting
final followSystemThemeProvider = StateProvider<bool>((ref) => true);

// StateNotifier to handle theme mode changes and persistence
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadThemePreferences();
  }

  static const _themeModeKey = 'themeMode';
  static const _followSystemThemeKey = 'followSystemTheme';

  // Load the saved theme preferences from SharedPreferences
  Future<void> _loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeModeKey);

    if (savedTheme == 'dark') {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.light;
    }
  }

  // Get the saved follow system theme preference
  Future<bool> getFollowSystemTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_followSystemThemeKey) ?? true;
  }

  // Set the theme mode
  void setThemeMode(ThemeMode mode) {
    state = mode;
    _saveThemeMode(mode);
  }

  // Toggle between light and dark theme modes
  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemeMode(state);
  }

  // Set whether to follow system theme
  void setFollowSystemTheme(bool follow, WidgetRef ref) {
    ref.read(followSystemThemeProvider.notifier).state = follow;
    _saveFollowSystemTheme(follow);
  }

  // Save the current theme mode to SharedPreferences
  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_themeModeKey, mode == ThemeMode.light ? 'light' : 'dark');
  }

  // Save the follow system theme setting to SharedPreferences
  Future<void> _saveFollowSystemTheme(bool follow) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_followSystemThemeKey, follow);
  }
}

// Define custom CupertinoThemeData for light theme
final lightTheme = CupertinoThemeData(
  primaryColor: CupertinoColors.activeBlue,
  // Use existing CupertinoColors for light theme
  barBackgroundColor: CupertinoColors.systemGroupedBackground,
  scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
  textTheme: const CupertinoTextThemeData(
    textStyle: TextStyle(
      fontFamily: 'Inter',
      color: CupertinoColors.label, // Dark text for light theme
    ),
    actionTextStyle: TextStyle(
      fontFamily: 'Inter',
    ),
    tabLabelTextStyle: TextStyle(
      fontFamily: 'Inter',
    ),
    navTitleTextStyle: TextStyle(
      fontFamily: 'Inter',
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: CupertinoColors.label, // Dark text for light theme
    ),
    navLargeTitleTextStyle: TextStyle(
      fontFamily: 'Inter',
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: CupertinoColors.label, // Dark text for light theme
    ),
    pickerTextStyle: TextStyle(
      fontFamily: 'Inter',
    ),
    dateTimePickerTextStyle: TextStyle(
      fontFamily: 'Inter',
    ),
  ),
);

// Define custom CupertinoThemeData for dark theme
final darkTheme = CupertinoThemeData(
  primaryColor: CupertinoColors.systemIndigo, // Example dark primary color
  // Define dark theme colors
  barBackgroundColor: CupertinoColors.systemGrey6,
  scaffoldBackgroundColor: CupertinoColors.black,
  textTheme: const CupertinoTextThemeData(
    textStyle: TextStyle(
      fontFamily: 'Inter',
      color: CupertinoColors.white, // Light text for dark theme
    ),
    actionTextStyle: TextStyle(
      fontFamily: 'Inter',
    ),
    tabLabelTextStyle: TextStyle(
      fontFamily: 'Inter',
    ),
    navTitleTextStyle: TextStyle(
      fontFamily: 'Inter',
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: CupertinoColors.white, // Light text for dark theme
    ),
    navLargeTitleTextStyle: TextStyle(
      fontFamily: 'Inter',
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: CupertinoColors.white, // Light text for dark theme
    ),
    pickerTextStyle: TextStyle(
      fontFamily: 'Inter',
    ),
    dateTimePickerTextStyle: TextStyle(
      fontFamily: 'Inter',
    ),
  ),
);
