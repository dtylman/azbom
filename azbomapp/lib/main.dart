import 'package:azbomapp/views/about_box.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  runApp(MyApp());
}

class VersionText extends StatefulWidget {
  const VersionText({Key? key}) : super(key: key);

  @override
  _VersionTextState createState() => _VersionTextState();
}

class _VersionTextState extends State<VersionText> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(future: _fetchVersion(), builder: _builder);
  }

  Widget _builder(BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.connectionState == ConnectionState.done) {
      if (snapshot.hasData) {
        var obj = json.decode(snapshot.data);
        var version = obj['version'];
        var db_created = obj['db_created'];        
      return 
          Text("Version $version\nUpdated $db_created");
     //     Spacer(),
     //     Text("DB Updated $db_created", style: AppStyles.header2),
      //  ],
    //  );
      } else {
        return Text('Failed to load version ${snapshot.error}', style: AppStyles.header2,);
      }
    } else {
      return SizedBox(height: 10, child:  CircularProgressIndicator());
    }
  }

  Future<String> _fetchVersion() async {
    final response = await http.get(
      Uri.parse('http://localhost:8080/api/version'),
    );
    return response.body;
  }
}

class AppStyles {
  static const TextStyle header2 = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    Text('Explorer'),
    VersionText(),
    Text('Source Control'),
    Text('Run & Debug'),
    Text('Extensions'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
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
                      child: NavigationRail(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: _onItemTapped,
                        labelType: NavigationRailLabelType.all,
                        destinations: [
                          NavigationRailDestination(
                            icon: Icon(Icons.folder),
                            selectedIcon: Icon(Icons.folder_open),
                            label: Text('Explorer'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.search),
                            selectedIcon: Icon(Icons.search),
                            label: Text('Search'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.source),
                            selectedIcon: Icon(Icons.source),
                            label: Text('Source Control'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.bug_report),
                            selectedIcon: Icon(Icons.bug_report),
                            label: Text('Run & Debug'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.extension),
                            selectedIcon: Icon(Icons.extension),
                            label: Text('Extensions'),
                          ),
                        ],
                      ),
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
            child: Center(
              child: _widgetOptions.elementAt(_selectedIndex),
            ),
          ),
        ],
      ),
    );
  }
}
