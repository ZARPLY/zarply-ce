import 'package:flutter/material.dart';
import '../shared/auth_layout.dart';

class TabletDrawer extends StatelessWidget {
  const TabletDrawer({
    required this.destinations,
    required this.main,
    required this.selectedRoute,
    required this.onNavigationChange,
    super.key,
  });
  final List<AdaptiveScaffoldDestination> destinations;
  final Widget main;
  final ValueChanged<String> onNavigationChange;
  final String selectedRoute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          NavigationRail(
            destinations: <NavigationRailDestination>[
              ...destinations.map(
                (AdaptiveScaffoldDestination d) => NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.title),
                ),
              ),
            ],
            selectedIndex: destinations.indexWhere(
              (AdaptiveScaffoldDestination d) => d.title == selectedRoute,
            ),
            onDestinationSelected: (int index) =>
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
