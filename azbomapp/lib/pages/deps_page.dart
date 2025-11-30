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

  @override
  void initState() {
    super.initState();
    loadProjects();
  }

  @override
  void dispose() {
    _projectSearchController.dispose();
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
                                                });
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
          constrained: false,
          minScale: 0.01,
          maxScale: 2.0,
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
      
      setState(() {
        _projects = projects;
        _filteredProjects = projects;
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _graph = null;
      });
      // Handle error - you might want to show a snackbar or dialog
      print('Error loading references: $e');
    }
  }

  Widget nodeBuilder(Node node) {
    var boxShadow = BoxShadow(color: Colors.blue[100]!, spreadRadius: 1);
    return InkWell(
        onTap: () {
          print('Tapped on node: ${node.key}');
        },
        child: Container(
           padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(4),
            boxShadow: [boxShadow],
          ),
          child: Text(node.key!.value.toString()),
        ));
  }
}
