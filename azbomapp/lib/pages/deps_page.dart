import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

class DepsPage extends StatelessWidget {
  const DepsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('DepsPage Page'),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}
