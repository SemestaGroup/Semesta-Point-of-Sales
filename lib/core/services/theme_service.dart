import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends GetxService {
  late SharedPreferences _prefs;
  final _key = 'isDarkMode';

  RxBool isDarkMode = false.obs;

  Future<ThemeService> init() async {
    _prefs = await SharedPreferences.getInstance();
    isDarkMode.value = _prefs.getBool(_key) ?? false;
    return this;
  }

  ThemeMode get theme => isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  void switchTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    _prefs.setBool(_key, isDarkMode.value);
  }

  void setTheme(bool dark) {
    if (isDarkMode.value == dark) return;
    isDarkMode.value = dark;
    Get.changeThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
    _prefs.setBool(_key, dark);
  }
}
