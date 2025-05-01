import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_calc/Pages/utils_theme_provider.dart';

class SettingsModalContent extends ConsumerWidget {
  final VoidCallback onClose;

  const SettingsModalContent({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final currentTheme = CupertinoTheme.of(context);
    // final themeModeNotifier = ref.read(themeModeProvider.notifier);
    // final currentThemeMode = ref.watch(themeModeProvider);
    // final followSystemTheme = ref.watch(followSystemThemeProvider);
    // final currentTheme = CupertinoTheme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.40,
      decoration: BoxDecoration(
        color: currentTheme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Modal Handle
          Container(
            height: 5,
            width: 35,
            margin: const EdgeInsets.symmetric(vertical: 10.0),
            decoration: BoxDecoration(
              color: currentTheme.primaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Settings',
                  style: currentTheme.textTheme.navTitleTextStyle,
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onClose,
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: currentTheme.primaryColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          // Settings List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              "Theme",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: currentTheme.textTheme.textStyle.color,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Expanded(
                            child: _buildThemeButton(
                              context: context,
                              label: "Light",
                              icon: CupertinoIcons.sun_max_fill,
                              isSelected: !themeState.followSystemTheme &&
                                  themeState.themeMode == ThemeMode.light,
                              onPressed: () {
                                themeNotifier.setThemeMode(ThemeMode.light,
                                    followSystem: false);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildThemeButton(
                              context: context,
                              label: "Dark",
                              icon: CupertinoIcons.moon_fill,
                              isSelected: !themeState.followSystemTheme &&
                                  themeState.themeMode == ThemeMode.dark,
                              onPressed: () {
                                themeNotifier.setThemeMode(ThemeMode.dark,
                                    followSystem: false);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildThemeButton(
                              context: context,
                              label: "System",
                              icon: CupertinoIcons.device_phone_portrait,
                              isSelected: themeState.followSystemTheme,
                              onPressed: () {
                                themeNotifier.setFollowSystemTheme(true);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ... rest of the code ...
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    final currentTheme = CupertinoTheme.of(context);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? CupertinoColors.activeBlue
              : currentTheme.barBackgroundColor,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected
                ? CupertinoColors.activeBlue
                : CupertinoColors.systemGrey4,
            width: 1.0,
          ),
        ),
        child: Row(
          // mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? CupertinoColors.white
                  : currentTheme.textTheme.textStyle.color!.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? CupertinoColors.white
                    : currentTheme.textTheme.textStyle.color!.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
