import 'dart:convert';
import 'package:http/http.dart' as http;

class ProjectSummary {
  String name;
  String repoName;
  String basePath;
  String targetFramework;
  String projectFile;
  String mainFile;

  ProjectSummary({
    required this.name,
    required this.repoName,
    required this.basePath,
    required this.targetFramework,
    required this.projectFile,
    required this.mainFile,
  });

  factory ProjectSummary.fromJson(Map<String, dynamic> json) {
    return ProjectSummary(
      name: json['name'] ?? '',
      repoName: json['repo_name'] ?? '',
      basePath: json['base_path'] ?? '',
      targetFramework: json['target_framework'] ?? '',
      projectFile: json['project_file'] ?? '',
      mainFile: json['main_file'] ?? '',
    );
  }
}

 class ProjectReference {
  String from;
  String to;

  ProjectReference({required this.from, required this.to});

  factory ProjectReference.fromJson(Map<String, dynamic> json) {
    return ProjectReference(from: json['from'], to: json['to']);
  }
}

class ReferencesResponse {
  List<ProjectReference> references;

  ReferencesResponse({required this.references});

  factory ReferencesResponse.fromJson(Map<String, dynamic> json) {
    var list = json['references'] as List;
    List<ProjectReference> refs = list.map((e) => ProjectReference.fromJson(e)).toList();
    return ReferencesResponse(references: refs);
  }
}

class ReferencesRequest {
  String project;
  bool dependsOn;
  bool dependsBy;
  bool onlyMyProjects;

  ReferencesRequest({required this.project, required this.dependsOn, required this.dependsBy, required this.onlyMyProjects});

  Map<String, dynamic> toJson() {
    return {
      'project': project,
      'depends_on': dependsOn,
      'depends_by': dependsBy,
      'only_my_projects': onlyMyProjects,
    };
  }
}

class Backend {  
  static String baseURL= 'http://localhost:8080';

  static Future<dynamic> getVersion() async {
     final response = await http.get(Uri.parse('$baseURL/api/version'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load version');
    }
  }

  static Future<dynamic> getBOM() async {
    final response = await http.get(Uri.parse('$baseURL/api/bom'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load BOM');
    }
  }

  static Future<List<ProjectSummary>> getProjects() async {
    final response = await http.get(Uri.parse('$baseURL/api/projects'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((project) => ProjectSummary.fromJson(project)).toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to load projects');
    }
  }
   
  static Future<ReferencesResponse> getRefs(ReferencesRequest? req) async {    
    http.Response response;
    if (req==null){
      response = await http.get(Uri.parse('$baseURL/api/references'));     
    } else {      
      String filter = jsonEncode(req.toJson());
      response = await http.get(Uri.parse('$baseURL/api/references?req=$filter'));
    }         
    if (response.statusCode == 200) {                  
      return ReferencesResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load refs');
    }
  }

  static Future<Map<String, dynamic>> refreshDatabase(String organizationUrl, String pat) async {
    final response = await http.post(
      Uri.parse('$baseURL/api/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'organization_url': organizationUrl,
        'pat': pat,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to refresh database: ${response.body}');
    }
  }
}