import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_calc/Pages/utils_theme_provider.dart';
// import 'font_awesome_flutter/font_awesome_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsModalContent extends ConsumerWidget {
  final VoidCallback onClose;

  const SettingsModalContent({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    debugPrint('themeState: $themeState');
    final currentTheme = CupertinoTheme.of(context);
    debugPrint(
        'currentTheme.textTheme.textStyle.color: ${currentTheme.textTheme.textStyle.color}');
    // final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    // final currentTheme = CupertinoTheme.of(context);
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Settings',
                  style: currentTheme.textTheme.navTitleTextStyle,
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
                          Text(
                            "Theme",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: currentTheme.textTheme.textStyle.color,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                // Social Media Links
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        color: currentTheme.primaryColor.withOpacity(0.2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Connect with us",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: currentTheme.textTheme.textStyle.color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                            context: context,
                            icon: FontAwesomeIcons.github,
                            url: "https://github.com/thegravity98/Pro-Calc",
                          ),
                          const SizedBox(width: 24),
                          _buildSocialButton(
                            context: context,
                            icon: FontAwesomeIcons.xTwitter,
                            url: "https://x.com/pranavxmeta",
                          ),
                          const SizedBox(width: 24),
                          _buildSocialButton(
                            context: context,
                            icon: FontAwesomeIcons.threads,
                            url: "https://www.threads.com/@pranavxmeta",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
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
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FontAwesomeIcons.github,
              color: isSelected
                  ? CupertinoColors.white
                  : currentTheme.textTheme.textStyle.color!.withOpacity(0.7),
              size: 16,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? CupertinoColors.white
                      : currentTheme.textTheme.textStyle.color!
                          .withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required IconData icon,
    required String url,
  }) {
    final currentTheme = CupertinoTheme.of(context);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () async {
        // Launch URL
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          debugPrint('Could not launch $url');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: currentTheme.barBackgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: currentTheme.primaryColor,
          size: 24,
        ),
      ),
    );
  }
}
