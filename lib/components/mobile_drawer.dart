import 'package:flutter/material.dart';
import 'package:zarply/shared/auth_layout.dart';

class MobileDrawer extends StatelessWidget {
  final List<AdaptiveScaffoldDestination> destinations;
  final ValueChanged<String> onNavigationChange;
  final Widget? main;
  final List<Widget>? actions;
  final Widget? title;
  final String selectedRoute;

  const MobileDrawer(
      {required this.destinations,
      required this.main,
      required this.actions,
      required this.title,
      required this.selectedRoute,
      required this.onNavigationChange,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: main,
      appBar: AppBar(
        title: Text(selectedRoute),
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
        currentIndex: destinations.indexWhere((d) => d.title == selectedRoute),
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black,
        onTap: (index) =>
            onNavigationChange(destinations[index].title.toLowerCase()),
      ),
    );
  }
}
