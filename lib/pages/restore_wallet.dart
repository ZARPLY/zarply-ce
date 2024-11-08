import 'package:flutter/material.dart';
import 'package:zarply/components/custom_bottom_navigation_bar.dart';
import 'package:zarply/components/navigator_drawer.dart';

class RestoreWalletScreen extends StatelessWidget {
  const RestoreWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isDesktop = constraints.maxWidth >= 600;

      return Scaffold(
        appBar: AppBar(),
        body: const Padding(
          padding: EdgeInsets.all(16.0),
        ),
        drawer: isDesktop ? const NavigatorDrawer() : null,
        bottomNavigationBar:
            isDesktop ? null : const CustomBottomNavigationBar(),
      );
    });
  }
}
