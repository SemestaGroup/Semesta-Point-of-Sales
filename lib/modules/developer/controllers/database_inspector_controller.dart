import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/styles/app_theme.dart';
import 'package:share_plus/share_plus.dart';

class DatabaseInspectorController extends GetxController {
  DatabaseService get _dbService {
    if (!Get.isRegistered<DatabaseService>()) {
      Get.put(DatabaseService(), permanent: true);
    }
    return Get.find<DatabaseService>();
  }

  RxList<String> tables = <String>[].obs;
  RxString selectedTable = ''.obs;
  RxList<Map<String, dynamic>> tableData = <Map<String, dynamic>>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTables();
  }

  Future<void> fetchTables() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> results = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
      tables.value = results.map((e) => e['name'] as String).toList();
      if (tables.isNotEmpty) {
        selectTable(tables.first);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch tables: $e');
    }
  }

  Future<void> selectTable(String tableName) async {
    selectedTable.value = tableName;
    fetchTableData();
  }

  Future<void> fetchTableData() async {
    if (selectedTable.value.isEmpty) return;

    isLoading.value = true;
    try {
      final data = await _dbService.query(selectedTable.value);
      tableData.value = data;
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch table data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportDatabase() async {
    try {
      final db = await _dbService.database;
      final String dbPath = db.path;
      final File sourceFile = File(dbPath);
      
      if (await sourceFile.exists()) {
        // Save to Download folder just in case
        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String destPath = '/storage/emulated/0/Download/pos_database_$timestamp.sqlite';
        try {
          await sourceFile.copy(destPath);
        } catch (e) {
          debugPrint("Failed to copy to Download folder: $e");
        }
        
        // Share using share_plus
        await Share.shareXFiles(
          [XFile(dbPath)],
          text: 'Backup Database SQLite POS ($timestamp)',
        );
      } else {
        Get.snackbar('Error', 'File database tidak ditemukan.');
      }
    } catch(e) {
      Get.snackbar('Error', 'Gagal mengekspor database: $e');
    }
  }
}
