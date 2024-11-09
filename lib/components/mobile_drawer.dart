import 'package:flutter/material.dart';
import 'package:zarply/shared/auth_layout.dart';

class MobileDrawer extends StatelessWidget {
  final List<AdaptiveScaffoldDestination> destinations;
  final int currentIndex;
  final ValueChanged<AdaptiveScaffoldDestination> onNavigationIndexChange;
  final Widget? main;
  final List<Widget>? actions;
  final Widget? title;

  const MobileDrawer(
      {required this.destinations,
      required this.currentIndex,
      required this.main,
      required this.actions,
      required this.title,
      required this.onNavigationIndexChange,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: main,
      appBar: AppBar(
        title: title,
        actions: actions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          ...destinations.map(
            (d) => BottomNavigationBarItem(
              icon: Icon(d.icon),
              label: d.title,
            ),
          ),
        ],
        currentIndex: currentIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black,
        onTap: (index) => onNavigationIndexChange(destinations[index]),
      ),
    );
  }
}
