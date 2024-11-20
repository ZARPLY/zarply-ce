import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:zarply/components/desktop_drawer.dart';
import 'package:zarply/components/mobile_drawer.dart';
import 'package:zarply/components/tablet_drawer.dart';
import 'package:zarply/pages/about.dart';
import 'package:zarply/pages/beneficiaries.dart';
import 'package:zarply/pages/settings.dart';
import 'package:zarply/pages/wallet.dart';

bool _isLargeScreen(BuildContext context) {
  return MediaQuery.of(context).size.width > 960.0;
}

bool _isMediumScreen(BuildContext context) {
  return MediaQuery.of(context).size.width > 640.0;
}

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
  final FloatingActionButton? floatingActionButton;

  const AuthLayout({
    this.title,
    this.body,
    this.actions = const [],
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
  final GlobalKey<NavigatorState> contentNavigatorKey =
      GlobalKey<NavigatorState>();
  String _selectedRoute = 'Wallet';

  @override
  Widget build(BuildContext context) {
    if (_isLargeScreen(context)) {
      return DesktopDrawer(
        destinations: destinations,
        selectedRoute: _selectedRoute,
        onNavigationChange: (route) {
          setState(() {
            _selectedRoute = route[0].toUpperCase() + route.substring(1);
          });
          contentNavigatorKey.currentState?.pushReplacementNamed('/$route');
        },
        main: Expanded(
          child: Navigator(
            key: contentNavigatorKey,
            onGenerateRoute: (RouteSettings settings) {
              WidgetBuilder builder;
              switch (settings.name) {
                case '/wallet':
                  builder = (BuildContext _) => const WalletScreen();
                  break;
                case '/beneficiaries':
                  builder = (BuildContext _) => const BeneficiariesScreen();
                  break;
                case '/settings':
                  builder = (BuildContext _) => const SettingsScreen();
                  break;
                case '/about':
                  builder = (BuildContext _) => const AboutScreen();
                  break;
                default:
                  builder = (BuildContext _) => const WalletScreen();
                  break;
              }

              return MaterialPageRoute(builder: builder, settings: settings);
            },
            initialRoute: '/wallet',
          ),
        ),
      );
    }

    if (_isMediumScreen(context)) {
      return TabletDrawer(
        destinations: destinations,
        selectedRoute: _selectedRoute,
        onNavigationChange: (route) {
          setState(() {
            _selectedRoute = route[0].toUpperCase() + route.substring(1);
          });
          contentNavigatorKey.currentState?.pushReplacementNamed('/$route');
        },
        main: Expanded(
          child: Navigator(
            key: contentNavigatorKey,
            onGenerateRoute: (RouteSettings settings) {
              log(settings.name ?? 'fffff');
              return _navigateToScreen(settings);
            },
            initialRoute: '/wallet',
          ),
        ),
      );
    }

    return MobileDrawer(
      destinations: destinations,
      selectedRoute: _selectedRoute,
      onNavigationChange: (route) {
        setState(() {
          _selectedRoute = route[0].toUpperCase() + route.substring(1);
        });
        contentNavigatorKey.currentState?.pushReplacementNamed('/$route');
      },
      actions: widget.actions,
      title: widget.title,
      main: Navigator(
        key: contentNavigatorKey,
        onGenerateRoute: (RouteSettings settings) {
          return _navigateToScreen(settings);
        },
        initialRoute: '/wallet',
      ),
    );
  }

  MaterialPageRoute _navigateToScreen(RouteSettings settings) {
    log(settings.name ?? '');
    switch (settings.name) {
      case '/wallet':
        return MaterialPageRoute(
          builder: (context) => const WalletScreen(),
        );
      case '/beneficiaries':
        return MaterialPageRoute(
          builder: (context) => const BeneficiariesScreen(),
        );
      case '/settings':
        return MaterialPageRoute(
          builder: (context) => const SettingsScreen(),
        );
      case '/about':
        return MaterialPageRoute(
          builder: (context) => const AboutScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (context) => const WalletScreen(),
        );
    }
  }
}
