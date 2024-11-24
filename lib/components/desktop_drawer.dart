import 'package:flutter/material.dart';
import 'package:zarply/shared/auth_layout.dart';

class DesktopDrawer extends StatelessWidget {
  final List<AdaptiveScaffoldDestination> destinations;
  final Widget main;
  final String selectedRoute;
  final ValueChanged<String> onNavigationChange;

  const DesktopDrawer(
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
        Drawer(
          child: Column(
            children: [
              DrawerHeader(
                child: Center(
                  child: Text(selectedRoute),
                ),
              ),
              for (var d in destinations)
                ListTile(
                  leading: Icon(d.icon),
                  title: Text(d.title),
                  selected: d.title == selectedRoute,
                  onTap: () => onNavigationChange(d.title.toLowerCase()),
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
    ));
  }
}
