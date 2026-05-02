import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import '../models/item_commerce_model.dart';
import '../models/item_variant_model.dart';
import '../models/public_item_detail_model.dart';
import '../models/public_wardrobe_item_model.dart';
import '../models/wardrobe_item_model.dart';

class ItemService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _buildHeaders({bool withAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': '69420',
    };

    if (withAuth) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  bool _isSuccessStatus(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  Exception _buildExceptionFromResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);

      if (body is Map<String, dynamic>) {
        final message = body['message']?.toString();
        if (message != null && message.trim().isNotEmpty) {
          return Exception(message);
        }
      }
    } catch (_) {}

    switch (response.statusCode) {
      case 400:
        return Exception('Bad request.');
      case 401:
        return Exception('Unauthorized. Please log in again.');
      case 403:
        return Exception('You do not have permission to perform this action.');
      case 404:
        return Exception('Requested data was not found.');
      case 500:
        return Exception('Server error. Please try again later.');
      default:
        return Exception('Request failed with status ${response.statusCode}.');
    }
  }

  Future<Map<String, dynamic>> getMyItemsPaginated(
      int page,
      int pageSize, {
        String searchQuery = '',
      }) async {
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.getAllMyItemEndpoint}",
    ).replace(
      queryParameters: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        if (searchQuery.isNotEmpty) 'search': searchQuery,
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: await _buildHeaders(withAuth: true),
      );

      if (_isSuccessStatus(response.statusCode)) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);

        if (decodedData['data'] != null &&
            decodedData['data'] is Map<String, dynamic>) {
          return decodedData['data'] as Map<String, dynamic>;
        }
      }

      return {'items': [], 'totalPages': 1};
    } catch (e) {
      debugPrint("Error getMyItemsPaginated: $e");
      return {'items': [], 'totalPages': 1};
    }
  }

  Future<List<WardrobeItemModel>> getMyItems() async {
    final url = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.getAllMyItemEndpoint}",
    );

    final response = await http.get(
      url,
      headers: await _buildHeaders(withAuth: true),
    );

    if (_isSuccessStatus(response.statusCode)) {
      final Map<String, dynamic> decodedData = jsonDecode(response.body);
      final list = decodedData['data'] as List<dynamic>? ?? [];

      return list
          .map((e) => WardrobeItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw _buildExceptionFromResponse(response);
  }

  Future<Map<String, dynamic>> getItemById(int itemId) async {
    final endpoint = ApiConstants.getItemByIdEndpoint.replaceFirst(
      '{itemId}',
      itemId.toString(),
    );
    final url = Uri.parse("${ApiConstants.baseUrl}$endpoint");

    final response = await http.get(
      url,
      headers: await _buildHeaders(),
    );

    if (_isSuccessStatus(response.statusCode)) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw _buildExceptionFromResponse(response);
  }

  Future<PublicItemDetailModel> getPublicItemDetail(int itemId) async {
    final endpoint = ApiConstants.publicItemDetailEndpoint.replaceFirst(
      '{itemId}',
      itemId.toString(),
    );
    final url = Uri.parse("${ApiConstants.baseUrl}$endpoint");

    final response = await http.get(
      url,
      headers: await _buildHeaders(),
    );

    if (_isSuccessStatus(response.statusCode)) {
      final Map<String, dynamic> body = jsonDecode(response.body);

      if (body['data'] == null || body['data'] is! Map<String, dynamic>) {
        throw Exception('Invalid public item detail data.');
      }

      return PublicItemDetailModel.fromJson(
        body['data'] as Map<String, dynamic>,
      );
    }

    throw _buildExceptionFromResponse(response);
  }

  Future<void> deleteItem(int itemId) async {
    final endpoint = ApiConstants.deleteItemEndpoint.replaceFirst(
      '{itemId}',
      itemId.toString(),
    );
    final url = Uri.parse("${ApiConstants.baseUrl}$endpoint");

    final response = await http.delete(
      url,
      headers: await _buildHeaders(withAuth: true),
    );

    if (!_isSuccessStatus(response.statusCode)) {
      throw _buildExceptionFromResponse(response);
    }
  }

  Future<void> updateItem(int itemId, Map<String, dynamic> data) async {
    final endpoint = ApiConstants.updateItemEndpoint.replaceFirst(
      '{itemId}',
      itemId.toString(),
    );
    final url = Uri.parse("${ApiConstants.baseUrl}$endpoint");

    final response = await http.put(
      url,
      headers: await _buildHeaders(withAuth: true),
      body: jsonEncode(data),
    );

    if (!_isSuccessStatus(response.statusCode)) {
      throw _buildExceptionFromResponse(response);
    }
  }

  Future<List<dynamic>> getSmartRecommendations({
    required int? referenceItemId,
    required String prompt,
    required bool useMyWardrobe,
    required bool useSavedItems,
    required bool useMyStylePreferences,
    required bool useMyPhysicalProfile,
    required List<int> targetWardrobeIds,
    int limit = 10,
  }) async {
    final url = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.smartMatchEndpoint}",
    );

    final payload = {
      'prompt': prompt,
      'referenceItemId': referenceItemId,
      'targetWardrobeIds': targetWardrobeIds,
      'includeMyWardrobe': useMyWardrobe,
      'includeSavedItems': useSavedItems,
      'useMyStylePreferences': useMyStylePreferences,
      'useMyPhysicalProfile': useMyPhysicalProfile,
      'limit': limit,
    };

    debugPrint("Sending smart match payload: ${jsonEncode(payload)}");

    final response = await http.post(
      url,
      headers: await _buildHeaders(withAuth: true),
      body: jsonEncode(payload),
    );

    debugPrint("Smart match status: ${response.statusCode}");
    debugPrint("Smart match body: ${response.body}");

    if (_isSuccessStatus(response.statusCode)) {
      final decodedData = jsonDecode(utf8.decode(response.bodyBytes));

      if (decodedData is Map<String, dynamic> &&
          decodedData['data'] != null &&
          decodedData['data'] is List) {
        return decodedData['data'] as List<dynamic>;
      }

      return [];
    }

    throw _buildExceptionFromResponse(response);
  }

  Future<int?> sendConsultRequest(int itemId) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/Chat/consult/$itemId"),
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': '69420',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    if (_isSuccessStatus(response.statusCode)) {
      final body = jsonDecode(response.body);
      return body['groupId'] is int
          ? body['groupId'] as int
          : int.tryParse(body['groupId'].toString());
    }

    throw _buildExceptionFromResponse(response);
  }

  Future<void> saveItem(int itemId) async {
    final endpoint = ApiConstants.saveItemEndpoint.replaceFirst(
      '{itemId}',
      itemId.toString(),
    );
    final url = Uri.parse("${ApiConstants.baseUrl}$endpoint");

    final response = await http.post(
      url,
      headers: await _buildHeaders(withAuth: true),
    );

    if (!_isSuccessStatus(response.statusCode)) {
      throw _buildExceptionFromResponse(response);
    }
  }

  Future<void> unsaveItem(int itemId) async {
    final endpoint = ApiConstants.saveItemEndpoint.replaceFirst(
      '{itemId}',
      itemId.toString(),
    );
    final url = Uri.parse("${ApiConstants.baseUrl}$endpoint");

    final response = await http.delete(
      url,
      headers: await _buildHeaders(withAuth: true),
    );

    if (!_isSuccessStatus(response.statusCode)) {
      throw _buildExceptionFromResponse(response);
    }
  }

  Future<List<PublicWardrobeItemModel>> getSavedItems() async {
    final url = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.getMySaveItemEndpoint}",
    );

    final response = await http.get(
      url,
      headers: await _buildHeaders(withAuth: true),
    );

    if (_isSuccessStatus(response.statusCode)) {
      final body = jsonDecode(response.body);

      if (body is Map<String, dynamic>) {
        final list = body['data'] as List<dynamic>? ?? [];
        return list
            .map(
              (e) => PublicWardrobeItemModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
            .toList();
      }

      if (body is List) {
        return body
            .map(
              (e) => PublicWardrobeItemModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
            .toList();
      }

      return [];
    }

    throw _buildExceptionFromResponse(response);
  }

  Future<ItemCommerceModel> publishItem({
    required int itemId,
    required double listedPrice,
    String? condition,
    required List<Map<String, dynamic>> variants,
  }) async {
    final endpoint = ApiConstants.publishItemEndpoint.replaceFirst(
      '{itemId}',
      itemId.toString(),
    );
    final url = Uri.parse("${ApiConstants.baseUrl}$endpoint");

    final response = await http.post(
      url,
      headers: await _buildHeaders(withAuth: true),
      body: jsonEncode({
        'listedPrice': listedPrice,
        'condition': condition,
        'variants': variants,
      }),
    );

    if (_isSuccessStatus(response.statusCode)) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ItemCommerceModel.fromJson(body['data'] as Map<String, dynamic>);
    }

    throw _buildExceptionFromResponse(response);
  }

  Future<ItemCommerceModel> unpublishItem(int itemId) async {
    final endpoint = ApiConstants.unpublishItemEndpoint.replaceFirst(
      '{itemId}',
      itemId.toString(),
    );
    final url = Uri.parse("${ApiConstants.baseUrl}$endpoint");

    final response = await http.post(
      url,
      headers: await _buildHeaders(withAuth: true),
    );

    if (_isSuccessStatus(response.statusCode)) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ItemCommerceModel.fromJson(body['data'] as Map<String, dynamic>);
    }

    throw _buildExceptionFromResponse(response);
  }

  Future<List<ItemVariantModel>> getItemVariants(int itemId) async {
    final endpoint = ApiConstants.getItemVariantsEndpoint.replaceFirst(
      '{itemId}',
      itemId.toString(),
    );
    final url = Uri.parse("${ApiConstants.baseUrl}$endpoint");

    final response = await http.get(
      url,
      headers: await _buildHeaders(withAuth: true),
    );

    if (_isSuccessStatus(response.statusCode)) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final list = body['data'] as List<dynamic>? ?? [];

      return list
          .map((e) => ItemVariantModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw _buildExceptionFromResponse(response);
  }

  Future<ItemVariantModel> createItemVariant({
    required int itemId,
    required Map<String, dynamic> data,
  }) async {
    final endpoint = ApiConstants.createItemVariantEndpoint.replaceFirst(
      '{itemId}',
      itemId.toString(),
    );
    final url = Uri.parse("${ApiConstants.baseUrl}$endpoint");

    final response = await http.post(
      url,
      headers: await _buildHeaders(withAuth: true),
      body: jsonEncode(data),
    );

    if (_isSuccessStatus(response.statusCode)) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ItemVariantModel.fromJson(body['data'] as Map<String, dynamic>);
    }

    throw _buildExceptionFromResponse(response);
  }

  Future<ItemVariantModel> updateItemVariant({
    required int itemVariantId,
    required Map<String, dynamic> data,
  }) async {
    final endpoint = ApiConstants.updateItemVariantEndpoint.replaceFirst(
      '{itemVariantId}',
      itemVariantId.toString(),
    );
    final url = Uri.parse("${ApiConstants.baseUrl}$endpoint");

    final response = await http.put(
      url,
      headers: await _buildHeaders(withAuth: true),
      body: jsonEncode(data),
    );

    if (_isSuccessStatus(response.statusCode)) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ItemVariantModel.fromJson(body['data'] as Map<String, dynamic>);
    }

    throw _buildExceptionFromResponse(response);
  }

  Future<void> deleteItemVariant(int itemVariantId) async {
    final endpoint = ApiConstants.deleteItemVariantEndpoint.replaceFirst(
      '{itemVariantId}',
      itemVariantId.toString(),
    );
    final url = Uri.parse("${ApiConstants.baseUrl}$endpoint");

    final response = await http.delete(
      url,
      headers: await _buildHeaders(withAuth: true),
    );

    if (!_isSuccessStatus(response.statusCode)) {
      throw _buildExceptionFromResponse(response);
    }
  }
}