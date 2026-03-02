import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class OutfitService {
  Future<bool> saveOutfit(Uint8List imageBytes, String name) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/Outfit");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['OutfitName'] = name;

      request.files.add(http.MultipartFile.fromBytes(
        'Image',
        imageBytes,
        filename: 'my_outfit.jpg',
      ));

      final response = await request.send();

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}