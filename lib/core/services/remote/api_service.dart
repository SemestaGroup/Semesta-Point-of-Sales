import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:semesta_pos/core/models/api/response_api_model.dart';
import 'package:semesta_pos/core/models/brand/brand_model.dart';
import 'package:semesta_pos/core/models/category/kategori_model.dart';
import 'package:semesta_pos/core/models/dashboard/dashboard_model.dart';
import 'package:semesta_pos/core/models/member/member_model.dart';
import 'package:semesta_pos/core/models/payment/pos_payment_model.dart';
import 'package:semesta_pos/core/models/penjualan/penjualan_model.dart';
import 'package:semesta_pos/core/models/product/product_model.dart';
import 'package:semesta_pos/core/models/staff/staff_model.dart';
import 'package:semesta_pos/core/models/user/client_model.dart';
import 'package:semesta_pos/core/services/remote/end_point.dart';
import 'package:semesta_pos/core/services/user_service.dart';
import 'package:semesta_pos/core/util/constans.dart';

class ApiService extends GetxService {
  Map<String, String> _getAuthHeaders({bool isMultipart = false}) {
    final userService = Get.find<UserService>();
    final headers = {
      'authtoken': userService.getAuthToken(),
    };
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }
    return headers;
  }

  Uri _getUri(String resource, {Map<String, dynamic>? queryParameters}) {
    final userService = Get.find<UserService>();
    String baseUrl = userService.getBaseUrl();
    if (!baseUrl.endsWith('/')) baseUrl += '/';

    final fullPath = '$baseUrl${EndPoint.apiPath}$resource';

    if (queryParameters != null) {
      // Filter out null values and convert to strings
      final cleanParams = <String, String>{};
      queryParameters.forEach((key, value) {
        if (value != null) cleanParams[key] = value.toString();
      });
      return Uri.parse(fullPath).replace(
          queryParameters: cleanParams.isNotEmpty ? cleanParams : null);
    }
    return Uri.parse(fullPath);
  }

  /// Legacy helper for PHP-based scripts if they don't follow the /api/ pattern
  Uri _getPhpUri(String scriptPath) {
    final userService = Get.find<UserService>();
    String baseUrl = userService.getBaseUrl();
    if (!baseUrl.endsWith('/')) baseUrl += '/';
    return Uri.parse('$baseUrl$scriptPath');
  }

  Future<ResponseApiModel> login(Map<String, String> map) async {
    try {
      final String email = map['email'] ?? '';
      final String password = map['password'] ?? '';

      debugPrint(
          'ApiService: Received email for login map: "$email" (length: ${email.length})');

      // Using GET with query parameters as shown in user's curl example
      final uri = Uri.parse(EndPoint.authEndpoint).replace(queryParameters: {
        'email': email,
        'password': password,
      });

      debugPrint('ApiService: Attempting login for $email at $uri');

      final responseApi = await http.get(
        uri,
        headers: {
          'authtoken': Constants.staticAuthToken,
        },
      );

      debugPrint('ApiService: Status Code: ${responseApi.statusCode}');
      String responseBody = responseApi.body;
      debugPrint(
          'ApiService: Response Body Preview: ${responseBody.length > 500 ? responseBody.substring(0, 500) : responseBody}');

      dynamic responseJson;
      try {
        responseJson = jsonDecode(responseBody);
      } catch (e) {
        debugPrint('ApiService: Failed to decode JSON response: $e');
        if (responseApi.statusCode == 401) {
          return const ResponseApiModel(
            responsestate: Constants.errorState,
            message: 'Email atau password salah. (401)',
            data: null,
          );
        }
        if (responseApi.statusCode != 200) {
          return ResponseApiModel(
            responsestate: Constants.errorState,
            message:
                'Server Error (${responseApi.statusCode}). Please contact administrator.',
            data: null,
          );
        }
        rethrow;
      }

      if (responseApi.statusCode == 200) {
        bool isSuccess = false;
        if (responseJson is Map) {
          if (responseJson['status'] == true) {
            isSuccess = true;
          } else if (responseJson.containsKey('base_url') &&
              responseJson.containsKey('location')) {
            // Some API responses might be missing "status: true" but have the data
            isSuccess = true;
          }
        }

        if (isSuccess) {
          return ResponseApiModel(
              responsestate: Constants.successState,
              message: responseJson['message'] ?? 'Login successful',
              data: responseJson);
        } else {
          return ResponseApiModel(
              responsestate: Constants.errorState,
              message: (responseJson is Map ? responseJson['message'] : null) ??
                  'Invalid credentials',
              data: null);
        }
      }

      // Handle non-200 status codes (like 401)
      String errorMessage = 'Server returned error: ${responseApi.statusCode}';
      if (responseJson is Map && responseJson.containsKey('message')) {
        errorMessage = responseJson['message'];
      }

      return ResponseApiModel(
          responsestate: Constants.errorState,
          message: errorMessage,
          data: null);
    } on SocketException catch (e) {
      debugPrint('ApiService Login Network Error: $e');
      return const ResponseApiModel(
          responsestate: Constants.errorState,
          message: 'Tidak ada koneksi internet. Silakan periksa jaringan Anda.',
          data: null);
    } on TimeoutException catch (e) {
      debugPrint('ApiService Login Timeout Error: $e');
      return const ResponseApiModel(
          responsestate: Constants.errorState,
          message: 'Koneksi ke server terputus (Timeout).',
          data: null);
    } on FormatException catch (e) {
      debugPrint('ApiService Login Format Error: $e');
      return const ResponseApiModel(
          responsestate: Constants.errorState,
          message: 'Server memberikan respon yang tidak valid (Bukan JSON).',
          data: null);
    } catch (e) {
      debugPrint('ApiService Login Error: $e');
      return ResponseApiModel(
          responsestate: Constants.serverErrState,
          message: 'Terjadi kesalahan: ${e.toString().split(':').last.trim()}',
          data: null);
    }
  }

  Future<ResponseApiModel> getProfile(int userId) async {
    try {
      final responseApi = await http.get(
          _getUri('${EndPoint.posProfile}/$userId'),
          headers: _getAuthHeaders());

      dynamic responseJson;
      try {
        responseJson = jsonDecode(responseApi.body);
      } catch (e) {
        debugPrint(
            'ApiService: Invalid JSON in getProfile for location $userId. Assuming profile endpoint not supported.');
        return const ResponseApiModel(
          responsestate: Constants.errorState,
          message: 'Profil tidak tersedia',
          data: null,
        );
      }

      if (responseApi.statusCode == 200) {
        final responApiModel = ResponseApiModel(
            responsestate: Constants.successState,
            message: responseJson['message'],
            data: ClientModel.fromJson(responseJson['data']));
        return responApiModel;
      }

      return ResponseApiModel(
          responsestate: Constants.errorState,
          message: responseJson['message'],
          data: null);
    } catch (e) {
      debugPrint(e.toString());
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          responsestate: Constants.serverErrState,
          message: 'Terjadi kesalahan sistem',
          data: null);
    }
  }

  Future<ResponseApiModel> updateProfile(
      Map<String, dynamic> map, int userId) async {
    try {
      final responseApi = await http.post(
        _getUri(
            '${EndPoint.posProfile}/update/$userId'), // Or just posProfile if REST
        headers: _getAuthHeaders(),
        body: jsonEncode(map),
      );
      final responseJson = jsonDecode(responseApi.body);

      if (responseApi.statusCode == 200) {
        final responApiModel = ResponseApiModel(
            responsestate: Constants.successState,
            message: responseJson['message'],
            data: null);
        return responApiModel;
      }

      return ResponseApiModel(
          responsestate: Constants.errorState,
          message: responseJson['message'],
          data: null);
    } catch (e) {
      debugPrint(e.toString());
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          responsestate: Constants.serverErrState,
          message: 'Terjadi kesalahan sistem',
          data: null);
    }
  }

  Future<ResponseApiModel> getBrand(
      {int? id, String? name, String? code}) async {
    try {
      final uri = _getUri(EndPoint.posBrands, queryParameters: {
        if (id != null) 'id': id,
        if (name != null) 'name': name,
        if (code != null) 'code': code,
      });

      final responseApi = await http.get(uri, headers: _getAuthHeaders());

      if (responseApi.statusCode == 200) {
        final dynamic dataResponse = jsonDecode(responseApi.body);
        List rawList = [];
        if (dataResponse is List) {
          rawList = dataResponse;
        } else if (dataResponse is Map) {
          if (dataResponse['status'] == true ||
              dataResponse.containsKey('status')) {
            dynamic brandsData = dataResponse['brands'] ??
                dataResponse['data']?['brands'] ??
                dataResponse['data'];
            if (brandsData is List) rawList = brandsData;
          } else {
            rawList =
                dataResponse['brands'] is List ? dataResponse['brands'] : [];
          }
        }

        return ResponseApiModel(
            responsestate: Constants.successState,
            message: 'success',
            data: rawList.map((item) {
              if (item is Map<String, dynamic>) {
                final val = item['id'];
                if (val != null) {
                  item['id'] =
                      (val is int) ? val : int.tryParse(val.toString()) ?? 0;
                }
              }
              return BrandModel.fromJson(item);
            }).toList());
      }
      return const ResponseApiModel(
          responsestate: Constants.errorState, message: 'Server Error');
    } catch (e) {
      debugPrint('Error getBrand: $e');
      rethrow;
    }
  }

  Future<ResponseApiModel> getPosPromotions(String idLocation) async {
    try {
      String centralUrl = Constants.centralBaseUrl;
      if (!centralUrl.endsWith('/')) centralUrl += '/';
      final fullPath = '$centralUrl${EndPoint.apiPath}pos_promotions';
      final uri = Uri.parse(fullPath)
          .replace(queryParameters: {'id_location': idLocation});

      debugPrint('ApiService: getPosPromotions URL: $uri');
      final responseApi = await http.get(
        uri,
        headers: _getAuthHeaders(),
      );
      debugPrint(
          'ApiService: getPosPromotions statusCode: ${responseApi.statusCode}');
      debugPrint('ApiService: getPosPromotions body: ${responseApi.body}');

      dynamic responseJson;
      try {
        responseJson = jsonDecode(responseApi.body);
      } catch (e) {
        debugPrint('ApiService: getPosPromotions JSON parse error: $e');
        return ResponseApiModel(
            responsestate: Constants.errorState,
            message: 'Format respons bukan JSON');
      }

      if (responseApi.statusCode == 200 || responseApi.statusCode == 201) {
        return ResponseApiModel(
          responsestate: Constants.successState,
          message: 'success',
          data: responseJson is Map
              ? (responseJson['data'] ?? responseJson)
              : responseJson,
        );
      }
      return ResponseApiModel(
          responsestate: Constants.errorState,
          message: 'Gagal memuat promo (HTTP ${responseApi.statusCode})');
    } catch (e) {
      debugPrint('ApiService: getPosPromotions Exception: $e');
      return ResponseApiModel(
          responsestate: Constants.errorState, message: e.toString());
    }
  }

  Future<ResponseApiModel> getPosPaymentModes() async {
    try {
      final responseApi = await http.get(
        _getUri('pos_payment_modes'),
        headers: _getAuthHeaders(),
      );
      final responseJson = jsonDecode(responseApi.body);
      if (responseApi.statusCode == 200) {
        return ResponseApiModel(
          responsestate: Constants.successState,
          message: 'success',
          data: responseJson is Map
              ? (responseJson['data'] ?? responseJson)
              : responseJson,
        );
      }
      return const ResponseApiModel(
          responsestate: Constants.errorState,
          message: 'Gagal memuat mode pembayaran');
    } catch (e) {
      return ResponseApiModel(
          responsestate: Constants.errorState, message: e.toString());
    }
  }

  Future<ResponseApiModel> getCategory({int? id, String? name}) async {
    try {
      final uri = _getUri(EndPoint.posCategories, queryParameters: {
        if (id != null) 'id': id,
        if (name != null) 'name': name,
      });

      final responseApi = await http.get(uri, headers: _getAuthHeaders());

      if (responseApi.statusCode == 200) {
        final dynamic dataResponse = jsonDecode(responseApi.body);
        List rawList = [];
        if (dataResponse is List) {
          rawList = dataResponse;
        } else if (dataResponse is Map) {
          if (dataResponse['status'] == true ||
              dataResponse.containsKey('status')) {
            dynamic catsData = dataResponse['categories'] ??
                dataResponse['data']?['categories'] ??
                dataResponse['data'];
            if (catsData is List) rawList = catsData;
          } else {
            rawList = dataResponse['categories'] is List
                ? dataResponse['categories']
                : [];
          }
        }

        return ResponseApiModel(
            responsestate: Constants.successState,
            message: 'success',
            data: rawList.map((item) {
              if (item is Map<String, dynamic>) {
                final val = item['commodity_type_id'];
                if (val != null) {
                  item['commodity_type_id'] =
                      (val is int) ? val : int.tryParse(val.toString()) ?? 0;
                }
              }
              return KategoriModel.fromJson(item);
            }).toList());
      }
      return const ResponseApiModel(
          responsestate: Constants.errorState,
          message: 'Gagal memuat kategori',
          data: null);
    } catch (e) {
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return ResponseApiModel(
          responsestate: Constants.errorState,
          message: 'Server error: $e',
          data: null);
    }
  }

  Future<ResponseApiModel> getProduct() async {
    try {
      final responseApi = await http.get(_getUri(EndPoint.posItems),
          headers: _getAuthHeaders());
      if (responseApi.statusCode == 200) {
        dynamic dataResponse;
        try {
          dataResponse = jsonDecode(responseApi.body);
        } catch (_) {
          debugPrint('storePosOrder Invalid JSON: ');
          String errorMsg = 'Server Error: ';
          if (responseApi.body.contains('<p>')) {
            final RegExp exp = RegExp(r'<p>(.*?)<\/p>');
            final match = exp.firstMatch(responseApi.body);
            if (match != null) errorMsg = match.group(1) ?? errorMsg;
          }
          return ResponseApiModel(
              message: errorMsg,
              responsestate: Constants.serverErrState,
              data: null);
        }

        if (dataResponse['status'] == true) {
          final dynamic data = dataResponse['data'] ?? dataResponse;
          final List items = data['items'] ?? [];

          final Map<String, dynamic> combinedData = {
            'items': items,
          };

          return ResponseApiModel(
              responsestate: Constants.successState,
              message: 'success',
              data: combinedData);
        } else {
          return ResponseApiModel(
              responsestate: Constants.errorState,
              message: dataResponse['message'] ?? 'Gagal memuat produk',
              data: null);
        }
      } else {
        return ResponseApiModel(
            responsestate: Constants.errorState,
            message: 'Gagal memuat produk (HTTP ${responseApi.statusCode})',
            data: null);
      }
    } catch (e) {
      debugPrint('GetProduct Error: $e');
      return const ResponseApiModel(
          responsestate: Constants.errorState,
          message: 'Server error',
          data: null);
    }
  }

  Future<ResponseApiModel> getMember() async {
    try {
      final responseApi = await http.get(_getUri(EndPoint.posCustomers),
          headers: _getAuthHeaders());
      if (responseApi.statusCode == 200) {
        dynamic dataResponse;
        try {
          dataResponse = jsonDecode(responseApi.body);
        } catch (_) {
          debugPrint('storePosOrder Invalid JSON: ');
          String errorMsg = 'Server Error: ';
          if (responseApi.body.contains('<p>')) {
            final RegExp exp = RegExp(r'<p>(.*?)<\/p>');
            final match = exp.firstMatch(responseApi.body);
            if (match != null) errorMsg = match.group(1) ?? errorMsg;
          }
          return ResponseApiModel(
              message: errorMsg,
              responsestate: Constants.serverErrState,
              data: null);
        }
        debugPrint('GET Members Response: ${responseApi.body}');

        List data = [];
        if (dataResponse is List) {
          data = dataResponse;
        } else if (dataResponse is Map && dataResponse['status'] == false) {
          return ResponseApiModel(
              responsestate: Constants.successState,
              message: dataResponse['message'] ?? 'No data found',
              data: []);
        }

        return ResponseApiModel(
            responsestate: Constants.successState,
            message: 'success',
            data: data.map((item) => MemberModel.fromJson(item)).toList());
      } else {
        return const ResponseApiModel(
            responsestate: Constants.errorState,
            message: 'Gagal memuat customer',
            data: null);
      }
    } catch (e) {
      return ResponseApiModel(
          responsestate: Constants.errorState,
          message: 'Server error: $e',
          data: null);
    }
  }

  Future<ResponseApiModel> getUnpaidOrders() async {
    try {
      final uri =
          _getUri(EndPoint.posOrder, queryParameters: {'search': 'unpaid'});
      final responseApi = await http.get(uri, headers: _getAuthHeaders());

      if (responseApi.statusCode == 200 || responseApi.statusCode == 201) {
        dynamic dataResponse;
        try {
          dataResponse = jsonDecode(responseApi.body);
        } catch (_) {
          debugPrint('storePosOrder Invalid JSON: ');
          String errorMsg = 'Server Error: ';
          if (responseApi.body.contains('<p>')) {
            final RegExp exp = RegExp(r'<p>(.*?)<\/p>');
            final match = exp.firstMatch(responseApi.body);
            if (match != null) errorMsg = match.group(1) ?? errorMsg;
          }
          return ResponseApiModel(
              message: errorMsg,
              responsestate: Constants.serverErrState,
              data: null);
        }

        if (dataResponse is Map && dataResponse['status'] == false) {
          return ResponseApiModel(
              message: dataResponse['message'] ?? 'No data found',
              responsestate: Constants.successState,
              data: []);
        }

        return ResponseApiModel(
            message: 'Berhasil memuat unpaid orders',
            responsestate: Constants.successState,
            data: dataResponse);
      } else {
        return ResponseApiModel(
            responsestate: Constants.errorState,
            message:
                'Gagal memuat unpaid orders (HTTP ${responseApi.statusCode})',
            data: null);
      }
    } catch (e) {
      debugPrint('getUnpaidOrders Exception: $e');
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          responsestate: Constants.errorState,
          message: 'Server error',
          data: null);
    }
  }

  Future<ResponseApiModel> getPosOrders() async {
    try {
      final responseApi = await http.get(_getUri(EndPoint.posOrder),
          headers: _getAuthHeaders());

      if (responseApi.statusCode == 200 || responseApi.statusCode == 201) {
        dynamic dataResponse;
        try {
          dataResponse = jsonDecode(responseApi.body);
        } catch (_) {
          debugPrint('storePosOrder Invalid JSON: ');
          String errorMsg = 'Server Error: ';
          if (responseApi.body.contains('<p>')) {
            final RegExp exp = RegExp(r'<p>(.*?)<\/p>');
            final match = exp.firstMatch(responseApi.body);
            if (match != null) errorMsg = match.group(1) ?? errorMsg;
          }
          return ResponseApiModel(
              message: errorMsg,
              responsestate: Constants.serverErrState,
              data: null);
        }

        if (dataResponse is Map && dataResponse['status'] == false) {
          return ResponseApiModel(
              message: dataResponse['message'] ?? 'No data found',
              responsestate: Constants.successState,
              data: []);
        }

        return ResponseApiModel(
            message: 'Berhasil memuat orders',
            responsestate: Constants.successState,
            data: dataResponse);
      } else {
        return ResponseApiModel(
            responsestate: Constants.errorState,
            message: 'Gagal memuat orders (HTTP ${responseApi.statusCode})',
            data: null);
      }
    } catch (e) {
      debugPrint('getPosOrders Exception: $e');
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          responsestate: Constants.errorState,
          message: 'Server error',
          data: null);
    }
  }

  Future<ResponseApiModel> getPosOrderDetails(String remoteId) async {
    try {
      final responseApi = await http.get(
          _getUri('${EndPoint.posOrder}/$remoteId'),
          headers: _getAuthHeaders());

      if (responseApi.statusCode == 200 || responseApi.statusCode == 201) {
        dynamic dataResponse;
        try {
          dataResponse = jsonDecode(responseApi.body);
        } catch (_) {
          debugPrint('storePosOrder Invalid JSON: ');
          String errorMsg = 'Server Error: ';
          if (responseApi.body.contains('<p>')) {
            final RegExp exp = RegExp(r'<p>(.*?)<\/p>');
            final match = exp.firstMatch(responseApi.body);
            if (match != null) errorMsg = match.group(1) ?? errorMsg;
          }
          return ResponseApiModel(
              message: errorMsg,
              responsestate: Constants.serverErrState,
              data: null);
        }
        return ResponseApiModel(
            message: 'Berhasil memuat detail order',
            responsestate: Constants.successState,
            data: dataResponse);
      } else {
        return ResponseApiModel(
            responsestate: Constants.errorState,
            message: 'Gagal memuat detail (HTTP ${responseApi.statusCode})',
            data: null);
      }
    } catch (e) {
      debugPrint('getPosOrderDetails Exception: $e');
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          responsestate: Constants.errorState,
          message: 'Server error',
          data: null);
    }
  }

  Future<ResponseApiModel> storePosOrder(Map<String, dynamic> data) async {
    final uri = _getUri(EndPoint.posOrder);
    _logApiCall('POST', uri, data);

    try {
      final responseApi = await http
          .post(
            uri,
            headers: _getAuthHeaders(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      print(
          'POS_API_LOG: POST $uri | Status: ${responseApi.statusCode} | Body: ${responseApi.body}');

      dynamic dataResponse;
      try {
        dataResponse = jsonDecode(responseApi.body);
      } catch (_) {
        debugPrint('storePosOrder Invalid JSON: ${responseApi.body}');
        String errorMsg = 'Server Error: ${responseApi.statusCode}';
        if (responseApi.body.contains('<p>')) {
          final RegExp exp = RegExp(r'<p>(.*?)<\/p>');
          final match = exp.firstMatch(responseApi.body);
          if (match != null) errorMsg = match.group(1) ?? errorMsg;
        }
        return ResponseApiModel(
            message: errorMsg,
            responsestate: Constants.serverErrState,
            data: null);
      }
      if (responseApi.statusCode == 200 || responseApi.statusCode == 201) {
        return ResponseApiModel(
            message: dataResponse['message'] ?? 'Transaksi berhasil',
            responsestate: Constants.successState,
            data: dataResponse['data']);
      } else {
        return ResponseApiModel(
            message: dataResponse['message'] ?? 'Transaksi gagal',
            responsestate: Constants.errorState,
            data: null);
      }
    } catch (e) {
      debugPrint('storePosOrder Error: $e');
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          message: 'Server Error',
          responsestate: Constants.serverErrState,
          data: null);
    }
  }

  Future<ResponseApiModel> updatePosOrder(
      int remoteId, Map<String, dynamic> data) async {
    final uri = _getUri('${EndPoint.posOrder}/$remoteId');
    _logApiCall('PUT', uri, data);

    try {
      final responseApi = await http
          .put(
            uri,
            headers: _getAuthHeaders(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      print(
          'POS_API_LOG: PUT $uri | Status: ${responseApi.statusCode} | Body: ${responseApi.body}');

      dynamic dataResponse;
      try {
        dataResponse = jsonDecode(responseApi.body);
      } catch (_) {
        debugPrint('updatePosOrder Invalid JSON: ${responseApi.body}');
        String errorMsg = 'Server Error: ${responseApi.statusCode}';
        if (responseApi.body.contains('<p>')) {
          final RegExp exp = RegExp(r'<p>(.*?)<\/p>');
          final match = exp.firstMatch(responseApi.body);
          if (match != null) errorMsg = match.group(1) ?? errorMsg;
        }
        return ResponseApiModel(
            message: errorMsg,
            responsestate: Constants.serverErrState,
            data: null);
      }
      if (responseApi.statusCode == 200 || responseApi.statusCode == 201) {
        return ResponseApiModel(
            message: dataResponse['message'] ?? 'Order diperbarui',
            responsestate: Constants.successState,
            data: dataResponse['data']);
      } else {
        return ResponseApiModel(
            message: dataResponse['message'] ?? 'Gagal memperbarui order',
            responsestate: Constants.errorState,
            data: null);
      }
    } catch (e) {
      debugPrint('updatePosOrder Error: $e');
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          message: 'Server Error',
          responsestate: Constants.serverErrState,
          data: null);
    }
  }

  Future<ResponseApiModel> deletePosOrder(dynamic remoteId) async {
    try {
      final responseApi = await http.delete(
        _getUri('${EndPoint.posOrder}/$remoteId'),
        headers: _getAuthHeaders(),
      );
      dynamic dataResponse;
      try {
        dataResponse = jsonDecode(responseApi.body);
      } catch (_) {
        return ResponseApiModel(
            message: 'Server Error: ${responseApi.statusCode}',
            responsestate: Constants.serverErrState,
            data: null);
      }
      if (responseApi.statusCode == 200 || responseApi.statusCode == 201) {
        return ResponseApiModel(
            message: dataResponse['message'] ?? 'Order berhasil dihapus',
            responsestate: Constants.successState,
            data: dataResponse['data']);
      } else {
        return ResponseApiModel(
            message: dataResponse['message'] ?? 'Gagal menghapus order',
            responsestate: Constants.errorState,
            data: null);
      }
    } catch (e) {
      debugPrint('deletePosOrder Error: $e');
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          message: 'Server Error',
          responsestate: Constants.serverErrState,
          data: null);
    }
  }

  Future<ResponseApiModel> storePosPayment(PosPaymentModel payment) async {
    final data = payment.toJson();
    final uri = _getUri(EndPoint.posTransaction);
    _logApiCall('POST', uri, data);

    try {
      final responseApi = await http.post(
        uri,
        headers: _getAuthHeaders(),
        body: jsonEncode(data),
      );

      _logApiCall('POST', uri, data,
          response: responseApi.body, statusCode: responseApi.statusCode);

      dynamic dataResponse;
      try {
        dataResponse = jsonDecode(responseApi.body);
      } catch (_) {
        debugPrint('storePosOrder Invalid JSON: ');
        String errorMsg = 'Server Error: ';
        if (responseApi.body.contains('<p>')) {
          final RegExp exp = RegExp(r'<p>(.*?)<\/p>');
          final match = exp.firstMatch(responseApi.body);
          if (match != null) errorMsg = match.group(1) ?? errorMsg;
        }
        return ResponseApiModel(
            message: errorMsg,
            responsestate: Constants.serverErrState,
            data: null);
      }
      if (responseApi.statusCode == 200 || responseApi.statusCode == 201) {
        return ResponseApiModel(
            message: dataResponse['message'] ?? 'Pembayaran berhasil',
            responsestate: Constants.successState,
            data: dataResponse['data']);
      } else {
        return ResponseApiModel(
            message: dataResponse['message'] ?? 'Pembayaran gagal',
            responsestate: Constants.errorState,
            data: null);
      }
    } catch (e) {
      debugPrint('storePosPayment Error: $e');
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          message: 'Server Error',
          responsestate: Constants.serverErrState,
          data: null);
    }
  }

  Future<ResponseApiModel> storeTransaction(Map<String, dynamic> data) async {
    try {
      final responseApi = await http.post(
        _getUri(EndPoint.posTransaction),
        headers: _getAuthHeaders(),
        body: jsonEncode(data),
      );
      dynamic dataResponse;
      try {
        dataResponse = jsonDecode(responseApi.body);
      } catch (_) {
        debugPrint('storePosOrder Invalid JSON: ');
        String errorMsg = 'Server Error: ';
        if (responseApi.body.contains('<p>')) {
          final RegExp exp = RegExp(r'<p>(.*?)<\/p>');
          final match = exp.firstMatch(responseApi.body);
          if (match != null) errorMsg = match.group(1) ?? errorMsg;
        }
        return ResponseApiModel(
            message: errorMsg,
            responsestate: Constants.serverErrState,
            data: null);
      }
      if (responseApi.statusCode == 200 || responseApi.statusCode == 201) {
        return ResponseApiModel(
            message: 'Transaksi berhasil',
            responsestate: Constants.successState,
            data: PenjualanModel.fromJson(dataResponse['data']));
      } else {
        return const ResponseApiModel(
            message: 'Transaksi gagal',
            responsestate: Constants.errorState,
            data: null);
      }
    } catch (e) {
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          message: 'Server Error',
          responsestate: Constants.serverErrState,
          data: null);
    }
  }

  Future<ResponseApiModel> searchProduct(String keyword) async {
    final userService = Get.find<UserService>();
    final baseUrl = userService.getBaseUrl();
    final authToken = userService.getAuthToken();
    try {
      // Ensure baseUrl ends with a slash and add /api/ if not present
      String apiBaseUrl = baseUrl;
      if (!apiBaseUrl.endsWith('/')) apiBaseUrl += '/';
      if (!apiBaseUrl.contains('/api/')) apiBaseUrl += 'api/';

      String url = '${apiBaseUrl}search/product';
      final Map<String, String> data = {'keyword': keyword};
      String queryString = Uri(queryParameters: data).query;
      String requestUrl = '$url?$queryString';
      final responseApi = await http.get(
        Uri.parse(requestUrl),
        headers: {'authtoken': authToken},
      );
      if (responseApi.statusCode == 200) {
        dynamic dataResponse;
        try {
          dataResponse = jsonDecode(responseApi.body);
        } catch (_) {
          debugPrint('storePosOrder Invalid JSON: ');
          String errorMsg = 'Server Error: ';
          if (responseApi.body.contains('<p>')) {
            final RegExp exp = RegExp(r'<p>(.*?)<\/p>');
            final match = exp.firstMatch(responseApi.body);
            if (match != null) errorMsg = match.group(1) ?? errorMsg;
          }
          return ResponseApiModel(
              message: errorMsg,
              responsestate: Constants.serverErrState,
              data: null);
        }
        final List items = dataResponse['data'] ?? [];

        final productList = items.map((item) {
          final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
          // Handle group_names nesting if it exists
          final groups = item['group_names'];
          if (groups != null && (groups is List) && groups.isNotEmpty) {
            itemMap['merk'] = groups[0]['name'];
          }
          return ProductModel.fromJson(itemMap);
        }).toList();

        return ResponseApiModel(
            responsestate: Constants.successState,
            message: 'success',
            data: productList);
      } else {
        return const ResponseApiModel(
            responsestate: Constants.errorState,
            message: 'Gagal memuat produk',
            data: null);
      }
    } catch (e) {
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          responsestate: Constants.errorState,
          message: 'Server error',
          data: null);
    }
  }

  Future<ResponseApiModel> storeCategory(String category) async {
    final userService = Get.find<UserService>();
    final baseUrl = userService.getBaseUrl();
    final authToken = userService.getAuthToken();
    try {
      // Ensure baseUrl ends with a slash and add /api/ if not present
      String apiBaseUrl = baseUrl;
      if (!apiBaseUrl.endsWith('/')) apiBaseUrl += '/';
      if (!apiBaseUrl.contains('/api/')) apiBaseUrl += 'api/';

      final Map<String, String> data = {'nama_kategori': category};
      final responseApi = await http.post(
        Uri.parse('${apiBaseUrl}category/store'),
        headers: {'authtoken': authToken},
        body: data,
      );

      if (responseApi.statusCode == 200) {
        return const ResponseApiModel(
            message: 'Berhasil menyimpan data',
            responsestate: Constants.successState,
            data: null);
      }

      return const ResponseApiModel(
          message: 'Gagal menyimpan data',
          responsestate: Constants.errorState,
          data: null);
    } catch (e) {
      debugPrint(e.toString());
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          message: 'Terjadi kesalahan sistem',
          responsestate: Constants.serverErrState,
          data: null);
    }
  }

  Future<ResponseApiModel> destroyCategory(int categoryId) async {
    final userService = Get.find<UserService>();
    final baseUrl = userService.getBaseUrl();
    final authToken = userService.getAuthToken();
    try {
      // Ensure baseUrl ends with a slash and add /api/ if not present
      String apiBaseUrl = baseUrl;
      if (!apiBaseUrl.endsWith('/')) apiBaseUrl += '/';
      if (!apiBaseUrl.contains('/api/')) apiBaseUrl += 'api/';

      final responseApi = await http.delete(
        Uri.parse('${apiBaseUrl}category/destroy/$categoryId'),
        headers: {'authtoken': authToken},
      );

      if (responseApi.statusCode == 204 || responseApi.statusCode == 200) {
        return const ResponseApiModel(
            message: 'Berhasil menghapus data',
            responsestate: Constants.successState,
            data: null);
      }

      return const ResponseApiModel(
          message: 'Gagal menghapus data',
          responsestate: Constants.errorState,
          data: null);
    } catch (e) {
      debugPrint(e.toString());
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          message: 'Terjadi kesalahan sistem',
          responsestate: Constants.serverErrState,
          data: null);
    }
  }

  Future<ResponseApiModel> storeMember(Map<String, String> map) async {
    final userService = Get.find<UserService>();
    final authToken = userService.getAuthToken();
    final baseUrl = userService.getBaseUrl();
    try {
      String apiBaseUrl = baseUrl;
      if (!apiBaseUrl.endsWith('/')) apiBaseUrl += '/';
      if (!apiBaseUrl.contains('/api/')) apiBaseUrl += 'api/';

      final request = http.MultipartRequest(
          'POST', Uri.parse('${apiBaseUrl}pos_customers/'));
      request.headers['authtoken'] = authToken;

      if (map.containsKey('telepon')) {
        map['no_hp'] = map.remove('telepon')!;
      }

      request.fields.addAll(map);

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 15));
      final responseApi = await http.Response.fromStream(streamedResponse)
          .timeout(const Duration(seconds: 15));

      if (responseApi.statusCode == 200 || responseApi.statusCode == 201) {
        dynamic dataResponse;
        try {
          dataResponse = jsonDecode(responseApi.body);
        } catch (_) {
          debugPrint('storePosOrder Invalid JSON: ');
          String errorMsg = 'Server Error: ';
          if (responseApi.body.contains('<p>')) {
            final RegExp exp = RegExp(r'<p>(.*?)<\/p>');
            final match = exp.firstMatch(responseApi.body);
            if (match != null) errorMsg = match.group(1) ?? errorMsg;
          }
          return ResponseApiModel(
              message: errorMsg,
              responsestate: Constants.serverErrState,
              data: null);
        }

        List<MemberModel> members = [];
        final dynamic dataRaw = dataResponse['data'];

        if (dataRaw is List) {
          members = dataRaw.map((item) => MemberModel.fromJson(item)).toList();
        } else if (dataRaw is Map<String, dynamic>) {
          members = [MemberModel.fromJson(dataRaw)];
        }

        return ResponseApiModel(
            message: dataResponse['message'] ?? 'Berhasil menyimpan data',
            responsestate: Constants.successState,
            data: members);
      }

      return const ResponseApiModel(
          message: 'Gagal menyimpan data',
          responsestate: Constants.errorState,
          data: null);
    } catch (e) {
      debugPrint(e.toString());
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          message: 'Terjadi kesalahan sistem',
          responsestate: Constants.serverErrState,
          data: null);
    }
  }

  Future<ResponseApiModel> updateMember(
      int id, Map<String, dynamic> map) async {
    try {
      if (map.containsKey('telepon')) {
        map['no_hp'] = map.remove('telepon')!;
      }

      final responseApi = await http.put(
        _getUri('${EndPoint.posCustomers}/$id'),
        headers: _getAuthHeaders(),
        body: jsonEncode(map),
      );

      if (responseApi.statusCode == 200) {
        dynamic dataResponse;
        try {
          dataResponse = jsonDecode(responseApi.body);
        } catch (_) {
          debugPrint('storePosOrder Invalid JSON: ');
          String errorMsg = 'Server Error: ';
          if (responseApi.body.contains('<p>')) {
            final RegExp exp = RegExp(r'<p>(.*?)<\/p>');
            final match = exp.firstMatch(responseApi.body);
            if (match != null) errorMsg = match.group(1) ?? errorMsg;
          }
          return ResponseApiModel(
              message: errorMsg,
              responsestate: Constants.serverErrState,
              data: null);
        }
        List<MemberModel>? members;
        final dynamic dataRaw = dataResponse['data'];

        if (dataRaw is List) {
          members = dataRaw.map((item) => MemberModel.fromJson(item)).toList();
        } else if (dataRaw is Map<String, dynamic>) {
          members = [MemberModel.fromJson(dataRaw)];
        }

        return ResponseApiModel(
            message: dataResponse['message'] ?? 'Berhasil mengubah data',
            responsestate: Constants.successState,
            data: members);
      }

      return const ResponseApiModel(
          message: 'Gagal mengubah data',
          responsestate: Constants.errorState,
          data: null);
    } catch (e) {
      debugPrint(e.toString());
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          message: 'Terjadi kesalahan sistem',
          responsestate: Constants.serverErrState,
          data: null);
    }
  }

  Future<ResponseApiModel> destroyMember(int memberId) async {
    try {
      final responseApi = await http.delete(
          _getUri('${EndPoint.posCustomers}/$memberId'),
          headers: _getAuthHeaders());

      if (responseApi.statusCode == 200 || responseApi.statusCode == 204) {
        return const ResponseApiModel(
            message: 'Berhasil menghapus data',
            responsestate: Constants.successState,
            data: null);
      }

      return const ResponseApiModel(
          message: 'Gagal menghapus data',
          responsestate: Constants.errorState,
          data: null);
    } catch (e) {
      debugPrint(e.toString());
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          message: 'Terjadi kesalahan sistem',
          responsestate: Constants.serverErrState,
          data: null);
    }
  }

  Future<ResponseApiModel> storeProduct(
      String imagePath, Map<String, String> map) async {
    try {
      final request = http.MultipartRequest('POST', _getUri(EndPoint.posItems));
      request.headers.addAll(_getAuthHeaders(isMultipart: true));

      map.forEach((key, value) => request.fields[key] = value);
      if (imagePath != '') {
        request.files
            .add(await http.MultipartFile.fromPath('gambar', imagePath));
      }

      var responseApi = await request.send();
      if (responseApi.statusCode == 204 ||
          responseApi.statusCode == 200 ||
          responseApi.statusCode == 201) {
        return const ResponseApiModel(
            message: 'Berhasil menyimpan data',
            responsestate: Constants.successState,
            data: null);
      }
      return const ResponseApiModel(
          message: 'Gagal menyimpan data',
          responsestate: Constants.errorState,
          data: null);
    } catch (e) {
      debugPrint(e.toString());
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          message: 'Terjadi kesalahan sistem',
          responsestate: Constants.serverErrState,
          data: null);
    }
  }

  Future<ResponseApiModel> destroyProduct(int productId) async {
    try {
      final responseApi = await http.delete(
          _getUri('${EndPoint.posItems}/$productId'),
          headers: _getAuthHeaders());
      if (responseApi.statusCode == 204 || responseApi.statusCode == 200) {
        return const ResponseApiModel(
            message: 'Berhasil menghapus data',
            responsestate: Constants.successState,
            data: null);
      }
      return const ResponseApiModel(
          message: 'Gagal menghapus data',
          responsestate: Constants.errorState,
          data: null);
    } catch (e) {
      debugPrint(e.toString());
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          message: 'Terjadi kesalahan sistem',
          responsestate: Constants.serverErrState,
          data: null);
    }
  }

  Future<ResponseApiModel> updateProduct(
      String imagePath, Map<String, String> map) async {
    try {
      // If RESTful PUT, but Multipart usually uses POST or PUT. User said method matters.
      // Usually updating with multipart is POST with a field like _method='PUT' or just POST.
      final request = http.MultipartRequest('POST', _getUri(EndPoint.posItems));
      request.headers.addAll(_getAuthHeaders(isMultipart: true));

      map.forEach((key, value) => request.fields[key] = value);
      if (imagePath != '') {
        request.files
            .add(await http.MultipartFile.fromPath('gambar', imagePath));
      }

      var responseApi = await request.send();
      if (responseApi.statusCode == 204 || responseApi.statusCode == 200) {
        return const ResponseApiModel(
            message: 'Berhasil mengubah data',
            responsestate: Constants.successState,
            data: null);
      }
      return const ResponseApiModel(
          message: 'Gagal mengubah data',
          responsestate: Constants.errorState,
          data: null);
    } catch (e) {
      debugPrint(e.toString());
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          message: 'Terjadi kesalahan sistem',
          responsestate: Constants.serverErrState,
          data: null);
    }
  }

  Future<ResponseApiModel> dashboard() async {
    try {
      final responseApiModel = await http.get(_getPhpUri(EndPoint.dashboard),
          headers: _getAuthHeaders());

      if (responseApiModel.statusCode == 200) {
        final dataResponse = jsonDecode(responseApiModel.body);
        return ResponseApiModel(
            message: 'Berhasil memuat data dashboard',
            responsestate: Constants.successState,
            data: DashboardModel.fromJson(dataResponse['data']));
      }
      return const ResponseApiModel(
          message: 'Gagal memuat data dashboard',
          responsestate: Constants.errorState,
          data: null);
    } catch (e) {
      debugPrint('error get dashboard: ${e.toString()}');
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          message: 'Server error',
          responsestate: Constants.serverErrState,
          data: null);
    }
  }

  Future<ResponseApiModel> getReport(
      String type, String tglAwal, String tglAkhir) async {
    try {
      final responseApiModel = await http.get(
        _getUri(EndPoint.posReport, queryParameters: {
          'type': type,
          'date_from': tglAwal,
          'date_to': tglAkhir
        }),
        headers: _getAuthHeaders(),
      );

      if (responseApiModel.statusCode == 200) {
        final dataResponse = jsonDecode(responseApiModel.body);

        return ResponseApiModel(
            message: 'Berhasil memuat data report',
            responsestate: Constants.successState,
            data: dataResponse);
      }
      return const ResponseApiModel(
          message: 'Gagal memuat data report',
          responsestate: Constants.errorState,
          data: null);
    } catch (e) {
      debugPrint('error get report: ${e.toString()}');
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          message: 'Server error',
          responsestate: Constants.serverErrState,
          data: null);
    }
  }

  Future<ResponseApiModel> getPosOptions() async {
    try {
      final responseApi = await http.get(_getUri(EndPoint.posOptions),
          headers: _getAuthHeaders());
      final responseJson = jsonDecode(responseApi.body);

      _logApiCall('GET', _getUri(EndPoint.posOptions), null,
          response: responseApi.body, statusCode: responseApi.statusCode);

      if (responseApi.statusCode == 200 && responseJson['status'] == true) {
        return ResponseApiModel(
            responsestate: Constants.successState,
            message: responseJson['message'] ?? 'Success',
            data: responseJson['data']);
      }
      return ResponseApiModel(
          responsestate: Constants.errorState,
          message: responseJson['message'] ?? 'Gagal memuat opsi',
          data: null);
    } catch (e) {
      debugPrint('getPosOptions Error: $e');
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          responsestate: Constants.serverErrState,
          message: 'Server error',
          data: null);
    }
  }

  Future<ResponseApiModel> getCreditNotes() async {
    final uri = _getUri(EndPoint.posCreditNotes);
    try {
      // --- DIAGNOSTIC LOG ---
      debugPrint('=== [getCreditNotes] ===');
      debugPrint('Method : GET');
      debugPrint('URL    : $uri');
      debugPrint('Headers: ${_getAuthHeaders()}');
      // ----------------------

      final responseApi = await http.get(uri, headers: _getAuthHeaders());

      debugPrint('Status : ${responseApi.statusCode}');
      debugPrint('Body   : ${responseApi.body}');
      debugPrint('=== [/getCreditNotes] ===');

      final dynamic responseJson = jsonDecode(responseApi.body);

      if (responseApi.statusCode == 200) {
        return ResponseApiModel(
            responsestate: Constants.successState,
            message: 'Success',
            data: responseJson);
      }

      final String errMsg =
          (responseJson is Map && responseJson['message'] != null)
              ? responseJson['message']
              : 'Gagal memuat pengembalian dana';
      return ResponseApiModel(
          responsestate: Constants.errorState, message: errMsg, data: null);
    } catch (e) {
      debugPrint('getCreditNotes Error: $e');
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          responsestate: Constants.serverErrState,
          message: 'Server error',
          data: null);
    }
  }

  Future<ResponseApiModel> getPosTransaction() async {
    try {
      final responseApi = await http.get(_getUri(EndPoint.posTransaction),
          headers: _getAuthHeaders());
      final responseJson = jsonDecode(responseApi.body);

      _logApiCall('GET', _getUri(EndPoint.posTransaction), null,
          response: responseApi.body, statusCode: responseApi.statusCode);

      if (responseApi.statusCode == 200) {
        return ResponseApiModel(
            responsestate: Constants.successState,
            message: 'Success',
            data: responseJson);
      }
      return const ResponseApiModel(
          responsestate: Constants.errorState,
          message: 'Gagal memuat transaksi',
          data: null);
    } catch (e) {
      debugPrint('getPosTransaction Error: $e');
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          responsestate: Constants.serverErrState,
          message: 'Server error',
          data: null);
    }
  }

  Future<ResponseApiModel> updatePosOptions(Map<String, dynamic> data) async {
    try {
      final uri = _getUri(EndPoint.posOptions);
      final bodyStr = jsonEncode(data);
      final responseApi = await http
          .put(
            uri,
            headers: _getAuthHeaders(),
            body: bodyStr,
          )
          .timeout(const Duration(seconds: 15));
      final responseJson = jsonDecode(responseApi.body);

      // DEBUG LOG — cek di Flutter console / logcat
      debugPrint('╔══════════════════════════════════════════════════');
      debugPrint('║ [API DEBUG] PUT pos_options');
      debugPrint('║ URL    : $uri');
      debugPrint('║ BODY   : $bodyStr');
      debugPrint('║ STATUS : ${responseApi.statusCode}');
      debugPrint('║ RESP   : ${responseApi.body}');
      debugPrint('╚══════════════════════════════════════════════════');

      bool isSuccess = false;
      if (responseApi.statusCode == 200) {
        if (responseJson['status'] == true ||
            responseJson['success'] == true ||
            responseJson['message']
                    ?.toString()
                    .toLowerCase()
                    .contains('success') ==
                true) {
          isSuccess = true;
        } else if (!responseJson.containsKey('status') &&
            !responseJson.containsKey('success')) {
          // If no status flag but 200 OK, consider it a success.
          isSuccess = true;
        }
      }

      if (isSuccess) {
        return const ResponseApiModel(
            responsestate: Constants.successState,
            message: 'Berhasil menyimpan pengaturan',
            data: null);
      }
      return ResponseApiModel(
          responsestate: Constants.errorState,
          message: responseJson['message'] ?? 'Gagal menyimpan pengaturan',
          data: null);
    } catch (e) {
      debugPrint('updatePosOptions Error: $e');
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException) {
        rethrow;
      }
      return const ResponseApiModel(
          responsestate: Constants.serverErrState,
          message: 'Server error',
          data: null);
    }
  }

  void _logApiCall(String method, Uri uri, dynamic body,
      {String? response, int? statusCode}) {
    final timestamp = DateTime.now().toString();
    debugPrint('');
    debugPrint('=== [DEBUG API CALL] ===');
    debugPrint('Time: $timestamp');
    debugPrint('Endpoint: [$method] $uri');
    if (body != null) {
      debugPrint('Payload: ${jsonEncode(body)}');
    }
    if (response != null) {
      debugPrint('Status Code: $statusCode');
      debugPrint('Response: $response');
    }
    debugPrint('=========================');
    debugPrint('');
  }

  Future<ResponseApiModel> getStaff() async {
    try {
      final responseApi = await http.get(_getUri(EndPoint.posStaff),
          headers: _getAuthHeaders());
      if (responseApi.statusCode == 200) {
        dynamic dataResponse;
        try {
          dataResponse = jsonDecode(responseApi.body);
        } catch (_) {
          debugPrint('getStaff Invalid JSON: ${responseApi.body}');
          String errorMsg = 'Server Error: ';
          if (responseApi.body.contains('<p>')) {
            final RegExp exp = RegExp(r'<p>(.*?)<\/p>');
            final match = exp.firstMatch(responseApi.body);
            if (match != null) errorMsg = match.group(1) ?? errorMsg;
          }
          return ResponseApiModel(
              message: errorMsg,
              responsestate: Constants.serverErrState,
              data: null);
        }
        List rawList = [];
        if (dataResponse is List) {
          rawList = dataResponse;
        } else if (dataResponse is Map) {
          final dynamic data = dataResponse['data'] ?? dataResponse;
          if (data is List) rawList = data;
        }

        return ResponseApiModel(
            responsestate: Constants.successState,
            message: 'success',
            data: rawList.map((item) => StaffModel.fromJson(item)).toList());
      } else {
        return ResponseApiModel(
            responsestate: Constants.errorState,
            message: 'Gagal memuat data staff (HTTP ${responseApi.statusCode})',
            data: null);
      }
    } catch (e) {
      debugPrint('GetStaff Error: $e');
      return ResponseApiModel(
          responsestate: Constants.errorState,
          message: 'Server error: $e',
          data: null);
    }
  }

  Future<ResponseApiModel> createStaff(Map<String, dynamic> data) async {
    final uri = _getUri(EndPoint.posStaff);
    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_getAuthHeaders(isMultipart: true));
      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 15));
      final responseApi = await http.Response.fromStream(streamedResponse);
      dynamic dataResponse;
      try {
        dataResponse = jsonDecode(responseApi.body);
      } catch (_) {
        debugPrint('createStaff Invalid JSON: ${responseApi.body}');
        String errorMsg = 'Server Error: ';
        if (responseApi.body.contains('<p>')) {
          final RegExp exp = RegExp(r'<p>(.*?)<\/p>');
          final match = exp.firstMatch(responseApi.body);
          if (match != null) errorMsg = match.group(1) ?? errorMsg;
        }
        return ResponseApiModel(
            message: errorMsg,
            responsestate: Constants.serverErrState,
            data: null);
      }
      if (responseApi.statusCode == 200 || responseApi.statusCode == 201) {
        bool isError = false;
        String? message;
        dynamic dataPayload;

        if (dataResponse is Map) {
          isError = dataResponse['status'] == false ||
              dataResponse['status'] == 'error';
          message = dataResponse['message'];
          dataPayload = dataResponse['data'];
        }

        if (!isError) {
          return ResponseApiModel(
            responsestate: Constants.successState,
            message: message ?? 'Staff created',
            data: dataPayload ?? dataResponse,
          );
        }
        return ResponseApiModel(
          responsestate: Constants.errorState,
          message: message ?? 'Failed to create staff',
          data: null,
        );
      } else {
        String? message;
        if (dataResponse is Map) message = dataResponse['message'];
        return ResponseApiModel(
          responsestate: Constants.errorState,
          message: message ?? 'HTTP ${responseApi.statusCode}',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('createStaff Error: $e');
      return ResponseApiModel(
        responsestate: Constants.errorState,
        message: 'Server error: $e',
        data: null,
      );
    }
  }
}
