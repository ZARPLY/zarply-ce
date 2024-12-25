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
        title: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: <Widget>[
                  const Image(image: AssetImage('images/zarp.jpeg')),
                  const SizedBox(width: 8),
                  Text(
                    'ZARP',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white30,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'i',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          const SizedBox(
            width: 30,
            height: 30,
            child: Image(image: AssetImage('images/saflag.png')),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white30,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'JT',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
        backgroundColor: Colors.blue[700],
      ),
      floatingActionButton: SizedBox(
        width: 80,
        height: 80,
        child: FloatingActionButton(
          onPressed: () {
            context.go('/pay-request');
          },
          shape: const CircleBorder(),
          backgroundColor: Colors.blue,
          child: const Icon(Icons.sync_alt, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
