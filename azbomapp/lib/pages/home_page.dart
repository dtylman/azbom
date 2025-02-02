import 'package:azbomapp/menu/main_menu.dart';
import 'package:flutter/material.dart';


import 'about_box.dart';

class HomePage extends StatelessWidget {
  final Widget child;

  const HomePage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Azure SBOM'),
      ),
      body: Row(
        children: <Widget>[
          LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.2,
                ),
                child: Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: MainMenuItems(),
                    ),
                    AboutBox(),
                  ],
                ),
              );
            },
          ),
          VerticalDivider(thickness: 1, width: 1),
          Expanded(
            flex: 4,
            child: child,
          ),
        ],
      ),
    );
  }
}

