import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:semesta_pos/core/services/app_service.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/core/services/remote/end_point.dart';
import 'package:semesta_pos/core/services/user_service.dart';

/// Centralized error reporting service.
/// Posts errors to `pos_error_logs` endpoint — works online and offline.
/// In offline mode, errors are queued to SQLite `sync_queue` for later sync.
class ErrorLogService {
  static ErrorLogService? _instance;
  static ErrorLogService get instance => _instance ??= ErrorLogService._();
  ErrorLogService._();

  static const String _endpoint = 'pos_error_logs';

  /// Log an error. Call this from any catch block.
  ///
  /// [category] – group identifier e.g. 'sync', 'payment', 'api', 'database'
  /// [errCode]  – short machine-readable code e.g. 'INVOICE_UPDATE_FAIL'
  /// [errMsg]   – the full error message / stack trace snippet
  static Future<void> log({
    required String category,
    required String errCode,
    required String errMsg,
  }) async {
    try {
      // If developer mode is on, show a visible snackbar with detail
      try {
        if (Get.isRegistered<AppService>() && Get.find<AppService>().developerMode.value) {
          Get.snackbar(
            '🐛 [$errCode]',
            '$category: $errMsg',
            backgroundColor: Colors.deepPurple.shade800,
            colorText: Colors.white,
            duration: const Duration(seconds: 6),
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(12),
            borderRadius: 8,
          );
        }
      } catch (_) {}

      await instance._logInternal(
        category: category,
        errCode: errCode,
        errMsg: errMsg,
      );
    } catch (e) {
      // Never let the error logger itself crash the app
      debugPrint('[ErrorLogService] Failed to log error: $e');
    }
  }

  Future<void> _logInternal({
    required String category,
    required String errCode,
    required String errMsg,
  }) async {
    // Truncate very long messages to avoid oversized payloads
    final safeMsg = errMsg.length > 1000 ? errMsg.substring(0, 1000) : errMsg;

    final payload = {
      'err_msg': safeMsg,
      'category': category,
      'err_code': errCode,
    };

    debugPrint('[ErrorLogService] Logging error | category=$category | code=$errCode');

    // Try to get services — they may not exist during very early startup errors
    UserService? userService;
    String? baseUrl;
    String? authToken;
    String? deviceId;

    try {
      userService = Get.find<UserService>();
      baseUrl = userService.getBaseUrl();
      authToken = userService.getAuthToken();
      deviceId = await userService.getDeviceId();
    } catch (_) {
      // Services not yet registered — queue offline only
    }

    // If we have connectivity info, try to post directly
    if (baseUrl != null && baseUrl.isNotEmpty && authToken != null && authToken.isNotEmpty) {
      final posted = await _tryPost(
        baseUrl: baseUrl,
        authToken: authToken,
        deviceId: deviceId ?? '',
        payload: payload,
      );
      if (posted) return;
    }

    // Fallback: save to sync_queue for later sync
    await _enqueueOffline(
      baseUrl: baseUrl ?? '',
      deviceId: deviceId ?? '',
      payload: payload,
    );
  }

  Future<bool> _tryPost({
    required String baseUrl,
    required String authToken,
    required String deviceId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      if (!baseUrl.endsWith('/')) baseUrl += '/';
      final uri = Uri.parse('$baseUrl${EndPoint.apiPath}$_endpoint/$deviceId');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'authtoken': authToken,
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[ErrorLogService] Error logged to server successfully.');
        return true;
      }
      debugPrint('[ErrorLogService] Server returned ${response.statusCode}, will queue offline.');
      return false;
    } on TimeoutException {
      debugPrint('[ErrorLogService] Timeout posting error log, queuing offline.');
      return false;
    } catch (e) {
      debugPrint('[ErrorLogService] HTTP error: $e, queuing offline.');
      return false;
    }
  }

  Future<void> _enqueueOffline({
    required String baseUrl,
    required String deviceId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final dbService = Get.find<DatabaseService>();
      if (!baseUrl.endsWith('/')) baseUrl += '/';
      final endpoint = '${EndPoint.apiPath}$_endpoint/$deviceId';

      await dbService.insert('sync_queue', {
        'method': 'POST',
        'base_url': baseUrl,
        'endpoint': endpoint,
        'body': jsonEncode(payload),
        'is_form_data': 0,
        'status': 'pending',
        'retry_count': 0,
        'last_error': null,
        'created_at': DateTime.now().toIso8601String(),
        'local_id': 'errlog_${DateTime.now().millisecondsSinceEpoch}',
      });
      debugPrint('[ErrorLogService] Error queued to sync_queue for later sync.');
    } catch (e) {
      debugPrint('[ErrorLogService] Failed to queue error log offline: $e');
    }
  }
}
