import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/core/models/penjualan_detail/penjualan_detail_model.dart';
import 'package:semesta_pos/core/services/sync_service.dart';

class PromoDiscount {
  final int finalPrice;
  final int discountTotal;
  final String discountType;

  PromoDiscount(this.finalPrice, this.discountTotal, this.discountType);
}

/// Internal helper to hold a promo discount result for a single product.
class _PromoItemDiscount {
  final int finalPrice;
  final int discountTotal;
  final String discountType;
  _PromoItemDiscount({
    required this.finalPrice,
    required this.discountTotal,
    required this.discountType,
  });
}

class PromoService extends GetxService {
  final DatabaseService _dbService = Get.find<DatabaseService>();
  
  // Cache of active promos
  final RxList<Map<String, dynamic>> activePromos = <Map<String, dynamic>>[].obs;
  // Cache of product IDs that have an active promo for O(1) lookup in UI
  final RxSet<int> promoProductIds = <int>{}.obs;
  // Cache of product IDs that have an active bundling promo
  final RxSet<int> bundlingProductIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadPromos();

    // Reactively reload promos if background/manual sync updates the database
    if (Get.isRegistered<SyncService>()) {
      ever(Get.find<SyncService>().syncStatus, (String status) {
        if (status == "Sync Complete" ||
            status.contains("Updated") ||
            status == "Promotions Updated") {
          loadPromos();
        }
      });
    }
  }

  /// Load all active promos from SQLite that are within the valid date range
  Future<void> loadPromos() async {
    try {
      final productRows = await _dbService.query('products', columns: ['id_produk']);
      final Set<int> localProductIds = productRows
          .map((r) => int.tryParse(r['id_produk']?.toString() ?? '') ?? 0)
          .where((id) => id != 0)
          .toSet();

      final rows = await _dbService.query('pos_promotions', where: "status = '1' OR status = 1");
      final now = DateTime.now();
      final List<Map<String, dynamic>> validPromos = [];

      for (var row in rows) {
        final startDateStr = row['start_date']?.toString();
        final endDateStr = row['end_date']?.toString();
        
        if (startDateStr != null && endDateStr != null) {
          try {
            final startRaw = DateTime.parse(startDateStr);
            final startDate = DateTime(startRaw.year, startRaw.month, startRaw.day);
            
            final endRaw = DateTime.parse(endDateStr);
            final endDate = DateTime(endRaw.year, endRaw.month, endRaw.day);
            
            final today = DateTime(now.year, now.month, now.day);
            
            bool isStartUnlimited = startDateStr.startsWith('0000-00-00');
            bool isEndUnlimited = endDateStr.startsWith('0000-00-00');
            
            bool validStart = isStartUnlimited || today.compareTo(startDate) >= 0;
            bool validEnd = isEndUnlimited || today.compareTo(endDate) <= 0;
            
            if (validStart && validEnd) {
              final promoMap = Map<String, dynamic>.from(row);
              bool shouldAdd = true;
              
              if (promoMap['promo_type']?.toString() == 'bundling') {
                shouldAdd = false;
                final rawItems = promoMap['items']?.toString();
                if (rawItems != null && rawItems.isNotEmpty) {
                  try {
                    dynamic decoded = jsonDecode(rawItems);
                    if (decoded is String) decoded = jsonDecode(decoded);
                    List rulesList = [];
                    if (decoded is Map) {
                      rulesList = decoded['detail'] ?? [];
                    } else if (decoded is List) {
                      rulesList = decoded;
                    }
                    for (var rule in rulesList) {
                      final targetIds = rule['target_id'];
                      if (targetIds is List) {
                        for (var tId in targetIds) {
                          final id = int.tryParse(tId.toString());
                          if (id != null && localProductIds.contains(id)) {
                            shouldAdd = true;
                            break;
                          }
                        }
                      }
                      if (shouldAdd) break;
                    }
                  } catch (_) {}
                }
              }
              
              if (shouldAdd) {
                validPromos.add(promoMap);
              }
            }
          } catch (e) {
            debugPrint("PromoService: Error parsing dates for promo ${row['id']}");
          }
        }
      }
      activePromos.value = validPromos;

      // Extract all item_ids that have active promos
      Set<int> ids = {};
      Set<int> bundlingIds = {};
      for (var promo in validPromos) {
        final rawItems = promo['items']?.toString();
        if (rawItems != null && rawItems.isNotEmpty) {
          try {
            dynamic decoded = jsonDecode(rawItems);
            // Handle double-encoded JSON if backend sends it as a string
            if (decoded is String) {
              decoded = jsonDecode(decoded);
            }
            
            final isBundling = promo['promo_type']?.toString() == 'bundling';
            
            if (isBundling) {
              // Bundling structure: { total_price: ..., detail: [ { target_id: [...], qty: ... } ] }
              List rulesList = [];
              if (decoded is Map) {
                rulesList = decoded['detail'] ?? [];
              } else if (decoded is List) {
                rulesList = decoded;
              }
              for (var rule in rulesList) {
                final targetIdsDynamic = rule['target_id'];
                if (targetIdsDynamic is List) {
                  for (var targetId in targetIdsDynamic) {
                    final id = int.tryParse(targetId.toString());
                    if (id != null) {
                      bundlingIds.add(id);
                    }
                  }
                }
              }
            } else {
              // Regular promo structure: list of items with item_id
              List itemsList = [];
              if (decoded is List) {
                itemsList = decoded;
              } else if (decoded is Map) {
                itemsList = decoded['items'] ?? [];
              }
              for (var item in itemsList) {
                final idStr = item['item_id']?.toString();
                if (idStr != null) {
                  final id = int.tryParse(idStr);
                  if (id != null) ids.add(id);
                }
              }
            }
          } catch (e) {
            debugPrint("PromoService: Error parsing promo items for ${promo['id']} - $e");
          }
        }
      }
      promoProductIds.clear();
      promoProductIds.addAll(ids);
      
      bundlingProductIds.clear();
      bundlingProductIds.addAll(bundlingIds);

      debugPrint("PromoService: Loaded ${activePromos.length} active promos.");
    } catch (e) {
      debugPrint("PromoService: Failed to load promos - $e");
    }
  }

  /// Calculates the best price taking into account product discounts and the manually selected promotion.
  /// Processing rules:
  ///   - Non-stackable promos (is_stackable != '1'): compete against each other, only the best one applies
  ///   - Stackable promos (is_stackable == '1'): chain on top of whatever best price is available
  PromoDiscount calculateBestPrice({
    required int productId,
    String? productBrandIdStr,
    required int dynamicPrice,
    required String orderType,
    required int productDiscountTotal,
    required String productDiscountType,
    List<Map<String, dynamic>>? selectedPromos,
  }) {
    // 1. Calculate price with product's own discount
    int productFinalPrice = _applyDiscount(dynamicPrice, productDiscountType, productDiscountTotal);
    int bestFinalPrice = productFinalPrice;
    int bestDiscountTotal = productDiscountTotal;
    String bestDiscountType = productDiscountType;

    // 2. If no promos are selected by the cashier, just return the product's own discount.
    if (selectedPromos == null || selectedPromos.isEmpty) {
      return PromoDiscount(bestFinalPrice, bestDiscountTotal, bestDiscountType);
    }

    // 3. Separate stackable and non-stackable promos
    final List<Map<String, dynamic>> nonStackablePromos = [];
    final List<Map<String, dynamic>> stackablePromos = [];
    for (var p in selectedPromos) {
      if (p['is_stackable']?.toString() == '1') {
        stackablePromos.add(p);
      } else {
        nonStackablePromos.add(p);
      }
    }

    // Phase A: Non-stackable promos — they compete, only the best one applies
    for (var selectedPromo in nonStackablePromos) {
      if (!_promoMatchesOrderType(selectedPromo, orderType)) continue;
      final result = _getDiscountForProduct(selectedPromo, productId, dynamicPrice);
      if (result != null && result.finalPrice < bestFinalPrice) {
        bestFinalPrice = result.finalPrice;
        bestDiscountTotal = result.discountTotal;
        bestDiscountType = result.discountType;
      }
    }

    // Phase B: Stackable promos — chain on top of the current best price
    for (var selectedPromo in stackablePromos) {
      if (!_promoMatchesOrderType(selectedPromo, orderType)) continue;
      final result = _getDiscountForProduct(selectedPromo, productId, bestFinalPrice);
      if (result != null && result.finalPrice < bestFinalPrice) {
        bestFinalPrice = result.finalPrice;
        bestDiscountTotal = dynamicPrice - bestFinalPrice;
        bestDiscountType = 'fixed';
      }
    }

    return PromoDiscount(bestFinalPrice, bestDiscountTotal, bestDiscountType);
  }

  /// Check whether a promo's order_types constraint matches the given order type.
  /// Returns true if the promo has no order_types filter, or if the input matches.
  bool _promoMatchesOrderType(Map<String, dynamic> promo, String orderType) {
    final rawOrderTypes = promo['order_types']?.toString();
    if (rawOrderTypes == null || rawOrderTypes.isEmpty) return true;
    try {
      dynamic decoded = jsonDecode(rawOrderTypes);
      if (decoded is String) decoded = jsonDecode(decoded);
      if (decoded is List) {
        final normalizedInput = orderType.replaceAll(' ', '').toLowerCase();
        for (var type in decoded) {
          if (type.toString().replaceAll(' ', '').toLowerCase() == normalizedInput) return true;
        }
      }
    } catch (e) {
      debugPrint("PromoService: Error parsing order_types - $e");
    }
    return false;
  }

  /// Extract the discount from a promo for a specific product, applied to [basePrice].
  /// Returns null if the promo doesn't apply to this product.
  _PromoItemDiscount? _getDiscountForProduct(
      Map<String, dynamic> promo, int productId, int basePrice) {
    final rawItems = promo['items']?.toString();
    if (rawItems == null || rawItems.isEmpty) return null;
    try {
      dynamic decoded = jsonDecode(rawItems);
      if (decoded is String) decoded = jsonDecode(decoded);
      List itemsList = [];
      if (decoded is List) {
        itemsList = decoded;
      } else if (decoded is Map) {
        itemsList = decoded['detail'] ?? decoded['items'] ?? [];
      }
      for (var item in itemsList) {
        if (item['item_id']?.toString() == productId.toString()) {
          final promoDiscountType = item['discount_type']?.toString() ?? 'fixed';
          final promoDiscountTotal = int.tryParse(item['discount']?.toString() ?? '0') ?? 0;
          final promoDiscountValue = int.tryParse(item['discount_value']?.toString() ?? '0') ?? 0;

          final discountAmt = (promoDiscountType == 'final_price')
              ? promoDiscountValue
              : promoDiscountTotal;
          final finalPrice = _applyDiscount(basePrice, promoDiscountType, discountAmt);
          return _PromoItemDiscount(
            finalPrice: finalPrice,
            discountTotal: discountAmt,
            discountType: promoDiscountType,
          );
        }
      }
    } catch (e) {
      debugPrint("PromoService: Error parsing promo items - $e");
    }
    return null;
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

  int calculateBundlingDiscount(List<PenjualanDetailModel> cart, Map<String, dynamic> promo) {
    try {
      if (promo['promo_type'] != 'bundling') return 0;
      
      final rawItems = promo['items'];
      if (rawItems == null) return 0;
      
      dynamic itemsObj = rawItems;
      if (itemsObj is String) {
        itemsObj = jsonDecode(itemsObj);
      }
      
      final bundlePriceStr = itemsObj['total_price']?.toString() ?? '0';
      final bundlePrice = int.tryParse(bundlePriceStr) ?? 0;
      final rulesDynamic = itemsObj['detail'];
      if (rulesDynamic == null || rulesDynamic is! List) return 0;
      final rules = rulesDynamic;
      
      final isMultiplied = promo['is_multiplied']?.toString() == '1';
      int totalDiscount = 0;
      
      // Build pool of available items
      List<Map<String, dynamic>> pool = [];
      for (var item in cart) {
        if (!item.isRefund && item.jumlah > 0) {
          pool.add({
            'id': item.idProduk,
            'qty': item.jumlah,
            // Normal base price of the item
            'price': item.hargaAwal > 0 ? item.hargaAwal : item.hargaJual,
          });
        }
      }
      
      while (true) {
        // Deep copy pool for this bundle instance iteration
        List<Map<String, dynamic>> tempPool = pool.map((p) => Map<String, dynamic>.from(p)).toList();
        bool allRulesMet = true;
        int normalPriceOfBundle = 0;
        
        for (var rule in rules) {
           final targetIdsDynamic = rule['target_id'];
           if (targetIdsDynamic == null || targetIdsDynamic is! List) {
             allRulesMet = false;
             break;
           }
           final targetIds = targetIdsDynamic.map((e) => int.tryParse(e.toString()) ?? -1).toList();
           final requiredQty = int.tryParse(rule['qty']?.toString() ?? '0') ?? 0;
           if (requiredQty <= 0) continue;
           
           final mustBeDifferent = rule['must_be_different']?.toString() == '1';
           
           if (mustBeDifferent) {
              var candidates = tempPool.where((p) => targetIds.contains(p['id']) && (p['qty'] as int) > 0).toList();
              if (candidates.length < requiredQty) {
                 allRulesMet = false;
                 break;
              }
              // Sort by highest price to give customer the best discount
              candidates.sort((a, b) => (b['price'] as int).compareTo(a['price'] as int));
              
              for (int i = 0; i < requiredQty; i++) {
                 candidates[i]['qty'] = (candidates[i]['qty'] as int) - 1;
                 normalPriceOfBundle += (candidates[i]['price'] as int);
              }
           } else {
              var candidates = tempPool.where((p) => targetIds.contains(p['id']) && (p['qty'] as int) > 0).toList();
              candidates.sort((a, b) => (b['price'] as int).compareTo(a['price'] as int));
              
              int remainingQty = requiredQty;
              for (var c in candidates) {
                 if (remainingQty == 0) break;
                 int available = c['qty'] as int;
                 int take = available >= remainingQty ? remainingQty : available;
                 c['qty'] = available - take;
                 normalPriceOfBundle += (c['price'] as int) * take;
                 remainingQty -= take;
              }
              if (remainingQty > 0) {
                 allRulesMet = false;
                 break;
              }
           }
        }
        
        if (allRulesMet) {
           // Commit deductions to the main pool
           pool = tempPool;
           
           int discountForThisBundle = normalPriceOfBundle - bundlePrice;
           if (discountForThisBundle < 0) discountForThisBundle = 0;
           totalDiscount += discountForThisBundle;
           
           if (!isMultiplied) break;
        } else {
           break; // Cannot fulfill another bundle
        }
      }
      return totalDiscount;
    } catch (e) {
      debugPrint("PromoService: Error calculating bundling discount - $e");
      return 0;
    }
  }
}
