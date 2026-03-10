import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/model_service.dart';

final ModelManager modelManager = ModelManager();

class ModelManager extends ChangeNotifier {
  bool isUploading = false;
  bool isLoading = false;
  List<Map<String, dynamic>> userModels = [];
  String statusMessage = "";
  final ModelService _modelService = ModelService();

  Future<bool> uploadModel(Uint8List imageBytes) async {
    isUploading = true;
    statusMessage = "Đang tải ảnh lên...";
    notifyListeners();

    try {
      final isSuccess = await _modelService.createModel(imageBytes);
      statusMessage = isSuccess ? "Thêm model thành công!" : "Lỗi khi thêm model.";
      return isSuccess;
    } catch (e) {
      statusMessage = "Lỗi kết nối.";
      return false;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyModels() async {
    isLoading = true;
    notifyListeners();

    try {
      final models = await _modelService.getMyModels();
      userModels = models;
    } catch (e) {
      debugPrint("Error fetching models: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}