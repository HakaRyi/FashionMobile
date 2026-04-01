// lib/utils/try_on_manager.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/try_on_history_service.dart';
import '../services/try_on_service.dart';

final TryOnManager tryOnManager = TryOnManager();

class TryOnManager extends ChangeNotifier {
  bool isProcessing = false;
  Uint8List? resultImageBytes;
  final TryOnService _service = TryOnService();
  List<Map<String, dynamic>> historyList = [];
  bool isLoadingHistory = false;

  final TryOnHistoryService _historyService = TryOnHistoryService();

  Future<void> startTryOn(
      BuildContext globalContext, {
        String? modelAssetPath,
        String? modelImageUrl,
        required String clothFilePath,
      }) async {
    if (isProcessing) return;

    isProcessing = true;
    resultImageBytes = null;
    notifyListeners();

    final result = await _service.processTryOn(
      modelAssetPath: modelAssetPath,
      modelImageUrl: modelImageUrl,
      clothImagePath: clothFilePath,
    );

    isProcessing = false;
    if (result != null) {
      resultImageBytes = result;
      if (resultImageBytes != null) {
        await _historyService.saveHistory(resultImageBytes!);
        await fetchHistory();
      }
      _showSuccessNotification(globalContext);
    } else {
      _showErrorNotification(globalContext);
    }

    notifyListeners();
  }

  void resetResult() {
    resultImageBytes = null;
    notifyListeners();
  }

  void _showSuccessNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Đã xử lý xong quần áo! Chạm để xem."),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: "XEM",
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showErrorNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Lỗi xử lý quần áo, vui lòng thử lại!"),
        backgroundColor: Colors.red,
      ),
    );
  }

  void setMockResultBytes(Uint8List bytes) {
    resultImageBytes = bytes;
    isProcessing = false;
    notifyListeners();
  }

  Future<void> fetchHistory() async {
    isLoadingHistory = true;
    notifyListeners();

    try {
      historyList = await _historyService.getMyHistory();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      isLoadingHistory = false;
      notifyListeners();
    }
  }
}