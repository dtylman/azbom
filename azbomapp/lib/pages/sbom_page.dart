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

  @override
  void initState() {
    super.initState();
    _getBOM();
    _initTable();
  }

  @override
  Widget build(BuildContext context) {
    return PlutoGrid(
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
    );
  }

  void _getBOM() async {
    var bom = await Backend.getBOM();
    setState(() {
      _bom = bom;
      _initTable();
    });
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
