import 'package:flutter/material.dart';
import 'package:zarply/shared/auth_layout.dart';

class TabletDrawer extends StatelessWidget {
  final List<AdaptiveScaffoldDestination> destinations;
  final Widget? title;
  final int currentIndex;
  final Widget main;
  final ValueChanged<AdaptiveScaffoldDestination> onNavigationIndexChange;

  const TabletDrawer(
      {required this.destinations,
      required this.title,
      required this.currentIndex,
      required this.main,
      required this.onNavigationIndexChange,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            destinations: [
              ...destinations.map(
                (d) => NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.title),
                ),
              ),
            ],
            selectedIndex: currentIndex,
            onDestinationSelected: (index) =>
                onNavigationIndexChange(destinations[index]),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Colors.grey[300],
          ),
          main,
        ],
      ),
    );
  }
}
