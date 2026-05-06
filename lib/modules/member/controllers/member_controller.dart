import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/models/member/member_model.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/core/services/sync_service.dart';
import 'package:semesta_pos/core/services/remote/api_service.dart';
import 'package:uuid/uuid.dart';
import 'package:semesta_pos/core/util/constans.dart';

class MemberController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isLoadingStore = false.obs;
  RxBool isFormView = false.obs;
  Rxn<MemberModel> selectedMember = Rxn<MemberModel>();

  final apiService = Get.put(ApiService());
  DatabaseService get _dbService => Get.find<DatabaseService>();

  RxList<MemberModel> memberModelList = <MemberModel>[].obs;
  RxList<MemberModel> filteredMemberList = <MemberModel>[].obs;
  RxString searchQuery = "".obs;

  TextEditingController namaMemberController = TextEditingController();
  TextEditingController teleponMemberController = TextEditingController();
  TextEditingController alamatMemberController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  
  RxInt currentPage = 1.obs;
  RxInt rowsPerPage = 10.obs;
  RxInt totalRows = 0.obs;

  RxList<MemberModel> paginatedList = <MemberModel>[].obs;
  RxList<Map<String, dynamic>> historyList = <Map<String, dynamic>>[].obs;
  RxString tempNama = "".obs;

  @override
  void onInit() {
    super.onInit();
    isFormView.value = false; // Reset view on each init attempt
    getMember();

    // Listen to controller changes for real-time reactivity in Profile Card
    namaMemberController.addListener(() {
      tempNama.value = namaMemberController.text;
    });
  }

  Future<void> refreshRemotePoints() async {
    isLoadingStore.value = true;
    try {
      final syncService = Get.find<SyncService>();
      await syncService.syncMembers();
      await getMember();
      
      // Update the points in the selected model if viewing detail
      if (selectedMember.value != null) {
        final updated = memberModelList.firstWhere(
            (m) => m.idMember == selectedMember.value!.idMember,
            orElse: () => selectedMember.value!);
        selectedMember.value = updated;
      }
      
      Get.snackbar('Success', 'Customer points updated from server',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          icon: const Icon(Icons.check_circle, color: Colors.green),
          colorText: Colors.black);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update latest points: $e',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          icon: const Icon(Icons.error, color: Colors.red));
    } finally {
      isLoadingStore.value = false;
    }
  }

  void updatePagination() {
    totalRows.value = filteredMemberList.length;
    final start = (currentPage.value - 1) * rowsPerPage.value;
    final end = (start + rowsPerPage.value).clamp(0, filteredMemberList.length);
    if (start >= filteredMemberList.length) {
      currentPage.value = 1;
      paginatedList.assignAll(filteredMemberList.take(rowsPerPage.value));
    } else {
      paginatedList.assignAll(filteredMemberList.sublist(
          start, end.clamp(0, filteredMemberList.length)));
    }
  }

  void changePage(int delta) {
    final maxPage = (totalRows.value / rowsPerPage.value).ceil();
    final newPage = (currentPage.value + delta).clamp(1, maxPage);
    if (newPage != currentPage.value) {
      currentPage.value = newPage;
      updatePagination();
    }
  }

  void filterMembers(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredMemberList.assignAll(memberModelList);
    } else {
      filteredMemberList.assignAll(memberModelList
          .where((member) =>
              (member.nama?.toLowerCase().contains(query.toLowerCase()) ??
                  false) ||
              (member.telepon?.toLowerCase().contains(query.toLowerCase()) ??
                  false))
          .toList());
    }
    currentPage.value = 1;
    updatePagination();
  }

  Future<void> getMember() async {
    isLoading.value = true;
    try {
      final List<Map<String, dynamic>> results =
          await _dbService.query('members');
      memberModelList.value =
          results.map((m) => MemberModel.fromJson(m)).toList();

      filterMembers(searchQuery.value);
      updatePagination();
      debugPrint(
          'Member list loaded from SQLite, count: ${memberModelList.length}');
    } catch (e) {
      Get.snackbar('Error', 'Failed to load local customer data',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          icon: const Icon(Icons.error, color: Colors.red));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> storeMember() async {
    final String idPosMember = const Uuid().v4();
    final Map<String, String> newMemberDataMap = {
      'nama': namaMemberController.text,
      'no_hp': teleponMemberController.text,
      'alamat': alamatMemberController.text,
      'id_pos': idPosMember,
    };

    isLoadingStore.value = true;
    try {
      // 1. Try immediate sync
      MemberModel? resolvedMember;
      bool syncedInstantly = false;

      try {
        final response = await apiService.storeMember(newMemberDataMap);
        if (response.responsestate == Constants.successState && response.data != null) {
          final List<MemberModel> members = response.data as List<MemberModel>;
          if (members.isNotEmpty) {
            resolvedMember = members.first;
            syncedInstantly = true;
          }
        }
      } catch (e) {
        debugPrint('MemberController: Immediate sync failed, falling back to background: $e');
      }

      int localId;
      if (syncedInstantly && resolvedMember != null) {
        localId = resolvedMember.idMember;
      } else {
        localId = -(DateTime.now().millisecondsSinceEpoch % 1000000000);
        resolvedMember = MemberModel(
          idMember: localId,
          idPos: idPosMember,
          nama: newMemberDataMap['nama'],
          telepon: newMemberDataMap['no_hp'],
          alamat: newMemberDataMap['alamat'],
        );
      }

      // 2. Save to local SQLite
      await _dbService.insert('members', {
        'id_member': resolvedMember.idMember,
        'id_pos': resolvedMember.idPos ?? idPosMember,
        'nama': resolvedMember.nama,
        'telepon': resolvedMember.telepon,
        'alamat': resolvedMember.alamat,
        'is_synced': syncedInstantly ? 1 : 0,
      });

      // 3. Enqueue Sync Command ONLY if not synced instantly
      if (!syncedInstantly) {
        final syncService = Get.find<SyncService>();
        await syncService.enqueueCommand(
          method: 'POST',
          endpoint: '/api/pos_customers/',
          isFormData: true,
          body: newMemberDataMap,
          localId: localId,
        );
      }

      // 4. Update UI
      await getMember();
      cleanField();
      isFormView.value = false;
      Get.snackbar('Success', 
          syncedInstantly ? 'Customer added successfully' : 'Customer added locally and syncing in background',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          icon: const Icon(Icons.check_circle, color: Colors.green));
    } catch (e) {
      Get.snackbar('Error', 'Failed to save customer: $e',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          icon: const Icon(Icons.error, color: Colors.red));
    } finally {
      isLoadingStore.value = false;
    }
  }

  void cleanField() {
    namaMemberController.clear();
    teleponMemberController.clear();
    alamatMemberController.clear();
    selectedMember.value = null;
    tempNama.value = "";
    historyList.clear();
  }

  Future validationStore() async {
    if (namaMemberController.text == '') {
      Get.snackbar('Error', 'Name cannot be empty',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          icon: const Icon(Icons.error, color: Colors.red));
      return;
    }

    if (teleponMemberController.text == '') {
      Get.snackbar('Error', 'Phone number cannot be empty',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          icon: const Icon(Icons.error, color: Colors.red));
      return;
    }

    if (alamatMemberController.text == '') {
      Get.snackbar('Error', 'Address cannot be empty',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          icon: const Icon(Icons.error, color: Colors.red));
      return;
    }

    // If there's a selected member, update it; otherwise create new
    if (selectedMember.value != null) {
      await updateMember();
    } else {
      await storeMember();
    }
  }

  Future<void> updateMember() async {
    final updatedData = {
      'nama': namaMemberController.text,
      'telepon': teleponMemberController.text,
      'alamat': alamatMemberController.text,
      'is_synced': 0,
    };

    final id = selectedMember.value!.idMember;
    isLoadingStore.value = true;
    try {
      // 1. Update local SQLite
      await _dbService.update('members', updatedData, 'id_member = ?', [id]);

      // 2. Enqueue Sync Command
      final syncService = Get.find<SyncService>();
      await syncService.enqueueCommand(
        method: 'PUT',
        endpoint: '/api/pos_customers/$id',
        body: {
          'nama': updatedData['nama'],
          'no_hp': updatedData['telepon'],
          'alamat': updatedData['alamat'],
        },
        localId: id,
      );

      // 3. Update UI
      await getMember();
      cleanField();
      isFormView.value = false;
      Get.snackbar(
          'Success', 'Customer data updated locally and syncing',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          icon: const Icon(Icons.check_circle, color: Colors.green));
    } catch (e) {
      Get.snackbar('Error', 'Failed to update customer: $e',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          icon: const Icon(Icons.error, color: Colors.red));
    } finally {
      isLoadingStore.value = false;
    }
  }

  Future<void> destroyMember(int memberId, int position) async {
    if (memberId < 0) {
      // Handle local-only placeholder deletion
      isLoadingStore.value = true;
      try {
        await _dbService.delete('members', 'id_member = ?', [memberId]);
        memberModelList.removeAt(position);
        memberModelList.refresh();
        Get.snackbar('Success', 'Local data deleted successfully',
            backgroundColor: Colors.green.withValues(alpha: 0.1),
            icon: const Icon(Icons.check_circle, color: Colors.green));
      } catch (e) {
        Get.snackbar('Error', 'Failed to delete local data: $e',
            backgroundColor: Colors.red.withValues(alpha: 0.1),
            icon: const Icon(Icons.error, color: Colors.red));
      } finally {
        isLoadingStore.value = false;
      }
      return;
    }

    isLoadingStore.value = true;
    try {
      // 1. Delete from local SQLite
      await _dbService.delete('members', 'id_member = ?', [memberId]);

      // 2. Enqueue Sync Command
      final syncService = Get.find<SyncService>();
      await syncService.enqueueCommand(
        method: 'DELETE',
        endpoint: '/api/pos_customers/$memberId',
      );

      // 3. Update UI
      memberModelList.removeAt(position);
      memberModelList.refresh();
      Get.snackbar('Success', 'Customer deleted locally and syncing',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          icon: const Icon(Icons.check_circle, color: Colors.green));
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete customer: $e',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          icon: const Icon(Icons.error, color: Colors.red));
    } finally {
      isLoadingStore.value = false;
    }
  }

  Future<void> fetchHistory(int memberId) async {
    try {
      final results = await _dbService.query(
        'transactions',
        where: 'id_member = ?',
        whereArgs: [memberId],
        orderBy: 'tgl_penjualan DESC',
        limit: 10,
      );
      historyList.assignAll(results);
    } catch (e) {
      debugPrint("MemberController: Error fetching history: $e");
    }
  }
}
