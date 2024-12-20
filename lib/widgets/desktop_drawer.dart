import 'package:flutter/material.dart';
import '../shared/auth_layout.dart';

class DesktopDrawer extends StatelessWidget {
  const DesktopDrawer({
    required this.destinations,
    required this.main,
    required this.selectedRoute,
    required this.onNavigationChange,
    super.key,
  });
  final List<AdaptiveScaffoldDestination> destinations;
  final Widget main;
  final String selectedRoute;
  final ValueChanged<String> onNavigationChange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          Drawer(
            child: Column(
              children: <Widget>[
                DrawerHeader(
                  child: Center(
                    child: Text(selectedRoute),
                  ),
                ),
                for (final AdaptiveScaffoldDestination destination
                    in destinations)
                  ListTile(
                    leading: Icon(destination.icon),
                    title: Text(destination.title),
                    selected: destination.title == selectedRoute,
                    onTap: () =>
                        onNavigationChange(destination.title.toLowerCase()),
                  ),
              ],
            ),
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
