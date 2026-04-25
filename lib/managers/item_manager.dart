import 'package:flutter/foundation.dart';

import '../models/item_commerce_model.dart';
import '../models/item_variant_model.dart';
import '../models/public_item_detail_model.dart';
import '../models/public_wardrobe_item_model.dart';
import '../models/wardrobe_item_model.dart';
import '../services/item_service.dart';

class ItemManager extends ChangeNotifier {
  final ItemService _itemService = ItemService();

  bool isLoading = false;
  String? errorMessage;

  List<WardrobeItemModel> myItems = [];
  List<PublicWardrobeItemModel> savedItems = [];

  ItemCommerceModel? commerceInfo;
  List<ItemVariantModel> variants = [];

  Future<void> loadMyItems() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      myItems = await _itemService.getMyItems();
    } catch (e) {
      errorMessage = _normalizeError(e);
      myItems = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSavedItems() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      savedItems = await _itemService.getSavedItems();
    } catch (e) {
      errorMessage = _normalizeError(e);
      savedItems = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> publishItem({
    required int itemId,
    required double listedPrice,
    String? condition,
    required List<Map<String, dynamic>> variantsPayload,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final result = await _itemService.publishItem(
        itemId: itemId,
        listedPrice: listedPrice,
        condition: condition,
        variants: variantsPayload,
      );

      commerceInfo = result;
      variants = result.variants;

      myItems = myItems.map((item) {
        if (item.itemId != itemId) {
          return item;
        }

        return item.copyWith(
          isForSale: result.isForSale,
          listedPrice: result.listedPrice,
          condition: result.condition,
        );
      }).toList();

      return true;
    } catch (e) {
      errorMessage = _normalizeError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> unpublishItem(int itemId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final result = await _itemService.unpublishItem(itemId);

      commerceInfo = result;
      variants = result.variants;

      myItems = myItems.map((item) {
        if (item.itemId != itemId) {
          return item;
        }

        return item.copyWith(
          isForSale: result.isForSale,
          listedPrice: result.listedPrice,
          condition: result.condition,
        );
      }).toList();

      return true;
    } catch (e) {
      errorMessage = _normalizeError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadItemVariants(int itemId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      variants = await _itemService.getItemVariants(itemId);
    } catch (e) {
      errorMessage = _normalizeError(e);
      variants = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createVariant({
    required int itemId,
    required String sku,
    String? sizeCode,
    String? color,
    required double price,
    required int stockQuantity,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final result = await _itemService.createItemVariant(
        itemId: itemId,
        data: {
          'sku': sku,
          'sizeCode': sizeCode,
          'color': color,
          'price': price,
          'stockQuantity': stockQuantity,
        },
      );

      variants = [...variants, result];
      return true;
    } catch (e) {
      errorMessage = _normalizeError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateVariant({
    required int itemVariantId,
    required String sku,
    String? sizeCode,
    String? color,
    required double price,
    required int stockQuantity,
    required int status,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final result = await _itemService.updateItemVariant(
        itemVariantId: itemVariantId,
        data: {
          'sku': sku,
          'sizeCode': sizeCode,
          'color': color,
          'price': price,
          'stockQuantity': stockQuantity,
          'status': status,
        },
      );

      final index = variants.indexWhere(
            (v) => v.itemVariantId == itemVariantId,
      );

      if (index != -1) {
        final updatedVariants = [...variants];
        updatedVariants[index] = result;
        variants = updatedVariants;
      } else {
        variants = [...variants, result];
      }

      return true;
    } catch (e) {
      errorMessage = _normalizeError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteVariant(int itemVariantId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _itemService.deleteItemVariant(itemVariantId);

      variants = variants
          .where((v) => v.itemVariantId != itemVariantId)
          .toList();

      return true;
    } catch (e) {
      errorMessage = _normalizeError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveItem(int itemId) async {
    try {
      errorMessage = null;

      await _itemService.saveItem(itemId);

      myItems = myItems.map((item) {
        if (item.itemId != itemId) {
          return item;
        }
        return item.copyWith(isSaved: true);
      }).toList();

      savedItems = savedItems.map((item) {
        if (item.itemId != itemId) {
          return item;
        }
        return item.copyWith(isSaved: true);
      }).toList();

      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = _normalizeError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> unsaveItem(int itemId) async {
    try {
      errorMessage = null;

      await _itemService.unsaveItem(itemId);

      myItems = myItems.map((item) {
        if (item.itemId != itemId) {
          return item;
        }
        return item.copyWith(isSaved: false);
      }).toList();

      savedItems = savedItems
          .where((item) => item.itemId != itemId)
          .map((item) => item.copyWith(isSaved: false))
          .toList();

      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = _normalizeError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(int itemId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _itemService.deleteItem(itemId);

      myItems = myItems.where((item) => item.itemId != itemId).toList();
      savedItems = savedItems.where((item) => item?.itemId != itemId).toList();

      if (commerceInfo?.itemId == itemId) {
        commerceInfo = null;
        variants = [];
      }

      return true;
    } catch (e) {
      errorMessage = _normalizeError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateItem(int itemId, Map<String, dynamic> data) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _itemService.updateItem(itemId, data);
      await loadMyItems();
      return true;
    } catch (e) {
      errorMessage = _normalizeError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<PublicItemDetailModel?> getPublicItemDetail(int itemId) async {
    try {
      errorMessage = null;
      notifyListeners();

      return await _itemService.getPublicItemDetail(itemId);
    } catch (e) {
      errorMessage = _normalizeError(e);
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void clearCommerceState() {
    commerceInfo = null;
    variants = [];
    errorMessage = null;
    notifyListeners();
  }

  String _normalizeError(Object error) {
    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '');
    }
    return text;
  }
}