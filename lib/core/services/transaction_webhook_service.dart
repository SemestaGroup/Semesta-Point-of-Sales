import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:semesta_pos/core/services/error_log_service.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/core/services/user_service.dart';
import 'package:semesta_pos/core/util/constans.dart';
import 'package:semesta_pos/modules/home/employee/controllers/shift_controller.dart';
import 'package:uuid/uuid.dart';

class TransactionWebhookService extends GetxService {
  DatabaseService get _dbService => Get.find<DatabaseService>();
  UserService get _userService => Get.find<UserService>();

  Future<void> sendOrderEvent({
    required int localTransactionId,
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final url = await _getWebhookUrl();
      if (url.isEmpty) return;

      final order = await _buildOrderSnapshotById(localTransactionId);
      if (order == null) return;

      final payload = await _buildBasePayload(
        eventType: 'order',
        action: action,
        metadata: metadata,
      );
      payload['order'] = order;

      await _postWebhook(url, payload);
    } catch (e) {
      debugPrint('TransactionWebhookService: sendOrderEvent failed: $e');
    }
  }

  Future<void> sendPaymentEvent({
    required int localPaymentId,
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final url = await _getWebhookUrl();
      if (url.isEmpty) return;

      final paymentPayload = await _buildPaymentSnapshotById(localPaymentId);
      if (paymentPayload == null) return;

      final payload = await _buildBasePayload(
        eventType: 'payment',
        action: action,
        metadata: metadata,
      );
      payload['payment'] = paymentPayload['payment'];

      final linkedOrder = paymentPayload['order'];
      if (linkedOrder is Map<String, dynamic>) {
        payload['order'] = linkedOrder;
      }

      await _postWebhook(url, payload);
    } catch (e) {
      debugPrint('TransactionWebhookService: sendPaymentEvent failed: $e');
    }
  }

  Future<String> _getWebhookUrl() async {
    final rows = await _dbService.query(
      'pos_options',
      where: 'option_name = ?',
      whereArgs: [Constants.posTransactionWebhookUrl],
      limit: 1,
    );

    if (rows.isEmpty) return '';

    final rawUrl = rows.first['option_value']?.toString().trim() ?? '';
    if (rawUrl.isEmpty || rawUrl == 'null' || rawUrl == 'Guest') return '';

    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }

    return 'https://$rawUrl';
  }

  Future<Map<String, dynamic>> _buildBasePayload({
    required String eventType,
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    final session = await _userService.getUserSession();

    return {
      'schema_version': 1,
      'event_id': const Uuid().v4(),
      'event_type': eventType,
      'action': action,
      'triggered_at': DateTime.now().toIso8601String(),
      'source': {
        'app': 'pos_app_new',
        'platform': Platform.operatingSystem,
        'base_url': _sanitizeString(
          session?['base_url']?.toString() ?? _userService.getBaseUrl(),
        ),
        'device_id': _sanitizeString(
          session?['device_id']?.toString() ??
              _userService.getPrefString('permanent_device_id'),
        ),
        'location': _sanitizeString(session?['location']?.toString() ?? ''),
        'company_name': _sanitizeString(
          _userService.getPrefString(Constants.posCompanyName),
        ),
        'company_address': _sanitizeString(
          _userService.getPrefString(Constants.posAddress),
        ),
        'company_phone': _sanitizeString(
          _userService.getPrefString(Constants.posPhoneNumber),
        ),
        'user_id': _userService.getPrefInt(Constants.userId),
        'user_name': _sanitizeString(_userService.getUserName()),
        'user_email': _sanitizeString(_userService.getUserEmail()),
        'role': _sanitizeString(_userService.getRole()),
      },
      if (metadata != null && metadata.isNotEmpty) 'meta': metadata,
    };
  }

  Future<Map<String, dynamic>?> _buildOrderSnapshotById(
      int localTransactionId) async {
    final rows = await _dbService.query(
      'transactions',
      where: 'id_penjualan = ?',
      whereArgs: [localTransactionId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    return _buildOrderSnapshot(rows.first);
  }

  Future<Map<String, dynamic>> _buildOrderSnapshot(
      Map<String, dynamic> txRow) async {
    final localId = _toInt(txRow['id_penjualan']);
    final remoteId = _toNullableInt(txRow['id_penjualan_remote']);
    final idPos = txRow['id_pos']?.toString() ?? '';
    final statusId = _toInt(txRow['status']);

    final member = await _buildMemberSnapshot(_toInt(txRow['id_member']));
    final cashier = await _buildCashierSnapshot(_toInt(txRow['id_user']));
    final shift = await _buildShiftSnapshot(_toInt(txRow['id_shift']));

    final detailRows = await _dbService.query(
      'transaction_details',
      where: 'id_penjualan = ?',
      whereArgs: [localId],
      orderBy: 'id_penjualan_detail ASC',
    );

    final paymentModeMap = await _loadPaymentModeMap();
    final paymentRows = await _loadPaymentsForTransaction(
      idPos: idPos,
      remoteId: remoteId?.toString() ?? '',
    );

    int refundCount = 0;
    int refundTotal = 0;
    final items = detailRows.map((item) {
      final isRefund = _isRefundFlag(item['is_refund']);
      if (isRefund) {
        refundCount++;
        refundTotal += _toInt(item['subtotal']);
      }

      return {
        'local_id': _toInt(item['id_penjualan_detail']),
        'product_id': _toInt(item['id_produk']),
        'product_name': item['product_name']?.toString() ?? '',
        'description': item['description']?.toString() ?? '',
        'qty': _toInt(item['jumlah']),
        'price': _toInt(item['harga_jual']),
        'subtotal': _toInt(item['subtotal']),
        'note': item['note']?.toString() ?? '',
        'order_type': item['order_type']?.toString() ?? '',
        'order_types_json': item['orderTypesJson']?.toString() ?? '',
        'remote_item_id': _toNullableInt(item['remote_item_id']),
        'discount_total': _toInt(item['discountTotal']),
        'discount_type': item['discountType']?.toString() ?? 'percent',
        'is_refund': isRefund,
      };
    }).toList();

    final payments = paymentRows
        .map((payment) => _mapPaymentRow(payment, paymentModeMap))
        .toList();

    final isFullyRefunded = items.isNotEmpty && refundCount == items.length;
    final hasRefundItems = refundCount > 0;

    return {
      'local_id': localId,
      'remote_id': remoteId,
      'id_pos': idPos,
      'remote_number': txRow['remote_number']?.toString() ?? '',
      'queue_number': _toInt(txRow['queue_number']),
      'status_id': statusId,
      'status_label': _resolveOrderStatusLabel(
        statusId,
        hasRefundItems: hasRefundItems,
        isFullyRefunded: isFullyRefunded,
      ),
      'flags': {
        'is_void': statusId == 5,
        'is_paid': statusId == 2 || statusId == 3,
        'has_refund_items': hasRefundItems,
        'is_fully_refunded': isFullyRefunded,
      },
      'timestamps': {
        'created_at': txRow['tgl_penjualan']?.toString() ?? '',
        'paid_at': txRow['tgl_bayar']?.toString() ?? '',
      },
      'order_type': txRow['order_type']?.toString() ?? '',
      'order_note': txRow['order_note']?.toString() ?? '',
      'label': txRow['label']?.toString() ?? '',
      'cashier': cashier,
      'member': member,
      'shift': shift,
      'totals': {
        'item_count': _toInt(txRow['total_item']),
        'subtotal': _toInt(txRow['total_harga']),
        'discount': _toInt(txRow['diskon']),
        'grand_total': _toInt(txRow['bayar']),
        'received_total': _toInt(txRow['diterima']),
        'manual_discount_value': _toInt(txRow['manual_discount_value']),
        'discount_type': txRow['discount_type']?.toString() ?? 'percent',
        'refund_total': refundTotal,
        'awarded_points': _toInt(txRow['awarded_points']),
      },
      'items': items,
      'payments': payments,
    };
  }

  Future<Map<String, dynamic>?> _buildPaymentSnapshotById(
      int localPaymentId) async {
    final rows = await _dbService.query(
      'pos_payments',
      where: 'id = ?',
      whereArgs: [localPaymentId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final paymentRow = rows.first;
    final paymentModeMap = await _loadPaymentModeMap();

    Map<String, dynamic>? order;
    final linkedOrderRows = await _loadLinkedOrderForPayment(paymentRow);
    if (linkedOrderRows.isNotEmpty) {
      order = await _buildOrderSnapshot(linkedOrderRows.first);
    }

    return {
      'payment': _mapPaymentRow(paymentRow, paymentModeMap),
      if (order != null) 'order': order,
    };
  }

  Future<Map<String, dynamic>?> _buildMemberSnapshot(int memberId) async {
    if (memberId <= 0) return null;

    final rows = await _dbService.query(
      'members',
      where: 'id_member = ?',
      whereArgs: [memberId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return {
        'id': memberId,
      };
    }

    final row = rows.first;
    return {
      'id': _toInt(row['id_member']),
      'id_pos': row['id_pos']?.toString() ?? '',
      'name': row['nama']?.toString() ?? '',
      'phone': row['telepon']?.toString() ?? '',
      'address': row['alamat']?.toString() ?? '',
      'email': row['email']?.toString() ?? '',
      'points': _toInt(row['points']),
      'datecreated': row['datecreated']?.toString() ?? '',
    };
  }

  Future<Map<String, dynamic>?> _buildCashierSnapshot(int userId) async {
    if (userId <= 0) {
      return {
        'id': 0,
        'name': _sanitizeString(_userService.getUserName()),
      };
    }

    final rows = await _dbService.query(
      'staff',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return {
        'id': userId,
        'name': _sanitizeString(_userService.getUserName()),
      };
    }

    final row = rows.first;
    final firstName = row['firstname']?.toString() ?? '';
    final lastName = row['lastname']?.toString() ?? '';

    return {
      'id': _toInt(row['id']),
      'name': '$firstName $lastName'.trim(),
      'email': row['email']?.toString() ?? '',
      'phone': row['phonenumber']?.toString() ?? '',
      'role': row['role']?.toString() ?? '',
    };
  }

  Future<Map<String, dynamic>?> _buildShiftSnapshot(int idShift) async {
    if (idShift > 0) {
      final rows = await _dbService.query(
        'shift_sessions',
        where: 'id_shift = ?',
        whereArgs: [idShift],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        final row = rows.first;
        return {
          'id_shift': _toInt(row['id_shift']),
          'shift_name': row['shift_name']?.toString() ?? '',
          'user_id': row['user_id']?.toString() ?? '',
          'start_time': row['start_time']?.toString() ?? '',
          'end_time': row['end_time']?.toString() ?? '',
          'status': _toInt(row['status']),
        };
      }
    }

    if (Get.isRegistered<ShiftController>()) {
      final activeShift = Get.find<ShiftController>().activeShift.value;
      if (activeShift != null) {
        return {
          'id_shift': activeShift.idShift,
          'shift_name': activeShift.shiftName,
          'user_id': activeShift.userId,
          'start_time': activeShift.startTime.toIso8601String(),
          'end_time': activeShift.endTime?.toIso8601String() ?? '',
          'status': activeShift.status,
        };
      }
    }

    return null;
  }

  Future<Map<String, String>> _loadPaymentModeMap() async {
    final rows = await _dbService.query('payment_modes');
    final map = <String, String>{};
    for (final row in rows) {
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      map[id] = row['name']?.toString() ?? id;
    }
    return map;
  }

  Future<List<Map<String, dynamic>>> _loadPaymentsForTransaction({
    required String idPos,
    required String remoteId,
  }) async {
    String where = '0 = 1';
    final args = <dynamic>[];

    if (idPos.isNotEmpty) {
      where += ' OR id_pos = ?';
      args.add(idPos);
    }

    if (remoteId.isNotEmpty && remoteId != '0') {
      where += ' OR invoiceid = ?';
      args.add(remoteId);
    }

    if (args.isEmpty) return const [];

    return _dbService.query(
      'pos_payments',
      where: where,
      whereArgs: args,
      orderBy: 'id ASC',
    );
  }

  Future<List<Map<String, dynamic>>> _loadLinkedOrderForPayment(
      Map<String, dynamic> paymentRow) async {
    final idPos = paymentRow['id_pos']?.toString() ?? '';
    if (idPos.isNotEmpty) {
      final rows = await _dbService.query(
        'transactions',
        where: 'id_pos = ?',
        whereArgs: [idPos],
        limit: 1,
      );
      if (rows.isNotEmpty) return rows;
    }

    final invoiceId = paymentRow['invoiceid']?.toString() ?? '';
    if (invoiceId.isEmpty || invoiceId == '0') return const [];

    return _dbService.query(
      'transactions',
      where: 'id_penjualan_remote = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );
  }

  Map<String, dynamic> _mapPaymentRow(
    Map<String, dynamic> paymentRow,
    Map<String, String> paymentModeMap,
  ) {
    final paymentModeId = paymentRow['paymentmode']?.toString() ?? '';
    return {
      'local_id': _toInt(paymentRow['id']),
      'id_pos': paymentRow['id_pos']?.toString() ?? '',
      'invoice_id': paymentRow['invoiceid']?.toString() ?? '',
      'amount': _toInt(paymentRow['amount']),
      'payment_mode_id': paymentModeId,
      'payment_mode_name': paymentModeMap[paymentModeId] ??
          paymentRow['paymentmethod']?.toString() ??
          '',
      'payment_method': paymentRow['paymentmethod']?.toString() ?? '',
      'date': paymentRow['date']?.toString() ?? '',
      'recorded_at': paymentRow['daterecorded']?.toString() ?? '',
      'note': paymentRow['note']?.toString() ?? '',
      'transaction_id': paymentRow['transactionid']?.toString() ?? '',
      'is_synced': _toInt(paymentRow['is_synced']) == 1,
    };
  }

  String _resolveOrderStatusLabel(
    int statusId, {
    required bool hasRefundItems,
    required bool isFullyRefunded,
  }) {
    if (statusId == 5) return 'voided';
    if (isFullyRefunded) return 'refunded';
    if (hasRefundItems) return 'partially_refunded';

    switch (statusId) {
      case 2:
        return 'paid';
      case 3:
        return 'completed';
      case 4:
        return 'draft';
      default:
        return 'open';
    }
  }

  Future<void> _postWebhook(String url, Map<String, dynamic> payload) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      debugPrint('TransactionWebhookService: Invalid webhook URL: $url');
      return;
    }

    try {
      final response = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errMsg = 'Webhook HTTP ${response.statusCode}: ${response.body}';
        debugPrint('TransactionWebhookService: $errMsg');
        ErrorLogService.log(
          category: 'webhook',
          errCode: 'WEBHOOK_HTTP_FAIL',
          errMsg: errMsg,
        );
      }
    } catch (e) {
      debugPrint('TransactionWebhookService: POST failed: $e');
      ErrorLogService.log(
        category: 'webhook',
        errCode: 'WEBHOOK_POST_FAIL',
        errMsg: e.toString(),
      );
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    final parsed = int.tryParse(value.toString());
    if (parsed == null || parsed == 0) return null;
    return parsed;
  }

  bool _isRefundFlag(dynamic value) {
    return value?.toString() == '1' || value == true;
  }

  String _sanitizeString(String value) {
    if (value == 'Guest' || value == 'null') return '';
    return value;
  }
}
