import 'dart:convert';
import 'package:http/http.dart' as http;

class Client {  
  static Future<dynamic> getVersion() async {
     final response = await http.get(Uri.parse('http://localhost:8080/api/version'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load version');
    }
  }
}
