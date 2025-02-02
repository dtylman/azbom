
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScreenA extends StatelessWidget {
  final String title;

  /// Constructs a [ScreenA] widget.
  const ScreenA(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title),
            TextButton(
              onPressed: () {
                context.go("/");
              },
              child: const Text('View A details'),
            ),
          ],
        ),
      ),
    );
  }
}