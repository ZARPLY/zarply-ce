import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/desktop_drawer.dart';
import '../widgets/mobile_drawer.dart';
import '../widgets/tablet_drawer.dart';

bool _isLargeScreen(BuildContext context) {
  return MediaQuery.of(context).size.width > 960.0;
}

bool _isMediumScreen(BuildContext context) {
  return MediaQuery.of(context).size.width > 640.0;
}

class AdaptiveScaffoldDestination {
  const AdaptiveScaffoldDestination({
    required this.title,
    required this.icon,
  });
  final String title;
  final IconData icon;
}

class AuthLayout extends StatefulWidget {
  const AuthLayout({
    required this.body,
    this.title,
    this.actions = const <Widget>[],
    this.floatingActionButton,
    super.key,
  });
  final List<Widget> actions;
  final Widget body;
  final Widget? title;
  final FloatingActionButton? floatingActionButton;

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout> {
  final List<AdaptiveScaffoldDestination> destinations =
      <AdaptiveScaffoldDestination>[
    const AdaptiveScaffoldDestination(title: 'Wallet', icon: Icons.wallet),
    const AdaptiveScaffoldDestination(
      title: 'Beneficiaries',
      icon: Icons.people,
    ),
    const AdaptiveScaffoldDestination(title: 'Settings', icon: Icons.settings),
    const AdaptiveScaffoldDestination(title: 'About', icon: Icons.info),
  ];
  String _selectedRoute = 'Wallet';

  @override
  Widget build(BuildContext context) {
    if (_isLargeScreen(context)) {
      return DesktopDrawer(
        destinations: destinations,
        selectedRoute: _selectedRoute,
        onNavigationChange: _handleOnNavigationChange,
        main: Expanded(child: widget.body),
      );
    }

    if (_isMediumScreen(context)) {
      return TabletDrawer(
        destinations: destinations,
        selectedRoute: _selectedRoute,
        onNavigationChange: _handleOnNavigationChange,
        main: Expanded(child: widget.body),
      );
    }

    return MobileDrawer(
      actions: widget.actions,
      title: widget.title,
      main: widget.body,
    );
  }

  void _handleOnNavigationChange(String route) {
    setState(() {
      _selectedRoute = route[0].toUpperCase() + route.substring(1);
    });
    context.go('/$route');
  }
}
