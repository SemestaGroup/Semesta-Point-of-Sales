import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/models/app/app_model.dart';
import 'package:semesta_pos/core/services/remote/api_service.dart';
import 'package:semesta_pos/core/services/user_service.dart';
import 'package:semesta_pos/core/util/constans.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/core/services/sync_service.dart';
import 'package:sqflite/sqflite.dart';

class AppService extends GetxService {
  Rx<AppModel> appModel = const AppModel().obs;
  RxBool allowZeroStock = true.obs;
  RxBool useDefaultDiscount = false.obs;
  // 'printer' = send to kitchen printer, 'livesync' = update DB so KDS tablet reads it
  RxString kitchenMode = 'printer'.obs;
  // Developer mode — owner only, shows SQLite inspector & detailed error snackbars
  RxBool developerMode = false.obs;
  
  // Queue tracking
  RxInt queueNumber = 1.obs;
  RxString lastQueueDate = "".obs;
  
  // Settings for POS Application
  RxMap<String, dynamic> posSettings = <String, dynamic>{
    'display': {
      'show_image': true,
      'show_name': true,
      'show_price': false,
      'show_stock': false,
    },
    'printing': {
      'auto_print': false,
    },
    'kitchen': {
      'send_mode': 'printer', // 'printer' or 'livesync'
    },
  }.obs;

  ApiService get apiService => Get.find<ApiService>();


  @override
  void onInit() {
    super.onInit();
    final userService = Get.find<UserService>();
    allowZeroStock.value = userService.getPrefBool(Constants.allowZeroStock);
    useDefaultDiscount.value =
        userService.getPrefBool(Constants.useDefaultDiscount);
    developerMode.value = userService.getPrefBool('developer_mode');
    
    // Load local only. Remote sync is handled by SyncService or manual refresh.
    loadLocalSettings();
  }

  void setDeveloperMode(bool value) {
    developerMode.value = value;
    final userService = Get.find<UserService>();
    userService.saveBool('developer_mode', value);
  }

  void updateKitchenSetting(String mode) {
    kitchenMode.value = mode;
    var kitchen = Map<String, dynamic>.from(posSettings['kitchen'] ?? {});
    kitchen['send_mode'] = mode;
    posSettings['kitchen'] = kitchen;
    saveSettingsLocally(posSettings);
  }

  void setAllowZeroStock(bool value) {
    allowZeroStock.value = value;
    final userService = Get.find<UserService>();
    userService.saveBool(Constants.allowZeroStock, value);
    
    // Also sync to unified posSettings
    var display = Map<String, dynamic>.from(posSettings['display'] ?? {});
    display['allow_zero_stock'] = value;
    posSettings['display'] = display;
    saveSettingsLocally(posSettings);
  }

  void setUseDefaultDiscount(bool value) {
    useDefaultDiscount.value = value;
    final userService = Get.find<UserService>();
    userService.saveBool(Constants.useDefaultDiscount, value);
    
    // Also sync to unified posSettings
    var display = Map<String, dynamic>.from(posSettings['display'] ?? {});
    display['use_default_discount'] = value;
    posSettings['display'] = display;
    saveSettingsLocally(posSettings);
  }

  void updateDisplaySetting(String key, bool value) {
    var display = Map<String, dynamic>.from(posSettings['display'] ?? {});
    display[key] = value;
    posSettings['display'] = display;
    saveSettingsLocally(posSettings);
  }

  void updatePrintingSetting(String key, bool value) {
    var printing = Map<String, dynamic>.from(posSettings['printing'] ?? {});
    printing[key] = value;
    posSettings['printing'] = printing;
    saveSettingsLocally(posSettings);
  }

  Future<void> saveSettingsLocally(Map<String, dynamic> settings) async {
    final userService = Get.find<UserService>();
    userService.saveString('pos_app_settings', jsonEncode(settings));
    
    // Also save to SQLite for robustness and visibility
    final db = Get.find<DatabaseService>();

    await db.insert('pos_options', {
      'option_name': 'pos_app_settings',
      'option_value': jsonEncode(settings),
    });
  }

  // AppModel get appModel => _appModel.value;

  Future<void> fetchAppData() async {
    try {
      final response = await apiService.getPosOptions();

      if (response.responsestate == Constants.successState &&
          response.data != null) {
        Map<String, dynamic> rawOptions = {};
        if (response.data is Map) {
          rawOptions = response.data as Map<String, dynamic>;
        } else if (response.data is List) {
          final list = response.data as List;
          for (var item in list) {
            if (item is Map) {
              if (item.containsKey('option_name') && item.containsKey('option_value')) {
                rawOptions[item['option_name'].toString()] = item['option_value'];
              } else {
                // If it's a list of maps (like the example in docs), merge them
                rawOptions.addAll(Map<String, dynamic>.from(item));
              }
            }
          }
        }
        
        final options = rawOptions.map((key, value) => MapEntry(key.trim(), value));
        
        await _processOptions(options);
      } else {
        await loadLocalSettings();
      }
    } catch (e) {
      debugPrint("AppService: fetchAppData failed, loading local: $e");
      await loadLocalSettings();
    }
  }

  Future<void> _processOptions(Map<String, dynamic> options) async {
    // Extract values with fallback to existing if empty (following API_DOCS.md GET structure)
    final newName = (options['pos_tenant_name'] ?? options['pos_company_name'] ?? options['company_name'])?.toString().trim() ?? "";
    final newAddress = (options['pos_address'] ?? options['company_address'] ?? options['address'])?.toString().trim() ?? "";
    final newPhone = (options['pos_phone'] ?? options['pos_phone_number'] ?? options['company_phone'])?.toString().trim() ?? "";
    final newVersion = (options['pos_version'] ?? options['version'] ?? options['app_version'])?.toString().trim() ?? "";
    final newDiscount = (options['pos_default_discount'] ?? options['default_discount'])?.toString().trim() ?? "0";

    appModel.value = appModel.value.copyWith(
      namaPerusahaan: newName.isNotEmpty ? newName : appModel.value.namaPerusahaan,
      alamat: newAddress.isNotEmpty ? newAddress : appModel.value.alamat,
      telepon: newPhone.isNotEmpty ? newPhone : appModel.value.telepon,
      diskon: int.tryParse(newDiscount) ?? appModel.value.diskon,
      version: newVersion.isNotEmpty ? newVersion : appModel.value.version,
    );
    
    // Parsing unified app settings
    final posAppSettingsRaw = options['pos_app_settings'] ?? options['app_settings'];
    if (posAppSettingsRaw != null && posAppSettingsRaw.toString().isNotEmpty) {
      try {
        final parsedSettings = jsonDecode(posAppSettingsRaw.toString()) as Map<String, dynamic>;
        posSettings.assignAll(parsedSettings);
        
        // Sync toggles
        if (parsedSettings.containsKey('display')) {
          final display = parsedSettings['display'];
          allowZeroStock.value = display['allow_zero_stock'] ?? true;
          useDefaultDiscount.value = display['use_default_discount'] ?? false;
        }
        if (parsedSettings.containsKey('kitchen')) {
          kitchenMode.value = parsedSettings['kitchen']['send_mode'] ?? 'printer';
        }
      } catch (e) {
        debugPrint("AppService: Error parsing pos_app_settings: $e");
      }
    }
    
    // Process queue info if available
    if (options.containsKey(Constants.psNextQueue)) {
      queueNumber.value = int.tryParse(options[Constants.psNextQueue].toString()) ?? 1;
    }
    if (options.containsKey(Constants.psLastQueueDate)) {
      lastQueueDate.value = options[Constants.psLastQueueDate]?.toString() ?? "";
    }
    
    // Cache for offline use (SharedPreferences & SQLite)
    final userService = Get.find<UserService>();
    final db = Get.find<DatabaseService>();

    
    // Bulk save to SQLite using a transaction for performance
    try {
      debugPrint('AppService: Bulk saving ${options.length} options to SQLite...');
      await db.transaction((txn) async {
        for (var entry in options.entries) {
          final serverVal = entry.value?.toString() ?? "";
          
          // PROTECT LOCAL SESSION WIPE
          if (entry.key == 'pos_active_session' || entry.key == 'pos_active_staff') {
            if (serverVal.isEmpty || serverVal.length <= 5) continue;
            try {
              final decoded = jsonDecode(serverVal);
              if (decoded is! Map<String, dynamic>) continue;
            } catch (e) {
              continue; // Skip invalid JSON
            }
          }

          await txn.insert('pos_options', {
            'option_name': entry.key,
            'option_value': serverVal,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
      debugPrint('AppService: Bulk save completed');
    } catch (e) {
      debugPrint('AppService: Bulk save failed: $e');
    }

    await saveSettingsLocally(posSettings);
    userService.saveString(Constants.posCompanyName, appModel.value.namaPerusahaan);
    userService.saveString(Constants.posAddress, appModel.value.alamat);
    userService.saveString(Constants.posPhoneNumber, appModel.value.telepon);
    userService.saveString(Constants.posDefaultDiscount, appModel.value.diskon.toString());
  }

  Future<void> loadLocalSettings() async {
    final userService = Get.find<UserService>();
    final db = Get.find<DatabaseService>();

    
    // 1. Load from SQLite first (more reliable)
    final sqliteOptions = await db.query('pos_options');
    Map<String, dynamic> options = {};
    for (var row in sqliteOptions) {
      options[row['option_name'] as String] = row['option_value'];
    }

    if (options.containsKey('pos_app_settings')) {
      try {
        posSettings.assignAll(jsonDecode(options['pos_app_settings']));
        if (posSettings['display'] != null) {
          allowZeroStock.value = posSettings['display']['allow_zero_stock'] ?? true;
          useDefaultDiscount.value = posSettings['display']['use_default_discount'] ?? false;
        }
        if (posSettings['kitchen'] != null) {
          kitchenMode.value = posSettings['kitchen']['send_mode'] ?? 'printer';
        }
      } catch (_) {}
    } else {
      // Fallback to SharedPreferences
      final localJson = userService.getPrefString('pos_app_settings');
      if (localJson.isNotEmpty && localJson != "Guest") {
        try {
          posSettings.assignAll(jsonDecode(localJson));
          if (posSettings['display'] != null) {
            allowZeroStock.value = posSettings['display']['allow_zero_stock'] ?? true;
            useDefaultDiscount.value = posSettings['display']['use_default_discount'] ?? false;
          }
        } catch (_) {}
      }
    }
    
    // Restore queue counter from SQLite
    if (options.containsKey(Constants.psNextQueue)) {
      queueNumber.value = int.tryParse(options[Constants.psNextQueue].toString()) ?? 1;
    }
    if (options.containsKey(Constants.psLastQueueDate)) {
      lastQueueDate.value = options[Constants.psLastQueueDate]?.toString() ?? "";
    }

    String name = (options['pos_tenant_name'] ?? options['pos_company_name'] ?? options['company_name'])?.toString().trim() ?? userService.getPrefString(Constants.posCompanyName);
    String address = (options['pos_address'] ?? options['company_address'] ?? options['address'])?.toString().trim() ?? userService.getPrefString(Constants.posAddress);
    String phone = (options['pos_phone'] ?? options['pos_phone_number'] ?? options['company_phone'])?.toString().trim() ?? userService.getPrefString(Constants.posPhoneNumber);
    String discount = (options['pos_default_discount'] ?? options['default_discount'])?.toString().trim() ?? userService.getPrefString(Constants.posDefaultDiscount);
    String version = (options['pos_version'] ?? options['version'] ?? options['app_version'])?.toString().trim() ?? "";
    
    appModel.value = AppModel(
      namaPerusahaan: (name != "Guest" && name.isNotEmpty) ? name : appModel.value.namaPerusahaan,
      alamat: (address != "Guest" && address.isNotEmpty) ? address : appModel.value.alamat,
      telepon: (phone != "Guest" && phone.isNotEmpty) ? phone : appModel.value.telepon,
      diskon: int.tryParse(discount) ?? appModel.value.diskon,
      version: version.isNotEmpty ? version : appModel.value.version,
    );
  }

  /// Atomically gets the current queue number for today AND increments the counter.
  /// Non-blocking: returns the assigned number instantly; all I/O is fire-and-forget.
  Future<int> getAndIncrementQueue() async {
    final today = DateTime.now().toIso8601String().split('T').first;

    if (lastQueueDate.value != today) {
      // New day: reset counter to 1
      queueNumber.value = 1;
      lastQueueDate.value = today;
    }

    final int assignedQueue = queueNumber.value;

    // Increment in memory for the NEXT transaction
    queueNumber.value++;

    // Fire-and-forget: persist to SQLite + enqueue server sync.
    // We do NOT await these — the number is already safe in memory.
    // Using unawaited so the payment flow is not blocked.
    unawaited(_persistQueueToSQLite());

    return assignedQueue;
  }

  /// Saves the current queue state to SQLite and enqueues a server sync.
  /// Runs in background — never await this directly.
  Future<void> _persistQueueToSQLite() async {
    try {
      final db = Get.find<DatabaseService>();
      await db.insert('pos_options', {
        'option_name': Constants.psNextQueue,
        'option_value': queueNumber.value.toString(),
      });
      await db.insert('pos_options', {
        'option_name': Constants.psLastQueueDate,
        'option_value': lastQueueDate.value,
      });
    } catch (e) {
      debugPrint("AppService: Failed to persist queue to SQLite: $e");
    }

    // Upsert: update the existing pending pos_options sync command body instead of
    // adding a new one. Uses localId='queue_counter' so deduplication works
    // (SQL '= null' never matches, so without a fixed localId every call adds a duplicate).
    try {
      final syncService = Get.find<SyncService>();
      await syncService.upsertQueueSync(
        method: 'PUT',
        endpoint: '/api/pos_options',
        localId: 'queue_counter',
        body: {
          Constants.psNextQueue: queueNumber.value,
          Constants.psLastQueueDate: lastQueueDate.value,
          'version': appModel.value.version, // Keep version intact
        },
      );
    } catch (e) {
      debugPrint("AppService: Failed to upsert queue sync: $e");
    }
  }

  /// Deprecated: Use getAndIncrementQueue() instead.
  /// Kept for any legacy calls — redirects to the atomic version synchronously
  /// but cannot actually increment; call getAndIncrementQueue() for correct behavior.
  int getTodayQueueNumber() {
    final today = DateTime.now().toIso8601String().split('T').first;
    if (lastQueueDate.value != today) {
      queueNumber.value = 1;
      lastQueueDate.value = today;
    }
    return queueNumber.value;
  }

  /// Deprecated: Use getAndIncrementQueue() instead.
  Future<void> incrementQueue() async {
    // This is now a no-op redirect — getAndIncrementQueue handles everything atomically
    debugPrint("AppService: incrementQueue() called — use getAndIncrementQueue() instead.");
  }
}
