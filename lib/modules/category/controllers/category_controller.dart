import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/models/category/kategori_model.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/core/services/sync_service.dart';

class CategoryController extends GetxController {
  final _dbService = Get.find<DatabaseService>();
  RxBool isLoading = false.obs;
  RxList<KategoriModel> categoryModelList = <KategoriModel>[].obs;
  RxBool isLoadingStore = false.obs;
  TextEditingController controllerNamaKategori = TextEditingController();

  Future<void> getCategory() async {
    try {
      isLoading.value = true;
      final List<Map<String, dynamic>> results =
          await _dbService.query('categories');
      categoryModelList.value =
          results.map((e) => KategoriModel.fromJson(e)).toList();
      update();
      debugPrint(
          'Category list loaded from SQLite, count: ${categoryModelList.length}');
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data kategori lokal: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> storeCategory() async {
    String namaKategori = controllerNamaKategori.text.trim();
    if (namaKategori.isEmpty) {
      Get.snackbar('Error', 'Nama kategori tidak boleh kosong');
      return;
    }

    isLoadingStore.value = true;
    try {
      // 1. Save to local SQLite
      await _dbService.insert('categories', {
        'id_kategori': -1, // Temporary Local ID
        'nama_kategori': namaKategori,
        'kategori_seo': namaKategori.toLowerCase().replaceAll(' ', '-'),
      });

      // 2. Enqueue Sync Command
      final syncService = Get.find<SyncService>();
      await syncService.enqueueCommand(
        method: 'POST',
        endpoint: '/api/pos_categories/',
        isFormData: true,
        body: {
          'nama_kategori': namaKategori,
        },
      );

      // 3. Update UI
      controllerNamaKategori.clear();
      await getCategory();
      Get.snackbar(
          'Berhasil', 'Kategori ditambahkan lokal & sedang disinkronkan');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menyimpan kategori: $e');
    } finally {
      isLoadingStore.value = false;
    }
  }

  Future<void> destroyCategory(int categoryId, int position) async {
    if (categoryId < 0) {
      // Handle local-only placeholder
      isLoadingStore.value = true;
      try {
        await _dbService.delete('categories', 'id_kategori = ?', [categoryId]);
        categoryModelList.removeAt(position);
        categoryModelList.refresh();
        Get.snackbar('Berhasil', 'Kategori lokal dihapus');
      } catch (e) {
        Get.snackbar('Error', 'Gagal menghapus kategori lokal: $e');
      } finally {
        isLoadingStore.value = false;
      }
      return;
    }

    isLoadingStore.value = true;
    try {
      // 1. Delete from local SQLite
      await _dbService.delete('categories', 'id_kategori = ?', [categoryId]);

      // 2. Enqueue Sync Command
      final syncService = Get.find<SyncService>();
      await syncService.enqueueCommand(
        method: 'DELETE',
        endpoint: '/api/pos_categories/$categoryId',
      );

      // 3. Update UI
      categoryModelList.removeAt(position);
      categoryModelList.refresh();
      Get.snackbar('Berhasil', 'Kategori dihapus lokal & sedang disinkronkan');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus kategori: $e');
    } finally {
      isLoadingStore.value = false;
    }
  }
}
