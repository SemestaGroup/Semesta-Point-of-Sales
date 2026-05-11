import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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
  TextEditingController labelOffsetXFieldController = TextEditingController(text: "20");
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
    
    // 2. Reactively update text controllers if background sync finishes
    ever(appService.appModel, (AppModel model) {
      if (companyNameFieldController.text.isEmpty || companyNameFieldController.text == 'Guest') {
        companyNameFieldController.text = model.namaPerusahaan;
      }
      if (companyAddressFieldController.text.isEmpty || companyAddressFieldController.text == 'Guest') {
        companyAddressFieldController.text = model.alamat;
      }
      if (companyTelpFieldController.text.isEmpty || companyTelpFieldController.text == 'Guest') {
        companyTelpFieldController.text = model.telepon;
      }
      if (companyDiscFieldController.text == '0' || companyDiscFieldController.text.isEmpty) {
        companyDiscFieldController.text = model.diskon.toString();
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
          assignedPrinters.value = list.map((e) => PrinterDevice.fromJson(e)).toList();
        } catch (_) {}
      }
      
      // 2. Load Company Info from AppService (Source of Truth)
      // AppService already handles the SQLite fallback in its onInit
      final model = appService.appModel.value;
      
      companyNameFieldController.text = model.namaPerusahaan;
      companyAddressFieldController.text = model.alamat;
      companyTelpFieldController.text = model.telepon;
      companyDiscFieldController.text = model.diskon.toString();
      companyVersionFieldController.text = model.version;
      
      final localLabelOffsetX = userService.getPrefString('pos_label_offset_x');
      if (localLabelOffsetX.isNotEmpty && localLabelOffsetX != "Guest") {
        labelOffsetXFieldController.text = localLabelOffsetX;
      } else {
        labelOffsetXFieldController.text = "20"; // Default offset
      }

      // Auto-connect defined network printers
      autoConnectAll();
    } catch (e) {
      debugPrint("SettingController: _loadLocalSettings error: $e");
    } finally {
      isLoading.value = false;
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
              if (item.containsKey('option_name') && item.containsKey('option_value')) {
                rawOptions[item['option_name'].toString()] = item['option_value'];
              } else {
                rawOptions.addAll(Map<String, dynamic>.from(item));
              }
            }
          }
        }
        
        // Sanitize keys
        final options = rawOptions.map((key, value) => MapEntry(key.trim(), value));

        // Sync to AppService
        final appService = Get.find<AppService>();
        
        // Extract values using keys from API_DOCS.md
        String name = (options['pos_tenant_name'] ?? options['pos_company_name'] ?? options['company_name'])?.toString().trim() ?? "";
        if (name.isEmpty || name == 'Guest') name = appService.appModel.value.namaPerusahaan;
        if (name.isEmpty || name == 'Guest') name = userService.getPrefString(Constants.posCompanyName);
        if (name == 'Guest') name = '';

        String address = (options['pos_address'] ?? options['company_address'] ?? options['address'])?.toString().trim() ?? "";
        if (address.isEmpty || address == 'Guest') address = appService.appModel.value.alamat;
        if (address.isEmpty || address == 'Guest') address = userService.getPrefString(Constants.posAddress);
        if (address == 'Guest') address = '';

        String phone = (options['pos_phone'] ?? options['pos_phone_number'] ?? options['company_phone'])?.toString().trim() ?? "";
        if (phone.isEmpty || phone == 'Guest') phone = appService.appModel.value.telepon;
        if (phone.isEmpty || phone == 'Guest') phone = userService.getPrefString(Constants.posPhoneNumber);
        if (phone == 'Guest') phone = '';

        String discount = (options['pos_default_discount'] ?? options['default_discount'])?.toString().trim() ?? "0";
        if (discount == "0" || discount.isEmpty) discount = appService.appModel.value.diskon.toString();

        String version = (options['pos_version'] ?? options['version'] ?? options['app_version'] ?? appService.appModel.value.version).toString();
        if (version.isEmpty || version == "null") version = "1.0.0";

        // Always update text controllers
        companyNameFieldController.text = name;
        companyAddressFieldController.text = address;
        companyTelpFieldController.text = phone;
        companyDiscFieldController.text = discount;
        companyVersionFieldController.text = version;

        // Persist to SharedPreferences via UserService if they exist (only not null ones)
        if (name.isNotEmpty) userService.saveString(Constants.posCompanyName, name);
        if (phone.isNotEmpty) userService.saveString(Constants.posPhoneNumber, phone);
        if (address.isNotEmpty) userService.saveString(Constants.posAddress, address);
        if (discount.isNotEmpty) userService.saveString(Constants.posDefaultDiscount, discount);
        if (version.isNotEmpty) userService.saveString('pos_version', version);

        // Update AppService model
        appService.appModel.value = appService.appModel.value.copyWith(
          namaPerusahaan: name.isNotEmpty ? name : appService.appModel.value.namaPerusahaan,
          alamat: address.isNotEmpty ? address : appService.appModel.value.alamat,
          telepon: phone.isNotEmpty ? phone : appService.appModel.value.telepon,
          diskon: int.tryParse(discount) ?? appService.appModel.value.diskon,
          version: version.isNotEmpty ? version : appService.appModel.value.version,
        );
        
        // Cache detailed options to SQLite for offline use
        final db = Get.find<DatabaseService>();
        for (var entry in options.entries) {
          final serverVal = entry.value?.toString() ?? "";
          
          if (entry.key == 'pos_active_session' || entry.key == 'pos_active_staff') {
            if (serverVal.isNotEmpty && serverVal.length > 5) {
              try {
                final decoded = jsonDecode(serverVal);
                if (decoded is Map<String, dynamic>) {
                  await db.insert('pos_options', {
                    'option_name': entry.key,
                    'option_value': serverVal,
                  });
                  
                  if (entry.key == 'pos_active_session' && Get.isRegistered<ShiftController>()) {
                    Get.find<ShiftController>().activeShift.value = ShiftSessionModel.fromJson(decoded);
                  }
                }
              } catch(e) {
                debugPrint('SettingController: Error parsing pos_active_session, ignoring server value: $e');
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
            final String printerJson = options['pos_printer_configs']?.toString() ?? "";
            if (printerJson.isNotEmpty && printerJson != "null") {
              final List<dynamic> list = jsonDecode(printerJson);
              assignedPrinters.value = list.map((e) => PrinterDevice.fromJson(e)).toList();
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
        companyVersionFieldController.text = model.version;
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
    const int maxRetries = 2;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('BT Connect Attempt $attempt for ${device.name}');
        
        // Step 1: Handle existing connections gracefully
        final bool? isCurrentlyConnected = await bluetooth.isConnected;
        
        if (isCurrentlyConnected == true) {
          if (connectedBluetoothAddress == device.address) {
            // Already connected to the target! Skip connect overhead.
            debugPrint('BT Already connected to target (${device.name}). Skipping connect.');
            _updatePrinterStatus(device.id, true);
            return true;
          } else {
            // Connected to a DIFFERENT device, so disconnect first.
            try { await bluetooth.disconnect(); } catch (_) {}
            await Future.delayed(const Duration(milliseconds: 1000));
            connectedBluetoothAddress = null;
          }
        }

        // Step 2: Find the specific target in bonded list
        List<blue.BluetoothDevice> bonded = await bluetooth.getBondedDevices();
        final target = bonded.firstWhereOrNull((d) => d.address == device.address);
        if (target == null) {
          debugPrint('BT device not found in paired list: ${device.name} (${device.address})');
          if (attempt == maxRetries) {
            _updatePrinterStatus(device.id, false);
            return false;
          }
          continue;
        }

        // Step 3: Attempt connection
        await bluetooth.connect(target);

        // Step 4: VERIFY — library may not throw even if printer is off
        await Future.delayed(const Duration(milliseconds: 1000)); // Wait for socket to stabilize
        final bool? isConnected = await bluetooth.isConnected;
        if (isConnected != true) {
          debugPrint('BT connect() returned but isConnected=false for ${device.name}. Printer may be off.');
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
            errMsg: 'Device: ${device.name} (${device.address}) | Attempt $attempt | $e',
          );
          return false;
        }
        await Future.delayed(const Duration(milliseconds: 1500)); // Cool down before retry
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
        errMsg: 'Device: ${device.name} (${device.address}:${device.port}) | $e',
      );
    }
  }

  void _updatePrinterStatus(String id, bool connected) {
    int idx = assignedPrinters.indexWhere((p) => p.id == id);
    if (idx != -1) {
      assignedPrinters[idx] = assignedPrinters[idx].copyWith(isConnected: connected);
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
    await _savePrinterConfigs();
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
      await _savePrinterConfigs();
    }
  }

  Future<void> _savePrinterConfigs() async {
    final String printerJson = jsonEncode(assignedPrinters.map((e) => e.toJson()).toList());
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
    String paperSize = '58mm',
    int copies = 1,
  }) async {
    final profile = await CapabilityProfile.load();
    final paper = paperSize == '80mm' ? PaperSize.mm80 : PaperSize.mm58;
    final generator = Generator(paper, profile);
    List<int> bytes = [];

    for (int i = 0; i < copies; i++) {
      bytes += generator.text(
        line1,
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text('------------------------------------------',
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text(
        line2,
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        line3,
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text('------------------------------------------',
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text(
        line4,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.feed(2);
      bytes += generator.cut();
    }


    return bytes;
  }



  /// Builds ESC/POS bytes for a test page, role-aware.
  Future<List<int>> _buildTestBytes(PrinterDevice printer) async {
    final profile = await CapabilityProfile.load();

    // --- Label test: ESC/POS mode for regular thermal label printers ---
    if (printer.role == 'label') {
      final now = DateTime.now();
      final dateTimeStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}'
          ' ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      return buildLabelEscPos(
        line1: dateTimeStr,
        line2: 'TEST CUSTOMER',
        line3: '#ABCDEF12',
        line4: 'TEST PRODUCT NAME',
        paperSize: printer.paperSize,
      );
    }

    // --- Generic test for cashier / kitchen ---
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    String companyName = userService.getPrefString(Constants.posCompanyName);
    if (companyName == 'Guest' || companyName.isEmpty) companyName = 'SEMESTA POS';
    String address = userService.getPrefString(Constants.posAddress);
    if (address == 'Guest') address = '';
    String phone = userService.getPrefString(Constants.posPhoneNumber);
    if (phone == 'Guest') phone = '';

    final isKitchen = printer.role == 'kitchen';
    final title = isKitchen ? 'KITCHEN TEST' : 'TEST PRINT';
    final lineSep = '------------------------------------------';

    bytes += generator.text(isKitchen ? '*** KITCHEN ***' : companyName.toUpperCase(),
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
    
    if (!isKitchen) {
      if (address.isNotEmpty) bytes += generator.text(address, styles: const PosStyles(align: PosAlign.center));
      if (phone.isNotEmpty) bytes += generator.text('Tel: $phone', styles: const PosStyles(align: PosAlign.center));
    }
    
    bytes += generator.text(lineSep, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(title, styles: const PosStyles(align: PosAlign.center, bold: true));
    
    if (isKitchen) {
       bytes += generator.text('Role: KITCHEN PREPARATION', styles: const PosStyles(align: PosAlign.center));
       bytes += generator.text('Receipt No: #TEST-KITCHEN', styles: const PosStyles(align: PosAlign.left));
       bytes += generator.text(lineSep, styles: const PosStyles(align: PosAlign.center));
       bytes += generator.text('1x TEST PRODUCT NAME', styles: const PosStyles(align: PosAlign.left, bold: true));
       bytes += generator.text('   * Test Note/Instruction', styles: const PosStyles(align: PosAlign.left, fontType: PosFontType.fontB));
       bytes += generator.text(lineSep, styles: const PosStyles(align: PosAlign.center));
    } else {
       bytes += generator.text('Role: ${printer.role.toUpperCase()}', styles: const PosStyles(align: PosAlign.center));
       bytes += generator.text('Connection: ${printer.type}', styles: const PosStyles(align: PosAlign.center));
       bytes += generator.text(lineSep, styles: const PosStyles(align: PosAlign.center));
       bytes += generator.text('Printer connected successfully!', styles: const PosStyles(align: PosAlign.center));
    }
    
    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }

  /// Prints a comprehensive Z-Report (Shift Summary) for a closed shift.
  Future<void> printZReport(ShiftSessionModel shift, Map<String, int> recap) async {
    final printer = getPrinterForRole('cashier');
    if (printer == null) {
      Get.snackbar('Printer Error', 'No active Cashier printer found for Z-Report.',
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

  Future<List<int>> _buildZReportBytes(PrinterDevice printer, ShiftSessionModel shift, Map<String, int> recap) async {
    final profile = await CapabilityProfile.load();
    final is80mm = printer.paperSize == '80mm';
    final paperSize = is80mm ? PaperSize.mm80 : PaperSize.mm58;
    
    final int maxChars = is80mm ? 48 : 33;
    final int labelWidth = is80mm ? 30 : 21;
    final int valueWidth = maxChars - labelWidth;
    final String lineSep = '-' * maxChars;

    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    // Helper for currency formatting
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

    String companyName = userService.getPrefString(Constants.posCompanyName);
    if (companyName == 'Guest' || companyName.isEmpty) companyName = 'SEMESTA POS';

    // Header
    bytes += generator.text(companyName.toUpperCase(),
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text('Z-REPORT / SHIFT RECAP', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.hr();
    
    // Financials
    // Parse detailed reconciliation data if available
    List<dynamic>? txDataList;
    Map<String, dynamic>? txData;
    if (shift.reconciliationData != null && shift.reconciliationData!.isNotEmpty) {
      try {
        txDataList = jsonDecode(shift.reconciliationData!);
        if (txDataList != null && txDataList.isNotEmpty) {
          txData = txDataList.first;
        }
      } catch(e) { debugPrint("Error parsing reconciliationData for print: $e"); }
    }


    void printRow(String label, String value, {bool bold = false, bool fontB = false}) {
      String lab = label;
      if (lab.length > labelWidth) lab = lab.substring(0, labelWidth - 2) + '..';
      bytes += generator.text(
        lab.padRight(labelWidth) + value.padLeft(valueWidth),
        styles: PosStyles(bold: bold, fontType: fontB ? PosFontType.fontB : PosFontType.fontA),
      );
    }

    String address = userService.getPrefString(Constants.posAddress);
    if (address == 'Guest') address = '';
    String phone = userService.getPrefString(Constants.posPhoneNumber);
    if (phone == 'Guest') phone = '';

    // 1. Header (Nota Style)
    bytes += generator.text(companyName.toUpperCase(),
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
    if (address.isNotEmpty) bytes += generator.text(address, styles: const PosStyles(align: PosAlign.center));
    if (phone.isNotEmpty) bytes += generator.text('Tel: $phone', styles: const PosStyles(align: PosAlign.center));
    
    bytes += generator.hr();
    bytes += generator.text('Z-REPORT / SHIFT RECAP', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.hr();
    
    // 2. Shift Info
    printRow('Shift:', shift.shiftName);
    printRow('Staff:', shift.userId);
    printRow('Start:', shift.startTime.toString().split('.')[0].substring(0, 16));
    if (shift.endTime != null) {
      printRow('End:', shift.endTime.toString().split('.')[0].substring(0, 16));
    }
    bytes += generator.hr();

    if (txData != null) {
      // 3. Initial Balance & Sales Summary
      printRow('Starting Balance:', f(shift.startingBalance), bold: true);
      
      final modes = txData['payment_modes'] as List<dynamic>? ?? [];
      int cashSales = 0;
      int nonCashSales = 0;
      for (var mode in modes) {
        final name = (mode['name'] ?? '').toString().toLowerCase();
        final amount = (mode['recorded'] ?? 0) as int;
        if (name.contains('cash') || name.contains('tunai') || mode['id'] == '1') {
          // cashSales = amount; // Wait, recorded cash might ALREADY include starting balance depending on controller
          // For the report, we usually want "Sales" only.
          // But our getRecordedAmount for cash includes starting balance.
          // So sales = recorded - startingBalance.
          cashSales += (amount - shift.startingBalance);
        } else {
          nonCashSales += amount;
        }
      }
      printRow('Cash Sales:', f(cashSales));
      printRow('Non-Cash Sales:', f(nonCashSales));
      bytes += generator.hr();

      // 4. Products Sold (List Items)
      bytes += generator.text('ITEM SALES', styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('------------------------------------------', styles: const PosStyles(align: PosAlign.center));
      final products = txData['products_sold'] as List<dynamic>? ?? [];
      for (var product in products) {
        final qty = product['qty'] ?? 0;
        final name = product['name'] ?? 'Item';
        final total = product['total'] ?? 0;
        final price = product['price'] ?? 0;
        
        // Style: [qty]x [name] [price] [total]
        // Following receipt: qty x name ... total
        String lab = '${qty}x $name';
        if (lab.length > 25) lab = lab.substring(0, 23) + '..';
        printRow(lab, f(total).replaceAll('Rp. ', ''), fontB: true);
        if (price > 0 && qty > 1) {
           bytes += generator.text('   @ ${f(price).replaceAll('Rp. ', '')}', 
             styles: const PosStyles(fontType: PosFontType.fontB));
        }
      }
      bytes += generator.hr();

      // 5. Credit Notes (Refunds)
      final creditNotes = txData['credit_notes'] ?? {};
      final cnList = creditNotes['list'] as List<dynamic>? ?? [];
      final cnTotal = creditNotes['total'] ?? 0;
      if (cnList.isNotEmpty) {
        bytes += generator.text('CREDIT NOTES (REFUNDS)', styles: const PosStyles(align: PosAlign.center, bold: true));
        for (var cn in cnList) {
          printRow(cn['number'] ?? 'CN', '-${f(cn['total']).replaceAll('Rp. ', '')}', fontB: true);
        }
        printRow('TOTAL REFUNDS:', f(cnTotal), bold: true);
        bytes += generator.hr();
      }

      // 6. Discounts & Loyalty
      final discounts = txData['discounts'] ?? {};
      final prodDisc = discounts['product'] ?? 0;
      final transDisc = discounts['transaction'] ?? 0;
      if (prodDisc > 0 || transDisc > 0) {
        bytes += generator.text('DISCOUNTS', styles: const PosStyles(align: PosAlign.center, bold: true));
        if (prodDisc > 0) printRow('Product Discounts:', '-${f(prodDisc).replaceAll('Rp. ', '')}');
        if (transDisc > 0) printRow('Trans. Discounts:', '-${f(transDisc).replaceAll('Rp. ', '')}');
        bytes += generator.hr();
      }

      final members = txData['members'] ?? {};
      final additions = members['additions'] ?? 0;
      if (additions > 0) {
        printRow('New Members:', '$additions');
        bytes += generator.hr();
      }

      // 7. Final Reconciliation
      final summary = txData['summary'] ?? {};
      final expectedTotal = (summary['expected_cash'] as num?)?.toInt() ?? 0;
      
      printRow('EXPECTED CASH:', f(expectedTotal), bold: true);
      if (shift.status == 1) { // 1 = Closed
        printRow('ACTUAL CASH:', f(shift.closingBalance), bold: true);
        final diff = shift.closingBalance - expectedTotal;
        printRow('DIFFERENCE:', f(diff), bold: true);
        if (shift.note.isNotEmpty) {
           bytes += generator.text('Note: ${shift.note}', styles: const PosStyles(bold: true));
        }
      }
    } else {
      // Legacy Format Fallback
      printRow('Starting Balance:', f(shift.startingBalance), bold: true);
      printRow('Cash Sales:', f(recap['cash'] ?? 0));
      printRow('Non-Cash Sales:', f(recap['nonCash'] ?? 0));
      bytes += generator.hr();
      
      final expectedTotal = shift.startingBalance + (recap['cash'] ?? 0);
      printRow('EXPECTED CASH:', f(expectedTotal), bold: true);
      if (shift.status == 1) {
        printRow('ACTUAL CASH:', f(shift.closingBalance), bold: true);
        final diff = shift.closingBalance - expectedTotal;
        printRow('DIFFERENCE:', f(diff), bold: true);
      }
    }
    
    bytes += generator.hr();
    bytes += generator.text('Printed on: ${DateTime.now().toString().split('.')[0]}', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }

  /// Core print method: connect → send bytes. 
  /// DOES NOT DISCONNECT immediately anymore to preserve socket stability across quick successive prints.
  /// For network printers, reuses socket or reconnects.
  Future<void> printToTarget(PrinterDevice printer, {bool isTestPrint = false, List<int>? prebuiltBytes}) async {
    try {
      final List<int> bytes = prebuiltBytes ?? await _buildTestBytes(printer);

      if (printer.type == 'bluetooth') {
        // Step 1: Connect
        final connected = await _connectToBluetooth(printer);
        if (!connected) {
          Get.snackbar('Printer Error', 'Could not connect to "${printer.name}". Make sure it is powered on and paired.');
          return;
        }
        // Step 2: Send bytes
        await Future.delayed(const Duration(milliseconds: 300)); // Small settle time
        await bluetooth.writeBytes(Uint8List.fromList(bytes));
        await Future.delayed(const Duration(milliseconds: 500)); // Wait for data to flush
        // Release the printer so other tablets/devices can connect.
        // Most Bluetooth thermal printers only support one active connection.
        await Future.delayed(const Duration(seconds: 1)); // Give time to finish printing
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
            socket = await Socket.connect(printer.address, printer.port, timeout: const Duration(seconds: 4));
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
          try { socket?.destroy(); } catch (_) {}
          
          _updatePrinterStatus(printer.id, false);
          ErrorLogService.log(
            category: 'printer',
            errCode: 'NETWORK_PRINT_FAIL',
            errMsg: 'Printer: ${printer.name} (${printer.address}:${printer.port}) | isTestPrint=$isTestPrint | $e',
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
        errMsg: 'Printer: ${printer.name} (${printer.type}/${printer.role}) | isTestPrint=$isTestPrint | $e',
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
    return assignedPrinters.any((p) => p.role == role && p.isActive);
  }

  PrinterDevice? getPrinterForRole(String role) {
    return assignedPrinters.firstWhereOrNull((p) => p.role == role && p.isActive);
  }

  void formValidate() async {
    String companyName = companyNameFieldController.text;
    String discount = companyDiscFieldController.text;
    String telp = companyTelpFieldController.text;
    String address = companyAddressFieldController.text;
    String version = companyVersionFieldController.text;
    String labelOffsetX = labelOffsetXFieldController.text;

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
      'label_offset_x': labelOffsetX.isNotEmpty ? labelOffsetX : '20',
    };

    await updateData(data);
  }

  Future<void> updateData(Map<String, dynamic> data) async {
    isLoadingStore.value = true;

    try {
      final appService = Get.find<AppService>();
      final optionsMap = {
        'version': data['versi'] ?? appModel.value.version,
        'pos_tenant_name': data['nama_perusahaan'],
        'pos_phone': data['telepon'],
        'pos_address': data['alamat'],
        'pos_default_discount': data['diskon'],
        'pos_label_offset_x': data['label_offset_x'],
        // FIXED: Ensure we encode the plain Map value of RxMap
        'pos_app_settings': jsonEncode(appService.posSettings),
      };

      // Always save locally first to ensure offline persistence
      await userService.saveString(Constants.posCompanyName, data['nama_perusahaan']);
      await userService.saveString(Constants.posPhoneNumber, data['telepon']);
      await userService.saveString(Constants.posAddress, data['alamat']);
      await userService.saveString(Constants.posDefaultDiscount, data['diskon']);
      await userService.saveString('pos_label_offset_x', data['label_offset_x']);
      await userService.saveString('pos_app_settings', jsonEncode(appService.posSettings));

      final responseApi = await apiService.updatePosOptions(optionsMap);

      if (responseApi.responsestate == Constants.successState) {
        // Success: Silently updated on server
      } else {
        // API error but local save succeeded
        Get.snackbar('Attention', 'Settings saved locally, but failed to sync to server: ${responseApi.message}',
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
        Uri.parse('https://manajemenpondok.com/api/pos_options'),
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
          String tenantVersion = "";
          if (optionsApi.responsestate == Constants.successState &&
              optionsApi.data != null) {
            final options = optionsApi.data as Map<String, dynamic>;
            tenantVersion = options['version']?.toString() ?? options['pos_version']?.toString() ?? "";
          }
          
          if (tenantVersion.isEmpty) {
            tenantVersion = companyVersionFieldController.text.trim();
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
        Uri.parse('https://manajemenpondok.com/api/pos_options'),
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
                  if (item.containsKey('option_name') && item.containsKey('option_value')) {
                    rawOptions[item['option_name'].toString()] = item['option_value'];
                  } else {
                    rawOptions.addAll(Map<String, dynamic>.from(item));
                  }
                }
              }
            }
            final options = rawOptions.map((key, value) => MapEntry(key.trim(), value));
            tenantVersion = options['version']?.toString() ?? options['pos_version']?.toString() ?? "";
          }
          
          if (tenantVersion.isEmpty) {
            tenantVersion = companyVersionFieldController.text.trim();
          }

          if (tenantVersion.isNotEmpty && masterVersion.isNotEmpty && tenantVersion != masterVersion) {
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
        content: Text('A new update ($cachedMasterVersion) is available. Do you want to go to settings to update?',
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
                Get.find<DashboardEmployeeController>().stateSelectedIndex.value = 6;
              } else if (Get.isRegistered<DashboardAdminController>()) {
                Get.find<DashboardAdminController>().stateSelectedIndex.value = 6;
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
