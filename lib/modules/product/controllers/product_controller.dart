import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:semesta_pos/core/models/category/kategori_model.dart';
import 'package:semesta_pos/core/models/product/product_model.dart';
import 'package:semesta_pos/core/services/remote/api_service.dart';
import 'package:semesta_pos/core/util/constans.dart';
import 'package:semesta_pos/core/services/user_service.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';

class ProductController extends GetxController {
  DatabaseService get _dbService => Get.find<DatabaseService>();

  RxList<ProductModel> productModelList = <ProductModel>[].obs;
  RxList<KategoriModel> categoryModelList = <KategoriModel>[].obs;
  RxBool isLoadingProduct = false.obs;
  RxBool isLoadingCategory = false.obs;
  final apiService = Get.put(ApiService());
  final userService = Get.put(UserService());
  RxString imageFile = ''.obs;
  final ImagePicker picker = ImagePicker();
  TextEditingController namaProductController = TextEditingController();
  TextEditingController kategoriProductController = TextEditingController();
  TextEditingController merkProductController = TextEditingController();
  TextEditingController hrgBeliProductController = TextEditingController();
  TextEditingController hrgJualProductController = TextEditingController();
  TextEditingController diskonProductController = TextEditingController();
  TextEditingController stokProductController = TextEditingController();
  String kategoriId = '';
  RxBool isLoadingStore = false.obs;
  RxBool isEditable = false.obs;
  int productId = 0;
  ProductModel productModel = const ProductModel();

  Future<void> getProductData() async {
    try {
      productModelList.clear();
      isLoadingProduct.value = true;
      final List<Map<String, dynamic>> results =
          await _dbService.query('products');
      productModelList.value = results.map((e) {
        return ProductModel.fromJson({
          'id': e['id_produk'],
          'category_id': e['id_kategori'],
          'name': e['nama_produk'],
          'sku': e['kode_produk'],
          'cost': e['harga_beli'],
          'price': e['harga_jual'],
          'stock_quantity': e['stok'],
          'image_url': e['img'],
          'merk': e['merk'],
          'order_types': e['order_types'],
          'discount_total': e['discount_total'],
          'discount_type': e['discount_type'],
          'status': e['status'],
        });
      }).toList();
      isLoadingProduct.value = false;
      debugPrint(
          'Product list loaded from SQLite, count: ${productModelList.length}');
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data produk lokal: $e');
    } finally {
      isLoadingProduct.value = false;
    }
  }

  Future<void> searchProduct(String query) async {
    isLoadingProduct.value = true;
    try {
      if (query.isEmpty) {
        await getProductData();
      } else {
        final List<Map<String, dynamic>> results = await _dbService.query(
          'products',
          where: 'nama_produk LIKE ?',
          whereArgs: ['%$query%'],
        );
        productModelList.value = results.map((e) {
          return ProductModel.fromJson({
            'id': e['id_produk'],
            'category_id': e['id_kategori'],
            'name': e['nama_produk'],
            'sku': e['kode_produk'],
            'cost': e['harga_beli'],
            'price': e['harga_jual'],
            'stock_quantity': e['stok'],
            'image_url': e['img'],
            'merk': e['merk'],
            'order_types': e['order_types'],
            'discount_total': e['discount_total'],
            'discount_type': e['discount_type'],
            'status': e['status'],
          });
        }).toList();
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal mencari produk lokal');
    } finally {
      isLoadingProduct.value = false;
    }
  }

  Future<void> getCategory() async {
    try {
      isLoadingCategory.value = true;
      final List<Map<String, dynamic>> results =
          await _dbService.query('categories');
      categoryModelList.value =
          results.map((e) => KategoriModel.fromJson(e)).toList();
      update();
      debugPrint(
          'Category list loaded from SQLite, count: ${categoryModelList.length}');
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data kategori lokal');
    } finally {
      isLoadingCategory.value = false;
    }
  }

  Future<void> getImage() async {
    XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      imageFile.value = image.path;
      return;
    } else {
      Get.snackbar('Error', 'Gagal mengambil gambar produk');
      // print('gambar produk tidak ada');
      return;
    }
  }

  void inputValidation() {
    if (namaProductController.text == '') {
      Get.snackbar('Error', 'Nama produk tidak boleh kosong');

      return;
    }

    if (kategoriId.isEmpty || kategoriId == '') {
      Get.snackbar('Error', 'Kategori produk tidak boleh kosong');
      return;
    }

    if (merkProductController.text == '') {
      Get.snackbar('Error', 'Merk tidak boleh kosong');
      return;
    }

    if (hrgBeliProductController.text == '') {
      Get.snackbar('Error', 'Harga beli tidak boleh kosong');
      return;
    }

    if (hrgJualProductController.text == '') {
      Get.snackbar('Error', 'Harga jual tidak boleh kosong');
      return;
    }

    if (diskonProductController.text == '') {
      Get.snackbar('Error', 'Diskon tidak boleh kosong');
      return;
    }

    if (stokProductController.text == '') {
      Get.snackbar('Error', 'Stok tidak boleh kosong');
      return;
    }

    Map<String, String> data = {};

    if (isEditable.value != true) {
      // store produk baru
      // bukan edit produk
      if (imageFile.value.isEmpty || imageFile.value == '') {
        Get.snackbar('Error', 'Gambar produk tidak boleh kosong');
        return;
      } else {
        data = {
          'merk': merkProductController.text,
          'id_kategori': kategoriId,
          'nama_produk': namaProductController.text,
          'harga_beli': cleanCurrencyFormat(hrgBeliProductController.text),
          'harga_jual': cleanCurrencyFormat(hrgJualProductController.text),
          'stok': stokProductController.text,
          'diskon': diskonProductController.text
        };
        storeProduct(imageFile.value, data);
        return;
      }
    } else {
      // edit produkk
      if (productId == 0) {
        Get.snackbar('Error', 'Product tidak valid');
        return;
      } else {
        data = {
          'id_produk': productId.toString(),
          'merk': merkProductController.text,
          'id_kategori': kategoriId,
          'nama_produk': namaProductController.text,
          'harga_beli': cleanCurrencyFormat(hrgBeliProductController.text),
          'harga_jual': cleanCurrencyFormat(hrgJualProductController.text),
          'stok': stokProductController.text,
          'diskon': diskonProductController.text
        };

        if (imageFile.value != '') {
          updateProduct(imageFile.value, data);
          return;
        } else {
          updateProduct('', data);
          return;
        }
      }
    }
  }

  Future<void> storeProduct(String imagePath, Map<String, String> data) async {
    isLoadingStore.value = true;
    final responseApi = await apiService.storeProduct(imagePath, data);
    isLoadingStore.value = false;

    if (responseApi.responsestate == Constants.successState) {
      Get.snackbar('Sukses', 'Berhasil menambahkan produk baru');
      productModelList.clear();

      resetStateStore();
      await getProductData();

      return;
    } else {
      Get.snackbar('Gagal', responseApi.message.toString());
      return;
    }
  }

  Future<void> updateProduct(String imagePath, Map<String, String> data) async {
    isLoadingStore.value = true;
    final responseApi = await apiService.updateProduct(imagePath, data);
    isLoadingStore.value = false;

    if (responseApi.responsestate == Constants.successState) {
      Get.snackbar('Sukses', 'Berhasil mengubah data');
      productModelList.clear();

      resetStateStore();
      await getProductData();

      return;
    } else {
      Get.snackbar('Gagal', responseApi.message.toString());
      return;
    }
  }

  void resetStateStore() {
    namaProductController.text = '';
    kategoriId = '';
    merkProductController.text = '';
    hrgBeliProductController.text = '';
    hrgJualProductController.text = '';
    diskonProductController.text = '';
    stokProductController.text = '';
    imageFile.value = '';
    productModel = const ProductModel();
    isEditable.value = false;
    productId = 0;
  }

  String cleanCurrencyFormat(String currency) {
    // Menghapus 'Rp. ' dan semua titik
    String noRp = currency.replaceAll('Rp. ', '').replaceAll('.', '');
    // Menghapus koma dan semua setelahnya
    String cleanNumber = noRp.split(',')[0];

    return cleanNumber;
  }

  Future<void> destroy(int productId) async {
    final responseApi = await apiService.destroyProduct(productId);
    if (responseApi.responsestate == Constants.successState) {
      Get.snackbar('Berhasil', 'Produk berhasil di hapus');

      productModelList.clear();

      await getProductData();
    } else {
      Get.snackbar('Error', responseApi.message.toString());
      return;
    }
  }

  void setProductEdit() {
    if (productModel.idProduk != 0) {
      isEditable.value = true;
      namaProductController.text = productModel.namaProduk.toString();
      merkProductController.text = productModel.merk.toString();
      hrgBeliProductController.text = productModel.hargaBeli.toString();
      hrgJualProductController.text = productModel.hargaJual.toString();
      diskonProductController.text = productModel.diskon.toString();
      stokProductController.text = productModel.stok.toString();
      productId = productModel.idProduk;
      return;
    }

    return;
  }
}
