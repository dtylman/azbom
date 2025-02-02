import 'package:azbomapp/menu/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainMenuItems extends StatefulWidget {
  const MainMenuItems({super.key});

  @override
  MainMenuItemsState createState() => MainMenuItemsState();
}


class MainMenuItemsState extends State<MainMenuItems> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      labelType: NavigationRailLabelType.all,
      destinations: MenuItem.mainMenu.map((item) {
        return NavigationRailDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.selectedIcon),
          label: Text(item.title),
        );
      }).toList(),
    );
  }

  void _onItemTapped(int value) {
    setState(() {
      _selectedIndex = value;
      context.go(MenuItem.mainMenu[value].route);
    });
  }
}
