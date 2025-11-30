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

  @override
  void initState() {
    super.initState();
    loadRefs();
  }

  @override
  Widget build(BuildContext context) {
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
    ReferencesRequest? req = ReferencesRequest(
        project: 'ConsumerFinancing.Web',
        dependsOn: true,
        dependsBy: true,
        onlyMyProjects: true);
    ReferencesResponse refs = await Backend.getRefs(req);
    setState(() {
      _references = refs;
    });
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
