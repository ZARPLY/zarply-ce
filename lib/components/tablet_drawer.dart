import 'package:flutter/material.dart';
import 'package:zarply/shared/auth_layout.dart';

class TabletDrawer extends StatelessWidget {
  final List<AdaptiveScaffoldDestination> destinations;
  final Widget main;
  final ValueChanged<String> onNavigationChange;
  final String selectedRoute;

  const TabletDrawer(
      {required this.destinations,
      required this.main,
      required this.selectedRoute,
      required this.onNavigationChange,
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
            selectedIndex:
                destinations.indexWhere((d) => d.title == selectedRoute),
            onDestinationSelected: (index) =>
                onNavigationChange(destinations[index].title.toLowerCase()),
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
