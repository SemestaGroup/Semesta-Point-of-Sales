import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:semesta_pos/core/models/shared_user_model.dart';
import 'package:semesta_pos/core/models/user/client_model.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/core/util/constans.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService extends GetxService {
  late SharedPreferences _sharedPreferences;
  DatabaseService get _dbService => Get.find<DatabaseService>();

  RxBool isLoading = true.obs;
  RxBool isLoggedIn = false.obs;

  Future<UserService> initSharedPref() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    isLoggedIn.value = getPrefBool(Constants.isLogin);
    return this;
  }

  Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? id;
    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        id = "WEB-${webInfo.vendor}-${webInfo.platform}-${webInfo.userAgent.hashCode}";
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        id = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        id = iosInfo.identifierForVendor;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        id = windowsInfo.deviceId;
      }
    } catch (e) {
      debugPrint('UserService: Error getting hardware device ID: $e');
    }

    if (id == null || id.isEmpty || id == 'unknown') {
      id = getPrefString('permanent_device_id');
      if (id == 'Guest' || id.isEmpty) {
        id = "GEN-${const Uuid().v4()}";
        await saveString('permanent_device_id', id);
      }
    }
    return id;
  }

  Future<SharedUserModel> getSharedUserModel() async {
    isLoading.value = false;

    String roleStr = getPrefString(Constants.role);
    // Legacy support for numeric roles stored as strings after migration
    if (roleStr == "1") roleStr = "owner";
    if (roleStr == "2") roleStr = "cashier";

    return SharedUserModel(
        userName: getPrefString(Constants.userName),
        isLogin: getPrefBool(Constants.isLogin),
        userId: getPrefInt(Constants.userId),
        role: roleStr,
        email: getPrefString(Constants.userEmail),
        baseUrl: getPrefString(Constants.baseUrl),
        authToken: getPrefString(Constants.authToken));
  }

  String getPrefString(String key) {
    try {
      final value = _sharedPreferences.get(key);
      if (value == null) return 'Guest';
      return value.toString();
    } catch (e) {
      debugPrint('UserService: Error getting pref string for $key: $e');
      return 'Guest';
    }
  }

  int getPrefInt(String key) {
    return _sharedPreferences.getInt(key) ?? 0;
  }

  String getUserName() => getPrefString(Constants.userName);

  bool getPrefBool(String key) {
    return _sharedPreferences.getBool(key) ?? false;
  }

  Future<void> saveString(String key, String value) async {
    await _sharedPreferences.setString(key, value);
  }

  Future<void> saveBool(String key, bool value) async {
    await _sharedPreferences.setBool(key, value);
  }

  Future<void> saveInt(String key, int value) async {
    await _sharedPreferences.setInt(key, value);
  }

  Future<void> saveUserInfo(ClientModel clientModel) async {
    isLoading.value = false;
    isLoggedIn.value = true;
    await saveBool(Constants.isLogin, true);
    await saveInt(Constants.userId, clientModel.userId);
    await saveString(Constants.userName, clientModel.name);
    await saveString(Constants.userEmail, clientModel.email);
    await saveString(Constants.role, clientModel.role);
    await saveString(Constants.baseUrl, clientModel.baseUrl);
    await saveString(Constants.authToken, clientModel.authToken);
  }

  Future<void> saveAuthData(String baseUrl, String authToken) async {
    debugPrint('UserService: Saving BaseURL: $baseUrl');
    debugPrint('UserService: Saving AuthToken: $authToken');
    await saveString(Constants.baseUrl, baseUrl);
    await saveString(Constants.authToken, authToken);
  }

  Future<void> saveUserSession(Map<String, dynamic> authData) async {
    final deviceId = await getDeviceId();
    await _dbService.clearTable('user_session');
    await _dbService.insert('user_session', {
      'id': 1,
      'staff': authData['staff'],
      'email': authData['email'],
      'location': authData['location'],
      'base_url': authData['base_url'],
      'auth_token': Constants.staticAuthToken,
      'device_id': deviceId,
    });
  }

  Future<Map<String, dynamic>?> getUserSession() async {
    final results = await _dbService.query('user_session', where: 'id = ?', whereArgs: [1]);
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<void> clearUserSession() async {
    await _dbService.clearTable('user_session');
  }

  String getBaseUrl() {
    String url = getPrefString(Constants.baseUrl);
    if (url == 'Guest' || url.isEmpty) return url;
    
    // Normalize: ensure trailing slash
    if (!url.endsWith('/')) url += '/';
    
    return url;
  }

  String getAuthToken() {
    final token = getPrefString(Constants.authToken);
    debugPrint('UserService: Retrieved AuthToken: $token');
    return token;
  }

  Future destroySession() async {
    isLoggedIn.value = false;
    await _sharedPreferences.clear();
    await clearUserSession();
  }

  String getRole() {
    String roleStr = getPrefString(Constants.role);
    // Legacy support for numeric roles stored as strings after migration
    if (roleStr == "1") return "owner";
    if (roleStr == "2") return "cashier";
    return roleStr;
  }

  bool isManagerialRole() {
    final role = getRole().toLowerCase();
    return role == 'owner' || role == 'supervisor';
  }

  bool isKitchenRole() {
    return getRole().toLowerCase() == 'kitchen';
  }

  bool isCashierRole() {
    final role = getRole().toLowerCase();
    return role == 'cashier' || role == 'owner' || role == 'supervisor';
  }

  String getUserEmail() => getPrefString(Constants.userEmail);
}
