import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart' as blue;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/models/app/app_model.dart';
import 'package:semesta_pos/core/services/remote/api_service.dart';
import 'package:semesta_pos/core/services/user_service.dart';
import 'package:semesta_pos/core/util/constans.dart';
import 'package:semesta_pos/styles/app_theme.dart';
import 'package:semesta_pos/core/services/sync_service.dart';
import 'package:semesta_pos/core/services/app_service.dart';
import 'package:semesta_pos/core/models/printer/printer_device.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/core/models/shift/shift_model.dart';
import 'package:semesta_pos/modules/home/employee/controllers/shift_controller.dart';
import 'package:semesta_pos/core/services/error_log_service.dart';
import 'package:semesta_pos/modules/dashboard/employee/controllers/dashboard_employee_controller.dart';
import 'package:semesta_pos/modules/dashboard/admin/controllers/dashboard_admin_controller.dart';

class SettingController extends GetxController {
  ApiService get apiService {
    if (!Get.isRegistered<ApiService>()) {
      Get.put(ApiService(), permanent: true);
    }
    return Get.find<ApiService>();
  }

  RxBool isLoading = false.obs;
  Rx<AppModel> appModel = const AppModel().obs;
  TextEditingController companyNameFieldController = TextEditingController();
  TextEditingController companyAddressFieldController = TextEditingController();
  TextEditingController companyTelpFieldController = TextEditingController();
  TextEditingController companyDiscFieldController = TextEditingController();
  TextEditingController companyVersionFieldController = TextEditingController();
  TextEditingController transactionWebhookUrlFieldController =
      TextEditingController();

  RxBool isLoadingStore = false.obs;

  // Printer Management
  blue.BlueThermalPrinter bluetooth = blue.BlueThermalPrinter.instance;
  RxList<PrinterDevice> assignedPrinters = <PrinterDevice>[].obs;
  Map<String, Socket?> networkSockets = {}; // IP -> Socket

  // Scanning State (for Add Printer dialog)
  RxList<blue.BluetoothDevice> discoveredDevices = <blue.BluetoothDevice>[].obs;
  RxBool isScanning = false.obs;
  String? connectedBluetoothAddress;

  RxBool isCheckingUpdate = false.obs;
  RxDouble downloadProgress = 0.0.obs;

  RxBool hasUpdateAvailable = false.obs;
  String cachedMasterVersion = "";
  String cachedMasterApkUrl = "";
  String cachedMasterChangelog = "";
  RxString installedAppVersion = ''.obs;

  RxList<String> availableBrands = <String>[].obs;

  UserService get userService {
    if (!Get.isRegistered<UserService>()) {
      Get.put(UserService(), permanent: true);
    }
    return Get.find<UserService>();
  }

  @override
  void onInit() {
    super.onInit();
    final appService = Get.find<AppService>();

    // 1. Load local settings immediately
    _loadLocalSettings();
    _loadInstalledAppVersion();
    fetchAvailableBrands();

    // 2. Reactively update text controllers if background sync finishes
    ever(appService.appModel, (AppModel model) {
      if (companyNameFieldController.text.isEmpty ||
          companyNameFieldController.text == 'Guest') {
        companyNameFieldController.text = model.namaPerusahaan;
      }
      if (companyAddressFieldController.text.isEmpty ||
          companyAddressFieldController.text == 'Guest') {
        companyAddressFieldController.text = model.alamat;
      }
      if (companyTelpFieldController.text.isEmpty ||
          companyTelpFieldController.text == 'Guest') {
        companyTelpFieldController.text = model.telepon;
      }
      if (companyDiscFieldController.text == '0' ||
          companyDiscFieldController.text.isEmpty) {
        companyDiscFieldController.text = model.diskon.toString();
      }
      final currentVersion = companyVersionFieldController.text.trim();
      if (currentVersion.isEmpty || currentVersion == '1.0.0') {
        companyVersionFieldController.text =
            _resolveBestKnownVersion(preferred: model.version);
      }
    });

    // 3. No longer calling getData() here as it's redundant with SyncService and AppService
  }

  /// Loads cached configurations from storage instantly.
  Future<void> _loadLocalSettings() async {
    isLoading.value = true;
    try {
      final appService = Get.find<AppService>();

      // 1. Load Printers from Prefs (as they are complex objects usually kept in prefs)
      final localPrinters = userService.getPrefString('pos_printer_configs');
      if (localPrinters.isNotEmpty && localPrinters != "Guest") {
        try {
          final List<dynamic> list = jsonDecode(localPrinters);
          assignedPrinters.value =
              list.map((e) => PrinterDevice.fromJson(e)).toList();
        } catch (_) {}
      }

      // 2. Load Company Info from AppService (Source of Truth)
      // AppService already handles the SQLite fallback in its onInit
      final model = appService.appModel.value;

      companyNameFieldController.text = model.namaPerusahaan;
      companyAddressFieldController.text = model.alamat;
      companyTelpFieldController.text = model.telepon;
      companyDiscFieldController.text = model.diskon.toString();
      companyVersionFieldController.text =
          _resolveBestKnownVersion(preferred: model.version);

      final webhookRows = await Get.find<DatabaseService>().query(
        'pos_options',
        where: 'option_name = ?',
        whereArgs: [Constants.posTransactionWebhookUrl],
        limit: 1,
      );
      transactionWebhookUrlFieldController.text = webhookRows.isNotEmpty
          ? webhookRows.first['option_value']?.toString() ?? ''
          : '';

      // Auto-connect defined network printers
      autoConnectAll();
    } catch (e) {
      debugPrint("SettingController: _loadLocalSettings error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadInstalledAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      installedAppVersion.value = packageInfo.version.trim();

      final currentFieldVersion =
          _sanitizeVersion(companyVersionFieldController.text);
      await _repairCorruptedVersionIfNeeded(currentFieldVersion);
    } catch (e) {
      debugPrint('SettingController: Failed to load installed app version: $e');
    }
  }

  Future<void> _repairCorruptedVersionIfNeeded(
    String currentFieldVersion,
  ) async {
    final targetVersion =
        _resolveBestKnownVersion(preferred: currentFieldVersion);
    if (targetVersion.isEmpty || currentFieldVersion == targetVersion) {
      return;
    }

    try {
      companyVersionFieldController.text = targetVersion;
      appModel.value = appModel.value.copyWith(version: targetVersion);

      await userService.saveString('pos_version', targetVersion);

      final db = Get.find<DatabaseService>();
      await db.insert('pos_options', {
        'option_name': 'version',
        'option_value': targetVersion,
      });
      await db.insert('pos_options', {
        'option_name': 'pos_version',
        'option_value': targetVersion,
      });

      try {
        await apiService.updatePosOptions({'version': targetVersion});
      } catch (e) {
        debugPrint(
          'SettingController: Failed to auto-repair tenant version remotely: $e',
        );
      }
    } catch (e) {
      debugPrint('SettingController: Failed to auto-repair version: $e');
    }
  }

  String get displayInstalledAppVersion {
    final version = _resolveBestKnownVersion(
      preferred: companyVersionFieldController.text,
    );
    return version.isNotEmpty ? version : '-';
  }

  String _sanitizeVersion(dynamic value) {
    final version = value?.toString().trim() ?? '';
    if (version.isEmpty || version == 'null' || version == 'Guest') {
      return '';
    }
    return version;
  }

  String _resolveBestKnownVersion({String? preferred}) {
    if (_isLikelyMengwiTenant()) return Constants.mengwiForcedVersion;

    final preferredVersion = _sanitizeVersion(preferred);
    if (preferredVersion.isNotEmpty) return preferredVersion;

    final cachedPrefVersion =
        _sanitizeVersion(userService.getPrefString('pos_version'));
    if (cachedPrefVersion.isNotEmpty) return cachedPrefVersion;

    final installedVersion = _sanitizeVersion(installedAppVersion.value);
    if (installedVersion.isNotEmpty) return installedVersion;

    final appModelVersion = _sanitizeVersion(appModel.value.version);
    if (appModelVersion.isNotEmpty) return appModelVersion;

    return _sanitizeVersion(companyVersionFieldController.text);
  }

  bool _isLikelyMengwiTenant() {
    final baseUrl = userService.getBaseUrl().trim();
    final email = userService.getUserEmail().trim().toLowerCase();
    return baseUrl == Constants.mengwiBaseUrl ||
        email == Constants.mengwiEmail.toLowerCase();
  }

  Future<void> fetchAvailableBrands() async {
    try {
      final db = Get.find<DatabaseService>();
      final result = await db.rawQuery(
          "SELECT DISTINCT nama_brand FROM brands WHERE nama_brand IS NOT NULL AND nama_brand != ''");
      availableBrands.value =
          result.map((e) => e['nama_brand'].toString()).toList();
    } catch (e) {
      debugPrint("SettingController: Failed to fetch brands: $e");
    }
  }

  Future<void> getData() async {
    isLoading.value = true;
    try {
      final optionsApi = await apiService.getPosOptions();

      if (optionsApi.responsestate == Constants.successState &&
          optionsApi.data != null) {
        Map<String, dynamic> rawOptions = {};
        if (optionsApi.data is Map) {
          rawOptions = optionsApi.data as Map<String, dynamic>;
        } else if (optionsApi.data is List) {
          final list = optionsApi.data as List;
          for (var item in list) {
            if (item is Map) {
              if (item.containsKey('option_name') &&
                  item.containsKey('option_value')) {
                rawOptions[item['option_name'].toString()] =
                    item['option_value'];
              } else {
                rawOptions.addAll(Map<String, dynamic>.from(item));
              }
            }
          }
        }

        // Sanitize keys
        final options =
            rawOptions.map((key, value) => MapEntry(key.trim(), value));

        // Sync to AppService
        final appService = Get.find<AppService>();

        // Extract values using keys from API_DOCS.md
        String name = (options['pos_tenant_name'] ??
                    options['pos_company_name'] ??
                    options['company_name'])
                ?.toString()
                .trim() ??
            "";
        if (name.isEmpty || name == 'Guest')
          name = appService.appModel.value.namaPerusahaan;
        if (name.isEmpty || name == 'Guest')
          name = userService.getPrefString(Constants.posCompanyName);
        if (name == 'Guest') name = '';

        String address = (options['pos_address'] ??
                    options['company_address'] ??
                    options['address'])
                ?.toString()
                .trim() ??
            "";
        if (address.isEmpty || address == 'Guest')
          address = appService.appModel.value.alamat;
        if (address.isEmpty || address == 'Guest')
          address = userService.getPrefString(Constants.posAddress);
        if (address == 'Guest') address = '';

        String phone = (options['pos_phone'] ??
                    options['pos_phone_number'] ??
                    options['company_phone'])
                ?.toString()
                .trim() ??
            "";
        if (phone.isEmpty || phone == 'Guest')
          phone = appService.appModel.value.telepon;
        if (phone.isEmpty || phone == 'Guest')
          phone = userService.getPrefString(Constants.posPhoneNumber);
        if (phone == 'Guest') phone = '';

        String discount =
            (options['pos_default_discount'] ?? options['default_discount'])
                    ?.toString()
                    .trim() ??
                "0";
        if (discount == "0" || discount.isEmpty)
          discount = appService.appModel.value.diskon.toString();

        String version = _resolveBestKnownVersion(
          preferred: options['pos_version'] ??
              options['version'] ??
              options['app_version'] ??
              appService.appModel.value.version,
        );

        final webhookUrl = (options[Constants.posTransactionWebhookUrl] ??
                    options['transaction_webhook_url'])
                ?.toString()
                .trim() ??
            '';

        // Always update text controllers
        companyNameFieldController.text = name;
        companyAddressFieldController.text = address;
        companyTelpFieldController.text = phone;
        companyDiscFieldController.text = discount;
        companyVersionFieldController.text = version;
        transactionWebhookUrlFieldController.text =
            webhookUrl == 'Guest' ? '' : webhookUrl;

        // Persist to SharedPreferences via UserService if they exist (only not null ones)
        if (name.isNotEmpty)
          userService.saveString(Constants.posCompanyName, name);
        if (phone.isNotEmpty)
          userService.saveString(Constants.posPhoneNumber, phone);
        if (address.isNotEmpty)
          userService.saveString(Constants.posAddress, address);
        if (discount.isNotEmpty)
          userService.saveString(Constants.posDefaultDiscount, discount);
        if (version.isNotEmpty) userService.saveString('pos_version', version);

        // Update AppService model
        appService.appModel.value = appService.appModel.value.copyWith(
          namaPerusahaan:
              name.isNotEmpty ? name : appService.appModel.value.namaPerusahaan,
          alamat:
              address.isNotEmpty ? address : appService.appModel.value.alamat,
          telepon: phone.isNotEmpty ? phone : appService.appModel.value.telepon,
          diskon: int.tryParse(discount) ?? appService.appModel.value.diskon,
          version:
              version.isNotEmpty ? version : appService.appModel.value.version,
        );

        // Cache detailed options to SQLite for offline use
        final db = Get.find<DatabaseService>();
        for (var entry in options.entries) {
          final serverVal = entry.value?.toString() ?? "";

          if (entry.key == 'pos_active_session' ||
              entry.key == 'pos_active_staff') {
            if (serverVal.isNotEmpty && serverVal.length > 5) {
              try {
                final decoded = jsonDecode(serverVal);
                if (decoded is Map<String, dynamic>) {
                  await db.insert('pos_options', {
                    'option_name': entry.key,
                    'option_value': serverVal,
                  });

                  if (entry.key == 'pos_active_session' &&
                      Get.isRegistered<ShiftController>()) {
                    Get.find<ShiftController>().activeShift.value =
                        ShiftSessionModel.fromJson(decoded);
                  }
                }
              } catch (e) {
                debugPrint(
                    'SettingController: Error parsing pos_active_session, ignoring server value: $e');
              }
            }
            continue;
          }

          await db.insert('pos_options', {
            'option_name': entry.key,
            'option_value': serverVal,
          });
        }

        // 1. Process Printer Configs
        if (options.containsKey('pos_printer_configs')) {
          try {
            final String printerJson =
                options['pos_printer_configs']?.toString() ?? "";
            if (printerJson.isNotEmpty && printerJson != "null") {
              final List<dynamic> list = jsonDecode(printerJson);
              assignedPrinters.value =
                  list.map((e) => PrinterDevice.fromJson(e)).toList();
              // Persist locally
              userService.saveString('pos_printer_configs', printerJson);
            }
          } catch (e) {
            debugPrint("Error parsing pos_printer_configs: $e");
          }
        }
      }
    } catch (e) {
      debugPrint("SettingController: Failed to fetch options from server: $e");
      // Fallback: If API fail, ensure fields at least have what's in AppService
      final appService = Get.find<AppService>();
      final model = appService.appModel.value;
      if (companyNameFieldController.text.isEmpty) {
        companyNameFieldController.text = model.namaPerusahaan;
        companyAddressFieldController.text = model.alamat;
        companyTelpFieldController.text = model.telepon;
        companyDiscFieldController.text = model.diskon.toString();
        companyVersionFieldController.text =
            _resolveBestKnownVersion(preferred: model.version);
      }
    } finally {
      isLoading.value = false;
    }

    // Auto-connect all active printers (after potential update from server)
    autoConnectAll();
  }

  Future<void> syncAllData() async {
    try {
      final syncService = Get.find<SyncService>();
      await syncService.syncFullData();
    } catch (e) {
      debugPrint("Sync Error in SettingController: $e");
    }
  }

  /// On startup: mark all BT printers as disconnected (no auto-connect).
  /// For network printers, try to connect and keep socket open.
  Future<void> autoConnectAll() async {
    // BT printers: always start as disconnected — actual connection
    // only happens on-demand when printing (connect → print → disconnect).
    for (var printer in assignedPrinters) {
      if (printer.type == 'bluetooth') {
        _updatePrinterStatus(printer.id, false);
      }
    }

    // Network printers: try to connect and keep socket alive.
    for (var printer in assignedPrinters) {
      if (!printer.isActive) continue;
      if (printer.type == 'network') {
        _connectToNetworkPrinter(printer);
      }
    }
  }

  /// Connects to BT printer. Always disconnects first (Android SPP = 1 connection at a time).
  /// Verifies connection actually succeeded AFTER connect() — library may not throw on failure.
  /// Returns true only if printer is confirmed connected.
  Future<bool> _connectToBluetooth(PrinterDevice device) async {
    const int maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('BT Connect Attempt $attempt for ${device.name}');

        // Step 1: Always force-disconnect any existing connection first.
        // This prevents "zombie socket" where library thinks it's connected but
        // the underlying TCP/RFCOMM channel is dead after idle or printer restart.
        try {
          await bluetooth.disconnect();
        } catch (_) {}
        connectedBluetoothAddress = null;
        // Android BT stack needs time to fully release the RFCOMM socket.
        // 800ms is not enough on many devices — use 2000ms to be safe.
        await Future.delayed(const Duration(milliseconds: 2000));

        // Step 2: Find the specific target in bonded list
        List<blue.BluetoothDevice> bonded = await bluetooth.getBondedDevices();
        final target =
            bonded.firstWhereOrNull((d) => d.address == device.address);
        if (target == null) {
          debugPrint(
              'BT device not found in paired list: ${device.name} (${device.address})');
          if (attempt == maxRetries) {
            _updatePrinterStatus(device.id, false);
            return false;
          }
          continue;
        }

        // Step 3: Attempt connection
        await bluetooth.connect(target);

        // Step 4: VERIFY — library may not throw even if printer is off
        await Future.delayed(
            const Duration(milliseconds: 1000)); // Wait for socket to stabilize
        final bool? isConnected = await bluetooth.isConnected;
        if (isConnected != true) {
          debugPrint(
              'BT connect() returned but isConnected=false for ${device.name}. Printer may be off.');
          if (attempt == maxRetries) {
            _updatePrinterStatus(device.id, false);
            return false;
          }
          continue; // Retry
        }

        connectedBluetoothAddress = device.address;
        _updatePrinterStatus(device.id, true);
        return true;
      } catch (e) {
        debugPrint('BT Connect ATTEMPT $attempt failed for ${device.name}: $e');
        if (attempt == maxRetries) {
          _updatePrinterStatus(device.id, false);
          ErrorLogService.log(
            category: 'printer',
            errCode: 'BT_CONNECT_FAIL',
            errMsg:
                'Device: ${device.name} (${device.address}) | Attempt $attempt | $e',
          );
          return false;
        }
        await Future.delayed(
            const Duration(milliseconds: 1500)); // Cool down before retry
      }
    }
    return false;
  }

  Future<void> _connectToNetworkPrinter(PrinterDevice device) async {
    try {
      // Close existing socket if any before reconnecting
      if (networkSockets.containsKey(device.address)) {
        try {
          networkSockets[device.address]?.destroy();
        } catch (_) {}
        networkSockets.remove(device.address);
      }

      final socket = await Socket.connect(device.address, device.port,
          timeout: const Duration(seconds: 3));

      // Handle socket errors/closure in background
      socket.done.then((_) {
        networkSockets.remove(device.address);
        _updatePrinterStatus(device.id, false);
      }).catchError((_) {
        networkSockets.remove(device.address);
        _updatePrinterStatus(device.id, false);
      });

      networkSockets[device.address] = socket;
      _updatePrinterStatus(device.id, true);
      debugPrint("Connected to network printer: ${device.address}");
    } catch (e) {
      debugPrint("Auto-Connect Network failed for ${device.address}: $e");
      networkSockets.remove(device.address);
      _updatePrinterStatus(device.id, false);
      ErrorLogService.log(
        category: 'printer',
        errCode: 'NETWORK_CONNECT_FAIL',
        errMsg:
            'Device: ${device.name} (${device.address}:${device.port}) | $e',
      );
    }
  }

  void _updatePrinterStatus(String id, bool connected) {
    int idx = assignedPrinters.indexWhere((p) => p.id == id);
    if (idx != -1) {
      assignedPrinters[idx] =
          assignedPrinters[idx].copyWith(isConnected: connected);
    }
  }

  Future<void> startBluetoothScan() async {
    isScanning.value = true;
    discoveredDevices.clear();
    try {
      List<blue.BluetoothDevice> devices = await bluetooth.getBondedDevices();
      discoveredDevices.addAll(devices);
    } catch (e) {
      debugPrint("Error scanning for bluetooth devices: $e");
    }
    isScanning.value = false;
  }

  Future<void> addPrinter(PrinterDevice device) async {
    assignedPrinters.add(device);
    await savePrinterConfigs();
    autoConnectAll();
  }

  Future<void> deletePrinter(String id) async {
    int idx = assignedPrinters.indexWhere((p) => p.id == id);
    if (idx != -1) {
      final p = assignedPrinters[idx];
      if (p.type == 'network') {
        networkSockets[p.address]?.destroy();
        networkSockets.remove(p.address);
      }
      assignedPrinters.removeAt(idx);
      await savePrinterConfigs();
    }
  }

  Future<void> savePrinterConfigs() async {
    final String printerJson =
        jsonEncode(assignedPrinters.map((e) => e.toJson()).toList());
    await userService.saveString('pos_printer_configs', printerJson);
    try {
      await apiService.updatePosOptions({'pos_printer_configs': printerJson});
    } catch (_) {}
  }

  Future<void> performTestPrint(PrinterDevice printer) async {
    await printToTarget(printer, isTestPrint: true);
  }

  /// Builds ESC/POS bytes for a label printout on a regular thermal printer (e.g. Kassen RPP02N).
  /// Supports 58mm and 80mm paper sizes.
  Future<List<int>> buildLabelEscPos({
    required String line1, // row 1: datetime
    required String line2, // row 2: customer name
    required String line3, // row 3: order code
    required String line4, // row 4: product name
    bool isAutoCut = false,
    int copies = 1,
    int startIndex = 1,
    int totalLabels = 1,
    String? productNote,
    String? orderNote,
  }) async {
    final profile = await CapabilityProfile.load();
    final paper = PaperSize.mm58;
    final generator = Generator(paper, profile);
    final int maxChars = 32;
    List<int> bytes = [];

    bytes += generator.reset();
    // ESC M 0 = Select Font A (raw ESC/POS) - needed for MPT-II and similar 58mm printers
    bytes += [0x1B, 0x4D, 0x00];

    for (int i = 0; i < copies; i++) {
      int currentCounter = startIndex + i;
      String labelCounter = '$currentCounter/$totalLabels';

      String topRow = _formatRow(line1, labelCounter, maxChars);

      // Row 1: Date/Time + Counter
      bytes +=
          generator.text(topRow, styles: const PosStyles(align: PosAlign.left));

      // Row 2: Customer Name
      bytes +=
          generator.text(line2, styles: const PosStyles(align: PosAlign.left));

      // Row 3: Order Code
      bytes +=
          generator.text(line3, styles: const PosStyles(align: PosAlign.left));

      // Row 4: Product Name (Bold) - Word-wrapped, no truncation
      List<String> wrappedName = _wrapTextByWord(line4, maxChars);
      for (final wline in wrappedName) {
        bytes += generator.text(wline,
            styles: const PosStyles(align: PosAlign.left, bold: true));
      }

      // Order Note (if any)
      final hasOrderNote = orderNote != null && orderNote.trim().isNotEmpty;
      if (hasOrderNote) {
        List<String> wrappedOrderNote =
            _wrapTextByWord('Order: ${orderNote.trim()}', maxChars);
        for (final wline in wrappedOrderNote) {
          bytes += generator.text(wline,
              styles: const PosStyles(align: PosAlign.left));
        }
      }

      // Item Note (if any)
      final hasItemNote = productNote != null && productNote.trim().isNotEmpty;
      if (hasItemNote) {
        List<String> wrappedItemNote =
            _wrapTextByWord('Item: ${productNote.trim()}', maxChars);
        for (final wline in wrappedItemNote) {
          bytes += generator.text(wline,
              styles: const PosStyles(align: PosAlign.left));
        }
      }

      bytes += generator.feed(1);
      bytes += generator.cut();
    }

    return bytes;
  }

  /// Word-wrap text to fit within maxChars per line without truncation
  List<String> _wrapTextByWord(String text, int maxChars) {
    if (text.length <= maxChars) return [text];

    List<String> lines = [];
    List<String> words = text.split(' ');
    String currentLine = '';

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
    return lines;
  }

  Future<void> printTest(PrinterDevice printer) async {
    try {
      final bytes = await _buildTestBytes(printer);
      await printToTarget(printer, prebuiltBytes: bytes);
    } catch (e) {
      Get.snackbar('Print Test Failed', 'Error: $e');
    }
  }

  /// Builds ESC/POS bytes for a test page, role-aware.

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

  Future<List<int>> _buildTestBytes(PrinterDevice printer) async {
    final profile = await CapabilityProfile.load();

    // --- Label test: ESC/POS mode for regular thermal label printers ---
    if (printer.roles.contains('label')) {
      final now = DateTime.now();
      final dateTimeStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}'
          ' ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      return buildLabelEscPos(
        line1: dateTimeStr,
        line2: 'TEST CUSTOMER',
        line3: '#ABCDEF12',
        line4: 'TEST PRODUCT NAME',
        isAutoCut: printer.isAutoCut,
      );
    }

    final isLabel = printer.roles.contains('label');
    final isKitchen = printer.roles.contains('kitchen');
    final title = isKitchen ? 'KITCHEN TEST' : 'TEST PRINT';

    final paperSize = printer.paperSize == 80 ? PaperSize.mm80 : PaperSize.mm58;
    final int maxChars = printer.paperSize == 80 ? 48 : 32;
    final String lineSep = '-' * maxChars;
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    bytes += generator.reset();
    // ESC M 0 = Select Font A (raw ESC/POS) - needed for printers that ignore library fontType
    if (printer.paperSize == 58) bytes += [0x1B, 0x4D, 0x00];

    String companyName = userService.getPrefString(Constants.posCompanyName);
    if (companyName == 'Guest' || companyName.isEmpty) companyName = 'FLINKPOS';
    String address = userService.getPrefString(Constants.posAddress);
    if (address == 'Guest') address = '';
    String phone = userService.getPrefString(Constants.posPhoneNumber);

    bytes += generator.text(
        _formatCenter(isKitchen ? '*** KITCHEN ***' : companyName.toUpperCase(),
            maxChars),
        styles: const PosStyles(
            align: PosAlign.left, bold: true, height: PosTextSize.size2));

    if (!isKitchen) {
      if (address.isNotEmpty)
        bytes += generator.text(_formatCenter(address, maxChars),
            styles: const PosStyles(align: PosAlign.left));
      if (phone.isNotEmpty) if (phone.isNotEmpty)
        bytes += generator.text(_formatCenter('Tel: $phone', maxChars),
            styles: const PosStyles(align: PosAlign.left));
    }

    bytes +=
        generator.text(lineSep, styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text(_formatCenter(title, maxChars),
        styles: const PosStyles(align: PosAlign.left, bold: true));

    if (isKitchen) {
      bytes += generator.text(
          _formatCenter('Role: KITCHEN PREPARATION', maxChars),
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text('Receipt No: #TEST-KITCHEN',
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text(lineSep,
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text('1x TEST PRODUCT NAME',
          styles: const PosStyles(align: PosAlign.left, bold: true));
      bytes += generator.text('   * Test Note/Instruction',
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text(lineSep,
          styles: const PosStyles(align: PosAlign.left));
    } else {
      bytes += generator.text(
          _formatCenter(
              'Roles: ${printer.roles.map((e) => e.toUpperCase()).join(", ")}',
              maxChars),
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text(
          _formatCenter('Connection: ${printer.type}', maxChars),
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text(lineSep,
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text(
          _formatCenter('Printer connected successfully!', maxChars),
          styles: const PosStyles(align: PosAlign.left));
    }

    // bytes += generator.feed(1);
    bytes += generator.cut();
    return bytes;
  }

  /// Prints a comprehensive Z-Report (Shift Summary) for a closed shift.
  Future<void> printZReport(
      ShiftSessionModel shift, Map<String, int> recap) async {
    final printer = getPrinterForRole('report') ?? getPrinterForRole('cashier');
    if (printer == null) {
      Get.snackbar('Printer Error',
          'No active Report/Cashier printer found for Z-Report.',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          icon: const Icon(Icons.print_disabled, color: Colors.orange));
      return;
    }

    try {
      final bytes = await _buildZReportBytes(printer, shift, recap);
      await printToTarget(printer, prebuiltBytes: bytes);
    } catch (e) {
      debugPrint('SettingController: Z-Report printing failed: $e');
      Get.snackbar('Print Error', 'Failed to print Z-Report: $e');
      ErrorLogService.log(
        category: 'printer',
        errCode: 'ZREPORT_PRINT_FAIL',
        errMsg: 'Printer: ${printer.name} | $e',
      );
    }
  }

  /// Prints the full End of Day (Z-Report)
  Future<void> printEndOfDayReport(Map<String, dynamic> eodData) async {
    final printer = getPrinterForRole('report') ?? getPrinterForRole('cashier');
    if (printer == null) {
      Get.snackbar('Printer Error',
          'No active Report/Cashier printer found for End of Day.',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          icon: const Icon(Icons.print_disabled, color: Colors.orange));
      return;
    }

    try {
      final bytes = await _buildEndOfDayBytes(printer, eodData);
      await printToTarget(printer, prebuiltBytes: bytes);
    } catch (e) {
      debugPrint('SettingController: End of Day printing failed: $e');
      Get.snackbar('Print Error', 'Failed to print End of Day Report: $e');
    }
  }

  Future<List<int>> _buildEndOfDayBytes(
      PrinterDevice printer, Map<String, dynamic> eodData) async {
    final profile = await CapabilityProfile.load();
    final is80mm = printer.paperSize == 80;
    final paperSize = is80mm ? PaperSize.mm80 : PaperSize.mm58;

    final int maxChars = is80mm ? 48 : 32;
    final int labelWidth = is80mm ? 30 : 20;
    final int valueWidth = maxChars - labelWidth;
    final String lineSep = '-' * maxChars;

    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    String f(int val) {
      String s = val.abs().toString();
      String res = "";
      int count = 0;
      for (int i = s.length - 1; i >= 0; i--) {
        count++;
        res = s[i] + res;
        if (count % 3 == 0 && i != 0) res = ".$res";
      }
      return 'Rp. ${val < 0 ? "-" : ""}$res';
    }

    void printRow(String label, String value, {bool bold = false}) {
      String lab = label;
      if (lab.length > labelWidth) {
        lab = '${lab.substring(0, labelWidth - 2)}..';
      }
      bytes += generator.text(
        lab.padRight(labelWidth) + value.padLeft(valueWidth),
        styles: PosStyles(bold: bold, align: PosAlign.left),
      );
    }

    String companyName = userService.getPrefString(Constants.posCompanyName);
    if (companyName == 'Guest' || companyName.isEmpty) companyName = 'FLINKPOS';

    String address = userService.getPrefString(Constants.posAddress);
    if (address == 'Guest') address = '';

    bytes += generator.reset();
    // ESC M 0 = Select Font A (raw ESC/POS) - needed for MPT-II and similar 58mm printers
    if (!is80mm) bytes += [0x1B, 0x4D, 0x00];

    // 1. HEADER
    bytes += generator.text(_formatCenter(companyName.toUpperCase(), maxChars),
        styles: const PosStyles(align: PosAlign.left, bold: true));
    if (address.isNotEmpty) {
      bytes += generator.text(_formatCenter(address, maxChars),
          styles: const PosStyles(align: PosAlign.left));
    }
    String phone = userService.getPrefString(Constants.posPhoneNumber);
    if (phone != 'Guest' && phone.isNotEmpty) {
      bytes += generator.text(_formatCenter('Tel: $phone', maxChars),
          styles: const PosStyles(align: PosAlign.left));
    }
    bytes +=
        generator.text(lineSep, styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text(_formatCenter('END OF DAY (Z-REPORT)', maxChars),
        styles: const PosStyles(align: PosAlign.left, bold: true));
    bytes +=
        generator.text(lineSep, styles: const PosStyles(align: PosAlign.left));

    // 2. INFO
    final dateStr = (eodData['date'] as String).substring(0, 10);
    printRow('Date', dateStr);
    final staffList = (eodData['staff'] as List<dynamic>).join(', ');
    printRow('Staff Today', staffList);
    bytes +=
        generator.text(lineSep, styles: const PosStyles(align: PosAlign.left));

    // 3. SHIFTS SUMMARY (Opening Balances)
    final shiftsSummary = eodData['shifts_summary'] as List<dynamic>? ?? [];
    if (shiftsSummary.isNotEmpty) {
      for (var s in shiftsSummary) {
        final String sName = s['name']?.toString() ?? 'Shift';
        final int ob = (s['opening_balance'] as num?)?.toInt() ?? 0;
        printRow('$sName Op. Bal', f(ob));
      }
      bytes += generator.text(lineSep,
          styles: const PosStyles(align: PosAlign.left));
    }

    // 4. INCOME SUMMARY
    bytes += generator.text(_formatCenter('INCOME SUMMARY', maxChars),
        styles: const PosStyles(align: PosAlign.left, bold: true));
    final paymentModes = eodData['payment_modes'] as List<dynamic>;
    for (var mode in paymentModes) {
      final amt = (mode['recorded'] as num?)?.toInt() ?? 0;
      if (amt > 0) {
        printRow('${mode['name']}', f(amt));
      }
    }
    final todayTotal = (eodData['today_income'] as num?)?.toInt() ?? 0;
    printRow('TOTAL INCOME', f(todayTotal), bold: true);

    bytes +=
        generator.text(lineSep, styles: const PosStyles(align: PosAlign.left));

    // 5. ITEM SALES (PRODUCTS SOLD)
    final products = eodData['products'] as List<dynamic>;
    if (products.isNotEmpty) {
      bytes += generator.text(_formatCenter('ITEM SALES', maxChars),
          styles: const PosStyles(align: PosAlign.left, bold: true));
      for (var p in products) {
        final qty = p['qty'] ?? 0;
        final name = p['name'] ?? 'Item';
        final total = p['total'] ?? 0;
        final price = p['price'] ?? 0;

        String lab = '${qty}x $name';
        if (lab.length > labelWidth) {
          lab = '${lab.substring(0, labelWidth - 2)}..';
        }
        printRow(lab, f(total).replaceAll('Rp. ', ''));
        if (qty > 1 && price > 0) {
          bytes += generator.text('  @ ${f(price)} /pcs',
              styles: const PosStyles(align: PosAlign.left));
        }
      }
      bytes += generator.text(lineSep,
          styles: const PosStyles(align: PosAlign.left));
    }

    // 6. DISCOUNTS, REFUNDS & CANCELLATIONS
    final discounts = eodData['discounts'] as Map<String, dynamic>?;
    final pDisc = (discounts?['product'] as num?)?.toInt() ?? 0;
    final tDisc = (discounts?['transaction'] as num?)?.toInt() ?? 0;
    final refunds = eodData['refunds'] as Map<String, dynamic>?;
    final refTotal = (refunds?['total'] as num?)?.toInt() ?? 0;
    final voids = eodData['voids'] as Map<String, dynamic>?;
    final voidCount = (voids?['count'] as num?)?.toInt() ?? 0;

    if (pDisc > 0 || tDisc > 0 || refTotal > 0 || voidCount > 0) {
      bytes += generator.text(_formatCenter('DISCOUNTS & VOIDS', maxChars),
          styles: const PosStyles(align: PosAlign.left, bold: true));

      if (pDisc > 0) printRow('Product Discounts', '-${f(pDisc)}');
      if (tDisc > 0) printRow('Trans. Discounts', '-${f(tDisc)}');

      if (refTotal > 0) {
        printRow('Total Refunds', '-${f(refTotal)}');
        final refList = refunds?['list'] as List<dynamic>? ?? [];
        for (var r in refList) {
          printRow(
              ' - ${r['name']}', '-${f((r['amount'] as num?)?.toInt() ?? 0)}');
        }
      }

      if (voidCount > 0) {
        printRow('Voided Orders', '$voidCount orders');
        printRow('Voided Amount', f((voids?['total'] as num?)?.toInt() ?? 0));
      }
      bytes += generator.text(lineSep,
          styles: const PosStyles(align: PosAlign.left));
    }

    // 7. CASH FLOW (EXPENSES)
    final expenses = eodData['expenses'] as Map<String, dynamic>;
    final expensesList = expenses['list'] as List<dynamic>;
    if (expensesList.isNotEmpty) {
      bytes += generator.text(_formatCenter('EXPENSES', maxChars),
          styles: const PosStyles(align: PosAlign.left, bold: true));
      for (var e in expensesList) {
        printRow(e['name'], f((e['amount'] as num?)?.toInt() ?? 0));
      }
      printRow('TOTAL EXPENSES', f((expenses['total'] as num?)?.toInt() ?? 0),
          bold: true);
      bytes += generator.text(lineSep,
          styles: const PosStyles(align: PosAlign.left));
    }

    // 8. MEMBERS
    final newMembersCount = (eodData['new_members'] as num?)?.toInt() ?? 0;
    if (newMembersCount > 0) {
      bytes += generator.text(_formatCenter('MEMBERS', maxChars),
          styles: const PosStyles(align: PosAlign.left, bold: true));
      printRow('New Members', '$newMembersCount');
      bytes += generator.text(lineSep,
          styles: const PosStyles(align: PosAlign.left));
    }

    // 9. RECONCILIATION
    final totalActualCash =
        (eodData['total_actual_cash'] as num?)?.toInt() ?? 0;
    final totalOpeningBalance =
        (eodData['total_opening_balance'] as num?)?.toInt() ?? 0;

    // Calculate total cash expected (only Cash income)
    int expectedCash = 0;
    for (var pm in paymentModes) {
      final String name = (pm['name']?.toString() ?? '').toLowerCase();
      final String id = pm['id']?.toString() ?? '';
      if (id == '1' || id == '7' || name.contains('cash')) {
        expectedCash += (pm['recorded'] as num?)?.toInt() ?? 0;
      }
    }
    final int actualSalesCash = totalActualCash - totalOpeningBalance;
    final int difference = actualSalesCash - expectedCash;

    printRow('EXPECTED CASH', f(expectedCash), bold: true);
    printRow('ACTUAL CASH', f(actualSalesCash), bold: true);
    printRow('DIFFERENCE', f(difference));

    bytes += generator.text('Note: Expected Cash = Today Sales',
        styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text('Actual = Drawer - Op. Balances',
        styles: const PosStyles(align: PosAlign.left));

    bytes +=
        generator.text(lineSep, styles: const PosStyles(align: PosAlign.left));

    // FOOTER
    bytes += generator.text(
        _formatCenter(
            'Printed on: ${DateTime.now().toString().split('.')[0]}', maxChars),
        styles: const PosStyles(align: PosAlign.left));

    bytes += generator.feed(3);
    if (printer.isAutoCut) {
      bytes += generator.cut();
    }
    return bytes;
  }

  Future<List<int>> _buildZReportBytes(PrinterDevice printer,
      ShiftSessionModel shift, Map<String, int> recap) async {
    final profile = await CapabilityProfile.load();
    final is80mm = printer.paperSize == 80;
    final paperSize = is80mm ? PaperSize.mm80 : PaperSize.mm58;
    final int maxChars = is80mm ? 48 : 32;
    final String lineSep = '-' * maxChars;

    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    // ESC M 0 = Select Font A (raw ESC/POS)
    bytes += generator.reset();
    if (!is80mm) bytes += [0x1B, 0x4D, 0x00];

    // Helper: currency formatting
    String f(int val) {
      String s = val.abs().toString();
      String res = "";
      int count = 0;
      for (int i = s.length - 1; i >= 0; i--) {
        count++;
        res = s[i] + res;
        if (count % 3 == 0 && i != 0) res = ".$res";
      }
      return '${val < 0 ? "-" : ""}$res';
    }

    String companyName = userService.getPrefString(Constants.posCompanyName);
    if (companyName == 'Guest' || companyName.isEmpty) companyName = 'FLINKPOS';
    String address = userService.getPrefString(Constants.posAddress);
    if (address == 'Guest') address = '';
    String phone = userService.getPrefString(Constants.posPhoneNumber);
    if (phone == 'Guest') phone = '';

    // 1. HEADER - normal size (no size2 to avoid wasted space)
    bytes += generator.text(_formatCenter(companyName.toUpperCase(), maxChars),
        styles: const PosStyles(align: PosAlign.left, bold: true));
    if (address.isNotEmpty) {
      bytes += generator.text(_formatCenter(address, maxChars),
          styles: const PosStyles(align: PosAlign.left));
    }
    if (phone.isNotEmpty) {
      bytes += generator.text(_formatCenter('Tel: $phone', maxChars),
          styles: const PosStyles(align: PosAlign.left));
    }
    bytes +=
        generator.text(lineSep, styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text(_formatCenter('Z-REPORT / SHIFT RECAP', maxChars),
        styles: const PosStyles(align: PosAlign.left, bold: true));
    bytes +=
        generator.text(lineSep, styles: const PosStyles(align: PosAlign.left));

    // 2. SHIFT INFO
    bytes += generator.text(_formatRow('Shift', shift.shiftName, maxChars),
        styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text(_formatRow('Staff', shift.userId, maxChars),
        styles: const PosStyles(align: PosAlign.left));
    final startStr = shift.startTime.toString().split('.')[0].substring(0, 16);
    bytes += generator.text(_formatRow('Start', startStr, maxChars),
        styles: const PosStyles(align: PosAlign.left));
    if (shift.endTime != null) {
      final endStr = shift.endTime.toString().split('.')[0].substring(0, 16);
      bytes += generator.text(_formatRow('End', endStr, maxChars),
          styles: const PosStyles(align: PosAlign.left));
    }
    bytes +=
        generator.text(lineSep, styles: const PosStyles(align: PosAlign.left));

    // Parse reconciliation data
    List<dynamic>? txDataList;
    Map<String, dynamic>? txData;
    if (shift.reconciliationData != null &&
        shift.reconciliationData!.isNotEmpty) {
      try {
        txDataList = jsonDecode(shift.reconciliationData!);
        if (txDataList != null && txDataList.isNotEmpty) {
          txData = txDataList.first;
        }
      } catch (e) {
        debugPrint("Error parsing reconciliationData for print: $e");
      }
    }

    if (txData != null) {
      // 3. SALES SUMMARY
      bytes += generator.text(
          _formatRow(
              'Opening Balance', 'Rp.${f(shift.startingBalance)}', maxChars),
          styles: const PosStyles(align: PosAlign.left, bold: true));

      final modes = txData['payment_modes'] as List<dynamic>? ?? [];
      int cashSales = 0;
      int nonCashSales = 0;
      for (var mode in modes) {
        final name = (mode['name'] ?? '').toString().toLowerCase();
        final amount = (mode['recorded'] ?? 0) as int;
        if (name.contains('cash') ||
            name.contains('tunai') ||
            mode['id'] == '1') {
          cashSales += (amount - shift.startingBalance);
        } else {
          nonCashSales += amount;
        }
      }
      bytes += generator.text(
          _formatRow('Cash Sales', 'Rp.${f(cashSales)}', maxChars),
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text(
          _formatRow('Non-Cash Sales', 'Rp.${f(nonCashSales)}', maxChars),
          styles: const PosStyles(align: PosAlign.left));

      // Payment modes detail
      for (var mode in modes) {
        final name = (mode['name'] ?? '').toString();
        final amount = (mode['recorded'] ?? 0) as int;
        if (amount > 0) {
          bytes += generator.text(
              _formatRow('  $name', 'Rp.${f(amount)}', maxChars),
              styles: const PosStyles(align: PosAlign.left));
        }
      }
      bytes += generator.text(lineSep,
          styles: const PosStyles(align: PosAlign.left));

      // 4. PRODUCTS SOLD
      final products = txData['products_sold'] as List<dynamic>? ?? [];
      if (products.isNotEmpty) {
        bytes += generator.text(_formatCenter('ITEM SALES', maxChars),
            styles: const PosStyles(align: PosAlign.left, bold: true));
        bytes += generator.text(lineSep,
            styles: const PosStyles(align: PosAlign.left));
        for (var product in products) {
          final qty = product['qty'] ?? 0;
          final name = product['name'] ?? 'Item';
          final total = product['total'] ?? 0;
          final price = product['price'] ?? 0;
          // Name: truncate to fit with qty prefix
          String lab = '${qty}x $name';
          final maxName = maxChars - 10;
          if (lab.length > maxName) lab = '${lab.substring(0, maxName - 2)}..';
          bytes += generator.text(_formatRow(lab, f(total), maxChars),
              styles: const PosStyles(align: PosAlign.left));
          if (price > 0 && qty > 1) {
            bytes += generator.text('   @ ${f(price)} /pcs',
                styles: const PosStyles(align: PosAlign.left));
          }
        }
        bytes += generator.text(lineSep,
            styles: const PosStyles(align: PosAlign.left));
      }

      // 5. DISCOUNTS
      final discounts = txData['discounts'] ?? {};
      final prodDisc = (discounts['product'] ?? 0) as int;
      final transDisc = (discounts['transaction'] ?? 0) as int;
      if (prodDisc > 0 || transDisc > 0) {
        bytes += generator.text(_formatCenter('DISCOUNTS', maxChars),
            styles: const PosStyles(align: PosAlign.left, bold: true));
        if (prodDisc > 0) {
          bytes += generator.text(
              _formatRow('Product Discounts', '-${f(prodDisc)}', maxChars),
              styles: const PosStyles(align: PosAlign.left));
        }
        if (transDisc > 0) {
          bytes += generator.text(
              _formatRow('Trans. Discounts', '-${f(transDisc)}', maxChars),
              styles: const PosStyles(align: PosAlign.left));
        }
        bytes += generator.text(lineSep,
            styles: const PosStyles(align: PosAlign.left));
      }

      // 6. CREDIT NOTES (REFUNDS)
      final creditNotes = txData['credit_notes'] ?? {};
      final cnList = creditNotes['list'] as List<dynamic>? ?? [];
      final cnTotal = (creditNotes['total'] ?? 0) as int;
      if (cnList.isNotEmpty) {
        bytes += generator.text(_formatCenter('REFUNDS', maxChars),
            styles: const PosStyles(align: PosAlign.left, bold: true));
        for (var cn in cnList) {
          bytes += generator.text(
              _formatRow(cn['number'] ?? 'CN',
                  '-${f((cn['total'] as num?)?.toInt() ?? 0)}', maxChars),
              styles: const PosStyles(align: PosAlign.left));
        }
        bytes += generator.text(
            _formatRow('TOTAL REFUNDS', '-${f(cnTotal)}', maxChars),
            styles: const PosStyles(align: PosAlign.left, bold: true));
        bytes += generator.text(lineSep,
            styles: const PosStyles(align: PosAlign.left));
      }

      // 7. FINAL RECONCILIATION
      final summary = txData['summary'] ?? {};
      final expectedTotal = (summary['expected_cash'] as num?)?.toInt() ?? 0;
      bytes += generator.text(
          _formatRow('EXPECTED CASH', 'Rp.${f(expectedTotal)}', maxChars),
          styles: const PosStyles(align: PosAlign.left, bold: true));
      if (shift.status == 1) {
        bytes += generator.text(
            _formatRow(
                'ACTUAL CASH', 'Rp.${f(shift.closingBalance)}', maxChars),
            styles: const PosStyles(align: PosAlign.left, bold: true));
        final diff = shift.closingBalance - expectedTotal;
        bytes += generator.text(
            _formatRow('DIFFERENCE', 'Rp.${f(diff)}', maxChars),
            styles: PosStyles(align: PosAlign.left, bold: diff != 0));
        if (shift.note.isNotEmpty) {
          bytes += generator.text('Note: ${shift.note}',
              styles: const PosStyles(align: PosAlign.left));
        }
      }
    } else {
      // Legacy fallback
      bytes += generator.text(
          _formatRow(
              'Opening Balance', 'Rp.${f(shift.startingBalance)}', maxChars),
          styles: const PosStyles(align: PosAlign.left, bold: true));
      bytes += generator.text(
          _formatRow('Cash Sales', 'Rp.${f(recap['cash'] ?? 0)}', maxChars),
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text(
          _formatRow(
              'Non-Cash Sales', 'Rp.${f(recap['nonCash'] ?? 0)}', maxChars),
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text(lineSep,
          styles: const PosStyles(align: PosAlign.left));
      final expectedTotal = shift.startingBalance + (recap['cash'] ?? 0);
      bytes += generator.text(
          _formatRow('EXPECTED CASH', 'Rp.${f(expectedTotal)}', maxChars),
          styles: const PosStyles(align: PosAlign.left, bold: true));
      if (shift.status == 1) {
        bytes += generator.text(
            _formatRow(
                'ACTUAL CASH', 'Rp.${f(shift.closingBalance)}', maxChars),
            styles: const PosStyles(align: PosAlign.left, bold: true));
        final diff = shift.closingBalance - expectedTotal;
        bytes += generator.text(
            _formatRow('DIFFERENCE', 'Rp.${f(diff)}', maxChars),
            styles: PosStyles(align: PosAlign.left, bold: diff != 0));
      }
    }

    // FOOTER
    bytes +=
        generator.text(lineSep, styles: const PosStyles(align: PosAlign.left));
    final now = DateTime.now();
    final printedStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    bytes += generator.text(_formatCenter('Printed: $printedStr', maxChars),
        styles: const PosStyles(align: PosAlign.left));
    bytes += generator.feed(3);
    if (printer.isAutoCut) {
      bytes += generator.cut();
    }

    return bytes;
  }

  /// Core print method: connect → send bytes.
  /// DOES NOT DISCONNECT immediately anymore to preserve socket stability across quick successive prints.
  /// For network printers, reuses socket or reconnects.
  Future<void> printToTarget(PrinterDevice printer,
      {bool isTestPrint = false, List<int>? prebuiltBytes}) async {
    try {
      final List<int> bytes = prebuiltBytes ?? await _buildTestBytes(printer);

      if (printer.type == 'bluetooth') {
        // Step 1: Connect
        final connected = await _connectToBluetooth(printer);
        if (!connected) {
          Get.snackbar('Printer Warning',
              'Printer ${printer.name} with roles ${printer.roles.join(", ")} failed. Make sure it is powered on and paired.');
          return;
        }
        // Step 2: Send bytes
        await Future.delayed(
            const Duration(milliseconds: 300)); // Small settle time

        // Write bytes with a one-time retry on failure (handles zombie socket)
        bool writeSuccess = false;
        for (int writeAttempt = 1; writeAttempt <= 2; writeAttempt++) {
          try {
            await bluetooth.writeBytes(Uint8List.fromList(bytes));
            writeSuccess = true;
            break;
          } catch (writeErr) {
            debugPrint(
                'BT writeBytes ATTEMPT $writeAttempt failed for ${printer.name}: $writeErr');
            if (writeAttempt < 2) {
              // Force a fresh reconnect and retry once
              connectedBluetoothAddress = null;
              try {
                await bluetooth.disconnect();
              } catch (_) {}
              await Future.delayed(const Duration(milliseconds: 1500));
              final reconnected = await _connectToBluetooth(printer);
              if (!reconnected) break;
            }
          }
        }

        if (!writeSuccess) {
          Get.snackbar(
            'Printer Tidak Merespon',
            '⚠️ Pembayaran BERHASIL, tapi struk gagal dicetak.\nCoba tekan tombol "Cetak Ulang" atau restart printer.',
            backgroundColor: Colors.orange.shade800,
            colorText: Colors.white,
            duration: const Duration(seconds: 6),
            snackPosition: SnackPosition.TOP,
            icon: const Icon(Icons.print_disabled, color: Colors.white),
          );
          connectedBluetoothAddress = null;
          try {
            await bluetooth.disconnect();
          } catch (_) {}
          return;
        }

        await Future.delayed(
            const Duration(milliseconds: 500)); // Wait for data to flush
        // Release the printer so other tablets/devices can connect.
        // Most Bluetooth thermal printers only support one active connection.
        await Future.delayed(
            const Duration(seconds: 1)); // Give time to finish printing
        try {
          await bluetooth.disconnect();
          connectedBluetoothAddress = null;
        } catch (e) {
          debugPrint('Error disconnecting after print: $e');
        }
      } else if (printer.type == 'network') {
        try {
          Socket? socket = networkSockets[printer.address];
          if (socket == null) {
            socket = await Socket.connect(printer.address, printer.port,
                timeout: const Duration(seconds: 4));
            networkSockets[printer.address] = socket;

            // Background listener
            socket.done.then((_) {
              networkSockets.remove(printer.address);
              _updatePrinterStatus(printer.id, false);
            });
          }

          socket.add(bytes);
          await socket.flush();
          _updatePrinterStatus(printer.id, true);
        } catch (e) {
          // IMPORTANT: Remove broken socket so next attempt starts fresh
          final socket = networkSockets.remove(printer.address);
          try {
            socket?.destroy();
          } catch (_) {}

          _updatePrinterStatus(printer.id, false);
          ErrorLogService.log(
            category: 'printer',
            errCode: 'NETWORK_PRINT_FAIL',
            errMsg:
                'Printer: ${printer.name} (${printer.address}:${printer.port}) | isTestPrint=$isTestPrint | $e',
          );
          Get.snackbar(
            'Printer Offline',
            'Failed to send to ${printer.address}:${printer.port}: $e',
            backgroundColor: Colors.red.withValues(alpha: 0.1),
            icon: const Icon(Icons.print_disabled, color: Colors.red),
            duration: const Duration(seconds: 5),
          );
        }
      }
    } catch (e) {
      debugPrint('printToTarget Error for ${printer.name}: $e');
      ErrorLogService.log(
        category: 'printer',
        errCode: 'PRINT_TO_TARGET_FAIL',
        errMsg:
            'Printer: ${printer.name} (${printer.type}/${printer.roles.join(", ")}) | isTestPrint=$isTestPrint | $e',
      );
      Get.snackbar('Print Error', 'Failed to print on "${printer.name}": $e');
    }
  }

  /// Sequential print to multiple printers.
  /// For Bluetooth: connect → print → disconnect → next.
  /// Caller builds bytes for each printer role separately.
  Future<void> printSequential(Map<PrinterDevice, List<int>> printJobs) async {
    for (final entry in printJobs.entries) {
      await printToTarget(entry.key, prebuiltBytes: entry.value);
    }
  }

  /// Returns true if at least one printer with [role] is configured and active.
  bool hasPrinterForRole(String role) {
    return assignedPrinters.any((p) => p.roles.contains(role) && p.isActive);
  }

  List<PrinterDevice> getPrintersForRole(String role) {
    return assignedPrinters
        .where((p) => p.roles.contains(role) && p.isActive)
        .toList();
  }

  PrinterDevice? getPrinterForRole(String role) {
    return assignedPrinters
        .firstWhereOrNull((p) => p.roles.contains(role) && p.isActive);
  }

  PrinterDevice? getPrinterForRoleAndBrand(String role, String brand) {
    // 1. Exact match: printer's roleBrands contains this specific brand for this role
    final exactMatch = assignedPrinters.firstWhereOrNull((p) {
      if (!p.roles.contains(role) || !p.isActive) return false;
      if (p.roleBrands.containsKey(role)) {
        return p.roleBrands[role]!.contains(brand);
      }
      return p.brands.contains(brand);
    });
    if (exactMatch != null) return exactMatch;

    // 2. Fallback match: printer has NO brands assigned for this role (acts as a generic/catch-all printer)
    final genericMatch = assignedPrinters.firstWhereOrNull((p) {
      if (!p.roles.contains(role) || !p.isActive) return false;
      if (p.roleBrands.containsKey(role)) {
        return p.roleBrands[role]!.isEmpty;
      }
      return p.brands.isEmpty;
    });
    return genericMatch;
  }

  void formValidate() async {
    String companyName = companyNameFieldController.text;
    String discount = companyDiscFieldController.text;
    String telp = companyTelpFieldController.text;
    String address = companyAddressFieldController.text;
    String version = companyVersionFieldController.text;
    String webhookUrl = transactionWebhookUrlFieldController.text.trim();

    if (companyName == '') {
      Get.snackbar('Error', 'Company name cannot be empty');
      return;
    }

    if (discount == '') {
      Get.snackbar('Error', 'Discount cannot be empty');
      return;
    }
    if (telp == '') {
      Get.snackbar('Error', 'Phone number cannot be empty');
      return;
    }
    if (address == '') {
      Get.snackbar('Error', 'Address cannot be empty');
      return;
    }
    Map<String, dynamic> data = {
      'nama_perusahaan': companyName,
      'telepon': telp,
      'alamat': address,
      'diskon': discount,
      'versi': version,
      'transaction_webhook_url': webhookUrl,
    };

    await updateData(data);
  }

  Future<void> updateData(Map<String, dynamic> data) async {
    isLoadingStore.value = true;

    try {
      final appService = Get.find<AppService>();

      // Ensure we never send an empty version which would wipe it out on the server
      String finalVersion = _resolveBestKnownVersion(preferred: data['versi']);

      // Build payload. Also include current queue state so we absorb any
      // pending queue_counter sync — preventing a second PUT to the same endpoint.
      final dbService = Get.find<DatabaseService>();
      final optionsMap = <String, dynamic>{
        'pos_tenant_name': data['nama_perusahaan'],
        'pos_phone': data['telepon'],
        'pos_address': data['alamat'],
        'pos_default_discount': data['diskon'],
        Constants.posTransactionWebhookUrl:
            data['transaction_webhook_url']?.toString().trim() ?? '',
        // Piggy-back the current queue state to avoid a second separate PUT
        Constants.psNextQueue: appService.queueNumber.value,
        Constants.psLastQueueDate: appService.lastQueueDate.value,
      };
      if (finalVersion.isNotEmpty) {
        optionsMap['version'] = finalVersion;
      }

      // Cancel any pending queue_counter sync so SyncService doesn't fire
      // a duplicate request to /api/pos_options right after this one.
      try {
        await dbService.rawQuery(
          "UPDATE sync_queue SET status = 'done' "
          "WHERE endpoint = '/api/pos_options' AND local_id = 'queue_counter' "
          "AND status IN ('pending', 'failed')",
          [],
        );
        debugPrint(
            'SettingController: Absorbed pending queue_counter sync into settings payload.');
      } catch (e) {
        debugPrint(
            'SettingController: Could not absorb queue_counter sync: \$e');
      }

      // Always save locally first to ensure offline persistence
      await userService.saveString(
          Constants.posCompanyName, data['nama_perusahaan']);
      await userService.saveString(Constants.posPhoneNumber, data['telepon']);
      await userService.saveString(Constants.posAddress, data['alamat']);
      await userService.saveString(
          Constants.posDefaultDiscount, data['diskon']);
      if (finalVersion.isNotEmpty) {
        await userService.saveString('pos_version', finalVersion);
      }
      await userService.saveString(
          'pos_app_settings', jsonEncode(appService.posSettings));

      final webhookUrl =
          data['transaction_webhook_url']?.toString().trim() ?? '';
      if (webhookUrl.isEmpty) {
        await dbService.delete(
          'pos_options',
          'option_name = ?',
          [Constants.posTransactionWebhookUrl],
        );
      } else {
        await dbService.insert('pos_options', {
          'option_name': Constants.posTransactionWebhookUrl,
          'option_value': webhookUrl,
        });
      }

      final responseApi = await apiService.updatePosOptions(optionsMap);

      if (responseApi.responsestate == Constants.successState) {
        Get.snackbar('Berhasil', 'Pengaturan berhasil disimpan.',
            backgroundColor: Colors.green.withValues(alpha: 0.1),
            icon: const Icon(Icons.check_circle, color: Colors.green));
      } else {
        // API error but local save succeeded
        Get.snackbar('Attention',
            'Settings saved locally, but failed to sync to server: ${responseApi.message}',
            backgroundColor: Colors.orange.withValues(alpha: 0.1),
            icon: const Icon(Icons.warning, color: Colors.orange));
      }
    } catch (e) {
      debugPrint("SettingController: Update failed: $e");
      // Local save already happened above the API call
      String errorMsg = e is SocketException
          ? 'No internet connection. Settings saved on this device.'
          : 'Sync failed ($e). Settings saved locally.';

      Get.snackbar('Info', errorMsg,
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          icon: const Icon(Icons.info, color: Colors.blue),
          duration: const Duration(seconds: 4));
    } finally {
      isLoadingStore.value = false;
    }
  }

  Future<void> checkUpdate() async {
    if (isCheckingUpdate.value) return;
    isCheckingUpdate.value = true;
    try {
      final masterResponse = await http.get(
        Uri.parse('https://flinkaja.com/api/pos_options'),
        headers: {'authtoken': userService.getAuthToken()},
      );
      if (masterResponse.statusCode == 200) {
        final masterData = jsonDecode(masterResponse.body);
        if (masterData['status'] == true) {
          final masterVersion = masterData['data']['version']?.toString() ?? "";
          final masterPosPath =
              masterData['data']['pos_path']?.toString() ?? "";
          final masterChangelog =
              masterData['data']['changelog']?.toString() ?? "";

          final optionsApi = await apiService.getPosOptions();
          String tenantVersion = _resolveBestKnownVersion();
          if (optionsApi.responsestate == Constants.successState &&
              optionsApi.data != null &&
              optionsApi.data is Map<String, dynamic>) {
            final options = optionsApi.data as Map<String, dynamic>;
            tenantVersion = _resolveBestKnownVersion(
              preferred: options['version'] ?? options['pos_version'],
            );
          }

          if (tenantVersion.isEmpty) {
            Get.snackbar('Error', 'Could not determine current version.');
          } else if (tenantVersion != masterVersion) {
            // Show update dialog
            _showUpdateDialog(masterVersion, masterChangelog, masterPosPath);
          } else {
            Get.snackbar('Information', 'Your application is up to date.',
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                icon: const Icon(Icons.info, color: Colors.blue));
          }
        } else {
          Get.snackbar('Error', 'Format data master tidak sesuai.');
        }
      } else {
        Get.snackbar('Error', 'Gagal mengecek pembaruan dari server master.');
      }
    } catch (e) {
      debugPrint('checkUpdate error: $e');
      Get.snackbar('Error',
          'An error occurred while checking for updates (No Internet/Timeout).');
    } finally {
      isCheckingUpdate.value = false;
    }
  }

  Future<void> checkUpdateBackground() async {
    try {
      final masterResponse = await http.get(
        Uri.parse('https://flinkaja.com/api/pos_options'),
        headers: {'authtoken': userService.getAuthToken()},
      ).timeout(const Duration(seconds: 15));
      if (masterResponse.statusCode == 200) {
        final masterData = jsonDecode(masterResponse.body);
        if (masterData['status'] == true) {
          final masterVersion = masterData['data']['version']?.toString() ?? "";
          final masterPosPath =
              masterData['data']['pos_path']?.toString() ?? "";
          final masterChangelog =
              masterData['data']['changelog']?.toString() ?? "";

          final optionsApi = await apiService.getPosOptions();
          String tenantVersion = "";
          if (optionsApi.responsestate == Constants.successState &&
              optionsApi.data != null) {
            Map<String, dynamic> rawOptions = {};
            if (optionsApi.data is Map) {
              rawOptions = optionsApi.data as Map<String, dynamic>;
            } else if (optionsApi.data is List) {
              final list = optionsApi.data as List;
              for (var item in list) {
                if (item is Map) {
                  if (item.containsKey('option_name') &&
                      item.containsKey('option_value')) {
                    rawOptions[item['option_name'].toString()] =
                        item['option_value'];
                  } else {
                    rawOptions.addAll(Map<String, dynamic>.from(item));
                  }
                }
              }
            }
            final options =
                rawOptions.map((key, value) => MapEntry(key.trim(), value));
            tenantVersion = _resolveBestKnownVersion(
              preferred: options['version'] ?? options['pos_version'],
            );
          }

          if (tenantVersion.isNotEmpty &&
              masterVersion.isNotEmpty &&
              tenantVersion != masterVersion) {
            hasUpdateAvailable.value = true;
            cachedMasterVersion = masterVersion;
            cachedMasterApkUrl = masterPosPath;
            cachedMasterChangelog = masterChangelog;
            _showBackgroundUpdateDialog();
          } else {
            hasUpdateAvailable.value = false;
          }
        }
      }
    } catch (e) {
      debugPrint('checkUpdateBackground error: $e');
    }
  }

  void _showBackgroundUpdateDialog() {
    Get.dialog(
      AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        backgroundColor: AppTheme.cardColor(Get.context!),
        title: Row(
          children: [
            const Icon(Icons.system_update, color: AppTheme.primaryColor),
            SizedBox(width: 8.w),
            Text('Update Available',
                style: TextStyle(
                    fontFamily: AppTheme.fontBold,
                    fontSize: 18.sp,
                    color: AppTheme.textColor(Get.context!))),
          ],
        ),
        content: Text(
            'A new update ($cachedMasterVersion) is available. Do you want to go to settings to update?',
            style: TextStyle(color: AppTheme.textColor(Get.context!))),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('Later',
                style: TextStyle(
                    color: Colors.grey, fontFamily: AppTheme.fontMedium)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              if (Get.isRegistered<DashboardEmployeeController>()) {
                Get.find<DashboardEmployeeController>()
                    .stateSelectedIndex
                    .value = 6;
              } else if (Get.isRegistered<DashboardAdminController>()) {
                Get.find<DashboardAdminController>().stateSelectedIndex.value =
                    6;
              } else {
                Get.toNamed('/setting');
              }
            },
            child: const Text('Update',
                style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontFamily: AppTheme.fontBold)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showUpdateDialog(String version, String changelog, String apkUrl) {
    Get.dialog(
      AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        backgroundColor: AppTheme.cardColor(Get.context!),
        title: Row(
          children: [
            const Icon(Icons.system_update, color: AppTheme.primaryColor),
            SizedBox(width: 8.w),
            Text('Update Available',
                style: TextStyle(
                    fontFamily: AppTheme.fontBold,
                    fontSize: 18.sp,
                    color: AppTheme.textColor(Get.context!))),
          ],
        ),
        content: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A new version ($version) is available.',
                    style: TextStyle(color: AppTheme.textColor(Get.context!))),
                SizedBox(height: 8.h),
                Text('Changelog:',
                    style: TextStyle(
                        fontFamily: AppTheme.fontBold,
                        color: AppTheme.textColor(Get.context!))),
                Text(changelog,
                    style: TextStyle(
                        color: AppTheme.secondaryTextColor(Get.context!))),
                if (downloadProgress.value > 0) ...[
                  SizedBox(height: 16.h),
                  LinearProgressIndicator(
                      value: downloadProgress.value,
                      color: AppTheme.primaryColor),
                  SizedBox(height: 8.h),
                  Text(
                      '${(downloadProgress.value * 100).toStringAsFixed(0)}% downloaded',
                      style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.secondaryTextColor(Get.context!))),
                ]
              ],
            )),
        actions: [
          TextButton(
            onPressed: () {
              if (downloadProgress.value == 0 ||
                  downloadProgress.value >= 1.0) {
                Get.back();
              }
            },
            child: const Text('Later',
                style: TextStyle(
                    color: Colors.grey, fontFamily: AppTheme.fontMedium)),
          ),
          Obx(() => TextButton(
                onPressed:
                    (downloadProgress.value > 0 && downloadProgress.value < 1.0)
                        ? null
                        : () => _downloadAndInstallUpdate(apkUrl, version),
                child: const Text('Update',
                    style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontFamily: AppTheme.fontBold)),
              )),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _downloadAndInstallUpdate(String url, String newVersion) async {
    try {
      downloadProgress.value = 0.01;
      final parsedUrl = Uri.parse(url);
      final fileName = parsedUrl.pathSegments.last.isNotEmpty
          ? parsedUrl.pathSegments.last
          : 'update.apk';

      Directory? tempDir;
      if (Platform.isAndroid) {
        tempDir = await getExternalStorageDirectory();
        // Fallback if null
        tempDir ??= await getTemporaryDirectory();
      } else {
        tempDir = await getTemporaryDirectory();
      }

      final savePath = '${tempDir.path}/$fileName';
      final file = File(savePath);

      final request = http.Request('GET', parsedUrl);
      final response = await http.Client().send(request);
      final contentLength = response.contentLength;

      int downloaded = 0;
      final sink = file.openWrite();

      response.stream.listen((List<int> chunk) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (contentLength != null && contentLength > 0) {
          downloadProgress.value = downloaded / contentLength;
        }
      }, onDone: () async {
        await sink.close();
        downloadProgress.value = 1.0;

        // Memperbarui versi di server tenant
        try {
          final optionsMap = {
            'pos_tenant_name': companyNameFieldController.text,
            'pos_phone': companyTelpFieldController.text,
            'pos_address': companyAddressFieldController.text,
            'pos_default_discount': companyDiscFieldController.text,
            'version': newVersion
          };
          await apiService.updatePosOptions(optionsMap);
          companyVersionFieldController.text = newVersion;
        } catch (e) {
          debugPrint("Gagal update versi otomatis ke tenant: $e");
        }

        Get.back();

        final result = await OpenFilex.open(savePath);
        debugPrint('OpenFilex result: ${result.message}');
        if (result.type != ResultType.done) {
          Get.snackbar('Installation Failed', result.message,
              duration: const Duration(seconds: 4));
        }

        // reset for future
        downloadProgress.value = 0.0;
      }, onError: (e) async {
        await sink.close();
        downloadProgress.value = 0.0;
        Get.snackbar('Error', 'Failed to download update.');
      });
    } catch (e) {
      debugPrint('Download error: $e');
      downloadProgress.value = 0.0;
      Get.snackbar('Error', 'Gagal memulai proses download.');
    }
  }

  String _truncateProductName(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 2)}..';
  }
}
