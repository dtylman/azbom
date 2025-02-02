import 'package:azbomapp/menu/routes.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Azure SBOM',
      theme: ThemeData(
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}


void main() async {
  runApp(MyApp());
}
