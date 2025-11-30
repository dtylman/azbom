import 'package:azbomapp/services/backend.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

class SbomPage extends StatefulWidget {
  const SbomPage({super.key});

  @override
  State<SbomPage> createState() => _SbomPageState();
}

class _SbomPageState extends State<SbomPage> {
  final List<PlutoColumn> columns = [];
  final List<PlutoRow> rows = [];
  dynamic _bom = [];
  bool _isRefreshing = false;
  String? _initialDbTimestamp;
  
  // Controllers for the input fields
  final TextEditingController _organizationUrlController = TextEditingController();
  final TextEditingController _patController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getBOM();
    _initTable();
  }

  @override
  void dispose() {
    _organizationUrlController.dispose();
    _patController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Refresh Controls Panel
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Refresh Database',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _organizationUrlController,
                      decoration: InputDecoration(
                        labelText: 'Organization URL',
                        hintText: 'https://dev.azure.com/yourorg',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _patController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Personal Access Token (PAT)',
                        hintText: 'Enter your Azure DevOps PAT',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isRefreshing ? _stopRefresh : _refreshDatabase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRefreshing ? Colors.orange : null,
                    ),
                    child: _isRefreshing
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              SizedBox(width: 8),
                              Text('Stop Refresh'),
                            ],
                          )
                        : Text('Refresh Database'),
                  ),
                ],
              ),
              if (_isRefreshing)
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Refreshing database... This may take several minutes. The table will update automatically when complete.',
                    style: TextStyle(color: Colors.orange[700], fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        ),
        // SBOM Table
        Expanded(
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            mode: PlutoGridMode.readOnly,
            configuration: PlutoGridConfiguration(
              columnSize: PlutoGridColumnSizeConfig(
                autoSizeMode: PlutoAutoSizeMode.scale,
              ),
            ),
            onLoaded: (PlutoGridOnLoadedEvent event) {
              event.stateManager.setShowColumnFilter(true);
            },
          ),
        ),
      ],
    );
  }

  void _getBOM() async {
    var bom = await Backend.getBOM();
    for (var item in bom) {
      var dockerFiles = item['docker_files'];
      if( ( dockerFiles!=null) && (dockerFiles.length > 0) ){        
        var name = item['name'];
        if ( (name == null) || (name == '') ){
          name = item['base_path'];
        }
        var line = "|${item['repo_name']}|$name||";
        print(line);
      }
    }
    setState(() {
      _bom = bom;
      _rebuildTable();
    });
  }

  void _rebuildTable() {
    // Clear existing data
    columns.clear();
    rows.clear();
    
    // Rebuild table with new data
    _initTable();
  }

  void _refreshDatabase() async {
    String organizationUrl = _organizationUrlController.text.trim();
    String pat = _patController.text.trim();

    if (organizationUrl.isEmpty || pat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter both Organization URL and Personal Access Token'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Get the current database timestamp before refresh
      var versionInfo = await Backend.getVersion();
      _initialDbTimestamp = versionInfo['db_created'];

      var response = await Backend.refreshDatabase(organizationUrl, pat);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Database refresh started'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      // Start polling for database changes
      _startPollingForUpdates();
      
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing database: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _stopRefresh() {
    setState(() {
      _isRefreshing = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Refresh monitoring stopped'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _startPollingForUpdates() {
    // Start polling immediately, then every 10 seconds
    _pollForUpdates(0, 60); // Poll for up to 10 minutes
  }

  void _pollForUpdates(int pollCount, int maxPolls) async {
    if (pollCount >= maxPolls) {
      setState(() {
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Refresh timeout - please check if the database was updated'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Check if the database timestamp has changed
      var versionInfo = await Backend.getVersion();
      String currentTimestamp = versionInfo['db_created'];
      
      if (currentTimestamp != _initialDbTimestamp) {
        // Database has been updated, refresh the table
        _getBOM();
        setState(() {
          _isRefreshing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database refresh completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }
      
      // Continue polling
      pollCount++;
      await Future.delayed(Duration(seconds: 10));
      if (_isRefreshing) {
        _pollForUpdates(pollCount, maxPolls);
      }
      
    } catch (e) {
      // If there's an error, continue polling (the refresh might still be in progress)
      pollCount++;
      await Future.delayed(Duration(seconds: 10));
      if (_isRefreshing) {
        _pollForUpdates(pollCount, maxPolls);
      }
    }
  }

  void _initTable() {
    columns.addAll([
      PlutoColumn(
        title: 'Repo',
        field: 'repo_name',
        type: PlutoColumnType.text(),
      ),
      PlutoColumn(
        title: 'Project',
        field: 'name',
        type: PlutoColumnType.text(),
      ),
      PlutoColumn(
          title: 'Main Branch',
          field: 'main_branch',
          type: PlutoColumnType.text())
    ]);

    for (var item in _bom) {
      rows.add(
        PlutoRow(
          cells: {
            'repo_name': PlutoCell(value: item['repo_name']),
            'name': PlutoCell(value: item['name']),
            'main_branch': PlutoCell(value: item['main_branch']),
          },
        ),
      );
    }
  }
}
