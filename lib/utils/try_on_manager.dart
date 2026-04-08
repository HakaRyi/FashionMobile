// lib/utils/try_on_manager.dart
// lib/utils/try_on_manager.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../models/try_on_history_model.dart';
import '../services/try_on_history_service.dart';
import '../services/try_on_info_service.dart';
import '../services/try_on_service.dart';

final TryOnManager tryOnManager = TryOnManager();

class TryOnManager extends ChangeNotifier {
  bool isProcessing = false;
  bool isLoadingHistory = false;
  bool isLoadingInfo = false;

  Uint8List? resultImageBytes;
  String? errorMessage;

  double balance = 0;
  double locked = 0;
  double available = 0;
  double price = 0;
  bool canTry = false;
  String infoMessage = "";

  List<TryOnHistoryModel> history = [];

  final TryOnService _service = TryOnService();
  final TryOnHistoryService _historyService = TryOnHistoryService();
  final TryOnInfoService _infoService = TryOnInfoService();

  Future<void> loadInfo() async {
    isLoadingInfo = true;
    notifyListeners();

    try {
      final data = await _infoService.getInfo();

      balance = _toDouble(data["balance"]);
      locked = _toDouble(data["lockedBalance"]);
      available = _toDouble(data["availableBalance"]);
      price = _toDouble(data["tryOnPrice"]);
      canTry = data["canTryOn"] == true;
      infoMessage = (data["message"] ?? "").toString();
    } catch (e) {
      debugPrint("TryOnManager.loadInfo error: $e");
    } finally {
      isLoadingInfo = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    isLoadingHistory = true;
    notifyListeners();

    try {
      history = await _historyService.getMyHistory();
    } catch (e) {
      debugPrint("TryOnManager.loadHistory error: $e");
    } finally {
      isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> tryOn({
    required BuildContext context,
    String? modelAssetPath,
    String? modelImageUrl,
    required String clothPath,
  }) async {
    if (isProcessing) return;

    isProcessing = true;
    errorMessage = null;
    resultImageBytes = null;
    notifyListeners();

    try {
      final Uint8List result = await _service.processTryOn(
        modelAssetPath: modelAssetPath,
        modelImageUrl: modelImageUrl,
        clothImagePath: clothPath,
      );

      resultImageBytes = result;

      await loadInfo();
      await loadHistory();

      _showSuccess(context);
    } on ApiException catch (e) {
      errorMessage = e.message;
      await loadInfo();
      _showError(context, e.message);
    } catch (e) {
      errorMessage = "Lỗi không xác định: $e";
      await loadInfo();
      _showError(context, errorMessage!);
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> deleteHistory(int id) async {
    final oldHistory = List<TryOnHistoryModel>.from(history);

    history.removeWhere((item) => item.id == id);
    notifyListeners();

    try {
      await _historyService.deleteHistory(id);
    } catch (e) {
      history = oldHistory;
      notifyListeners();
      rethrow;
    }
  }

  void reset() {
    resultImageBytes = null;
    errorMessage = null;
    notifyListeners();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  void _showSuccess(BuildContext context) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Try-on thành công 🎉"),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}