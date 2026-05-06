import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/models/api/response_api_model.dart';
import 'package:semesta_pos/core/models/user/client_model.dart';
import 'package:semesta_pos/core/services/remote/api_service.dart';
import 'package:semesta_pos/core/services/user_service.dart';
import 'package:semesta_pos/core/util/constans.dart';

class EmployeeProfileController extends GetxController {
  RxBool isLoading = true.obs;
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  final userService = Get.put(UserService());
  final apiService = Get.put(ApiService());
  Rx<ClientModel> clientModel = ClientModel().obs;
  RxString email = "".obs;
  RxBool isLoadingUpdateData = false.obs;

  @override
  void onInit() {
    getProfile();
    super.onInit();
  }

  Future<void> inputValidation() async {
    if (nameController.text.isEmpty) {
      Get.snackbar('Gagal', 'Nama tidak boleh kosong');
      return;
    }

    await updateProfile();
  }

  String _capitalizeName(String name) {
    if (name.isEmpty) return "";
    return name.split(' ').map((word) {
      if (word.isEmpty) return "";
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Future<void> getProfile() async {
    isLoading.value = true;
    try {
      // 1. Try to load from Local SQLite first (User Session)
      final session = await userService.getUserSession();
      if (session != null) {
        debugPrint("EmployeeProfileController: Loading session from SQLite");
        final String rawName = session['staff'] ?? 'User';
        final String capitalizedName = _capitalizeName(rawName);
        final String userEmail = session['email'] ?? '';

        final localProfile = ClientModel(
          userId: int.tryParse(session['location']?.toString() ?? '0') ?? 0,
          name: capitalizedName,
          role: 'cashier',
          baseUrl: session['base_url'] ?? '',
          authToken: session['auth_token'] ?? '',
        );
        clientModel.value = localProfile;
        nameController.text = capitalizedName;
        emailController.text = userEmail;
        email.value = userEmail;

        // If we found local data, we can stop loading early while we refresh in background
        isLoading.value = false;
      }

      // 2. Refresh/Fetch from API
      int userId = userService.getPrefInt(Constants.userId);
      ResponseApiModel responseApiModel = await apiService.getProfile(userId);

      if (responseApiModel.responsestate == Constants.successState &&
          responseApiModel.data != null) {
        final ClientModel clientModels =
            ClientModel.fromJson(responseApiModel.data);
        final String capitalizedName = _capitalizeName(clientModels.name);

        clientModel.value = clientModels.copyWith(name: capitalizedName);
        nameController.text = capitalizedName;

        // Also update local session if name changed
        if (session != null && session['staff'] != clientModels.name) {
          await userService.saveUserSession({
            'staff': clientModels.name,
            'email': clientModels.email.isNotEmpty
                ? clientModels.email
                : session['email'],
            'location': session['location'],
            'base_url': session['base_url'],
          });
        }
      } else if (session == null) {
        // Only show error if we have NO local data at all
        Get.snackbar("Error", responseApiModel.message ?? 'Terjadi kesalahan');
      }
    } catch (e) {
      debugPrint("EmployeeProfileController: getProfile Error: $e");
      // If we have local data, don't show an intrusive error for connectivity
      if (await userService.getUserSession() == null) {
        if (e is SocketException) {
          Get.snackbar('Koneksi Terputus', 'Gagal memuat profil dari server.');
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile() async {
    isLoadingUpdateData.value = true;
    try {
      int userId = userService.getPrefInt(Constants.userId);

      if (userId != 0) {
        Map<String, dynamic> map = {};
        map['name'] = nameController.text;
        map['user_id'] = userId.toString();

        // update profile
        final responseApi = await apiService.updateProfile(map, userId);

        if (responseApi.responsestate == Constants.successState) {
          final capitalizedName = _capitalizeName(nameController.text);
          nameController.text = capitalizedName;

          await userService.saveString(Constants.userName, capitalizedName);

          // UPDATE SQLITE SESSION
          final session = await userService.getUserSession();
          if (session != null) {
            await userService.saveUserSession({
              'staff': capitalizedName,
              'email': session['email'],
              'location': session['location'],
              'base_url': session['base_url'],
            });
          }

          Get.snackbar("Berhasil", responseApi.message.toString());
        } else {
          Get.snackbar("Error", responseApi.message.toString());
        }
      } else {
        Get.snackbar('Error', 'User tidak ditemukan');
      }
    } catch (e) {
      debugPrint("EmployeeProfileController: updateProfile Error: $e");
      if (e is SocketException) {
        Get.snackbar(
            'Error', 'Gagal memperbarui profil: Tidak ada koneksi internet.');
      } else {
        Get.snackbar('Error', 'Terjadi kesalahan sistem: $e');
      }
    } finally {
      isLoadingUpdateData.value = false;
    }
  }
}
