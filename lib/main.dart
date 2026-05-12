import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/models/shared_user_model.dart';
import 'package:semesta_pos/core/services/user_service.dart';
import 'package:semesta_pos/routes/app_pages.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:semesta_pos/core/services/remote/api_service.dart';
import 'package:semesta_pos/core/services/sync_service.dart';
import 'package:semesta_pos/core/services/app_service.dart';
import 'package:semesta_pos/core/services/theme_service.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/styles/app_theme.dart';
import 'package:workmanager/workmanager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:semesta_pos/modules/setting/controllers/setting_controller.dart';
import 'package:semesta_pos/modules/home/employee/controllers/shift_controller.dart';
import 'package:semesta_pos/core/services/service_dependency.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("Workmanager: Starting background sync task: $task");

    // Initialize services for background task
    Get.put(DatabaseService());
    final userService = Get.put(UserService());
    await userService.initSharedPref();

    Get.put(ApiService());
    final syncService = Get.put(SyncService());

    try {
      await syncService.pushLocalTransactions();
      return Future.value(true);
    } catch (e) {
      debugPrint("Workmanager: Sync task failed: $e");
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Set to false for production
  );

  // Register periodic task (every 1 hour)
  await Workmanager().registerPeriodicTask(
    "1",
    "syncTask",
    frequency: const Duration(hours: 1),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  await ServiceDependency.init();
  final userService = Get.find<UserService>();
  final syncService = Get.find<SyncService>();

  final sharedUserData = await userService.getSharedUserModel();

  // Trigger startup synchronization if logged in
  if (sharedUserData.isLogin) {
    syncService.pullMasterData();
  }

  debugPrint(sharedUserData.toString());
  initializeDateFormatting('id_ID', null);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestBluetoothPermissions();
      if (Get.isRegistered<SettingController>()) {
        Get.find<SettingController>().checkUpdateBackground();
      }
    });

    WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    FlutterNativeSplash.remove();

    final themeService = Get.isRegistered<ThemeService>()
        ? Get.find<ThemeService>()
        : Get.put(ThemeService());
    final userService = Get.isRegistered<UserService>()
        ? Get.find<UserService>()
        : Get.put(UserService());

    // Determine initial route ONCE at startup
    final String initialRoute =
        userService.isLoggedIn.value ? Routes.sync : Routes.login;

    return ScreenUtilInit(
        designSize: const Size(1024, 768),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, context) {
          return GetMaterialApp(
            title: 'Flink POS',
            debugShowCheckedModeBanner: false,
            themeMode: themeService.theme,
            theme: ThemeData(
              brightness: Brightness.light,
              primaryColor: AppTheme.primaryColor,
              scaffoldBackgroundColor: AppTheme.scaffoldBgColor,
              cardColor: Colors.white,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primaryColor: AppTheme.primaryColor,
              scaffoldBackgroundColor: AppTheme.darkBackgroundColor,
              cardColor: AppTheme.darkCardColor,
              dividerColor: AppTheme.darkBorderColor,
            ),
            initialRoute: initialRoute,
            getPages: AppPages.routes,
          );
        });
  }
}

Future<void> requestBluetoothPermissions() async {
  // Check if permissions are already granted
  Map<Permission, PermissionStatus> statuses = await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
  ].request();

  bool isGranted = statuses[Permission.bluetoothScan]!.isGranted &&
      statuses[Permission.bluetoothConnect]!.isGranted &&
      statuses[Permission.location]!.isGranted;

  if (!isGranted) {
    // Show informational dialog if not granted
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Bluetooth Permissions Required",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                "The application requires Bluetooth and Location access to:"),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.print, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                    child:
                        Text("Searching and connecting to thermal printers.")),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.receipt, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                    child: Text("Printing transaction receipts directly.")),
              ],
            ),
            const SizedBox(height: 16),
            Text(
                "Please grant permissions in the settings menu if the system dialog does not appear.",
                style: TextStyle(
                    fontSize: AppTheme.fontSizeLabelMedium,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("TUTUP", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child:
                const Text("PENGATURAN", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
