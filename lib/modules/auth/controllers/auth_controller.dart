import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/models/api/response_api_model.dart';
import 'package:semesta_pos/core/models/staff/staff_model.dart';
import 'package:semesta_pos/core/models/user/client_model.dart';
import 'package:semesta_pos/core/services/app_service.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/core/services/remote/api_service.dart';
import 'package:semesta_pos/core/services/user_service.dart';
import 'package:semesta_pos/core/util/constans.dart';
import 'package:semesta_pos/routes/app_pages.dart';
import 'package:sqflite/sqflite.dart';

class AuthController extends GetxController {
  TextEditingController emailController = TextEditingController();
  TextEditingController pwController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  RxBool isLoading = false.obs;
  RxBool isAddingStaff = false.obs;
  RxList<StaffModel> staffList = <StaffModel>[].obs;
  RxList<StaffModel> filteredStaff = <StaffModel>[].obs;
  ApiService get apiService {
    if (!Get.isRegistered<ApiService>()) {
      Get.put(ApiService(), permanent: true);
    }
    return Get.find<ApiService>();
  }

  UserService get userService {
    if (!Get.isRegistered<UserService>()) {
      Get.put(UserService(), permanent: true);
    }
    return Get.find<UserService>();
  }

  DatabaseService get _dbService {
    if (!Get.isRegistered<DatabaseService>()) {
      Get.put(DatabaseService(), permanent: true);
    }
    return Get.find<DatabaseService>();
  }

  @override
  void onInit() {
    super.onInit();
    debugPrint('AuthController: onInit called');
    searchController.addListener(_onSearchChanged);
  }

  @override
  void onReady() {
    super.onReady();
    debugPrint("AuthController: Controller is READY, triggering staff fetch...");
    fetchLocalStaff();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void _onSearchChanged() {
    String query = searchController.text.toLowerCase();
    if (query.isEmpty) {
      filteredStaff.assignAll(staffList);
    } else {
      filteredStaff.assignAll(staffList.where((s) {
        return s.fullName.toLowerCase().contains(query) ||
            (s.role?.toLowerCase().contains(query) ?? false);
      }).toList());
    }
  }

  Future<void> fetchLocalStaff() async {
    try {
      debugPrint("AuthController: Fetching staff list from local DB...");
      final results =
          await _dbService.query('staff', where: 'active = ?', whereArgs: ["1"])
          .timeout(const Duration(seconds: 5), onTimeout: () {
            debugPrint("AuthController TIMEOUT: Database query for staff took too long (> 5s)");
            return [];
          });
      debugPrint("AuthController: Found ${results.length} staff members");
      staffList.assignAll(results.map((e) => StaffModel.fromJson(e)).toList());
      filteredStaff.assignAll(staffList);
      debugPrint("AuthController: Staff list updated successfully");
    } catch (e) {
      debugPrint("AuthController Error: Failed to fetch staff: $e");
    }
  }

  void validateLogin() {
    if (emailController.text.isEmpty || pwController.text.isEmpty) {
      Get.snackbar("Login Failed", "All fields required!");
      return;
    }
    login();
  }

  Future<void> login() async {
    isLoading.value = true;
    
    final rawEmail = emailController.text;
    final trimmedEmail = rawEmail.trim();
    final trimmedPassword = pwController.text.trim();
    
    debugPrint('AuthController: Raw email: "$rawEmail" (length: ${rawEmail.length})');
    debugPrint('AuthController: Trimmed email: "$trimmedEmail"');
    
    final Map<String, String> data = {
      'email': trimmedEmail,
      'password': trimmedPassword,
    };

    ResponseApiModel responseApiModel;
    try {
      debugPrint('AuthController: Sending login request...');
      responseApiModel = await apiService.login(data);
      debugPrint('AuthController: Login response received: ${responseApiModel.responsestate}');
    } catch (e) {
      debugPrint('AuthController Login Request Crash: $e');
      isLoading.value = false;
      Get.snackbar("Error", "Gagal menghubungi server. Periksa koneksi internet Anda.");
      return;
    }

    if (responseApiModel.responsestate == Constants.successState &&
        responseApiModel.data != null) {
      try {
        final Map<String, dynamic> authData = responseApiModel.data;
        debugPrint('AuthController: Processing success data...');

        await userService.initSharedPref();

        // Save the critical auth data to SharedPreferences for core service lookups
        await userService.saveAuthData(
            authData['base_url'], Constants.staticAuthToken);
        
        // PERSIST FULL SESSION TO SQLITE for offline profile and cashier name
        await userService.saveUserSession(authData);

        // Save password for access code checks
        await userService.saveString('cached_password', trimmedPassword);
        
        // Refresh App Settings will be handled by the /sync page sequence
        debugPrint('AuthController: Session saved. Transitioning to sync...');

        // Fetch Staff and update local DB
        debugPrint('AuthController: Fetching remote staff list...');
        final staffResponse = await apiService.getStaff();
        if (staffResponse.responsestate == Constants.successState && staffResponse.data != null) {
          final List<StaffModel> remoteStaffList = staffResponse.data;
          debugPrint('AuthController: Syncing ${remoteStaffList.length} staff to local DB using transaction');
          
          await _dbService.transaction((txn) async {
            // Clear within transaction
            await txn.delete('staff'); 
            
            for (var staff in remoteStaffList) {
              await txn.insert('staff', staff.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
            }
          });
          debugPrint('AuthController: Staff sync completed');
        }
        
        debugPrint('AuthController: Login process completed. Navigating to selection...');
        isLoading.value = false;

        // Redirect to Sync page FIRST
        Get.offAllNamed(Routes.sync);
        
        // Show success msg AFTER navigation starts to avoid race condition with UI build
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.snackbar("Success", "Synchronizing data...");
        });
      } catch (e) {
        debugPrint('AuthController Success Path Crash: $e');
        isLoading.value = false;
        Get.snackbar("Error", "Terjadi kesalahan saat memproses data.");
      }
      return;
    } else {
      debugPrint('AuthController: Login failed with message: ${responseApiModel.message}');
      isLoading.value = false;

      Get.snackbar("Error", responseApiModel.message?.toString() ?? "Login gagal");
      return;
    }
  }

  Future<void> completeStaffLogin(StaffModel staff) async {
    isLoading.value = true;
    try {
      // Get current session data
      final session = await userService.getUserSession();
      if (session == null) {
        Get.snackbar('Error', 'Sesi lokasi tidak ditemukan. Mohon login ulang.');
        Get.offAllNamed(Routes.login);
        return;
      }

      // Update UserService with staff info (Legacy Compat)
      await userService.saveUserInfo(ClientModel(
        userId: int.tryParse(session['location']?.toString() ?? '0') ?? 0,
        name: staff.fullName,
        email: staff.email ?? '',
        role: staff.role?.toLowerCase() ?? 'cashier',
        baseUrl: session['base_url'],
        authToken: Constants.staticAuthToken,
      ));

      // 💥 CRUCIAL: Update SQLite User Session to reflect SELECTED STAFF, not just the root merchant
      await userService.saveUserSession({
        'staff': staff.fullName,
        'email': staff.email ?? '',
        'location': session['location'],
        'base_url': session['base_url'],
      });

      // Update pos_options with pos_active_staff (not pos_active_session which is for Shifts)
      if (Get.isRegistered<AppService>()) {
        final appService = Get.find<AppService>();
        await appService.saveSettingsLocally({'pos_active_staff': staff.fullName});
        
        // Try syncing this option to backend
        try {
          await apiService.updatePosOptions({'pos_active_staff': staff.fullName});
        } catch (_) {}
        
        await appService.fetchAppData();
      }

      // Add a flag to indicate an active staff session
      await userService.saveBool('has_active_staff', true);

      isLoading.value = false;
      Get.snackbar("Berhasil", "Selamat bekerja, ${staff.fullName}!");

      // Since sync is already done during initial login/boot, go straight to dashboard
      if (staff.role?.toLowerCase() == 'owner' || staff.role?.toLowerCase() == 'supervisor') {
        Get.offAllNamed(Routes.dashboardAdmin);
      } else {
        Get.offAllNamed(Routes.dashboardEmployee);
      }
    } catch (e) {
      isLoading.value = false;
      debugPrint('Error completing staff login: $e');
      Get.snackbar('Error', 'Gagal memproses login pengguna');
    }
  }

  Future<void> changeUser() async {
    // We do NOT clear the session here. 
    // This allows the user to press the 'Back' button on the Staff Selection screen 
    // to cancel switching staff and return to their active dashboard.
    Get.toNamed(Routes.staffSelection);
  }

  Future<void> refreshStaff() async {
    try {
      final staffResponse = await apiService.getStaff();
      if (staffResponse.responsestate == 'success' && staffResponse.data != null) {
        final List<StaffModel> remoteStaffList = staffResponse.data;
        await _dbService.transaction((txn) async {
          await txn.delete('staff');
          for (var staff in remoteStaffList) {
            final staffId = staff.id != null ? int.tryParse(staff.id.toString()) : null;
            final row = <String, dynamic>{
              'firstname': staff.firstname ?? '',
              'lastname': staff.lastname ?? '',
              'email': staff.email ?? '',
              'phonenumber': staff.phonenumber ?? '',
              'role': staff.role ?? '',
              'active': staff.active ?? '1',
              'password': staff.password ?? '',
              'pin': staff.pin ?? '',
            };
            if (staffId != null && staffId > 0) row['id'] = staffId;
            await txn.insert('staff', row, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        });
        await fetchLocalStaff();
        Get.snackbar('Staff Diperbarui', '${remoteStaffList.length} staff berhasil disinkronkan.',
            backgroundColor: Colors.green.shade600, colorText: Colors.white,
            duration: const Duration(seconds: 2));
      }
    } catch (e) {
      debugPrint('AuthController refreshStaff error: $e');
    }
  }

  Future<void> addStaff({
    required String firstname,
    String? lastname,
    required String roleId, // "1"=Owner,"2"=Cashier,"3"=Kitchen,"4"=Supervisor
    String pin = '0000',
  }) async {
    isAddingStaff.value = true;
    try {
      final sanitizedFirst = firstname.trim();
      final sanitizedLast = (lastname?.trim().isEmpty ?? true) ? '-' : lastname!.trim();
      final email = '${sanitizedFirst.toLowerCase().replaceAll(' ', '_')}.notreal@email.com';

      final body = {
        'firstname': sanitizedFirst,
        'lastname': sanitizedLast,
        'email': email,
        'password': '12345678',
        'pin': pin,
        'admin': 0,
        'role': int.tryParse(roleId) ?? 2,
      };

      final response = await apiService.createStaff(body);
      if (response.responsestate == 'success') {
        Get.snackbar('Staff Ditambahkan', 'Staff "$sanitizedFirst" berhasil dibuat.',
            backgroundColor: Colors.green.shade600, colorText: Colors.white,
            duration: const Duration(seconds: 3));
        // Sync local DB with updated list from server
        await refreshStaff();
      } else {
        Get.snackbar('Gagal', response.message ?? 'Gagal menambahkan staff.',
            backgroundColor: Colors.red.shade600, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint('AuthController addStaff error: $e');
      Get.snackbar('Error', 'Terjadi kesalahan: $e',
          backgroundColor: Colors.red.shade600, colorText: Colors.white);
    } finally {
      isAddingStaff.value = false;
    }
  }

  Future<void> logoutLocation() async {
    final role = userService.getRole().toLowerCase();
    if (role != 'owner') {
      Get.snackbar(
        'Akses Ditolak',
        'Hanya Owner yang dapat keluar dari sesi lokasi ini.',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Keluar dari Lokasi'),
        content: const Text('Apakah Anda yakin ingin keluar dan kembali ke layar login? Seluruh sesi dan data offline akan dihapus bersih.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Tutup dialog konfirmasi
              
              // Tampilkan dialog loading yang tidak bisa ditutup
              Get.dialog(
                const PopScope(
                  canPop: false,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                barrierDismissible: false,
              );

              try {
                // Hapus seluruh session, cache, dan database SQLite
                await userService.destroySession();
                await _dbService.deleteDatabaseFile();

                // Berikan jeda sebentar untuk memastikan pembersihan selesai
                await Future.delayed(const Duration(milliseconds: 500));

                // Kembali ke layar login
                // Jika MainApp sudah re-build karena isLoggedIn berubah, 
                // pemanggilan ini akan memastikan kita berada di halaman login.
                Get.offAllNamed(Routes.login);
              } catch (e) {
                debugPrint('Logout Error: $e');
                Get.offAllNamed(Routes.login);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluar & Hapus Data', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
