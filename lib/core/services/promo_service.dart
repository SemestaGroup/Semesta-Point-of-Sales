import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';

class PromoDiscount {
  final int finalPrice;
  final int discountTotal;
  final String discountType;

  PromoDiscount(this.finalPrice, this.discountTotal, this.discountType);
}

class PromoService extends GetxService {
  final DatabaseService _dbService = Get.find<DatabaseService>();
  
  // Cache of active promos
  final RxList<Map<String, dynamic>> activePromos = <Map<String, dynamic>>[].obs;
  // Cache of product IDs that have an active promo for O(1) lookup in UI
  final RxSet<int> promoProductIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadPromos();
  }

  /// Load all active promos from SQLite that are within the valid date range
  Future<void> loadPromos() async {
    try {
      final rows = await _dbService.query('pos_promotions', where: "status = '1' OR status = 1");
      final now = DateTime.now();
      final List<Map<String, dynamic>> validPromos = [];

      for (var row in rows) {
        final startDateStr = row['start_date']?.toString();
        final endDateStr = row['end_date']?.toString();
        
        if (startDateStr != null && endDateStr != null) {
          try {
            final startDate = DateTime.parse(startDateStr);
            final endDate = DateTime.parse(endDateStr).add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)); // End of day
            
            if (now.compareTo(startDate) >= 0 && now.compareTo(endDate) <= 0) {
              validPromos.add(Map<String, dynamic>.from(row));
            }
          } catch (e) {
            debugPrint("PromoService: Error parsing dates for promo ${row['id']}");
          }
        }
      }
      activePromos.value = validPromos;

      // Extract all item_ids that have active promos
      Set<int> ids = {};
      for (var promo in validPromos) {
        final rawItems = promo['items']?.toString();
        if (rawItems != null && rawItems.isNotEmpty) {
          try {
            final Map itemsObj = jsonDecode(rawItems);
            final List itemsList = itemsObj['items'] ?? [];
            for (var item in itemsList) {
              final idStr = item['item_id']?.toString();
              if (idStr != null) {
                final id = int.tryParse(idStr);
                if (id != null) ids.add(id);
              }
            }
          } catch (_) {}
        }
      }
      promoProductIds.value = ids;

      debugPrint("PromoService: Loaded ${activePromos.length} active promos.");
    } catch (e) {
      debugPrint("PromoService: Failed to load promos - $e");
    }
  }

  /// Calculates the best price taking into account product discounts and active promotions.
  /// Does NOT stack discounts. Returns the discount configuration that gives the lowest price.
  PromoDiscount calculateBestPrice({
    required int productId,
    required String? productBrandIdStr, // Since ProductModel does not have idBrand directly in the file, we can pass it or ignore if not available
    required int dynamicPrice,
    required String orderType,
    required int productDiscountTotal,
    required String productDiscountType,
  }) {
    // 1. Calculate price with product's own discount
    int productFinalPrice = _applyDiscount(dynamicPrice, productDiscountType, productDiscountTotal);
    int bestFinalPrice = productFinalPrice;
    int bestDiscountTotal = productDiscountTotal;
    String bestDiscountType = productDiscountType;

    // 2. Check all active promos to find if any gives a better price
    for (var promo in activePromos) {
      // Check Order Type
      bool matchOrderType = false;
      final rawOrderTypes = promo['order_types']?.toString();
      if (rawOrderTypes != null && rawOrderTypes.isNotEmpty) {
        try {
          final List types = jsonDecode(rawOrderTypes);
          final normalizedInput = orderType.replaceAll(' ', '').toLowerCase();
          for (var type in types) {
            final normalizedType = type.toString().replaceAll(' ', '').toLowerCase();
            if (normalizedType == normalizedInput) {
              matchOrderType = true;
              break;
            }
          }
        } catch (_) {}
      }
      // If the promo specifies order types and ours doesn't match, skip
      if (rawOrderTypes != null && rawOrderTypes.isNotEmpty && !matchOrderType) {
        continue;
      }

      // Check Items
      final rawItems = promo['items']?.toString();
      if (rawItems != null && rawItems.isNotEmpty) {
        try {
          final Map itemsObj = jsonDecode(rawItems);
          final List itemsList = itemsObj['items'] ?? [];
          for (var item in itemsList) {
            if (item['item_id']?.toString() == productId.toString()) {
              final promoDiscountType = item['discount_type']?.toString() ?? 'fixed';
              final promoDiscountTotal = int.tryParse(item['discount']?.toString() ?? '0') ?? 0;
              final promoDiscountValue = int.tryParse(item['discount_value']?.toString() ?? '0') ?? 0;

              // For final_price, we use discount_value. For percent, discount is the %.
              // Actually, the example shows "discount" holds the % or fixed amount.
              // We will map 'discount_type' logic here:
              int discountAmt = (promoDiscountType == 'final_price') 
                  ? promoDiscountValue 
                  : promoDiscountTotal;

              int promoFinalPrice = _applyDiscount(dynamicPrice, promoDiscountType, discountAmt);
              
              if (promoFinalPrice < bestFinalPrice) {
                bestFinalPrice = promoFinalPrice;
                bestDiscountTotal = discountAmt;
                bestDiscountType = promoDiscountType;
              }
            }
          }
        } catch (e) {
          debugPrint("PromoService: Error parsing promo items - $e");
        }
      }
    }

    return PromoDiscount(bestFinalPrice, bestDiscountTotal, bestDiscountType);
  }

  int _applyDiscount(int basePrice, String type, int discountValue) {
    if (discountValue <= 0) return basePrice;
    
    int price = basePrice;
    if (type == 'percent') {
      price = basePrice - (basePrice * discountValue ~/ 100);
    } else if (type == 'final_price') {
      price = discountValue;
    } else {
      // fixed
      price = basePrice - discountValue;
    }
    
    return price < 0 ? 0 : price;
  }
}
