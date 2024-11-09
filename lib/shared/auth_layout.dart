import 'package:flutter/material.dart';
import 'package:zarply/components/desktop_drawer.dart';
import 'package:zarply/components/mobile_drawer.dart';
import 'package:zarply/components/tablet_drawer.dart';

bool _isLargeScreen(BuildContext context) {
  return MediaQuery.of(context).size.width > 960.0;
}

bool _isMediumScreen(BuildContext context) {
  return MediaQuery.of(context).size.width > 640.0;
}

/// See bottomNavigationBarItem or NavigationRailDestination
class AdaptiveScaffoldDestination {
  final String title;
  final IconData icon;

  const AdaptiveScaffoldDestination({
    required this.title,
    required this.icon,
  });
}

class AuthLayout extends StatefulWidget {
  final Widget? title;
  final List<Widget> actions;
  final Widget? body;
  final ValueChanged<int>? onNavigationIndexChange;
  final FloatingActionButton? floatingActionButton;

  const AuthLayout({
    this.title,
    this.body,
    this.actions = const [],
    this.onNavigationIndexChange,
    this.floatingActionButton,
    super.key,
  });

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout> {
  final List<AdaptiveScaffoldDestination> destinations = [
    const AdaptiveScaffoldDestination(title: 'Wallet', icon: Icons.wallet),
    const AdaptiveScaffoldDestination(
        title: 'Beneficiaries', icon: Icons.people),
    const AdaptiveScaffoldDestination(title: 'Settings', icon: Icons.settings),
    const AdaptiveScaffoldDestination(title: 'About', icon: Icons.info),
  ];
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (_isLargeScreen(context)) {
      return DesktopDrawer(
        destinations: destinations,
        title: widget.title,
        currentIndex: currentIndex,
        onNavigationIndexChange: _destinationTapped,
        main: Expanded(
          child: Scaffold(
            body: widget.body,
            floatingActionButton: widget.floatingActionButton,
          ),
        ),
      );
    }

    if (_isMediumScreen(context)) {
      return TabletDrawer(
          destinations: destinations,
          title: widget.title,
          currentIndex: currentIndex,
          onNavigationIndexChange: _destinationTapped,
          main: Expanded(
            child: widget.body!,
          ));
    }

    return MobileDrawer(
        destinations: destinations,
        currentIndex: currentIndex,
        main: widget.body,
        onNavigationIndexChange: _destinationTapped,
        actions: widget.actions,
        title: widget.title);
  }

  void _destinationTapped(AdaptiveScaffoldDestination destination) {
    var idx = destinations.indexOf(destination);
    if (idx != currentIndex) {
      setState(() {
        currentIndex = idx;
      });
    }
  }
}
