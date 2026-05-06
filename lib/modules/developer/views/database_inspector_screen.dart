import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/modules/developer/controllers/database_inspector_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DatabaseInspectorScreen extends StatelessWidget {
  const DatabaseInspectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DatabaseInspectorController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('SQLite Inspector'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Table Selector
          Obx(() => Container(
                padding: EdgeInsets.all(16.w),
                child: DropdownButtonFormField<String>(
                  initialValue: controller.selectedTable.value.isEmpty
                      ? null
                      : controller.selectedTable.value,
                  decoration: const InputDecoration(
                    labelText: 'Select Table',
                    border: OutlineInputBorder(),
                  ),
                  items: controller.tables.map((table) {
                    return DropdownMenuItem(
                      value: table,
                      child: Text(table),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) controller.selectTable(value);
                  },
                ),
              )),

          // Data Table
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.tableData.isEmpty) {
                return const Center(child: Text('No data found in this table'));
              }

              final columns = controller.tableData.first.keys.toList();

              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: columns
                        .map((col) => DataColumn(label: Text(col)))
                        .toList(),
                    rows: controller.tableData.map((row) {
                      return DataRow(
                        cells: columns
                            .map((col) => DataCell(Text(row[col].toString())))
                            .toList(),
                      );
                    }).toList(),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
