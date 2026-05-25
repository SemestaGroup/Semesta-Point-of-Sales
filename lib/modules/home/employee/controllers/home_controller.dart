import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:semesta_pos/modules/home/employee/controllers/shift_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';
import 'package:semesta_pos/core/models/api/response_api_model.dart';
import 'package:semesta_pos/modules/member/controllers/member_controller.dart';
import 'package:semesta_pos/core/models/category/kategori_model.dart';
import 'package:uuid/uuid.dart';
import 'package:semesta_pos/core/util/constans.dart';
import 'package:semesta_pos/core/models/member/member_model.dart';
import 'package:semesta_pos/core/models/penjualan/penjualan_model.dart';
import 'package:semesta_pos/core/models/penjualan_detail/penjualan_detail_model.dart';
import 'package:semesta_pos/core/models/product/product_model.dart';
import 'package:semesta_pos/core/services/app_service.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/core/services/remote/api_service.dart';
import 'package:semesta_pos/core/services/user_service.dart';
import 'package:semesta_pos/core/models/payment/pos_payment_model.dart';
import 'package:semesta_pos/core/services/sync_service.dart';
import 'package:semesta_pos/core/services/promo_service.dart';
import 'package:semesta_pos/modules/order/controllers/order_controller.dart';
import 'package:semesta_pos/routes/app_pages.dart';
import 'package:semesta_pos/modules/setting/controllers/setting_controller.dart';
import 'package:semesta_pos/modules/dashboard/employee/controllers/dashboard_employee_controller.dart';
import 'package:semesta_pos/modules/dashboard/admin/controllers/dashboard_admin_controller.dart';
import 'package:semesta_pos/modules/report/controllers/report_controller.dart';
import 'package:semesta_pos/core/services/error_log_service.dart';
import 'package:semesta_pos/modules/recap/controllers/recap_controller.dart';

class HomeController extends GetxController {
  RxList<dynamic> foodList = [].obs;
  RxBool isLoadingProduct = true.obs;
  RxList<KategoriModel> kategoryModelList = <KategoriModel>[].obs;
  RxList<ProductModel> productModelList = <ProductModel>[].obs;
  RxList<ProductModel> orderList = <ProductModel>[].obs;
  ApiService get apiService => Get.find<ApiService>();

  RxList<PenjualanDetailModel> penjualanDetailModelList =
      <PenjualanDetailModel>[].obs;
  Map<int, TextEditingController> controllerStock = {};
  RxBool isLoadingMember = false.obs;
  AppService get appService {
    if (!Get.isRegistered<AppService>()) {
      Get.put(AppService(), permanent: true);
    }
    return Get.find<AppService>();
  }

  ShiftController get _shiftController {
    if (!Get.isRegistered<ShiftController>()) {
      Get.put(ShiftController(), permanent: true);
    }
    return Get.find<ShiftController>();
  }

  DatabaseService get _dbService {
    if (!Get.isRegistered<DatabaseService>()) {
      Get.put(DatabaseService(), permanent: true);
    }
    return Get.find<DatabaseService>();
  }

  TextEditingController controllerDiskon = TextEditingController();
  TextEditingController controllerDiterima = TextEditingController();
  TextEditingController controllerKembalian = TextEditingController();
  RxInt memberId = 0.obs;
  RxList<MemberModel> memberList = <MemberModel>[].obs;
  RxInt totalTransaction = 0.obs;
  RxBool isLoadingTransaction = false.obs;
  RxBool isProcessingPayment = false.obs;
  RxBool isSyncingDirectly = false.obs;
  RxString lastSyncError = "".obs; // Captures detailed server response messages
  UserService get userService {
    if (!Get.isRegistered<UserService>()) {
      Get.put(UserService(), permanent: true);
    }
    return Get.find<UserService>();
  }

  PromoService get promoService {
    if (!Get.isRegistered<PromoService>()) {
      Get.put(PromoService(), permanent: true);
    }
    return Get.find<PromoService>();
  }

  PromoDiscount _calculateBestPriceForCartItem(
      int idProduk, int dynamicPrice, String orderType) {
    final product =
        productModelList.firstWhereOrNull((p) => p.idProduk == idProduk);
    final productDiscountTotal = product?.discountTotal ?? 0;
    final productDiscountType = product?.discountType ?? 'percent';

    return promoService.calculateBestPrice(
      productId: idProduk,
      productBrandIdStr: null,
      dynamicPrice: dynamicPrice,
      orderType: orderType,
      productDiscountTotal: productDiscountTotal,
      productDiscountType: productDiscountType,
    );
  }

  int totalDiterima = 0;
  int totalHarga = 0;
  RxInt disscount = 0.obs;
  RxString selectedOrderType = "Dine In".obs;
  RxString orderNote = "".obs;
  Rx<MemberModel?> selectedMember = Rx<MemberModel?>(null);
  final searchFocusNode = FocusNode();
  String? currentIdPos;
  String?
      originalTglPenjualan; // preserved creation date when editing an existing order

  // Official server data for the active order
  RxString currentRemoteNumber = "".obs;
  RxInt currentRemoteId = 0.obs;

  RxInt subtotalRaw = 0.obs;
  RxDouble taxRate =
      0.0.obs; // Set default tax to 0 as it's not yet coming from API/Settings
  RxInt taxAmount = 0.obs;

  var isAddingCustomer = false.obs;
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  // Custom Discount States
  RxInt manualDiscountValue = 0.obs;
  final RxBool manualDiscountIsPercent = false.obs;

  final RxBool isRefundMode = false.obs;
  RxBool isSavingSettings = false.obs;

  RxString customerLabel = "".obs;
  RxString searchMemberQuery = "".obs;
  RxList<MemberModel> filteredMemberList = <MemberModel>[].obs;
  RxInt manualCashAmount = 0.obs;

  // Dynamic Order Types discovered from products
  RxList<String> availableOrderTypes = <String>["Dine In", "Take Away"].obs;

  RxList<Map<String, dynamic>> cashlessPaymentModes =
      <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> allPaymentModes = <Map<String, dynamic>>[].obs;

  String get customerName {
    if (customerLabel.value.isNotEmpty) return customerLabel.value;
    if (selectedMember.value != null) {
      return selectedMember.value!.nama ?? 'Customer';
    }
    return 'Walk-in Customer';
  }

  @override
  void onInit() {
    super.onInit();
    fetchPaymentModes();

    // Reactively reload if background sync finishes while the app is open (Fresh Install Fix)
    if (Get.isRegistered<SyncService>()) {
      ever(Get.find<SyncService>().syncStatus, (String status) {
        if (status == "Sync Complete" || status.contains("Updated")) {
          // If we currently have no payment modes (besides potentially 'cash' which is often hardcoded or first), reload.
          if (allPaymentModes.isEmpty || cashlessPaymentModes.isEmpty) {
            fetchPaymentModes();
          }
          // Refresh catalog and members seamlessly
          getProductData(silent: true);
          getMember(silent: true);
          // Reload promos in case they were updated during sync
          if (Get.isRegistered<PromoService>()) {
            Get.find<PromoService>().loadPromos();
          }
        }
      });
    }
    // Reactive totals calculation
    ever(penjualanDetailModelList, (_) => calculateTotals());
    ever(appService.useDefaultDiscount, (_) => calculateTotals());
    ever(taxRate, (_) => calculateTotals());

    // When order type changes, recalculate prices for all items in cart
    ever(selectedOrderType, (String newType) {
      if (penjualanDetailModelList.isEmpty) return;

      final updated = penjualanDetailModelList.map((item) {
        if (item.orderTypesJson.isEmpty) return item;

        // 1. Calculate new base price for the selected order type
        final basePrice = getDynamicPrice(item.orderTypesJson, newType,
            item.hargaAwal > 0 ? item.hargaAwal : item.hargaJual);

        // 2. Apply existing item-level discount logic to the new base price
        final promoDiscount =
            _calculateBestPriceForCartItem(item.idProduk, basePrice, newType);
        int newPrice = promoDiscount.finalPrice;

        return item.copyWith(
          hargaAwal: basePrice,
          hargaJual: newPrice,
          subtotal: newPrice * item.jumlah,
          orderType: newType,
          discountTotal: promoDiscount.discountTotal,
          discountType: promoDiscount.discountType,
        );
      }).toList();

      penjualanDetailModelList.value = updated;
      calculateTotals();
    });

    // Reactive member filtering
    ever(searchMemberQuery, (String query) {
      if (query.isEmpty) {
        filteredMemberList.value = memberList;
      } else {
        final q = query.toLowerCase();
        filteredMemberList.value = memberList.where((m) {
          final n = m.nama?.toLowerCase() ?? "";
          final p = m.telepon?.toLowerCase() ?? "";
          return n.contains(q) || p.contains(q);
        }).toList();
      }
    });

    // Keep filtered list updated when main list changes
    ever(memberList, (List<MemberModel> list) {
      searchMemberQuery.refresh(); // re-trigger filtering
    });
  }

  @override
  void onReady() {
    super.onReady();
    discoverOrderTypes();
    updateCategoriesForBrand().then((_) => getProductData());
  }

  RxList<ProductModel> productModelList2 = <ProductModel>[].obs;

  RxList<Map<String, dynamic>> brandList = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> categoryList = <Map<String, dynamic>>[].obs;
  RxInt selectedBrandId = 0.obs;
  RxInt selectedCategoryId = 0.obs;
  // Accordion state: which brand is currently expanded in the sidebar (-1 = none, 0 = "All" pseudo-brand)
  RxInt expandedBrandId = (-1).obs;

  RxString searchQuery = "".obs;
  Rx<String?> currentParentId = Rx<String?>(null);
  final TextEditingController searchProductController = TextEditingController();

  Future<void> fetchPaymentModes() async {
    try {
      final dbService = Get.find<DatabaseService>();
      final List<Map<String, dynamic>> results = await dbService
          .query('payment_modes', where: 'active = ?', whereArgs: ['1']);
      allPaymentModes.value = results;
      cashlessPaymentModes.value = results.where((mode) {
        final n = (mode['name'] ?? '').toString().toLowerCase();
        return n != 'cash' && n != 'tunai' && n != 'cash/tunai';
      }).toList();
    } catch (e) {
      debugPrint('HomeController: Error fetching payment modes: $e');
    }
  }

  Future<void> getProductData({bool silent = false}) async {
    try {
      productModelList.clear();
      if (!silent) isLoadingProduct.value = true;

      // Only show brands that have at least one active product
      final activeBrandRows = await _dbService.rawQuery(
          "SELECT DISTINCT id_brand FROM products WHERE status = 'active' AND id_brand IS NOT NULL");
      final activeBrandIds = activeBrandRows.map((r) => r['id_brand']).toSet();
      final localBrands = await _dbService.query('brands');
      brandList.value = localBrands
          .where((b) => activeBrandIds.contains(b['id_brand']))
          .toList();

      // Auto-expand and select the first brand if nothing is selected yet
      if (selectedBrandId.value == 0 && brandList.isNotEmpty) {
        final firstBrandId = brandList.first['id_brand'] as int;
        selectedBrandId.value = firstBrandId;
        expandedBrandId.value = firstBrandId;
        // Ensure category sub-menu is updated for this default selection
        unawaited(updateCategoriesForBrand());
      }

      String where = "status = 'active'";
      List<dynamic> whereArgs = [];
      String table = 'products';

      if (searchQuery.value.isNotEmpty) {
        // Global search: Ignore brand, category, and parent filters
        where += ' AND (nama_produk LIKE ? OR kode_produk LIKE ?)';
        whereArgs.add('%${searchQuery.value}%');
        whereArgs.add('%${searchQuery.value}%');
      } else {
        if (selectedBrandId.value != 0) {
          where += ' AND id_brand = ?';
          whereArgs.add(selectedBrandId.value);
        }

        if (selectedCategoryId.value != 0) {
          if (selectedBrandId.value == 0) {
            final cat = await _dbService.query('categories',
                where: 'id_kategori = ?',
                whereArgs: [selectedCategoryId.value]);
            if (cat.isNotEmpty) {
              final catName = cat[0]['nama_kategori'];
              table =
                  'products p INNER JOIN categories c ON p.id_kategori = c.id_kategori';
              where += ' AND c.nama_kategori = ?';
              whereArgs.add(catName);
            }
          } else {
            where += ' AND id_kategori = ?';
            whereArgs.add(selectedCategoryId.value);
          }
        }

        if (currentParentId.value == null) {
          where += ' AND (parent IS NULL OR parent = "" OR parent = "null")';
        } else {
          where += ' AND parent = ?';
          whereArgs.add(currentParentId.value);
        }
      }

      final localProducts = await _dbService.query(table,
          where: where,
          whereArgs: whereArgs,
          columns: table == 'products' ? null : ['p.*']);

      isLoadingProduct.value = false;

      if (localProducts.isNotEmpty) {
        productModelList.addAll(localProducts.map((e) {
          return ProductModel.fromJson({
            'id': e['id_produk'],
            'category_id': e['id_kategori'],
            'name': e['nama_produk'],
            'description': e['description'],
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
            'parent': e['parent'],
            'children': e['children'],
          });
        }).toList());
        return;
      }

      debugPrint('Tidak ada data produk di database lokal');
      return;
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data produk lokal: $e');
      return;
    }
  }

  Future<void> filterByBrand(int brandId) async {
    searchFocusNode.unfocus();
    if (selectedBrandId.value == brandId) {
      selectedBrandId.value = 0;
    } else {
      selectedBrandId.value = brandId;
    }
    selectedCategoryId.value = 0;
    currentParentId.value = null;
    searchQuery.value = "";
    searchProductController.clear();
    await updateCategoriesForBrand();
    await getProductData();
  }

  /// Directly sets the brand filter without toggle logic (used by the accordion sidebar).
  Future<void> filterByBrandDirect(int brandId) async {
    searchFocusNode.unfocus();
    selectedBrandId.value = brandId;
    selectedCategoryId.value = 0;
    currentParentId.value = null;
    searchQuery.value = "";
    searchProductController.clear();
    await updateCategoriesForBrand();
    await getProductData();
  }

  /// Returns a dynamic product image URL derived from the logged-in user's base_url.
  /// Falls back to a generic flinkaja URL if no base_url is stored.
  String getProductImageUrl(String imgPath) {
    String base = userService.getBaseUrl();
    if (base == 'Guest' || base.isEmpty) {
      base = 'https://flinkaja.com/';
    }
    if (!base.endsWith('/')) base += '/';
    // Strip leading slash from imgPath to avoid double-slash
    final cleanPath = imgPath.startsWith('/') ? imgPath.substring(1) : imgPath;
    // Compose: <base_url>uploads/products/<cleanPath>
    return '${base}uploads/products/$cleanPath';
  }

  Future<void> filterByCategory(int categoryId) async {
    searchFocusNode.unfocus();
    if (selectedCategoryId.value == categoryId) {
      selectedCategoryId.value = 0;
    } else {
      selectedCategoryId.value = categoryId;
    }
    currentParentId.value = null;
    searchQuery.value = "";
    searchProductController.clear();
    await getProductData();
  }

  Future<void> updateCategoriesForBrand() async {
    try {
      // Always filter categories that have at least one active product
      if (selectedBrandId.value == 0) {
        final activeCatRows = await _dbService.rawQuery(
            "SELECT DISTINCT id_kategori FROM products WHERE status = 'active'");
        final activeCatIds = activeCatRows.map((r) => r['id_kategori']).toSet();
        final allCats = await _dbService.rawQuery(
            'SELECT MIN(id_kategori) as id_kategori, nama_kategori, brand_name, commodity_code FROM categories GROUP BY LOWER(TRIM(nama_kategori))');
        final list = allCats
            .where((c) => activeCatIds.contains(c['id_kategori']))
            .toList();
        list.sort((a, b) {
          final nameA = (a['nama_kategori']?.toString() ?? '').toLowerCase().trim();
          final nameB = (b['nama_kategori']?.toString() ?? '').toLowerCase().trim();
          return nameA.compareTo(nameB);
        });
        categoryList.value = list;
      } else {
        // Active products in the selected brand
        final productsInBrand = await _dbService.query('products',
            columns: ['id_kategori'],
            where: "id_brand = ? AND status = 'active'",
            whereArgs: [selectedBrandId.value],
            distinct: true);

        final List<int> categoryIds = productsInBrand
            .map((p) => p['id_kategori'] is int
                ? (p['id_kategori'] as int)
                : int.tryParse(p['id_kategori'].toString()) ?? 0)
            .where((id) => id != 0)
            .toList();

        final List<Map<String, dynamic>> allCats =
            await _dbService.query('categories');

        List<Map<String, dynamic>> filteredCats = allCats
            .where((cat) => categoryIds.contains(cat['id_kategori']))
            .toList();

        // Fallback: match by brand_name if no category IDs found
        if (filteredCats.isEmpty) {
          final brands = await _dbService.query('brands',
              where: 'id_brand = ?', whereArgs: [selectedBrandId.value]);
          if (brands.isNotEmpty) {
            final brandName =
                brands[0]['nama_brand']?.toString().toLowerCase().trim();
            filteredCats = allCats.where((cat) {
              final catBrand =
                  cat['brand_name']?.toString().toLowerCase().trim();
              return catBrand != null && catBrand == brandName;
            }).toList();
          }
        }

        // Deduplicate by name
        final Map<String, Map<String, dynamic>> uniqueCats = {};
        for (var cat in filteredCats) {
          final name = cat['nama_kategori']?.toString().trim() ?? '';
          if (name.isNotEmpty && !uniqueCats.containsKey(name.toLowerCase())) {
            uniqueCats[name.toLowerCase()] = cat;
          }
        }
        
        final list = uniqueCats.values.toList();
        list.sort((a, b) {
          final nameA = (a['nama_kategori']?.toString() ?? '').toLowerCase().trim();
          final nameB = (b['nama_kategori']?.toString() ?? '').toLowerCase().trim();
          return nameA.compareTo(nameB);
        });
        categoryList.value = list;
      }
    } catch (e) {
      debugPrint("Error fetching categories for brand: $e");
    }
  }

  Future<void> searchProduct(String query) async {
    searchQuery.value = query.trim();
    await getProductData();
  }

  void setupControllers() {
    for (var order in penjualanDetailModelList) {
      controllerStock[order.idProduk] =
          TextEditingController(text: order.jumlah.toString());
    }
  }

  void handleProductTap(ProductModel productModel) {
    searchFocusNode.unfocus();

    bool hasChildren = productModel.children != null &&
        productModel.children != "[]" &&
        productModel.children != "null" &&
        productModel.children!.isNotEmpty;

    if (hasChildren) {
      currentParentId.value = productModel.idProduk.toString();
      searchQuery.value = "";
      searchProductController.clear();
      getProductData();
    } else {
      addProduct(productModel);
    }
  }

  Future<void> addProduct(ProductModel productModel) async {
    var index = penjualanDetailModelList
        .indexWhere((element) => element.idProduk == productModel.idProduk);

    String currentItemType = selectedOrderType.value;

    // Determine the active price according to order type
    final dynamicPrice = getDynamicPrice(
        productModel.orderTypes, currentItemType, productModel.hargaJual);

    final promoDiscount = _calculateBestPriceForCartItem(
        productModel.idProduk, dynamicPrice, currentItemType);
    int finalPrice = promoDiscount.finalPrice;

    if (!appService.allowZeroStock.value && productModel.stok <= 0) {
      Get.snackbar('Error', 'Out of stock');
      return;
    }

    if (index != -1) {
      var productSelected = penjualanDetailModelList[index];

      if (!appService.allowZeroStock.value &&
          productSelected.jumlah + 1 > productModel.stok) {
        Get.snackbar('Error', 'Stok produk tidak cukup');
        return;
      }
      var updatedProduct = productSelected.copyWith(
        jumlah: productSelected.jumlah + 1,
        subtotal: finalPrice * (productSelected.jumlah + 1),
        hargaJual: finalPrice,
        hargaAwal: dynamicPrice,
        discountTotal: promoDiscount.discountTotal,
        discountType: promoDiscount.discountType,
      );
      penjualanDetailModelList[index] = updatedProduct;
      penjualanDetailModelList.refresh();

      controllerStock[productModel.idProduk] = TextEditingController(
        text: updatedProduct.jumlah.toString(),
      );

      calculateTotals();
      return;
    }

    final newProductSelected = PenjualanDetailModel(
      idProduk: productModel.idProduk,
      productName: productModel.namaProduk,
      description: productModel.description,
      hargaJual: finalPrice,
      hargaAwal: dynamicPrice,
      jumlah: 1,
      totalStock: productModel.stok,
      subtotal: finalPrice,
      orderType: currentItemType,
      orderTypesJson: productModel.orderTypes ?? "",
      note: "",
      discountTotal: promoDiscount.discountTotal,
      discountType: promoDiscount.discountType,
    );
    penjualanDetailModelList.add(newProductSelected);
    controllerStock[productModel.idProduk] = TextEditingController(
      text: newProductSelected.jumlah.toString(),
    );
    calculateTotals();
    update();
  }

  /// Scans all products in SQLite to find unique order types (dinein, gofood, etc.)
  /// and updates the [availableOrderTypes] list for the UI.
  Future<void> discoverOrderTypes() async {
    try {
      final rows = await _dbService.rawQuery(
          "SELECT DISTINCT order_types FROM products WHERE order_types IS NOT NULL AND order_types != ''");

      Set<String> discoveredKeys = {
        "dinein",
        "takeaway"
      }; // Start with defaults

      for (var row in rows) {
        final rawJson = row['order_types']?.toString() ?? "";
        if (rawJson.isEmpty || rawJson == "null") continue;

        try {
          final decoded = jsonDecode(rawJson);
          dynamic finalData = decoded;
          if (decoded is String) {
            try {
              finalData = jsonDecode(decoded);
            } catch (_) {}
          }

          if (finalData is List) {
            for (var item in finalData) {
              if (item is Map) {
                for (var key in item.keys) {
                  final k = key.toString().toLowerCase().trim();
                  if (k != "delivery") discoveredKeys.add(k);
                }
              }
            }
          }
        } catch (_) {}
      }

      // Map keys to labels using Constants
      final List<String> labels = discoveredKeys.map((key) {
        return Constants.orderTypeLabels[key] ?? key.capitalizeFirst!;
      }).toList();

      // Sort to keep Dine In, Take Away, Delivery at start if possible
      labels.sort((a, b) {
        const priority = {"Dine In": 0, "Take Away": 1};
        int pa = priority[a] ?? 100;
        int pb = priority[b] ?? 100;
        if (pa != pb) return pa.compareTo(pb);
        return a.compareTo(b);
      });

      availableOrderTypes.value = labels;
      debugPrint(
          "HomeController: Discovered ${labels.length} order types: $labels");
    } catch (e) {
      debugPrint("HomeController: discoverOrderTypes error: $e");
    }
  }

  int getDynamicPrice(
      String? orderTypesRaw, String currentOrderTypeLabel, int defaultPrice) {
    if (orderTypesRaw == null ||
        orderTypesRaw.isEmpty ||
        orderTypesRaw == "null") {
      return defaultPrice;
    }

    try {
      // Convert Label back to Key (e.g. "Dine In" -> "dinein")
      String searchKey = "";

      // USER REQUEST: Take Away and Dine In use the same price (dinein)
      if (currentOrderTypeLabel == "Take Away" ||
          currentOrderTypeLabel == "Dine In") {
        searchKey = "dinein";
      } else {
        Constants.orderTypeLabels.forEach((key, label) {
          if (label == currentOrderTypeLabel) searchKey = key;
        });
      }

      // Fallback: lowercase-no-spaces if not in map
      if (searchKey.isEmpty) {
        searchKey = currentOrderTypeLabel.toLowerCase().replaceAll(' ', '');
      }

      final decoded = jsonDecode(orderTypesRaw);
      dynamic finalData = decoded;
      if (decoded is String &&
          (decoded.startsWith('[') || decoded.startsWith('{'))) {
        try {
          finalData = jsonDecode(decoded);
        } catch (_) {}
      }

      if (finalData is! List) return defaultPrice;

      List<dynamic> parsedList = finalData;
      for (var item in parsedList) {
        if (item is Map && item.containsKey(searchKey)) {
          return double.tryParse(item[searchKey].toString())?.toInt() ??
              defaultPrice;
        }
      }
    } catch (e) {
      debugPrint("HomeController: getDynamicPrice error: $e");
    }

    return defaultPrice;
  }

  void calculateTotals() {
    int subtotal = 0;
    for (var item in penjualanDetailModelList) {
      if (item.isRefund) continue;
      subtotal += item.subtotal;
    }
    subtotalRaw.value = subtotal;

    int effectiveDiscountAmount = 0;

    // Prioritize manual discount if set
    if (manualDiscountValue.value > 0) {
      if (manualDiscountIsPercent.value) {
        effectiveDiscountAmount =
            (subtotal * (manualDiscountValue.value / 100)).round();
        disscount.value = manualDiscountValue
            .value; // Store percent for UI if in percent mode
      } else {
        effectiveDiscountAmount = manualDiscountValue.value;
        // In fixed mode, we show 0 in the 'percent' field or handle it accordingly
        disscount.value = 0;
      }
    } else if (appService.useDefaultDiscount.value) {
      // Fallback to default app-wide discount
      int discountPercent = appService.appModel.value.diskon;
      disscount.value = discountPercent;
      effectiveDiscountAmount = (subtotal * (discountPercent / 100)).round();
    } else {
      disscount.value = 0;
    }

    int afterDiscount = subtotal - effectiveDiscountAmount;
    taxAmount.value = (afterDiscount * (taxRate.value / 100)).round();

    totalTransaction.value = afterDiscount + taxAmount.value;
    totalHarga = subtotal;

    // We can store the effective amount for API use if needed,
    // but we can also recalculate in _pushOrderToApi
  }

  void removeItemCart(int index) {
    penjualanDetailModelList.removeAt(index);
    penjualanDetailModelList.refresh();
    calculateTotals();
  }

  /// Adjust the qty of a pending (not-yet-confirmed) refund row.
  /// [refundIndex] = index of the refund item in the list.
  /// [newRefundQty] = new desired refund qty (0 = cancel refund entirely).
  void adjustRefundQty(int refundIndex, int newRefundQty) {
    final refundItem = penjualanDetailModelList[refundIndex];
    if (!refundItem.isRefund) return;

    final originalQty = refundItem.originalQty > 0
        ? refundItem.originalQty
        : refundItem.jumlah; // fallback if originalQty wasn't stored

    // Find corresponding normal item for the same product
    final normalIdx = penjualanDetailModelList.indexWhere(
      (i) => !i.isRefund && i.idProduk == refundItem.idProduk,
    );

    if (newRefundQty <= 0) {
      // Cancel refund entirely
      if (normalIdx != -1) {
        // Restore normal item to full original qty
        final normal = penjualanDetailModelList[normalIdx];
        penjualanDetailModelList[normalIdx] = normal.copyWith(
          jumlah: originalQty,
          subtotal: normal.hargaJual * originalQty,
        );
        penjualanDetailModelList.removeAt(refundIndex);
      } else {
        // Full-refund row (in-place, remoteItemId preserved): restore to normal
        penjualanDetailModelList[refundIndex] = refundItem.copyWith(
          jumlah: originalQty,
          isRefund: false,
          orderType: '',
        );
      }
    } else {
      // Update refund row qty
      penjualanDetailModelList[refundIndex] = refundItem.copyWith(
        jumlah: newRefundQty,
        subtotal: refundItem.hargaJual * newRefundQty,
      );

      final newNormalQty = originalQty - newRefundQty;
      if (normalIdx != -1) {
        // Update normal row qty
        final normal = penjualanDetailModelList[normalIdx];
        penjualanDetailModelList[normalIdx] = normal.copyWith(
          jumlah: newNormalQty,
          subtotal: normal.hargaJual * newNormalQty,
        );
      } else {
        // Full-refund case: insert a new normal row with remaining qty
        final normalItem = refundItem.copyWith(
          jumlah: newNormalQty,
          isRefund: false,
          orderType: '',
          subtotal: refundItem.hargaJual * newNormalQty,
        );
        // Insert BEFORE the refund row
        penjualanDetailModelList.insert(refundIndex, normalItem);
      }
    }

    penjualanDetailModelList.refresh();
    calculateTotals();
  }

  void updateItemCart(int index, {int? qty, String? note, String? orderType}) {
    var item = penjualanDetailModelList[index];

    // --- Refund Logic ---
    if (orderType == 'Refund' && !item.isRefund) {
      int refundQty = qty ?? item.jumlah;

      // Cap to original ordered quantity
      if (item.originalQty > 0 && refundQty > item.originalQty) {
        refundQty = item.originalQty;
      }
      if (refundQty > item.jumlah && item.originalQty <= 0) {
        refundQty = item.jumlah;
      }

      // Check if there's already a refund row for this same product right after this item
      final existingRefundIdx = penjualanDetailModelList.indexWhere(
        (r) => r.isRefund && r.idProduk == item.idProduk,
      );

      if (refundQty == item.jumlah) {
        // Full refund: convert item in-place to a refund row.
        // KEEP the original remoteItemId so the PUT body can emit the
        // original item (with itemid) alongside the refund entry.
        // calculateTotals() skips isRefund=true rows so total is correct.
        penjualanDetailModelList[index] = item.copyWith(
          orderType: 'Refund',
          isRefund: true,
          // remoteItemId is intentionally NOT zeroed — the PUT builder uses it
          // to distinguish a full-refund row from a split-refund row.
          note: note ?? item.note,
        );
        // Remove stale separate refund row if any
        if (existingRefundIdx != -1 && existingRefundIdx != index) {
          penjualanDetailModelList.removeAt(existingRefundIdx);
        }
      } else {
        int remainingQty = item.jumlah - refundQty;

        // Update normal item with remaining qty
        penjualanDetailModelList[index] = item.copyWith(
          jumlah: remainingQty,
          subtotal: item.hargaJual * remainingQty,
        );

        if (existingRefundIdx != -1) {
          // Merge into existing refund row
          var existing = penjualanDetailModelList[existingRefundIdx];
          int mergedQty = existing.jumlah + refundQty;
          // Ensure merged qty doesn't exceed original qty
          if (item.originalQty > 0 && mergedQty > item.originalQty) {
            mergedQty = item.originalQty;
          }
          penjualanDetailModelList[existingRefundIdx] = existing.copyWith(
            jumlah: mergedQty,
            subtotal: existing.hargaJual * mergedQty,
          );
        } else {
          // Insert new refund row below current item
          var refundItem = item.copyWith(
            jumlah: refundQty,
            orderType: 'Refund',
            isRefund: true,
            remoteItemId: 0,
            subtotal: item.hargaJual * refundQty,
            note: note ?? item.note,
          );
          penjualanDetailModelList.insert(index + 1, refundItem);
        }
      }

      penjualanDetailModelList.refresh();
      calculateTotals();
      return;
    }
    // --- End Refund Logic ---

    int dynamicPrice = item.hargaAwal > 0 ? item.hargaAwal : item.hargaJual;
    int finalPrice = item.hargaJual;
    int currentDiscountTotal = item.discountTotal;
    String currentDiscountType = item.discountType;

    if (orderType != null && orderType != item.orderType) {
      var productDb =
          productModelList.firstWhereOrNull((p) => p.idProduk == item.idProduk);

      // Use previous hargaAwal or fallback to product base price
      int defaultBasePrice = productDb?.hargaJual ??
          (item.hargaAwal > 0 ? item.hargaAwal : item.hargaJual);

      // Calculate new base price for the NEW order type
      dynamicPrice =
          getDynamicPrice(item.orderTypesJson, orderType, defaultBasePrice);

      final promoDiscount = _calculateBestPriceForCartItem(
          item.idProduk, dynamicPrice, orderType);
      finalPrice = promoDiscount.finalPrice;
      currentDiscountTotal = promoDiscount.discountTotal;
      currentDiscountType = promoDiscount.discountType;
    }

    penjualanDetailModelList[index] = item.copyWith(
      jumlah: qty ?? item.jumlah,
      note: note ?? item.note,
      orderType: orderType ?? item.orderType,
      hargaAwal: dynamicPrice,
      hargaJual: finalPrice, // UPDATE HARGA
      discountTotal: currentDiscountTotal,
      discountType: currentDiscountType,
      subtotal:
          (qty ?? item.jumlah) * finalPrice, // RECALC SUBTOTAL WITH NEW PRICE
    );
    penjualanDetailModelList.refresh();
    calculateTotals();
  }

  Future<void> editQty(
      PenjualanDetailModel penjualanDetailModel, int qty) async {
    isLoadingMember.value = true;
    var index = penjualanDetailModelList.indexWhere(
        (element) => element.idProduk == penjualanDetailModel.idProduk);

    if (!appService.allowZeroStock.value &&
        penjualanDetailModel.totalStock <= 0) {
      Get.snackbar('Error', 'Produk telah habis');
      return;
    }

    if (index != -1) {
      var productSelected = penjualanDetailModelList[index];

      if (!appService.allowZeroStock.value &&
          qty > penjualanDetailModel.totalStock) {
        Get.snackbar('Error', 'Stok produk tidak cukup');
        return;
      }
      var updatedProduct = productSelected.copyWith(
        jumlah: qty,
        subtotal: productSelected.hargaJual * qty,
      );
      penjualanDetailModelList[index] = updatedProduct;
      penjualanDetailModelList.refresh();

      controllerStock[penjualanDetailModel.idProduk] = TextEditingController(
        text: qty.toString(),
      );

      isLoadingMember.value = false;
      return;
    }
  }

  void deleteProduct(int index) {
    penjualanDetailModelList.removeAt(index);
  }

  void _resetPOSUIState() {
    penjualanDetailModelList.clear();
    selectedMember.value = null;
    orderNote.value = "";
    customerLabel.value = "";
    selectedOrderType.value = "Dine In";
    manualDiscountValue.value = 0;
    manualDiscountIsPercent.value = false;
    manualCashAmount.value = 0;
    currentIdPos = null;
    currentRemoteId.value = 0;
    currentRemoteNumber.value = '';
    originalTglPenjualan = null;
    penjualanDetailModelList.refresh();
    calculateTotals();

    // Trigger immediate badge count update
    try {
      if (Get.isRegistered<DashboardEmployeeController>()) {
        Get.find<DashboardEmployeeController>().updateActiveOrderCount();
      }
      if (Get.isRegistered<DashboardAdminController>()) {
        Get.find<DashboardAdminController>().updateActiveOrderCount();
      }
    } catch (_) {}
  }

  void clearOrder() {
    _resetPOSUIState();
    // Get.snackbar(
    //   'POS Cleared',
    //   'Cart and customer has been reset to default state.',
    //   snackPosition: SnackPosition.BOTTOM,
    //   backgroundColor: Colors.blueGrey.shade700,
    //   colorText: Colors.white,
    //   duration: const Duration(seconds: 2),
    //   icon: const Icon(CupertinoIcons.refresh_thick, color: Colors.white),
    // );
  }

  Future<void> cancelOrder() async {
    // 1. If it's a saved/remote order, prompt for remote cancel (status update)
    if (currentIdPos != null) {
      final existing = await _dbService.query('transactions',
          where: 'id_pos = ?', whereArgs: [currentIdPos]);

      if (existing.isNotEmpty) {
        final map = existing.first;
        final localId = map['id_penjualan'] as int;
        final remoteId = map['id_penjualan_remote'] as int?;

        // Show confirmation dialog
        bool confirmed = await Get.dialog<bool>(AlertDialog(
              title: const Text("Cancel Order"),
              content: const Text(
                  "Are you sure you want to cancel this order? This will mark it as cancelled on the server."),
              actions: [
                TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text("No")),
                ElevatedButton(
                  onPressed: () => Get.back(result: true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Yes, Cancel",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            )) ??
            false;

        if (confirmed) {
          // Cleanup existing sync queue for this order to avoid conflicts/duplicates
          // This removes any old partial status updates or pending create/updates
          final db = await _dbService.database;
          await db.delete(
            'sync_queue',
            where: '(local_id = ? OR endpoint LIKE ?) AND endpoint LIKE ?',
            whereArgs: [
              localId.toString(),
              '%pos_order/$remoteId',
              '%pos_order%'
            ],
          );

          // Update Local DB Status to 5 (Cancelled)
          await _dbService.update('transactions', {'status': 5, 'is_synced': 0},
              'id_penjualan = ?', [localId]);

          // If it has a remote ID, enqueue a full PUT to update status
          if (remoteId != null) {
            // Fetch items for the full payload
            final detailItems = await _dbService.query('transaction_details',
                where: 'id_penjualan = ?', whereArgs: [localId]);

            final itemsArray = <Map<String, dynamic>>[];
            for (int i = 0; i < detailItems.length; i++) {
              final item = detailItems[i];

              // Calculate real nominal discount for long_description
              final discTotal = (item['discountTotal'] as num? ?? 0).toInt();
              final discType = item['discountType'] as String? ?? 'percent';
              final harga = (item['harga_jual'] as num? ?? 0).toInt();
              int nominalItemDisc = 0;
              if (discTotal > 0) {
                if (discType == 'percent') {
                  nominalItemDisc = (harga * discTotal / 100).round();
                } else {
                  nominalItemDisc = discTotal;
                }
              }
              final longDesc = nominalItemDisc > 0
                  ? 'Discount: ${formatRupiah(nominalItemDisc)}'
                  : '';

              final mapItem = <String, dynamic>{
                'description': item['product_name'] ?? 'Product',
                'long_description': longDesc,
                'qty': (item['jumlah'] as num).toDouble().toStringAsFixed(2),
                'rate':
                    (item['harga_jual'] as num).toDouble().toStringAsFixed(2),
                'order': (i + 1).toString(),
                'unit': '',
                'taxname': <String>[],
              };
              final remoteItemId = item['remote_item_id']?.toString() ?? '';
              if (remoteItemId.isNotEmpty &&
                  remoteItemId != '0' &&
                  remoteItemId != 'null') {
                mapItem['itemid'] = remoteItemId;
              }
              itemsArray.add(mapItem);
            }
            final today = DateTime.now().toIso8601String().split('T')[0];

            // Fetch member address for dynamic billing_street
            String memberAddress = '-';
            final idMember = map['id_member'];
            if (idMember != null && idMember != 0) {
              final memberData = await _dbService.query('members',
                  where: 'id_member = ?', whereArgs: [idMember]);
              if (memberData.isNotEmpty) {
                final rawAlamat = memberData.first['alamat']?.toString() ?? '';
                memberAddress = rawAlamat.trim().isNotEmpty ? rawAlamat : '-';
              }
            }
            final clientId = (map['id_member'] != null && map['id_member'] != 1)
                ? map['id_member'].toString()
                : '1';

            final putBody = <String, dynamic>{
              'clientid': clientId,
              'date': map['tgl_penjualan']?.toString().split('T')[0] ?? today,
              'currency': '3',
              'number': (map['remote_number']?.toString().isNotEmpty == true)
                  ? map['remote_number'].toString()
                  : remoteId.toString(),
              'billing_street': memberAddress,
              'allowed_payment_modes': allPaymentModes.isNotEmpty
                  ? allPaymentModes.map((e) => e['id'].toString()).toList()
                  : ['7'],
              'items': itemsArray,
              'subtotal':
                  (map['total_harga'] as num).toDouble().toStringAsFixed(2),
              'total':
                  ((map['total_harga'] as num) - (map['diskon'] as num? ?? 0))
                      .toDouble()
                      .toStringAsFixed(2),
              'discount_total':
                  (map['diskon'] as num? ?? 0).toDouble().toStringAsFixed(2),
              'discount_percent': '0.00',
              'discount_type': 'percent',
              'clientnote': map['note']?.toString() ?? '',
              'terms': map['order_type']?.toString() ?? 'Dine In',
              'status': 5, // Mark as Cancelled
            };

            final syncService = Get.find<SyncService>();
            await syncService.enqueueCommand(
              method: 'PUT',
              endpoint: '/api/pos_order/$remoteId',
              body: putBody,
              localId: localId,
            );
          }

          Get.snackbar('Success', 'Order has been marked as cancelled');
        } else {
          return; // User cancelled the cancellation
        }
      }
    }

    // 2. Clear UI state
    _resetPOSUIState();
  }

  Future<void> getMember({bool silent = false}) async {
    if (!silent) isLoadingMember.value = true;
    try {
      final List<Map<String, dynamic>> results =
          await _dbService.query('members');
      memberList.value = results.map((m) => MemberModel.fromJson(m)).toList();
      filteredMemberList.value = memberList;
      debugPrint(
          'HomeController: Member list loaded from SQLite, count: ${memberList.length}');
    } catch (e) {
      debugPrint('HomeController: Error loading members from SQLite: $e');
    } finally {
      if (!silent) isLoadingMember.value = false;
    }
  }

  void clearSelectedMember() {
    selectedMember.value = null;
    memberId.value = 1; // Walk-In ID
    searchMemberQuery.value = "";
  }

  Future<void> countExchange(String value) async {
    totalDiterima = cleanCurrencyFormat(value);
    int kembalian = totalDiterima - totalTransaction.value;
    controllerKembalian.text = formatRupiah(kembalian);
  }

  void countDiscount() {
    if (memberId.value == 0) {
      int discount = appService.appModel.value.diskon;
      disscount.value = discount;
      totalTransaction.value =
          countTotalWithDiscount(totalTransaction.value, discount);
      return;
    }
  }

  Future<void> transactionValidation({bool isSaveOnly = false}) async {
    await userService.initSharedPref();
    int userId = userService.getPrefInt(Constants.userId);
    calculateTotals();
    int idMember = memberId.value == 0 ? 1 : memberId.value;
    int totalItem = countTotalItem();

    debugPrint(
        'DEBUG: transactionValidation - totalItem: $totalItem, totalHarga: $totalHarga, bayar: ${totalTransaction.value}');

    if (userId == 0) {
      Get.snackbar('Error', 'Anda tidak memilki akses');
      return;
    }

    if (totalItem == 0 || totalHarga == 0 || penjualanDetailModelList.isEmpty) {
      Get.snackbar('Attention', 'Please select a product first');
      return;
    }

    int totalDiterima = 0;

    if (!isSaveOnly) {
      if (controllerDiterima.text.isEmpty) {
        Get.snackbar('Error', 'Nominal diterima tidak boleh kosong');
        return;
      }

      totalDiterima = cleanCurrencyFormat(controllerDiterima.text);

      if (totalDiterima == 0 || totalTransaction.value > totalDiterima) {
        Get.snackbar('Error', 'Nominal pembayaran tidak valid atau kurang');
        return;
      }
    }

    currentIdPos ??= const Uuid().v4();
    final String idPos = currentIdPos!;

    final PenjualanModel penjualanModel = PenjualanModel(
        idMember: idMember,
        totalItem: totalItem,
        totalHarga: totalHarga,
        diskon: disscount.value,
        bayar: totalTransaction.value,
        diterima: totalDiterima,
        idUser: userId);

    Map<String, dynamic> dataTransaction = {
      'id_user': userId,
      'id_member': idMember,
      'total_item': totalItem,
      'total_harga': totalHarga,
      'diskon': disscount.value,
      'bayar': totalTransaction.value,
      'diterima': totalDiterima,
      'penjualan': penjualanModel.toJson(),
      'penjualan_detail':
          penjualanDetailModelList.map((element) => element.toJson()).toList(),
      'id_pos': idPos,
    };

    isLoadingTransaction.value = true;
    await storeTransaction(dataTransaction, isSaveOnly: isSaveOnly);
  }

  // Builds a merged clientnote string that embeds per-item notes into the
  // order's main note field (since the API doesn't have per-item note fields).
  String _buildMergedClientNote(
      List<PenjualanDetailModel> items, String mainNote) {
    // 1. Clean the main note of any existing merged markers to prevent duplication
    String cleanedNote = mainNote;
    if (cleanedNote.contains('---ITEM NOTES---')) {
      cleanedNote = cleanedNote.split('---ITEM NOTES---')[0].trim();
    }

    final itemLines = items.where((i) {
      final diffType = i.orderType.isNotEmpty &&
          i.orderType != "Dine In"; // Always show if not default
      final hasNote = i.note.isNotEmpty;
      return diffType || hasNote;
    }).map((i) {
      final type = i.orderType.isNotEmpty ? i.orderType : "Dine In";
      final note = i.note.isNotEmpty ? ' - ${i.note}' : '';
      return '${i.productName ?? 'Item'} | $type$note';
    }).toList();

    if (itemLines.isEmpty) return cleanedNote;

    final buffer = StringBuffer();
    if (cleanedNote.isNotEmpty) {
      buffer.writeln(cleanedNote);
    }
    buffer.writeln('---ITEM NOTES---');
    buffer.writeAll(itemLines, '\n');
    return buffer.toString().trim();
  }

  Future<void> storeTransaction(Map<String, dynamic> map,
      {bool isSaveOnly = false}) async {
    try {
      debugPrint(
          'DEBUG: storeTransaction - Upserting transaction with id_pos: ${map['id_pos']}');

      // 1. Check if a transaction with this UUID already exists
      final existing = await _dbService.query('transactions',
          where: 'id_pos = ?', whereArgs: [map['id_pos']]);

      int idPenjualanLocal;
      bool isNewRecord = existing.isEmpty;
      int? existingRemoteId;
      String? remoteNumber;

      if (!isNewRecord) {
        // UPDATE existing transaction
        idPenjualanLocal = existing.first['id_penjualan'] as int;
        existingRemoteId = existing.first['id_penjualan_remote'] as int?;
        remoteNumber = existing.first['remote_number']?.toString();
        debugPrint(
            'DEBUG: storeTransaction - Updating existing local ID: $idPenjualanLocal');

        // Preserve original creation date — never overwrite it on update
        final preservedDate = originalTglPenjualan ??
            existing.first['tgl_penjualan']?.toString() ??
            DateTime.now().toIso8601String();

        await _dbService.update(
            'transactions',
            {
              'id_user': map['id_user'],
              'id_member': map['id_member'],
              'total_item': map['total_item'],
              'total_harga': map['total_harga'],
              'diskon': map['diskon'],
              'bayar': map['bayar'],
              'diterima': map['diterima'],
              'tgl_penjualan': preservedDate,
              'order_note': orderNote.value,
              'order_type': selectedOrderType.value,
              'label': customerLabel.value,
              'discount_type':
                  manualDiscountIsPercent.value ? 'percent' : 'fixed',
              'manual_discount_value': manualDiscountValue.value,
              'is_synced': 0,
            },
            'id_penjualan = ?',
            [idPenjualanLocal]);

        // Refresh items: delete existing details and insert new ones
        await _dbService.delete(
            'transaction_details', 'id_penjualan = ?', [idPenjualanLocal]);
      } else {
        // INSERT new transaction — atomically assigns and increments queue number
        final int newQueue = await appService.getAndIncrementQueue();
        idPenjualanLocal = await _dbService.insert('transactions', {
          'id_user': map['id_user'],
          'id_member': map['id_member'],
          'total_item': map['total_item'],
          'total_harga': map['total_harga'],
          'diskon': map['diskon'],
          'bayar': map['bayar'],
          'diterima': map['diterima'],
          'tgl_penjualan':
              DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          'id_pos': map['id_pos'],
          'order_note': orderNote.value,
          'order_type': selectedOrderType.value,
          'label': customerLabel.value,
          'discount_type': manualDiscountIsPercent.value ? 'percent' : 'fixed',
          'manual_discount_value': manualDiscountValue.value,
          'queue_number': newQueue,
          'is_synced': 0,
        });
      }

      // Insert detail rows with note and order_type
      final List items = map['penjualan_detail'];
      for (var item in items) {
        await _dbService.insert('transaction_details', {
          'id_penjualan': idPenjualanLocal,
          'id_produk': item['id_produk'],
          'harga_jual': item['harga_jual'],
          'jumlah': item['jumlah'],
          'subtotal': item['subtotal'],
          'note': item['note'] ?? '',
          'order_type': item['orderType'] ?? '',
          'orderTypesJson': item['orderTypesJson'] ?? '',
          'discountTotal': item['discountTotal'] ?? 0,
          'discountType': item['discountType'] ?? 'percent',
          'hargaAwal': item['hargaAwal'] ?? 0,
          'product_name': item['productName'],
          'description': item['description'],
          'remote_item_id': item['remote_item_id'],
          'is_refund': item['is_refund'] ?? 0,
        });
      }

      // Push to remote API
      await _pushOrderToApi(
        map: map,
        isNew: isNewRecord,
        existingRemoteId: existingRemoteId,
        idPenjualanLocal: idPenjualanLocal,
        remoteNumber: remoteNumber,
      );

      isLoadingTransaction.value = false;
      await resetState(idPenjualanLocal, isSaveOnly: isSaveOnly);
    } catch (e) {
      isLoadingTransaction.value = false;
      Get.snackbar('Error', 'Failed to save transaction: $e');
    }
  }

  Future<void> _pushOrderToApi({
    required Map<String, dynamic> map,
    required bool isNew,
    required int idPenjualanLocal,
    int? existingRemoteId,
    String? remoteNumber,
  }) async {
    try {
      final List detailItems = map['penjualan_detail'];
      final mergedNote =
          _buildMergedClientNote(penjualanDetailModelList, orderNote.value);

      final clientId = (map['id_member'] != null && map['id_member'] != 1)
          ? map['id_member']
          : 1;

      // Get billing_street from selected member
      final billingStreet =
          (selectedMember.value?.alamat?.trim().isNotEmpty == true)
              ? selectedMember.value!.alamat!
              : '-';

      // Use the actual transaction date, falling back to now if missing
      final String tglStr = map['tgl_penjualan']?.toString() ?? DateTime.now().toIso8601String();
      final String today = tglStr.split('T')[0].split(' ')[0];
      final syncService = Get.find<SyncService>();

      // Remove any pending pushes for this exact local order to avoid sending multiple stale updates
      // We check by both numeric ID and UUID placeholder in the body to be extremely thorough
      await _dbService.delete(
          'sync_queue',
          '(local_id = ? OR body LIKE ?) AND endpoint LIKE ?',
          [idPenjualanLocal.toString(), '%${map['id_pos']}%', '%pos_order%']);

      // Fetch queue_number from local DB so it can be saved in adminnote
      final localTx = await _dbService.query('transactions',
          where: 'id_penjualan = ?', whereArgs: [idPenjualanLocal]);
      final queueNum =
          localTx.isNotEmpty ? (localTx.first['queue_number'] as int? ?? 0) : 0;

      if (isNew || existingRemoteId == null) {
        // POST: newitems is an Array. Used for totally new orders OR un-synced offline orders
        final newitemsArray = detailItems.asMap().entries.map((entry) {
          final item = entry.value as Map<String, dynamic>;

          // Calculate real nominal discount for long_description
          final discTotal = (item['discountTotal'] as num? ?? 0).toInt();
          final discType = item['discountType'] as String? ?? 'percent';
          final harga = (item['harga_jual'] as num? ?? 0).toInt();
          int nominalItemDisc = 0;
          if (discTotal > 0) {
            if (discType == 'percent') {
              nominalItemDisc = (harga * discTotal / 100).round();
            } else {
              nominalItemDisc = discTotal;
            }
          }
          final longDesc = nominalItemDisc > 0
              ? 'Discount: ${formatRupiah(nominalItemDisc)}'
              : '';

          final mapItem = {
            'description': item['productName'] ?? 'Product',
            'long_description': longDesc,
            'qty': (item['jumlah'] as num).toDouble().toStringAsFixed(2),
            'rate': (item['harga_jual'] as num).toDouble().toStringAsFixed(2),
            'order': (entry.key + 1).toString(),
            'unit': '',
            'taxname': <String>[],
          };
          final productId = item['id_produk']?.toString() ?? '';
          if (productId.isNotEmpty && productId != '0') {
            mapItem['itemid'] = productId;
          }
          return mapItem;
        }).toList();

        // Calculate exact discount details for API
        double subtotalVal = (map['total_harga'] as num).toDouble();
        double discountAmount = 0;
        double discountPercent = 0;
        String discountType =
            manualDiscountIsPercent.value ? 'percent' : 'fixed';

        if (manualDiscountValue.value > 0) {
          if (manualDiscountIsPercent.value) {
            discountPercent = manualDiscountValue.value.toDouble();
            discountAmount = subtotalVal * (discountPercent / 100);
          } else {
            discountAmount = manualDiscountValue.value.toDouble();
            discountPercent = 0; // Empty in API
          }
        } else if (appService.useDefaultDiscount.value) {
          discountPercent = appService.appModel.value.diskon.toDouble();
          discountAmount = subtotalVal * (discountPercent / 100);
          discountType = 'percent';
        }

        final postBody = <String, dynamic>{
          'id_pos': map['id_pos'],
          'clientid': clientId,
          'date': today,
          'datecreated': tglStr,
          'currency': 3,
          'prefix': 'POS-',
          'newitems': newitemsArray,
          'allowed_payment_modes': allPaymentModes.isNotEmpty
              ? allPaymentModes.map((e) => e['id'].toString()).toList()
              : ['7'],
          'billing_street': billingStreet,
          'subtotal': subtotalVal.toStringAsFixed(2),
          'total': (map['bayar'] as num).toDouble().toStringAsFixed(2),
          'discount_total': discountAmount.toStringAsFixed(2),
          'discount_percent': discountPercent.toStringAsFixed(2),
          'discount_type': discountType,
          'clientnote': mergedNote,
          'terms': selectedOrderType.value,
          'adminnote': queueNum > 0 ? queueNum.toString() : '',
          'sale_agent': userService.getPrefInt(Constants.userId).toString(),
        };

        await syncService.enqueueCommand(
          method: 'POST',
          endpoint: '/api/pos_order',
          body: postBody,
          localId: idPenjualanLocal,
        );
      } else {
        // PUT: Replace existing remote items with current local items

        // Build items array for current cart
        final itemsArray = <Map<String, dynamic>>[];
        for (int i = 0; i < detailItems.length; i++) {
          final item = detailItems[i] as Map<String, dynamic>;

          // Calculate real nominal discount for long_description
          final bool isRefundItem =
              item['is_refund']?.toString() == '1' || item['isRefund'] == true;
          final discTotal = (item['discountTotal'] as num? ?? 0).toInt();
          final discType = item['discountType'] as String? ?? 'percent';
          final harga = (item['harga_jual'] as num? ?? 0).toInt();
          int nominalItemDisc = 0;
          if (discTotal > 0) {
            if (discType == 'percent') {
              nominalItemDisc = (harga * discTotal / 100).round();
            } else {
              nominalItemDisc = discTotal;
            }
          }
          // long_description: 'Refund' for refund items, discount info for discounted, else empty
          final String longDesc = isRefundItem
              ? 'Refund'
              : (nominalItemDisc > 0
                  ? 'Discount: ${formatRupiah(nominalItemDisc)}'
                  : '');

          final mapItem = <String, dynamic>{
            'description': item['productName'] ?? 'Product',
            'long_description': longDesc,
            'qty': (item['jumlah'] as num).toDouble().toStringAsFixed(2),
            'rate': (item['harga_jual'] as num).toDouble().toStringAsFixed(2),
            'order': (i + 1).toString(),
            'unit': '',
            'taxname': <String>[],
          };

          if (isRefundItem) {
            final remoteItemId = item['remote_item_id']?.toString() ?? '';
            final isFullRefundRow = remoteItemId.isNotEmpty &&
                remoteItemId != '0' &&
                remoteItemId != 'null';

            if (isFullRefundRow) {
              // Full-refund row: the item was converted in-place (remoteItemId preserved).
              // Emit the original item with its itemid (to update the server row),
              // then emit a separate refund entry without itemid.
              final originalQty =
                  (item['originalQty'] as num? ?? item['jumlah'] as num)
                      .toDouble();
              itemsArray.add(<String, dynamic>{
                'description': item['productName'] ?? 'Product',
                'long_description': longDesc,
                'qty': originalQty.toStringAsFixed(2),
                'rate':
                    (item['harga_jual'] as num).toDouble().toStringAsFixed(2),
                'order': (i + 1).toString(),
                'unit': '',
                'taxname': <String>[],
                'itemid': remoteItemId,
              });
              itemsArray.add(<String, dynamic>{
                'description': item['productName'] ?? 'Product',
                'long_description': 'Refund',
                'qty': (item['jumlah'] as num).toDouble().toStringAsFixed(2),
                'rate':
                    (item['harga_jual'] as num).toDouble().toStringAsFixed(2),
                'order': (i + 1).toString(),
                'unit': '',
                'taxname': <String>[],
                'is_refund': 1,
              });
            } else {
              // Split-refund row: remoteItemId=0, just emit as refund entry
              mapItem['is_refund'] = 1;
              itemsArray.add(mapItem);
            }
          } else {
            // Normal / remaining row: attach server-side item id so Perfex updates it in place
            final remoteItemId = item['remote_item_id']?.toString() ?? '';
            if (remoteItemId.isNotEmpty &&
                remoteItemId != '0' &&
                remoteItemId != 'null') {
              mapItem['itemid'] = remoteItemId;
            }
            itemsArray.add(mapItem);
          }
        }

        // Calculate exact discount details for API
        double subtotalVal = (map['total_harga'] as num).toDouble();
        double discountAmount = 0;
        double discountPercent = 0;
        String discountType =
            manualDiscountIsPercent.value ? 'percent' : 'fixed';

        if (manualDiscountValue.value > 0) {
          if (manualDiscountIsPercent.value) {
            discountPercent = manualDiscountValue.value.toDouble();
            discountAmount = subtotalVal * (discountPercent / 100);
          } else {
            discountAmount = manualDiscountValue.value.toDouble();
            discountPercent = 0;
          }
        } else if (appService.useDefaultDiscount.value) {
          discountPercent = appService.appModel.value.diskon.toDouble();
          discountAmount = subtotalVal * (discountPercent / 100);
          discountType = 'percent';
        }
        final putBody = <String, dynamic>{
          'clientid': clientId.toString(),
          'date': today,
          'currency': '3',
          'number': (remoteNumber?.trim().isNotEmpty == true)
              ? remoteNumber!
              : existingRemoteId.toString(),
          'billing_street': billingStreet,
          'allowed_payment_modes': allPaymentModes.isNotEmpty
              ? allPaymentModes.map((e) => e['id'].toString()).toList()
              : ['7'],
          'items': itemsArray,
          'subtotal': subtotalVal.toStringAsFixed(2),
          'total': (map['bayar'] as num).toDouble().toStringAsFixed(2),
          'discount_total': discountAmount.toStringAsFixed(2),
          'discount_percent': discountPercent.toStringAsFixed(2),
          'discount_type': discountType,
          'clientnote': mergedNote,
          'terms': selectedOrderType.value,
          'adminnote': queueNum > 0 ? queueNum.toString() : '',
          // NOTE: 'status' is intentionally omitted — Perfex rejects PUT with status field.
          // Payment status is updated via the /api/pos_transaction endpoint instead.
        };

        debugPrint(
            'HomeController: _pushOrderToApi (PUT) Body: ${jsonEncode(putBody)}');

        await syncService.enqueueCommand(
          method: 'PUT',
          endpoint: '/api/pos_order/$existingRemoteId',
          body: putBody,
          localId: map['id_pos'], // Fixed: use key from map
        );
      }
    } catch (e) {
      debugPrint('WARNING: Failed to enqueue order push: $e');
    }
  }

  Future<bool> storePayment(String paymentMode, int amount,
      {String? note, String? paymentMethod}) async {
    if (isProcessingPayment.value) return false; // Fix: Prevent double-clicks

    try {
      isProcessingPayment.value = true;
      isSyncingDirectly.value =
          true; // Guard background sync during payment flow

      // 1. Safety: Ensure we have a valid order ID before proceeding
      if (currentIdPos == null) {
        Get.snackbar(
            'Error', 'Sesi pesanan tidak valid. Silakan muat ulang pesanan.');
        isProcessingPayment.value = false;
        return false;
      }
      final String idPos = currentIdPos!;
      final String date = DateTime.now().toIso8601String().split('T')[0];
      final String dateRecorded = DateTime.now().toIso8601String();

      // 2. Mark local status as Paid (status 2) immediately.
      // Also store payment_method and tgl_bayar here so shift reconciliation
      // can read payment data directly from transactions (no pos_payments dependency).
      // NOTE: We do NOT reset is_synced here. If the order is already synced (is_synced=1),
      // resetting it would trigger a redundant PUT /api/pos_order on the next sync,
      // which can cause invoice duplication on the Perfex backend.
      // The payment is protected via the pos_payments.is_synced=0 guard in pullRemoteOrders.
      await _dbService.update(
          'transactions',
          {
            'status': 2,
            'diterima': amount,
            'payment_method': paymentMethod ?? paymentMode,
            'tgl_bayar': dateRecorded,
          },
          'id_pos = ?',
          [idPos]);

      // Find local or remote transaction ID to use as invoiceid placeholder
      debugPrint(
          "HomeController: storePayment - Looking up transaction for id_pos: $idPos");
      final tx = await _dbService
          .query('transactions', where: 'id_pos = ?', whereArgs: [idPos]);
      int? localTxId;
      String invoiceIdStr = '';
      if (tx.isNotEmpty) {
        localTxId = tx.first['id_penjualan'] as int;
        if (tx.first['id_penjualan_remote'] != null &&
            tx.first['id_penjualan_remote'].toString() != '0') {
          // Order already has a remote ID — use it directly.
          invoiceIdStr = tx.first['id_penjualan_remote'].toString();
        } else {
          // Order not yet synced — use the UUID (id_pos) as placeholder.
          // SyncService._remapLocalIdInQueue will replace this UUID with the
          // actual remote ID after the pos_order POST succeeds.
          invoiceIdStr = idPos;
        }
        debugPrint(
            "HomeController: storePayment - Found transaction. localId: $localTxId, remoteIdStr: $invoiceIdStr");
      } else {
        debugPrint(
            "HomeController: storePayment ERROR - Transaction NOT FOUND in local DB for id_pos: $idPos");
        throw Exception(
            "Transaction record not found for this order (#${idPos.substring(0, 8)})");
      }

      // Map the paymentMode string to its dynamic ID from the database
      String paymentModeId = '7'; // fallback
      final modeMatch = allPaymentModes.firstWhere(
        (m) {
          final n = (m['name'] ?? '').toString().toLowerCase();
          final q = paymentMode.toLowerCase();
          if (q == 'cash' || q == 'tunai') {
            return n == 'cash' || n == 'tunai' || n == 'cash/tunai';
          }
          return n == q;
        },
        orElse: () => <String, dynamic>{},
      );
      if (modeMatch.isNotEmpty) {
        paymentModeId = modeMatch['id'].toString();
      }

      final payment = PosPaymentModel(
        idPos: idPos,
        invoiceId: invoiceIdStr,
        amount: amount.toString(),
        paymentMode:
            paymentModeId, // Store mapped ID in local SQLite instead of string
        paymentMethod:
            paymentMethod ?? paymentMode, // Keep original string here
        date: date,
        dateRecorded: dateRecorded,
        note: note ?? orderNote.value,
        transactionId: '', // Optional transaction trace ID
      );

      // Wait for insert to get the actual local ID
      final localPaymentId =
          await _dbService.insert('pos_payments', payment.toJson());

      // Update member points locally immediately
      if (selectedMember.value != null && selectedMember.value!.idMember != 1) {
        final earnedPoints = (amount / 10000).floor();
        if (earnedPoints > 0) {
          final int currentPoints =
              int.tryParse(selectedMember.value!.points ?? '0') ?? 0;
          final int newPoints = currentPoints + earnedPoints;
          selectedMember.value = selectedMember.value!.copyWith(points: newPoints.toString());

          await _dbService.update(
            'members',
            {'points': newPoints.toString()},
            'id_member = ?',
            [selectedMember.value!.idMember],
          );
          selectedMember.refresh();
        }
      }

      final apiPaymentBody = {
        'id_pos': idPos,
        'invoiceid': invoiceIdStr,
        'amount': amount.toString(),
        'paymentmode': paymentModeId,
        'paymentmethod': paymentMethod ?? paymentMode,
        'date': date,
        'daterecorded': dateRecorded,
        'transactionid': '',
        'note': note ?? orderNote.value,
        'sale_agent': userService.getPrefInt(Constants.userId).toString(),
      };

      // Enqueue the pos_order FIRST so the server only creates the invoice and awards points at payment time.
      if (localTxId != null) {
        final subtotalVal = subtotalRaw.value;
        final Map<String, dynamic> localData = {
          'id_user': userService.getPrefInt(Constants.userId),
          'id_member': selectedMember.value?.idMember ?? 1,
          'total_item': penjualanDetailModelList.length,
          'total_harga': subtotalVal,
          'diskon': (manualDiscountIsPercent.value
                  ? (subtotalVal * (manualDiscountValue.value / 100))
                  : manualDiscountValue.value)
              .toInt(),
          'bayar': totalTransaction.value,
          'id_pos': currentIdPos,
          'penjualan_detail':
              penjualanDetailModelList.map((e) => e.toJson()).toList(),
        };

        await _pushOrderToApi(
          map: localData,
          isNew: currentRemoteId.value == 0,
          idPenjualanLocal: localTxId,
          existingRemoteId:
              currentRemoteId.value != 0 ? currentRemoteId.value : null,
          remoteNumber: currentRemoteNumber.value.isNotEmpty
              ? currentRemoteNumber.value
              : null,
        );
      }

      // Enqueue payment using the specific payment's local ID
      await Get.find<SyncService>().enqueueCommand(
        method: 'POST',
        endpoint: '/api/pos_transaction',
        body: apiPaymentBody,
        localId: localPaymentId,
      );

      isProcessingPayment.value = false;

      // 3. UI REACTIVITY: Instantly refresh other controllers to reflect the Paid status locally
      if (Get.isRegistered<DashboardEmployeeController>()) {
        Get.find<DashboardEmployeeController>().updateActiveOrderCount();
      }
      if (Get.isRegistered<DashboardAdminController>()) {
        Get.find<DashboardAdminController>().updateActiveOrderCount();
      }
      if (Get.isRegistered<OrderController>()) {
        Get.find<OrderController>()
            .getOrders(forceRemote: false); // Reload from local DB
      }
      if (Get.isRegistered<ReportController>()) {
        Get.find<ReportController>()
            .getOrders(); // Refresh analysis and history
      }

      return true;
    } catch (e) {
      isProcessingPayment.value = false;
      isSyncingDirectly.value = false;
      Get.snackbar('Error', 'Gagal menyimpan pembayaran: $e');
      return false;
    }
  }

  /// Handles resetting all cart and local transaction states to prepare for a new session.
  Future<void> finalizePayment() async {
    isSyncingDirectly.value = false;
    penjualanDetailModelList.clear();
    for (var c in controllerStock.values) {
      c.dispose();
    }
    controllerStock.clear();
    memberId.value = 0;
    selectedMember.value = null;
    orderNote.value = '';
    manualDiscountValue.value = 0;
    manualDiscountIsPercent.value = false;
    controllerDiskon.clear();
    manualCashAmount.value = 0;
    selectedOrderType.value = "Dine In";
    customerLabel.value = "";
    currentIdPos = null;
    currentRemoteId.value = 0;
    currentRemoteNumber.value = '';
    totalTransaction.value = 0;
    totalHarga = 0;

    penjualanDetailModelList.refresh();
  }

  /// Print Labels/Stickers for multiple items in an order.
  /// Combines all items into a single Bluetooth payload to avoid connecting/disconnecting
  /// multiple times per order.
  Future<void> printLabels(List<PenjualanDetailModel> items,
      {PenjualanModel? penjualan}) async {
    try {
      final settingCtrl = Get.find<SettingController>();
      final labelPrinter = settingCtrl.getPrinterForRole('label');
      if (labelPrinter == null) {
        Get.snackbar('No Label Printer',
            'Please configure a printer with the Label role in Settings.');
        return;
      }

      final now = DateTime.now();
      final dateTimeStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}'
          ' ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      // Last 8 chars of id_pos as order code
      final idPosRef = penjualan?.idPos ?? currentIdPos;
      final orderCode = idPosRef != null && idPosRef.isNotEmpty
          ? '#${idPosRef.substring(idPosRef.length > 8 ? idPosRef.length - 8 : 0).toUpperCase()}'
          : '#---';

      final customerName = penjualan != null
          ? ((selectedMember.value != null &&
                  selectedMember.value!.idMember == penjualan.idMember)
              ? (selectedMember.value!.nama ?? 'Customer')
              : 'Customer #${penjualan.idMember}')
          : (selectedMember.value?.nama ?? 'Walk In');

      List<int> allBytes = [];
      int totalLabels = 0;
      for (var item in items) {
        totalLabels += item.jumlah;
      }

      int currentIndex = 1;
      for (var item in items) {
        final orderTypeStr = item.orderType.isNotEmpty
            ? item.orderType
            : (penjualan?.orderType ?? selectedOrderType.value);

        final customerWithOrderType = '$customerName ($orderTypeStr)';

        // Build ESC/POS bytes via SettingController helper
        final bytes = await settingCtrl.buildLabelEscPos(
          line1: dateTimeStr,
          line2: customerWithOrderType,
          line3: orderCode,
          line4: normalizeUIName(item.description?.isNotEmpty == true
              ? item.description!
              : (item.productName ?? '')),
          productNote: item.note,
          isAutoCut: labelPrinter.isAutoCut,
          copies: item.jumlah, // Use item quantity for copies
          startIndex: currentIndex,
          totalLabels: totalLabels,
        );
        allBytes.addAll(bytes);
        currentIndex += item.jumlah;
      }

      // Delegate to SettingController for sequential BT connect→print→disconnect (once per order)
      await settingCtrl.printToTarget(labelPrinter, prebuiltBytes: allBytes);
    } catch (e) {
      Get.snackbar('Print Label Error', 'Failed to print labels: $e');
    }
  }

  // Used specifically for the UI to show the full name with parent, replacing '_' with space.
  String normalizeUIName(String rawName) {
    String name = rawName.trim();
    if (name.contains('_')) {
      name = name.replaceAll('_', ' ');
    }
    return name.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _formatRow(String left, String right, int maxChars) {
    if (left.length + right.length > maxChars) {
      if (left.length > maxChars - right.length - 1) {
        left = '${left.substring(0, maxChars - right.length - 2)}..';
      }
    }
    int padLength = maxChars - left.length;
    if (padLength < 0) padLength = 0;
    return left + right.padLeft(padLength);
  }

  String _formatCenter(String text, int maxChars) {
    List<String> words = text.split(' ');
    List<String> lines = [];
    String currentLine = '';

    // 1. Bungkus teks per kata agar tidak melebihi maxChars
    for (String word in words) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if ('$currentLine $word'.length <= maxChars) {
        currentLine = '$currentLine $word';
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }
    if (currentLine.isNotEmpty) lines.add(currentLine);

    // 2. Buat tiap baris berada di tengah secara presisi
    List<String> centeredLines = lines.map((line) {
      int totalSpaces = maxChars - line.length;

      // Jika teks pas atau lebih dari maxChars, biarkan apa adanya
      if (totalSpaces <= 0) return line;

      // Menghitung spasi kiri (pembagian bulat)
      int leftSpaces = totalSpaces ~/ 2;

      // Satukan spasi kiri + teks + spasi kanan hingga totalnya pas maxChars
      return line.padLeft(leftSpaces + line.length).padRight(maxChars);
    }).toList();

    return centeredLines.join('\n');
  }

  /// Print cashier receipt.
  /// Routes to the 'cashier' role printer via SettingController (sequential BT flow).
  /// [penjualan] and [details] can be provided; otherwise defaults to current controller state.
  List<String> _wrapText(String text, int maxWidth) {
    if (text.isEmpty) return [""];
    List<String> lines = [];
    int start = 0;
    while (start < text.length) {
      if (text.length - start <= maxWidth) {
        lines.add(text.substring(start).trim());
        break;
      }
      int breakPoint = -1;
      for (int i = start + maxWidth; i > start; i--) {
        if (i < text.length && (text[i] == ' ' || text[i] == '-')) {
          breakPoint = i;
          break;
        }
      }
      if (breakPoint == -1) {
        lines.add(text.substring(start, start + maxWidth).trim());
        start += maxWidth;
      } else {
        int end = text[breakPoint] == '-' ? breakPoint + 1 : breakPoint;
        lines.add(text.substring(start, end).trim());
        start = text[breakPoint] == '-' ? breakPoint + 1 : breakPoint + 1;
      }
    }
    return lines;
  }

  Future<void> printReceipt({
    required String paymentMethod,
    required int total,
    required int diterima,
    required int kembalian,
    PenjualanModel? penjualan,
    List<PenjualanDetailModel>? details,
  }) async {
    try {
      final settingCtrl = Get.find<SettingController>();
      final cashierPrinter = settingCtrl.getPrinterForRole('cashier');
      if (cashierPrinter == null) {
        Get.snackbar('No Cashier Printer',
            'Please configure a printer with the Cashier role in Settings.');
        return;
      }

      final profile = await CapabilityProfile.load();
      final isAutoCutPrinter = cashierPrinter.isAutoCut;
      final paperSize = PaperSize.mm58;

      // Standardizing widths: 58mm -> 32 chars (Font A), 80mm -> 48 chars
      // We always format for 32 chars since the receipt design is meant for 58mm paper.
      final int maxChars = 32;
      final String lineSeparator = '-' * maxChars;

      final generator = Generator(paperSize, profile);
      List<int> bytes = [];

      bytes += generator.reset();

      // 1. Logo
      final logoUrl = userService.getPrefString('pos_brand_logo');
      if (logoUrl.isNotEmpty) {
        try {
          final res = await http
              .get(Uri.parse(logoUrl))
              .timeout(const Duration(seconds: 4));
          if (res.statusCode == 200) {
            final decodedImage = img.decodeImage(res.bodyBytes);
            if (decodedImage != null) {
              final resized = img.copyResize(decodedImage, width: 250);
              bytes += generator.image(resized);
            }
          }
        } catch (_) {
          debugPrint('Failed to download or print logo.');
        }
      }

      // 2. Header
      String companyName = userService.getPrefString(Constants.posCompanyName);
      if (companyName == 'Guest' || companyName.isEmpty) {
        companyName = appService.appModel.value.namaPerusahaan;
      }
      if (companyName.isEmpty) {
        companyName = 'FLINKPOS';
      }
      String address = userService.getPrefString(Constants.posAddress);
      if (address == 'Guest') {
        address = '';
      }
      String phone = userService.getPrefString(Constants.posPhoneNumber);
      if (phone == 'Guest') {
        phone = '';
      }

      bytes += generator.text(_formatCenter(companyName, maxChars),
          styles: const PosStyles(
              align: PosAlign.left, bold: true, height: PosTextSize.size2));
      if (address.isNotEmpty) {
        bytes += generator.text(_formatCenter(address, maxChars),
            styles: const PosStyles(align: PosAlign.left));
      }
      if (phone.isNotEmpty) {
        bytes += generator.text(_formatCenter(phone, maxChars),
            styles: const PosStyles(align: PosAlign.left));
      }
      bytes += generator.text(_formatCenter('Closed Bill', maxChars),
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text(lineSeparator,
          styles: const PosStyles(align: PosAlign.left));

      // 3. Order Info
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final orderCode = penjualan?.idPos != null
          ? (penjualan!.idPos!.length >= 6
              ? penjualan.idPos!
                  .substring(penjualan.idPos!.length - 6)
                  .toUpperCase()
              : penjualan.idPos!)
          : (currentIdPos != null && currentIdPos!.length >= 6
              ? currentIdPos!.substring(currentIdPos!.length - 6).toUpperCase()
              : '---');

      final orderTypeStr = penjualan?.orderType ?? selectedOrderType.value;
      final isWalkIn = penjualan != null
          ? (penjualan.idMember == 0 || penjualan.idMember == 1)
          : (selectedMember.value == null ||
              selectedMember.value!.idMember == 1);

      String customerName = 'Walk In Customer';
      if (penjualan != null) {
        // If printing from DB, we might not have the name directly unless we query it.
        // For now, if provided in controller state use it, else generic.
        customerName = (selectedMember.value != null &&
                selectedMember.value!.idMember == penjualan.idMember)
            ? (selectedMember.value!.nama ?? 'Customer')
            : 'Customer #${penjualan.idMember}';
      } else {
        customerName = isWalkIn
            ? 'Walk In Customer'
            : (selectedMember.value!.nama ?? 'Customer');
      }

      final queueNoStr =
          (penjualan?.queueNumber ?? appService.queueNumber.value)
              .toString()
              .padLeft(3, '0');

      bytes += generator.text(
          _formatRow('$dateStr $timeStr', 'Q: $queueNoStr', maxChars),
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text('Order Type: $orderTypeStr',
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text('Receipt No: $orderCode',
          styles: const PosStyles(align: PosAlign.left));
      String cashierName = userService.getPrefString(Constants.userName);
      if (penjualan != null && penjualan.idUser > 0) {
        try {
          final _dbService = Get.find<DatabaseService>();
          final rows = await _dbService.rawQuery(
              'SELECT firstname, lastname FROM staff WHERE id = ?',
              [penjualan.idUser]);
          if (rows.isNotEmpty) {
            final fName = rows.first['firstname']?.toString() ?? '';
            final lName = rows.first['lastname']?.toString() ?? '';
            final full = '$fName $lName'.trim();
            if (full.isNotEmpty) cashierName = full;
          }
        } catch (_) {}
      }

      bytes += generator.text(
          'Cashier   : $cashierName',
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text('Customer  : $customerName',
          styles: const PosStyles(align: PosAlign.left));

      final orderNoteStr = (penjualan?.orderNote ?? orderNote.value)
          .replaceAll('<br />', ' ')
          .replaceAll('<br>', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>');
      if (orderNoteStr.isNotEmpty) {
        bytes += generator.text('Note      : $orderNoteStr',
            styles: const PosStyles(align: PosAlign.left));
      }
      bytes += generator.text(lineSeparator,
          styles: const PosStyles(align: PosAlign.left));

      // 4. Items
      final itemsToPrint = details ?? penjualanDetailModelList;
      for (var item in itemsToPrint) {
        final int subtotal = item.subtotal;
        
        final String rawDesc = item.description?.toString() ?? "";
        final String rawProd = item.productName?.toString() ?? "";
        final String rawNote = item.note?.toString() ?? "";
        
        String name = rawDesc.isNotEmpty ? rawDesc : (rawProd.isNotEmpty ? rawProd : rawNote);
        if (name.isEmpty) name = "Item";

        String cleanName = name.replaceAll('_', ' ').replaceAll('|', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

        int displaySubtotal = subtotal;
        int totalNominal = 0;

        if (item.discountTotal > 0) {
          final base = item.hargaAwal > 0 ? item.hargaAwal : item.hargaJual;
          displaySubtotal = (base * item.jumlah).toInt();

          int nominalPerUnit = 0;
          if (item.discountType == 'percent') {
            nominalPerUnit = (base * item.discountTotal / 100).round();
          } else if (item.discountType == 'final_price') {
            nominalPerUnit = base - item.discountTotal;
          } else {
            nominalPerUnit = item.discountTotal;
          }
          totalNominal = (nominalPerUnit * item.jumlah).toInt();
        }

        final String itemPrice = formatRupiah(displaySubtotal).replaceAll('Rp. ', '');
        final String prefix = '${item.jumlah.toInt()}x ';

        int maxWidth = 24 - prefix.length;
        List<String> wrappedLines = _wrapText(cleanName, maxWidth);

        if (wrappedLines.length == 1) {
          bytes += generator.text(_formatRow('$prefix${wrappedLines[0]}', itemPrice, maxChars),
              styles: const PosStyles(align: PosAlign.left));
        } else {
          bytes += generator.text('$prefix${wrappedLines[0]}',
              styles: const PosStyles(align: PosAlign.left));
          for (int i = 1; i < wrappedLines.length; i++) {
            String indent = ' ' * prefix.length;
            if (i == wrappedLines.length - 1) {
              bytes += generator.text(_formatRow('$indent${wrappedLines[i]}', itemPrice, maxChars),
                  styles: const PosStyles(align: PosAlign.left));
            } else {
              bytes += generator.text('$indent${wrappedLines[i]}',
                  styles: const PosStyles(align: PosAlign.left));
            }
          }
        }

        if (totalNominal > 0) {
          bytes += generator.text(
              _formatRow(
                  '   disc',
                  '-${formatRupiah(totalNominal).replaceAll('Rp. ', '')}',
                  maxChars),
              styles: const PosStyles(
                  align: PosAlign.left, fontType: PosFontType.fontB));
        }
      }
      bytes += generator.text(lineSeparator,
          styles: const PosStyles(align: PosAlign.left));

      // 5. Totals
      final subtotalToPrint =
          details?.fold(0, (sum, item) => sum + item.subtotal) ??
              subtotalRaw.value;

      // Calculate order-level discount
      int discountToPrint = 0;
      if (penjualan != null) {
        if (penjualan.manualDiscountValue > 0) {
          discountToPrint = penjualan.discountType == 'percent'
              ? (subtotalToPrint * penjualan.manualDiscountValue / 100).round()
              : penjualan.manualDiscountValue;
        } else if (penjualan.diskon > 0) {
          discountToPrint = (subtotalToPrint * penjualan.diskon / 100).round();
        }
      } else {
        if (manualDiscountValue.value > 0) {
          discountToPrint = manualDiscountIsPercent.value
              ? (subtotalToPrint * manualDiscountValue.value / 100).round()
              : manualDiscountValue.value;
        } else if (disscount.value > 0) {
          discountToPrint = (subtotalToPrint * disscount.value / 100).round();
        }
      }

      final String fSub = formatRupiah(subtotalToPrint).replaceAll('Rp. ', '');
      bytes += generator.text(_formatRow('Subtotal', fSub, maxChars),
          styles: const PosStyles(align: PosAlign.left));

      if (discountToPrint > 0) {
        final String fDisc =
            formatRupiah(discountToPrint).replaceAll('Rp. ', '');
        bytes += generator.text(_formatRow('Discount', '-$fDisc', maxChars),
            styles: const PosStyles(align: PosAlign.left));
      }

      final fTotal = formatRupiah(total).replaceAll('Rp. ', '');
      bytes += generator.text(_formatRow('Total', fTotal, maxChars),
          styles: const PosStyles(align: PosAlign.left, bold: true));

      final fDiterima = formatRupiah(diterima).replaceAll('Rp. ', '');
      bytes += generator.text(_formatRow('Cash', fDiterima, maxChars),
          styles: const PosStyles(align: PosAlign.left));

      final fKembalian = formatRupiah(kembalian).replaceAll('Rp. ', '');
      bytes += generator.text(
          _formatRow('Change', kembalian > 0 ? fKembalian : '0', maxChars),
          styles: const PosStyles(align: PosAlign.left));

      bytes += generator.text(lineSeparator,
          styles: const PosStyles(align: PosAlign.left));

      bytes += generator.text(_formatRow('PAID', fTotal, maxChars),
          styles: const PosStyles(align: PosAlign.left, bold: true));

      bytes += generator.text(lineSeparator,
          styles: const PosStyles(align: PosAlign.left));

      // 6. Points
      if (!isWalkIn) {
        final earnedPoints = (total / 10000).floor();
        final prevPoints =
            int.tryParse(selectedMember.value?.points ?? '0') ?? 0;
        final newTotal = prevPoints + earnedPoints;
        if (earnedPoints > 0) {
          bytes += generator.text(
              _formatCenter('Points Earned : +$earnedPoints pts', maxChars),
              styles: const PosStyles(align: PosAlign.left));
          bytes += generator.text(
              _formatCenter('Current Points: $newTotal pts', maxChars),
              styles: const PosStyles(align: PosAlign.left));
          bytes += generator.hr();
        }
      }

      // 7. Footer
      final footerLine1 = userService.getPrefString('pos_receipt_footer_1');
      if (footerLine1.isNotEmpty && footerLine1 != 'Guest') {
        bytes += generator.text(_formatCenter(footerLine1, maxChars),
            styles: const PosStyles(align: PosAlign.left));
      }
      if (phone.isNotEmpty) {
        bytes += generator.text(_formatCenter('HP : $phone', maxChars),
            styles: const PosStyles(align: PosAlign.left));
      }
      final igAccount = userService.getPrefString('pos_ig_account');
      if (igAccount.isNotEmpty && igAccount != 'Guest') {
        bytes += generator.text(_formatCenter('IG : $igAccount', maxChars),
            styles: const PosStyles(align: PosAlign.left));
      }

      // 8. Feedback QR
      bytes += generator.text(_formatCenter('KRITIK & SARAN', maxChars),
          styles: const PosStyles(align: PosAlign.left, bold: true));
      final encodedTenant = Uri.encodeComponent(companyName);
      final waUrl =
          "https://api.whatsapp.com/send?phone=6281387401166&text=Halo%20kak%2C%20saya%20ingin%20menyampaikan%20kritik%20dan%20saran%20untuk%20$encodedTenant";

      if (isAutoCutPrinter) {
        // Geser margin kiri (Left Margin) sebanyak 96 dots
        // (384 dots 58mm - 192 dots QR code) / 2 = 96 dots.
        bytes += [29, 76, 96, 0]; // GS L 96 0
        bytes += generator.qrcode(waUrl, align: PosAlign.left);
        bytes += [29, 76, 0, 0]; // Reset margin kiri
      } else {
        // Untuk printer kecil asli (58mm), tidak usah digeser, langsung align center
        bytes += generator.qrcode(waUrl, align: PosAlign.center);
      }

      bytes += generator.feed(1);
      bytes += generator.cut();

      // Delegate to SettingController for sequential BT connect→print→disconnect
      await settingCtrl.printToTarget(cashierPrinter, prebuiltBytes: bytes);
    } catch (e) {
      ErrorLogService.log(
        category: 'printer',
        errCode: 'RECEIPT_PRINT_FAIL',
        errMsg: 'paymentMethod=$paymentMethod | total=$total | $e',
      );
      Get.snackbar('Print Error', 'Failed to print receipt: $e');
    }
  }

  /// Print kitchen order ticket.
  /// Routes to the 'kitchen' role printer via SettingController (sequential BT flow).
  /// If kitchen mode is 'livesync', skip printing — KDS tablet reads from DB directly.
  Future<void> printKitchenOrder({
    PenjualanModel? penjualan,
    List<PenjualanDetailModel>? details,
  }) async {
    try {
      final appService = Get.find<AppService>();
      final kitchenMode = appService.kitchenMode.value;

      if (kitchenMode == 'livesync') {
        // Live Sync mode: order is already persisted in DB.
        // KDS on the other tablet will pick it up on next refresh.
        debugPrint(
            'HomeController: Kitchen mode is livesync — skipping printer.');
        Get.snackbar(
          'Order Sent',
          'Order has been queued for the kitchen display.',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        );
        return;
      }

      // Printer mode: send ticket to registered kitchen thermal printer
      final settingCtrl = Get.find<SettingController>();
      final kitchenPrinter = settingCtrl.getPrinterForRole('kitchen');
      if (kitchenPrinter == null) {
        Get.snackbar('No Kitchen Printer',
            'Please configure a printer with the Kitchen role in Settings.');
        return;
      }

      final profile = await CapabilityProfile.load();
      final isAutoCutPrinter = kitchenPrinter.isAutoCut;
      final paperSize = PaperSize.mm58;
      final generator = Generator(paperSize, profile);
      List<int> bytes = [];

      bytes += generator.reset();

      final String companyName =
          userService.getPrefString(Constants.posCompanyName);

      final orderCode = penjualan?.idPos != null
          ? (penjualan!.idPos!.length >= 6
              ? penjualan.idPos!
                  .substring(penjualan.idPos!.length - 6)
                  .toUpperCase()
              : penjualan.idPos!)
          : (currentIdPos != null && currentIdPos!.length >= 6
              ? currentIdPos!.substring(currentIdPos!.length - 6).toUpperCase()
              : '---');

      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final orderTypeStr = penjualan?.orderType ?? selectedOrderType.value;
      final queueNoStr =
          (penjualan?.queueNumber ?? appService.queueNumber.value)
              .toString()
              .padLeft(3, '0');

      final customerName = penjualan != null
          ? ((selectedMember.value != null &&
                  selectedMember.value!.idMember == penjualan.idMember)
              ? (selectedMember.value!.nama ?? 'Customer')
              : 'Customer #${penjualan.idMember}')
          : (selectedMember.value?.nama ?? 'Walk In');

      final int maxChars = 32;
      final String lineSep = '-' * maxChars;

      bytes += generator.text(_formatCenter('KITCHEN ORDER', maxChars),
          styles: const PosStyles(
              align: PosAlign.left, bold: true, height: PosTextSize.size2));
      bytes += generator.text(lineSep,
          styles: const PosStyles(align: PosAlign.left));

      bytes += generator.text(
          _formatRow('$dateStr $timeStr', 'Q: $queueNoStr', maxChars),
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text('Order Type: $orderTypeStr',
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text('Receipt No: $orderCode',
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text('Customer  : $customerName',
          styles: const PosStyles(align: PosAlign.left));

      final orderNoteStr = penjualan?.orderNote ?? orderNote.value;
      if (orderNoteStr.isNotEmpty) {
        bytes += generator.text('Note      : $orderNoteStr',
            styles: const PosStyles(align: PosAlign.left));
      }

      bytes += generator.text(lineSep,
          styles: const PosStyles(align: PosAlign.left));

      final itemsToPrint = details ?? penjualanDetailModelList;
      for (var item in itemsToPrint) {
        final String prefix = '${item.jumlah.toInt()}x ';
        String rawName = item.description?.isNotEmpty == true
            ? item.description!
            : (item.productName ?? "Item");

        if (rawName.contains('|')) {
          int maxPart1 = 24 - prefix.length;
          String part1 = rawName;
          String part2 = "";
          
          if (rawName.length > maxPart1) {
            part1 = rawName.substring(0, maxPart1);
            part2 = rawName.substring(maxPart1).trimLeft();
          }
          
          final String itemLabel1 = '$prefix$part1';
          bytes += generator.text(itemLabel1, styles: const PosStyles(align: PosAlign.left));
          
          String indent = ' ' * prefix.length;
          String indentedPart2 = '$indent$part2';
          bytes += generator.text(_formatRow(indentedPart2, '[ ]', maxChars),
              styles: const PosStyles(align: PosAlign.left));
        } else {
          final int maxNameLen = 24 - prefix.length;
          String name = rawName;
          if (name.length > maxNameLen) {
            name = '${name.substring(0, maxNameLen - 3)}..';
          }
          final String itemLabel = '$prefix$name';
          bytes += generator.text(_formatRow(itemLabel, '[ ]', maxChars),
              styles: const PosStyles(align: PosAlign.left));
        }

        if (item.note.isNotEmpty) {
          bytes += generator.text('   * ${item.note}',
              styles: const PosStyles(
                  align: PosAlign.left, fontType: PosFontType.fontB));
        }
      }

      bytes += generator.text(lineSep,
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.feed(3);
      bytes += generator.cut();

      // Delegate to SettingController for sequential BT connect→print→disconnect
      await settingCtrl.printToTarget(kitchenPrinter, prebuiltBytes: bytes);
    } catch (e) {
      ErrorLogService.log(
        category: 'printer',
        errCode: 'KITCHEN_PRINT_FAIL',
        errMsg: 'orderCode=${penjualan?.idPos ?? currentIdPos} | $e',
      );
      Get.snackbar('Print Kitchen Error', 'Failed to print kitchen order: $e');
    }
  }

  /// --- SEQUENTIAL PRINTING ORCHESTRATION ---

  /// Main entry point for printing an entire order session (Receipt, Kitchen, Label).
  /// Fetches transaction data from DB by [penjualanId].
  Future<void> printTransactionSession(int penjualanId) async {
    try {
      final data = await _loadTransactionForPrinting(penjualanId);
      if (data == null) {
        Get.snackbar('Print Error', 'Transaction data not found.');
        return;
      }

      final penjualan = data['header'] as PenjualanModel;
      final details = data['details'] as List<PenjualanDetailModel>;

      // 1. Print Receipt (Cashier)
      await printReceipt(
        paymentMethod: 'Cash', // Defaulting for simple thermal print
        total: penjualan.bayar,
        diterima: penjualan.diterima,
        kembalian: (penjualan.diterima - penjualan.bayar),
        penjualan: penjualan,
        details: details,
      );

      // 2. Print Kitchen Order
      await printKitchenOrder(
        penjualan: penjualan,
        details: details,
      );

      // 3. Print Labels for all items in one batch
      final settingCtrl = Get.find<SettingController>();
      if (settingCtrl.hasPrinterForRole('label')) {
        await printLabels(details, penjualan: penjualan);
      }
    } catch (e) {
      debugPrint('HomeController: printTransactionSession error: $e');
      Get.snackbar('Print Error', 'Failed to execute printing session.');
    }
  }

  /// Helper to load a transaction and its details from local DB.
  Future<Map<String, dynamic>?> _loadTransactionForPrinting(int id) async {
    try {
      final headerRes = await _dbService
          .query('transactions', where: 'id_penjualan = ?', whereArgs: [id]);
      if (headerRes.isEmpty) return null;

      final header = PenjualanModel.fromJson(headerRes.first);
      final List<Map<String, dynamic>> detailRes = await _dbService.rawQuery('''
        SELECT td.*, p.nama_produk as productName
        FROM transaction_details td
        LEFT JOIN products p ON td.id_produk = p.id_produk
        WHERE td.id_penjualan = ?
      ''', [id]);

      final details =
          detailRes.map((m) => PenjualanDetailModel.fromJson(m)).toList();

      return {'header': header, 'details': details};
    } catch (e) {
      debugPrint('HomeController: _loadTransactionForPrinting error: $e');
      return null;
    }
  }

  int countTotalItem() {
    int totalitem = 0;
    for (var element in penjualanDetailModelList) {
      totalitem += element.jumlah;
    }
    return totalitem;
  }

  int countTotalWithDiscount(int hargaAwal, int diskonPersen) {
    return (hargaAwal - (diskonPersen / 100 * hargaAwal)).round();
  }

  int cleanCurrencyFormat(String currency) {
    String noRp = currency.replaceAll('Rp. ', '').replaceAll('.', '');
    String cleanNumber = noRp.split(',')[0];
    return int.parse(cleanNumber);
  }

  String formatRupiah(int number) {
    String currency = 'Rp. ';
    String formattedNumber = number.toString();
    String result = '';
    while (formattedNumber.length > 3) {
      result =
          '.${formattedNumber.substring(formattedNumber.length - 3)}$result';
      formattedNumber =
          formattedNumber.substring(0, formattedNumber.length - 3);
    }
    result = formattedNumber + result;
    return currency + result;
  }

  Future<void> sendToKitchen() async {
    if (penjualanDetailModelList.isEmpty) {
      Get.snackbar(
          'Empty Cart', 'Please add products before sending to kitchen.',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (isProcessingPayment.value ||
        isLoadingTransaction.value ||
        isSyncingDirectly.value) {
      debugPrint("HomeController: sendToKitchen early return — busy state");
      Get.snackbar('System Busy',
          'Aksi sebelumnya sedang diproses. Mohon tunggu sebentar.',
          backgroundColor: Colors.blue.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 2));
      return;
    }

    try {
      isLoadingTransaction.value = true;
      bool saved = await saveOrderLocally();
      if (saved) {
        // Find the newly saved/updated local ID
        final localRow = await _dbService.query('transactions',
            where: 'id_pos = ?', whereArgs: [currentIdPos]);

        if (localRow.isNotEmpty) {
          final idLocal = localRow.first['id_penjualan'];
          final data = await _loadTransactionForPrinting(idLocal);
          if (data != null) {
            final penjualan = data['header'] as PenjualanModel;
            final details = data['details'] as List<PenjualanDetailModel>;

            await printKitchenOrder(
              penjualan: penjualan,
              details: details,
            );

            // Also print labels for each item if a label printer is configured
            final settingCtrl = Get.find<SettingController>();
            if (settingCtrl.hasPrinterForRole('label')) {
              await printLabels(details, penjualan: penjualan);
            }

            Get.snackbar('Sent to Kitchen',
                'Order #${currentRemoteNumber.value.isNotEmpty ? currentRemoteNumber.value : currentRemoteNumber.value} has been sent to preparation.',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                icon: const Icon(CupertinoIcons.check_mark_circled,
                    color: Colors.white));
          }
        } else {
          Get.snackbar('Error', 'Gagal memuat data lokal untuk cetak dapur.',
              backgroundColor: Colors.red.withValues(alpha: 0.1));
        }
      } else {
        final appService = Get.find<AppService>();
        String errorMsg =
            'Gagal menyimpan pesanan. Periksa koneksi internet Anda.';
        if (appService.developerMode.value && lastSyncError.value.isNotEmpty) {
          errorMsg = 'Developer Mode Error: ${lastSyncError.value}';
        }

        Get.snackbar('Sync Failed', errorMsg,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint("HomeController: sendToKitchen error: $e");
      Get.snackbar('Error', 'Failed to send to kitchen: $e');
    } finally {
      isLoadingTransaction.value = false;
    }
  }

  // ----- EXPENSE FEATURE -----
  Future<bool> submitExpense({
    required String name,
    required String note,
    required int amount,
  }) async {
    try {
      final userEmail = userService.getUserEmail();
      int addedFrom = 1;
      String staffFirstName = '';

      // Resolve staff info from SQLite
      if (userEmail.isNotEmpty) {
        final staffRows = await _dbService.query(
          'staff',
          where: 'email = ?',
          whereArgs: [userEmail],
        );
        if (staffRows.isNotEmpty) {
          addedFrom = (staffRows.first['id'] as num?)?.toInt() ?? 1;
          staffFirstName = staffRows.first['firstname']?.toString() ?? '';
        }
      }

      // Fallback: use session staff name if not found in staff table
      if (staffFirstName.isEmpty) {
        staffFirstName = userService.getUserName();
      }

      final now = DateTime.now();
      final dateStr = now.toIso8601String().split('T')[0];
      final createdAt = now.toIso8601String();

      // Get active shift ID
      int idShift = 0;
      if (Get.isRegistered<ShiftController>()) {
        idShift = Get.find<ShiftController>().activeShift.value?.idShift ?? 0;
      }

      // 1. Always save to SQLite first (offline-safe)
      final localId = await _dbService.insertCashFlow({
        'expense_name': name.isNotEmpty ? name : 'Expense',
        'note': note,
        'amount': amount,
        'direction': 'out',
        'staff_name': staffFirstName,
        'staff_email': userEmail,
        'date': dateStr,
        'created_at': createdAt,
        'id_shift': idShift,
        'is_synced': 0,
        'category': '1',
        'addedfrom': addedFrom.toString(),
      });

      // 2. Try to sync to remote API
      final Map<String, dynamic> payload = {
        if (name.isNotEmpty) "expense_name": name,
        if (note.isNotEmpty) "note": note,
        "category": 1,
        "date": dateStr,
        "amount": amount,
        "addedfrom": addedFrom,
      };

      try {
        final response = await apiService.postExpense(payload);
        if (response.responsestate == Constants.successState) {
          // Mark as synced in SQLite
          final remoteId = response.data?['id'] as int? ?? 0;
          await _dbService.markCashFlowSynced(localId, remoteId);

          Get.snackbar(
            'Success',
            'Cash out has been recorded successfully.',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          // API returned error but data is saved locally
          debugPrint(
              '[submitExpense] API error: ${response.message}. Saved offline.');
          Get.snackbar(
            'Saved Offline',
            'Expense saved locally. Will sync when connection is available.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
      } catch (networkError) {
        // Network error — data already saved locally
        debugPrint(
            '[submitExpense] Network error: $networkError. Saved offline.');
        Get.snackbar(
          'Saved Offline',
          'Expense saved locally. Will sync when connection is available.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }

      // Automatically refresh Recap summary if registered
      if (Get.isRegistered<RecapController>()) {
        Get.find<RecapController>().calculateShiftTotals();
      }

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<bool> saveOrderLocally() async {
    lastSyncError.value = "";
    if (penjualanDetailModelList.isEmpty) {
      lastSyncError.value = "Keranjang belanja kosong.";
      return false;
    }
    if (isProcessingPayment.value || isSyncingDirectly.value) {
      lastSyncError.value = "Sistem sedang sibuk menyinkronkan data.";
      return false;
    }

    int idPenjualanLocal = 0;

    try {
      print("POS_LOG: saveOrderLocally started.");
      isSyncingDirectly.value = true;
      isLoadingTransaction.value = true;

      // Guard: If we are working with an existing order, check if it's already PAID
      if (currentIdPos != null) {
        final existingTx = await _dbService.query('transactions',
            where: 'id_pos = ?', whereArgs: [currentIdPos]);
        if (existingTx.isNotEmpty &&
            (existingTx.first['status'] == 2 ||
                existingTx.first['status'] == '2')) {
          debugPrint(
              "HomeController: Order already PAID ($currentIdPos). Skipping saveOrderLocally.");
          return true;
        }
      }

      await userService
          .initSharedPref(); // Ensure prefs are loaded for dynamic baseUrl

      // 1. Prepare data
      final idPos = currentIdPos ?? const Uuid().v4();
      currentIdPos = idPos;

      final subtotal = subtotalRaw.value;
      final total = totalTransaction.value;
      final disc = disscount.value;

      final effectiveMemberId =
          selectedMember.value != null && selectedMember.value!.idMember != 0
              ? selectedMember.value!.idMember
              : (memberId.value != 0 ? memberId.value : 1);

      final Map<String, dynamic> map = {
        'id_user': userService.getPrefInt(Constants.userId),
        'id_member': effectiveMemberId,
        'total_item': penjualanDetailModelList.length,
        'total_harga': subtotal,
        'diskon': disc,
        'bayar': total,
        'diterima': 0, // not yet paid
        'id_pos': idPos,
        'penjualan_detail':
            penjualanDetailModelList.map((e) => e.toJson()).toList(),
      };

      // 2. Local Save (Upsert)
      final existing = await _dbService
          .query('transactions', where: 'id_pos = ?', whereArgs: [idPos]);

      bool isNewRecord = existing.isEmpty;

      final int queueNum = isNewRecord
          ? await appService.getAndIncrementQueue()
          : (existing.first['queue_number'] as int? ?? 0);

      final Map<String, dynamic> txData = {
        'id_user': map['id_user'],
        'id_member': map['id_member'],
        'total_item': map['total_item'],
        'total_harga': map['total_harga'],
        'diskon': map['diskon'],
        'bayar': map['bayar'],
        'order_note': orderNote.value,
        'order_type': selectedOrderType.value,
        'label': customerName,
        'discount_type': manualDiscountIsPercent.value ? 'percent' : 'fixed',
        'manual_discount_value': manualDiscountValue.value,
        'queue_number': queueNum,
      };

      if (!isNewRecord) {
        idPenjualanLocal = existing.first['id_penjualan'] as int;

        await _dbService.update(
            'transactions', txData, 'id_penjualan = ?', [idPenjualanLocal]);

        await _dbService.delete(
            'transaction_details', 'id_penjualan = ?', [idPenjualanLocal]);
      } else {
        txData['id_pos'] = idPos;
        txData['id_shift'] = _shiftController.activeShift.value?.idShift ?? 0;
        txData['status'] = 1; // 1 = Saved / Unpaid
        txData['tgl_penjualan'] = DateTime.now().toIso8601String();
        txData['diterima'] = 0;

        idPenjualanLocal = await _dbService.insert('transactions', txData);
      }

      // Insert details
      for (var element in penjualanDetailModelList) {
        await _dbService.insert('transaction_details', {
          'id_penjualan': idPenjualanLocal,
          'id_produk': element.idProduk,
          'harga_jual': element.hargaJual,
          'jumlah': element.jumlah,
          'subtotal': element.subtotal,
          'note': element.note,
          'order_type': element.orderType,
          'orderTypesJson': element.orderTypesJson,
          'remote_item_id': element.remoteItemId,
          'discountTotal': element.discountTotal,
          'discountType': element.discountType,
          'hargaAwal': element.hargaAwal,
          'product_name': element.productName ?? '',
          'description': element.description,
        });
      }

      return true;
    } catch (e) {
      debugPrint("HomeController: saveOrderLocally error: $e");
      ErrorLogService.log(
        category: 'payment_sync',
        errCode: 'SAVE_ORDER_LOCALLY_FAIL',
        errMsg: e.toString(),
      );
      return false;
    } finally {
      isLoadingTransaction.value = false;
      isSyncingDirectly.value = false;
    }
  }

  void cancelRefund() {
    resetState(0, isSaveOnly: true);
  }

  Future resetState(int penjualanId, {bool isSaveOnly = false}) async {
    if (!isSaveOnly && penjualanId > 1) {
      // Full checkout: delete controller & navigate to success
      Get.delete<HomeController>();
      await Future.delayed(Duration.zero);
      Get.offAllNamed(Routes.successPage,
          arguments: {'penjualan_id': penjualanId});
    } else {
      // Save only: clear all POS state & stay on POS page
      // EXCEPT if we are currently in the Payment flow — we need to preserve state for the payment sync
      if (Get.currentRoute.toLowerCase().contains('payment')) {
        debugPrint(
            "HomeController: Sync completed for payment flow. Preserving state.");
        return;
      }

      final shortCode = (currentIdPos ?? '').length >= 6
          ? (currentIdPos!).substring(currentIdPos!.length - 6).toUpperCase()
          : (currentIdPos ?? '???');

      // --- Clear everything ---
      isRefundMode.value = false;
      penjualanDetailModelList.clear();
      for (var c in controllerStock.values) {
        c.dispose();
      }
      controllerStock.clear();
      memberId.value = 0;
      selectedMember.value = null;
      customerLabel.value = '';
      searchMemberQuery.value = '';
      orderNote.value = '';
      selectedOrderType.value = 'Dine In';
      disscount.value = 0;
      manualDiscountValue.value = 0;
      manualDiscountIsPercent.value = false;
      totalTransaction.value = 0;
      totalHarga = 0;
      totalDiterima = 0;
      currentIdPos = null; // Next save will create a new order
      currentRemoteId.value = 0;
      currentRemoteNumber.value = '';
      originalTglPenjualan = null;
      controllerDiterima.clear();
      controllerKembalian.clear();

      // UI REACTIVITY: Refresh Order & Dashboard counts
      if (Get.isRegistered<OrderController>()) {
        Get.find<OrderController>().getOrders(forceRemote: false);
      }
      if (Get.isRegistered<DashboardEmployeeController>()) {
        Get.find<DashboardEmployeeController>().updateActiveOrderCount();
      }
      if (Get.isRegistered<DashboardAdminController>()) {
        Get.find<DashboardAdminController>().updateActiveOrderCount();
      }
      if (Get.isRegistered<ReportController>()) {
        Get.find<ReportController>().getOrders();
      }
      controllerDiskon.clear();
      manualCashAmount.value = 0;
      // ------------------------

      Get.snackbar(
        'Order Tersimpan',
        'Kode order: #$shortCode',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      // Refresh Active Orders list if visible
      if (Get.isRegistered<OrderController>()) {
        final orderCtrl = Get.find<OrderController>();
        orderCtrl.getOrders(forceRemote: false);
        orderCtrl.update(); // Force refresh for GetBuilder if used
      }

      // Trigger immediate badge count update for sidebar
      try {
        if (Get.isRegistered<DashboardEmployeeController>()) {
          Get.find<DashboardEmployeeController>().updateActiveOrderCount();
        }
        if (Get.isRegistered<DashboardAdminController>()) {
          Get.find<DashboardAdminController>().updateActiveOrderCount();
        }
      } catch (_) {}
    }
  }

  Future<void> loadTransaction(Map<String, dynamic> order,
      {bool isRefundMode = false}) async {
    try {
      isLoadingTransaction.value = true;

      // 1. Clear current POS state completely to avoid duplication
      penjualanDetailModelList.clear();
      for (var c in controllerStock.values) {
        c.dispose();
      }
      controllerStock.clear();
      totalTransaction.value = 0;
      totalHarga = 0;
      memberId.value = 0;
      selectedMember.value = null;
      orderNote.value = '';
      manualDiscountValue.value = 0;
      manualDiscountIsPercent.value = false;

      // 2. Restore header fields
      final idPenjualan = order['id_penjualan'];
      currentIdPos = order['id_pos'];
      originalTglPenjualan =
          order['tgl_penjualan']?.toString(); // preserve original date
      memberId.value = order['id_member'] ?? 0;
      selectedOrderType.value =
          (order['order_type'] as String?)?.isNotEmpty == true
              ? order['order_type'] as String
              : 'Dine In';

      String rawNote = order['order_note']?.toString() ?? "";

      // Cleanup: Strip out ITEM NOTES if they exist in the DB (for old/migrated records)
      if (rawNote.contains('---ITEM NOTES---')) {
        rawNote = rawNote.split('---ITEM NOTES---')[0].trim();
      }

      orderNote.value = rawNote;
      customerLabel.value = (order['label'] as String?) ?? '';

      // RESTORE MANUAL DISCOUNT STATE
      final String discType = (order['discount_type'] as String?) ?? 'percent';
      manualDiscountIsPercent.value = discType == 'percent';
      manualDiscountValue.value = (order['manual_discount_value'] as int?) ?? 0;

      // Update global refund mode state
      this.isRefundMode.value = isRefundMode;

      // 3. Restore selected member
      // FORCE REFRESH: Fetch the very latest member data from DB, bypassing the potentially stale memberList
      final freshMemberData = await _dbService.query('members',
          where: 'id_member = ?', whereArgs: [memberId.value]);

      if (freshMemberData.isNotEmpty) {
        selectedMember.value = MemberModel.fromJson(freshMemberData.first);

        // Also update the list in memory if it was stale
        final listIdx =
            memberList.indexWhere((m) => m.idMember == memberId.value);
        if (listIdx != -1) {
          memberList[listIdx] = selectedMember.value!;
        } else {
          memberList.add(selectedMember.value!);
        }
      }

      // 4. Fetch transaction details with product info
      final List<Map<String, dynamic>> details = await _dbService.rawQuery('''
        SELECT td.*, p.nama_produk as fresh_name, p.stok as current_stok
        FROM transaction_details td
        LEFT JOIN products p ON td.id_produk = p.id_produk
        WHERE td.id_penjualan = ?
      ''', [idPenjualan]);

      // 5. Populate cart, restoring per-item note and orderType
      for (var detail in details) {
        final itemOrderType =
            (detail['order_type'] as String?)?.isNotEmpty == true
                ? detail['order_type'] as String
                : selectedOrderType.value;
        String noteStr = (detail['note'] as String?) ?? '';

        // Priority: 1. Live name (catalog), 2. Persisted name in DB from transaction-time/sync, 3. Fallback
        String prodName = (detail['fresh_name'] as String?) ??
            ((detail['product_name'] as String?)?.isNotEmpty == true
                ? detail['product_name'] as String
                : 'Unknown Product');

        if (detail['id_produk'] == 0 && noteStr.startsWith('REMOTE_ITEM:')) {
          prodName = noteStr.replaceFirst('REMOTE_ITEM:', '');
          noteStr = ''; // Hide the internal marker from the UI
        }

        final int hargaJual = (detail['harga_jual'] as num?)?.toInt() ?? 0;
        final int jumlah = (detail['jumlah'] as num?)?.toInt() ?? 0;
        final int rawHargaAwal = (detail['harga_awal'] as num?)?.toInt() ?? 0;
        final int hargaAwal = rawHargaAwal > 0 ? rawHargaAwal : hargaJual;
        final int discountTotal =
            (detail['discountTotal'] as num?)?.toInt() ?? 0;
        // Recalculate subtotal if stored value is 0 or null (handles legacy / corrupted rows)
        int savedSubtotal = (detail['subtotal'] as num?)?.toInt() ?? 0;
        if (savedSubtotal == 0 && jumlah > 0 && hargaJual > 0) {
          savedSubtotal = jumlah * hargaJual;
        }

        final item = PenjualanDetailModel(
          idProduk: (detail['id_produk'] as num?)?.toInt() ?? 0,
          productName: prodName,
          description: detail['description']?.toString(),
          hargaJual: hargaJual,
          hargaAwal: hargaAwal,
          jumlah: jumlah,
          totalStock: (detail['current_stok'] as num?)?.toInt() ?? 0,
          subtotal: savedSubtotal,
          orderType: itemOrderType,
          orderTypesJson: (detail['orderTypesJson'] as String?) ?? "",
          note: noteStr,
          remoteItemId: (detail['remote_item_id'] as num?)?.toInt() ?? 0,
          discountTotal: discountTotal,
          discountType: (detail['discountType'] as String?) ?? 'percent',
          isRefund: (detail['is_refund']?.toString() == '1' ||
              detail['isRefund'] == true),
          originalQty: isRefundMode
              ? jumlah
              : 0, // Store original qty for max void limit
        );

        penjualanDetailModelList.add(item);
        controllerStock[item.idProduk] =
            TextEditingController(text: item.jumlah.toString());
      }

      calculateTotals();
      isLoadingTransaction.value = false;
      // No success snackbar — navigating to POS is feedback enough
    } catch (e) {
      isLoadingTransaction.value = false;
      Get.snackbar('Error', 'Failed to load order: $e');
      debugPrint('ERROR loading order: $e');
      ErrorLogService.log(
        category: 'order',
        errCode: 'LOAD_ORDER_FAIL',
        errMsg: e.toString(),
      );
    }
  }

  void clearCustomerForm() {
    nameController.clear();
    phoneController.clear();
    addressController.clear();
    isAddingCustomer.value = false;
  }

  Future<void> saveNewCustomer() async {
    if (nameController.text.isEmpty) {
      Get.snackbar('Error', 'Nama customer tidak boleh kosong');
      return;
    }

    // Show loading
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final String name = nameController.text.trim();
      final String phone = phoneController.text.trim();
      final String address = addressController.text.trim();
      final String idPosMember = const Uuid().v4();

      final Map<String, String> memberData = {
        'id_pos': idPosMember,
        'nama': name,
        'no_hp': phone,
        'alamat': address,
      };

      // 1. Try to sync immediately
      MemberModel? resolvedMember;
      bool syncedInstantly = false;

      try {
        final response = await apiService.storeMember(memberData);
        if (response.responsestate == Constants.successState &&
            response.data != null) {
          final List<MemberModel> members = response.data as List<MemberModel>;
          if (members.isNotEmpty) {
            resolvedMember = members.first;
            syncedInstantly = true;
          }
        }
      } catch (e) {
        debugPrint(
            'HomeController: Immediate member sync failed (offline?), falling back: $e');
      }

      int localId;
      if (syncedInstantly && resolvedMember != null) {
        localId = resolvedMember.idMember;
      } else {
        localId = -(DateTime.now().millisecondsSinceEpoch % 1000000000);
        resolvedMember = MemberModel(
          idMember: localId,
          idPos: idPosMember,
          nama: name,
          telepon: phone,
          alamat: address,
        );
      }

      // 2. Save to local SQLite
      await _dbService.insert('members', {
        'id_member': resolvedMember.idMember,
        'id_pos': resolvedMember.idPos ?? idPosMember,
        'nama': resolvedMember.nama,
        'telepon': resolvedMember.telepon,
        'alamat': resolvedMember.alamat,
        'is_synced': syncedInstantly ? 1 : 0,
      });

      // 3. Enqueue Sync Command ONLY if not already synced instantly
      if (!syncedInstantly) {
        final syncService = Get.find<SyncService>();
        await syncService.enqueueCommand(
          method: 'POST',
          endpoint: '/api/pos_customers',
          isFormData: true,
          body: memberData,
          localId: localId,
        );
      }

      // Close loading dialog
      Get.back();

      // 4. Update UI instantly
      if (!memberList.any((m) => m.nama == name && m.telepon == phone)) {
        memberList.insert(0, resolvedMember);
      }

      selectedMember.value = resolvedMember;
      memberId.value = resolvedMember.idMember;
      customerLabel.value = resolvedMember.nama ?? '';
      isAddingCustomer.value = false;
      clearCustomerForm();

      // Notify MemberController if it exists
      if (Get.isRegistered<MemberController>()) {
        Get.find<MemberController>().getMember();
      }

      Get.snackbar(
          'Success',
          syncedInstantly
              ? 'Customer berhasil ditambahkan'
              : 'Customer ditambahkan lokal & sedang disinkronkan');
    } catch (e) {
      if (Get.isOverlaysOpen) Get.back(); // Close loading if open
      Get.snackbar('Error', 'Gagal menambahkan customer: $e');
      ErrorLogService.log(
        category: 'customer',
        errCode: 'ADD_CUSTOMER_FAIL',
        errMsg: e.toString(),
      );
    }
  }

  Future<void> savePosSettings(Map<String, dynamic> newSettings) async {
    if (isSavingSettings.value) return;
    isSavingSettings.value = true;

    Get.dialog(const Center(child: CircularProgressIndicator()),
        barrierDismissible: false);
    try {
      // 1. Update local state and persist to SQLite immediately
      appService.posSettings.value = newSettings;
      await appService.saveSettingsLocally(newSettings);

      final payload = {
        'pos_app_settings': jsonEncode(newSettings),
      };

      final response = await apiService.updatePosOptions(payload);
      if (Get.isDialogOpen ?? false) Get.back(); // close loading indicator

      if (response.responsestate == Constants.successState) {
        Get.snackbar('Success', 'Settings successfully saved and synced');
      } else {
        Get.snackbar('Attention',
            'Settings saved locally, but server returned: ${response.message}');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();

      String errorMsg =
          e is SocketException || e.toString().contains('host lookup')
              ? 'No internet connection. Settings saved on this device.'
              : 'Failed to sync to server ($e). Settings saved locally.';

      Get.snackbar('Info', errorMsg,
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          icon: const Icon(Icons.info, color: Colors.blue),
          duration: const Duration(seconds: 4));
    } finally {
      isSavingSettings.value = false;
    }
  }

  @override
  void onClose() {
    searchFocusNode.dispose();
    super.onClose();
  }
}
