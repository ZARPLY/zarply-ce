import 'package:flutter/material.dart';
import 'package:zarply/shared/auth_layout.dart';

class DesktopDrawer extends StatelessWidget {
  final List<AdaptiveScaffoldDestination> destinations;
  final Widget? title;
  final int currentIndex;
  final Widget main;
  final ValueChanged<AdaptiveScaffoldDestination> onNavigationIndexChange;

  const DesktopDrawer(
      {required this.destinations,
      required this.title,
      required this.currentIndex,
      required this.main,
      required this.onNavigationIndexChange,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Drawer(
          child: Column(
            children: [
              DrawerHeader(
                child: Center(
                  child: title,
                ),
              ),
              for (var d in destinations)
                ListTile(
                  leading: Icon(d.icon),
                  title: Text(d.title),
                  selected: destinations.indexOf(d) == currentIndex,
                  onTap: () => onNavigationIndexChange(d),
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
    );
  }
}
