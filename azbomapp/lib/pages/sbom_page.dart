import 'package:azbomapp/services/client.dart';
import 'package:flutter/material.dart';

class SbomPage extends StatefulWidget {
  const SbomPage({super.key});

  @override
  State<SbomPage> createState() => _SbomPageState();
}

class _SbomPageState extends State<SbomPage> {
  var _bom = [];

  @override
  void initState() {
    _getBOM();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var _sortColumnIndex = 0;    
    var _sortAscending = true;
    return Center(
      child:       
    Column(
      children: [
      TextField(
        decoration: const InputDecoration(
        labelText: 'Filter',
        ),
        onChanged: (value) {
        setState(() {
          _bom = _bom.where((item) {
          return item['name'].toLowerCase().contains(value.toLowerCase()) ||
               item['target_framework'].toLowerCase().contains(value.toLowerCase());
          }).toList();
        });
        },
      ),
      
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        columns: [
          DataColumn(
            label: const Text('Repo'),
            onSort: (columnIndex, ascending) {
          setState(() {
            _sortColumnIndex = columnIndex;
            _sortAscending = ascending;
            _bom.sort((a, b) {
              if (!ascending) {
            final c = a;
            a = b;
            b = c;
              }
              return a['name'].compareTo(b['name']);
            });
          });
            },
          ),
          DataColumn(label: const Text('Name')),
          DataColumn(
            label: const Text('Framework'),
            onSort: (columnIndex, ascending) {
          setState(() {
            _sortColumnIndex = columnIndex;
            _sortAscending = ascending;
            _bom.sort((a, b) {
              if (!ascending) {
            final c = a;
            a = b;
            b = c;
              }
              return a['target_framework'].compareTo(b['target_framework']);
            });
          });
            },
          ),

        ],
        rows: _bom.map((item) {
          return DataRow(cells: [
            DataCell(Text(item['repo_name'])),
            DataCell(Text(item['name'])),
            DataCell(Text(item['target_framework'])),            
          ]);
        }).toList(),
          ),
        ),
      ),
      ],
    ),
    );
  }
  
  void _getBOM() async {
    var bom = await Client.getBOM();
    print(bom);
    setState(() {
      _bom = bom;      
    });
  }
}