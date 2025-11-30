import 'package:azbomapp/services/backend.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class DepsPage extends StatefulWidget {
  const DepsPage({super.key});

  @override
  State<DepsPage> createState() => DepsPageState();
}

class DepsPageState extends State<DepsPage> {
  ReferencesResponse? _references;
  String? _selectedProject;
  bool _dependsOn = true;
  bool _dependsBy = true;
  bool _onlyMyProjects = true;
  bool _isLoading = false;
  bool _isLoadingProjects = true;
  List<ProjectSummary> _projects = [];
  List<ProjectSummary> _filteredProjects = [];
  TextEditingController _projectSearchController = TextEditingController();
  bool _showProjectDropdown = false;
  Graph? _graph;
  Map<String, ProjectSummary> _projectMap = {};
  String? _focusedProjectNode;
  TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    loadProjects();
  }

  @override
  void dispose() {
    _projectSearchController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Controls Panel
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Project:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        _isLoadingProjects
                            ? Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      SizedBox(width: 8),
                                      Text('Loading projects...'),
                                    ],
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  TextField(
                                    controller: _projectSearchController,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      hintText: _selectedProject ?? 'Search and select a project...',
                                      suffixIcon: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_selectedProject != null)
                                            IconButton(
                                              icon: Icon(Icons.clear),
                                              onPressed: () {
                                                setState(() {
                                                  _selectedProject = null;
                                                  _projectSearchController.clear();
                                                  _showProjectDropdown = false;
                                                  _references = null;
                                                  _graph = null;
                                                  _focusedProjectNode = null;
                                                });
                                                // Reset the transformation
                                                _transformationController.value = Matrix4.identity();
                                              },
                                            ),
                                          IconButton(
                                            icon: Icon(_showProjectDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                                            onPressed: () {
                                              setState(() {
                                                _showProjectDropdown = !_showProjectDropdown;
                                                if (_showProjectDropdown) {
                                                  _filterProjects(_projectSearchController.text);
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    onChanged: (value) {
                                      _filterProjects(value);
                                      if (!_showProjectDropdown) {
                                        setState(() {
                                          _showProjectDropdown = true;
                                        });
                                      }
                                    },
                                    onTap: () {
                                      setState(() {
                                        _showProjectDropdown = true;
                                        _filterProjects(_projectSearchController.text);
                                      });
                                    },
                                  ),
                                  if (_showProjectDropdown && _filteredProjects.isNotEmpty)
                                    Container(
                                      constraints: BoxConstraints(maxHeight: 200),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(4),
                                          bottomRight: Radius.circular(4),
                                        ),
                                      ),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: _filteredProjects.length,
                                        itemBuilder: (context, index) {
                                          return ListTile(
                                            title: Text(_filteredProjects[index].name),
                                            subtitle: Text(_filteredProjects[index].repoName),
                                            onTap: () {
                                              setState(() {
                                                _selectedProject = _filteredProjects[index].name;
                                                _projectSearchController.text = _filteredProjects[index].name;
                                                _showProjectDropdown = false;
                                              });
                                              loadRefs(); // Auto-refresh when project changes
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Options:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                title: Text('Depends On'),
                                value: _dependsOn,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _dependsOn = value ?? false;
                                  });
                                  loadRefs(); // Auto-refresh when option changes
                                },
                                controlAffinity: ListTileControlAffinity.leading,
                                dense: true,
                              ),
                            ),
                            Expanded(
                              child: CheckboxListTile(
                                title: Text('Depends By'),
                                value: _dependsBy,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _dependsBy = value ?? false;
                                  });
                                  loadRefs(); // Auto-refresh when option changes
                                },
                                controlAffinity: ListTileControlAffinity.leading,
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                        CheckboxListTile(
                          title: Text('Only My Projects'),
                          value: _onlyMyProjects,
                          onChanged: (bool? value) {
                            setState(() {
                              _onlyMyProjects = value ?? false;
                            });
                            loadRefs(); // Auto-refresh when option changes
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Graph Area
        Expanded(
          child: _buildGraphArea(),
        ),
      ],
    );
  }

  Widget _buildGraphArea() {
    if (_graph == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Select a project to view dependencies',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          transformationController: _transformationController,
          constrained: false,
          minScale: 0.01,
          maxScale: 4.0,
          boundaryMargin: EdgeInsets.all(20),
          scaleEnabled: true,
          panEnabled: true,
          child: Transform.scale(
            scale: 0.3, // Start at 30% scale to fit better
            child: GraphView(
              graph: _graph!,
              algorithm: SugiyamaAlgorithm(
                SugiyamaConfiguration()
                  ..bendPointShape = MaxCurvedBendPointShape()
                  ..levelSeparation = 50
                  ..nodeSeparation = 30
                  ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT,
              ),
              builder: nodeBuilder,
            ),
          ),
        );
      },
    );
  }

  void loadProjects() async {
    setState(() {
      _isLoadingProjects = true;
    });
    
    try {
      List<ProjectSummary> projects = await Backend.getProjects();
      
      // Create a map for quick project lookup
      Map<String, ProjectSummary> projectMap = {};
      for (var project in projects) {
        projectMap[project.name] = project;
      }
      
      setState(() {
        _projects = projects;
        _filteredProjects = projects;
        _projectMap = projectMap;
        _isLoadingProjects = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProjects = false;
      });
      print('Error loading projects: $e');
    }
  }

  void _filterProjects(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProjects = _projects;
      } else {
        _filteredProjects = _projects
            .where((project) => project.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void loadRefs() async {
    if (_selectedProject == null) {
      setState(() {
        _graph = null;
        _focusedProjectNode = null;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      ReferencesRequest req = ReferencesRequest(
          project: _selectedProject!,
          dependsOn: _dependsOn,
          dependsBy: _dependsBy,
          onlyMyProjects: _onlyMyProjects);
      ReferencesResponse refs = await Backend.getRefs(req);
      
      // Build the graph
      Graph graph = Graph();
      for (ProjectReference ref in refs.references) {        
        graph.addEdge(Node.Id(ref.from), Node.Id(ref.to));
      }
      
      setState(() {
        _references = refs;
        _graph = graph;
        _focusedProjectNode = _selectedProject;
        _isLoading = false;
      });
      
      // Center the focused node after the graph is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerOnFocusedNode();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _graph = null;
        _focusedProjectNode = null;
      });
      // Handle error - you might want to show a snackbar or dialog
      print('Error loading references: $e');
    }
  }

  void _centerOnFocusedNode() {
    if (_focusedProjectNode == null) return;
    
    // Reset transformation to center the graph
    // Since we don't have direct access to node positions in GraphView,
    // we'll reset the view to show the entire graph centered
    _transformationController.value = Matrix4.identity()
      ..scale(0.3); // Match our initial scale
  }

  Widget nodeBuilder(Node node) {
    String projectName = node.key!.value.toString();
    ProjectSummary? project = _projectMap[projectName];
    
    bool isFocusedNode = projectName == _focusedProjectNode;
    Color backgroundColor = _getFrameworkColor(project?.targetFramework ?? 'unknown');
    Color textColor = _getContrastColor(backgroundColor);
    
    // Enhance focused node appearance
    if (isFocusedNode) {
      backgroundColor = backgroundColor.withOpacity(1.0); // Full opacity for focused node
    } else {
      backgroundColor = backgroundColor.withOpacity(0.8); // Slightly transparent for other nodes
    }
    
    return InkWell(
      onTap: () {
        if (project != null) {
          _showProjectDetails(project);
        } else {
          print('Project not found: $projectName');
        }
      },
      child: Container(
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(minWidth: 120, maxWidth: 200),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFocusedNode ? Colors.blue[800]! : Colors.grey[400]!, 
            width: isFocusedNode ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isFocusedNode ? Colors.blue.withOpacity(0.3) : Colors.black26,
              blurRadius: isFocusedNode ? 8 : 4,
              offset: Offset(2, 2),
              spreadRadius: isFocusedNode ? 2 : 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              projectName,
              style: TextStyle(
                fontSize: isFocusedNode ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (project?.targetFramework != null && project!.targetFramework.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  project.targetFramework,
                  style: TextStyle(
                    fontSize: isFocusedNode ? 13 : 12,
                    color: textColor.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getFrameworkColor(String framework) {
    // List of 30 distinct, visible colors that are easy to distinguish
    final List<Color> colors = [
      Colors.red[400]!,
      Colors.blue[400]!,
      Colors.green[400]!,
      Colors.orange[400]!,
      Colors.purple[400]!,
      Colors.teal[400]!,
      Colors.pink[400]!,
      Colors.indigo[400]!,
      Colors.cyan[400]!,
      Colors.amber[400]!,
      Colors.deepOrange[400]!,
      Colors.lightGreen[400]!,
      Colors.deepPurple[400]!,
      Colors.brown[400]!,
      Colors.blueGrey[400]!,
      Colors.lime[400]!,
      Colors.yellow[600]!, // Darker yellow for better visibility
      Colors.red[600]!,
      Colors.blue[600]!,
      Colors.green[600]!,
      Colors.orange[600]!,
      Colors.purple[600]!,
      Colors.teal[600]!,
      Colors.pink[600]!,
      Colors.indigo[600]!,
      Colors.cyan[600]!,
      Colors.deepOrange[600]!,
      Colors.lightGreen[600]!,
      Colors.deepPurple[600]!,
      Colors.brown[600]!,
    ];

    if (framework.isEmpty || framework.toLowerCase() == 'unknown') {
      return Colors.grey[400]!;
    }

    // Create a hash from the framework name
    int hash = framework.toLowerCase().hashCode;
    
    // Ensure positive number and get index within our color range
    int colorIndex = hash.abs() % colors.length;
    
    return colors[colorIndex];
  }

  Color _getContrastColor(Color backgroundColor) {
    // Calculate luminance to determine if we need dark or light text
    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  void _showProjectDetails(ProjectSummary project) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(project.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Repository', project.repoName),
              _buildDetailRow('Target Framework', project.targetFramework),
              _buildDetailRow('Base Path', project.basePath),
              _buildDetailRow('Project File', project.projectFile),
              if (project.mainFile.isNotEmpty)
                _buildDetailRow('Main File', project.mainFile),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(
              value.isEmpty ? 'N/A' : value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
