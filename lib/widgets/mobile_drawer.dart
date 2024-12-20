import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileDrawer extends StatelessWidget {
  const MobileDrawer({
    required this.main,
    required this.actions,
    required this.title,
    super.key,
  });
  final Widget? main;
  final List<Widget>? actions;
  final Widget? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: main,
      backgroundColor: Colors.blue[700],
      appBar: AppBar(
        title: title,
        actions: actions,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/pay-request');
        },
        shape: const CircleBorder(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.sync_alt, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
