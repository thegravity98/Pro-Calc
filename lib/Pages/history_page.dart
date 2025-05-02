// import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../models/calculation_history.dart';
import 'package:flutter/cupertino.dart';
// import 'package:flutter/services.dart';

// Color constants
class AppColors {
  // Dark mode colors
  static const darkSnackBarBackground = Color.fromRGBO(60, 60, 60, 0.80);
  static const lightSnackBarBackground = Color.fromRGBO(240, 240, 240, 1);
  static const snackBarTextColor = Colors.white;
  // static const transparentColor = Color.transparent;

  // Icon and text colors
  static final darkGrey = Colors.grey[400];
  static final lightGrey = Colors.grey;
  static final darkGreyText = Colors.black12;
  static final lightTimestampColor =
      Colors.grey[600]; // More visible timestamp color for light mode

  // Button colors
  static final darkRedButton = Colors.red[900];
  static final lightRedButton = Colors.red[100];
  static final darkIconColor = Colors.white.withOpacity(0.87);
  static const lightIconColor = Colors.black87;

  // Shadow colors
  static final darkShadow = Colors.black.withOpacity(0.3);
  static final lightShadow = Colors.grey.withOpacity(0.2);

  // History card colors
  static const darkCardBackground = Color.fromRGBO(40, 40, 40, 1);
  static const lightCardBackground = Color.fromRGBO(245, 245, 245, 1);
}

class HistoryPage extends StatefulWidget {
  final List<CalculationHistory> history;
  final Function(String)? onExpressionTap;
  final VoidCallback? onClear; // Add callback for clearing history

  const HistoryPage({
    super.key,
    required this.history,
    this.onExpressionTap,
    this.onClear, // Add this parameter
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  void _showSnackBar() {
    final overlay = Navigator.of(context).overlay!;
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 32,
        right: 32,
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoTheme.of(context).brightness == Brightness.dark
                  ? Color.fromRGBO(50, 50, 50, 0.9) // Darker snackbar
                  : Color.fromRGBO(230, 230, 230, 0.9), // Lighter snackbar
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              child: Text(
                'History Cleared',
                style: TextStyle(
                  color:
                      CupertinoTheme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 1), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          color: CupertinoTheme.of(context).brightness == Brightness.dark
              ? Color.fromRGBO(30, 30, 30, 1) // Dark background
              : Color.fromRGBO(240, 240, 240, 1), // Light background
          child: widget.history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FluentIcons.history_24_regular,
                        size: 48,
                        color: CupertinoTheme.of(context).brightness ==
                                Brightness.dark
                            ? AppColors.darkGrey
                            : AppColors.lightGrey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No calculations yet',
                        style: TextStyle(
                          color: CupertinoTheme.of(context).brightness ==
                                  Brightness.dark
                              ? AppColors.darkGrey
                              : AppColors.lightGrey,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                )
              : ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(
                    physics: const BouncingScrollPhysics(),
                    scrollbars: false,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.history.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final entry = widget.history[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RepaintBoundary(
                          child: GestureDetector(
                            onTap: () {
                              if (widget.onExpressionTap != null) {
                                widget.onExpressionTap!(entry.result);
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: CupertinoTheme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkCardBackground
                                    : AppColors.lightCardBackground,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        CupertinoTheme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.darkShadow
                                            : AppColors.lightShadow,
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          FluentIcons.history_24_regular,
                                          size: 20,
                                          color: CupertinoTheme.of(context)
                                                      .brightness ==
                                                  Brightness.dark
                                              ? AppColors.darkGrey
                                              : AppColors.lightGrey,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            entry.expression,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: CupertinoTheme.of(context)
                                                  .textTheme
                                                  .textStyle
                                                  .color!
                                                  .withOpacity(0.87),
                                            ),
                                            overflow: TextOverflow
                                                .ellipsis, // Show '...' if too long
                                            maxLines:
                                                1, // Ensure it stays on one line
                                            softWrap: false, // Prevent wrapping
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '= ${entry.result}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: CupertinoTheme.of(context)
                                            .textTheme
                                            .textStyle
                                            .color,
                                      ),
                                      overflow: TextOverflow
                                          .ellipsis, // Handle potential overflow
                                      maxLines:
                                          2, // Allow maybe two lines for result
                                      softWrap: true,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTimestamp(entry.timestamp),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: CupertinoTheme.of(context)
                                                    .brightness ==
                                                Brightness.dark
                                            ? AppColors.darkGrey
                                            : AppColors.lightTimestampColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
        if (widget.history.isNotEmpty && widget.onClear != null)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                widget.onClear?.call();
                _showSnackBar();
              },
              backgroundColor:
                  CupertinoTheme.of(context).brightness == Brightness.dark
                      ? AppColors.darkRedButton
                      : AppColors.lightRedButton,
              elevation: 4,
              child: Icon(
                FluentIcons.broom_24_regular,
                color: CupertinoTheme.of(context).brightness == Brightness.dark
                    ? AppColors.darkIconColor
                    : AppColors.lightIconColor,
              ),
            ),
          ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
