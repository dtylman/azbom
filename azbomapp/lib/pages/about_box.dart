import 'package:azbomapp/services/client.dart';
import 'package:flutter/material.dart';

class AboutBox extends StatefulWidget {
  const AboutBox({Key? key}) : super(key: key);

  @override
  AboutBoxState createState() => AboutBoxState();
}

class AboutBoxState extends State<AboutBox> {
  dynamic _version = {};
  
  @override
  void initState() {  
    _getVersion();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var ver = _version["version"];
    var dbCreated = _version["db_created"];

    return SizedBox(
        child: Column(children: [
      Padding(padding: const EdgeInsets.all(8.0), child: Text("Version: $ver")),
      Padding(padding: const EdgeInsets.all(8.0), child: Text("Updated: $dbCreated")),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextButton(
          onPressed: _onAboutClicked,
          child: Text('About'),
        ),
      )
    ]));
  }

  void _onAboutClicked() {
    showAboutDialog(
      context: context,
      applicationName: 'Azure SBOM',
      applicationVersion: _version["version"],
      children: [
        Text('This is an application to manage Azure SBOM.'),
      ],
    );
  }
  
  void _getVersion() async{    
    var version = await Client.getVersion();
    setState(() {
      _version = version;
    });
  }
}
