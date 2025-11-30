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
  String _selectedProject = 'ConsumerFinancing.Web';
  bool _dependsOn = true;
  bool _dependsBy = true;
  bool _onlyMyProjects = true;
  bool _isLoading = false;

  // Add more projects as needed
  final List<String> _projects = [
    'ConsumerFinancing.Web',
    'ConsumerFinancing.API',
    'ConsumerFinancing.Core',
    'ConsumerFinancing.Data',
  ];

  @override
  void initState() {
    super.initState();
    loadRefs();
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
                        DropdownButtonFormField<String>(
                          value: _selectedProject,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: _projects.map((String project) {
                            return DropdownMenuItem<String>(
                              value: project,
                              child: Text(project),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedProject = newValue;
                              });
                            }
                          },
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
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : loadRefs,
                    child: _isLoading 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Render Graph'),
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
    if (_references == null) {
      return Center(child: CircularProgressIndicator());
    }
    Graph graph = Graph();
    for (ProjectReference ref in _references!.references) {
      print('Adding edge from ${ref.from} to ${ref.to}');
      graph.addEdge(Node.Id(ref.from), Node.Id(ref.to));
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
              graph: graph,
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

  void loadRefs() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      ReferencesRequest req = ReferencesRequest(
          project: _selectedProject,
          dependsOn: _dependsOn,
          dependsBy: _dependsBy,
          onlyMyProjects: _onlyMyProjects);
      ReferencesResponse refs = await Backend.getRefs(req);
      setState(() {
        _references = refs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
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
