import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ModelService {
  //CREATE MODEL
  Future<bool> createModel(Uint8List imageBytes) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/model/create");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      var request = http.MultipartRequest('POST', url);
      request.headers.addAll({'Authorization': 'Bearer $token'});

      request.files.add(http.MultipartFile.fromBytes(
        'Image',
        imageBytes,
        filename: 'model_image.jpg',
      ));

      final response = await request.send();
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  //GET MY MODELS
  Future<List<Map<String, dynamic>>> getMyModels() async {
    final url = Uri.parse("${ApiConstants.baseUrl}/Model/my-models");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}