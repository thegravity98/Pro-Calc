import 'package:flutter/cupertino.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import 'Export_Page_list/shape_page_list.dart';

class ShapesPage extends StatelessWidget {
  const ShapesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: null,
      child: SafeArea(
        child: ShapesGridContent(),
      ),
    );
  }
}

class ShapesGridContent extends StatelessWidget {
  ShapesGridContent({super.key});

  final List<Map<String, dynamic>> shapesList = [
    {'name': 'Rectangle', 'icon': FluentIcons.rectangle_landscape_24_regular},
    {'name': 'Square', 'icon': FluentIcons.square_24_regular},
    {'name': 'Circle', 'icon': FluentIcons.circle_24_regular},
    {'name': 'Triangle', 'icon': FluentIcons.triangle_24_regular},
    {'name': 'Trapezoid', 'icon': FluentIcons.triangle_24_regular},
  ];

  void _navigateToShape(BuildContext context, String name) {
    Widget? page;
    switch (name) {
      case 'Rectangle':
        page = const RectangleShapePage();
        break;
      case 'Square':
        page = const SquareShapePage();
        break;
      case 'Circle':
        page = const CircleShapePage();
        break;
      case 'Triangle':
        page = const TriangleShapePage();
        break;
      case 'Trapezoid':
        page = const TrapezoidShapePage();
        break;
      default:
        return;
    }
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page!,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: shapesList.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _navigateToShape(context, shapesList[index]['name']),
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  shapesList[index]['icon'],
                  size: 32,
                  color: CupertinoColors.activeBlue,
                ),
                const SizedBox(height: 8),
                Text(
                  shapesList[index]['name'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
