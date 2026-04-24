import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../models/wardrobe_item_model.dart';
import '../../services/item_service.dart';
import '../../utils/route_transitions.dart';
import '../../utils/upload_utils.dart';
import '../../widgets/action_button.dart';
import '../../widgets/add_clothing_card.dart';
import '../../widgets/clothing_item.dart';
import '../ai_suggestion_screen.dart';
import '../clothing_detail_screen.dart';
import '../suggestion_screen.dart';
import '../try_on_screen.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  late Future<List<WardrobeItemModel>> _itemsFuture;
  final ItemService _itemService = ItemService();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _itemsFuture = _itemService.getMyItems();
    });
  }

  Future<void> _handleRefresh() async {
    _loadItems();
    await _itemsFuture;
  }

  Future<void> _confirmDelete(
      BuildContext context,
      WardrobeItemModel item,
      ) async {
    if (!mounted) {
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.menu,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          "Confirm Delete",
          style: TextStyle(color: Colors.black),
        ),
        content: Text(
          "The item '${item.itemName}' will be permanently deleted.",
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          color: AppColors.textPink,
        ),
      ),
    );

    try {
      await _itemService.deleteItem(item.itemId);

      if (!mounted) {
        return;
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Item deleted successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      _loadItems();
    } catch (e) {
      if (!mounted) {
        return;
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_normalizeError(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showActionMenu(BuildContext context, WardrobeItemModel item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.menu,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.auto_awesome,
                  color: Colors.black,
                ),
                title: const Text(
                  "AI Outfit Suggestion",
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    SlideRoute(
                      page: AISuggestionScreen(
                        selectedItem: {
                          'itemId': item.itemId,
                          'itemName': item.itemName,
                          'description': item.description,
                          'mainColor': item.mainColor,
                          'brand': item.brand,
                          'status': item.status,
                          'imageUrl': item.imageUrl,
                          'category': item.category,
                          'isSaved': item.isSaved,
                          'isOwner': item.isOwner,
                          'isForSale': item.isForSale,
                          'listedPrice': item.listedPrice,
                          'condition': item.condition,
                        },
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete,
                  color: Colors.black,
                ),
                title: const Text(
                  "Remove from Wardrobe",
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDelete(context, item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 16.0,
      ),
      child: Column(
        children: [
          const Text(
            "Wardrobe",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ActionButton(
                  icon: Icons.add_a_photo,
                  label: "Add Item",
                  color: AppColors.accent,
                  onTap: () async {
                    final result = await UploadUtils.showUploadMenu(context);
                    if (result == true) {
                      _loadItems();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ActionButton(
                  icon: Icons.history,
                  label: "Suggest History",
                  color: Colors.orangeAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SuggestionScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ActionButton(
                  icon: Icons.face,
                  label: "Try-On",
                  color: AppColors.textPink,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TryOnScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _normalizeError(Object error) {
    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '');
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.textPink,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context),
              ),
              const SliverToBoxAdapter(
                child: Divider(
                  color: AppColors.menu,
                  thickness: 0,
                ),
              ),
              FutureBuilder<List<WardrobeItemModel>>(
                future: _itemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.textPink,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _normalizeError(snapshot.error!),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final items = snapshot.data ?? [];

                  return SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverGrid(
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          if (index == items.length) {
                            return AddClothingCard(
                              onUploadSuccess: _loadItems,
                            );
                          }

                          final item = items[index];

                          return ClothingItem(
                            title: item.itemName.isEmpty
                                ? "Unnamed"
                                : item.itemName,
                            imageUrl: item.imageUrl,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClothingDetailScreen(
                                    itemData: {
                                      'itemId': item.itemId,
                                      'itemName': item.itemName,
                                      'description': item.description,
                                      'mainColor': item.mainColor,
                                      'brand': item.brand,
                                      'status': item.status,
                                      'imageUrl': item.imageUrl,
                                      'category': item.category,
                                      'isSaved': item.isSaved,
                                      'isOwner': item.isOwner,
                                      'isForSale': item.isForSale,
                                      'listedPrice': item.listedPrice,
                                      'condition': item.condition,
                                    },
                                  ),
                                ),
                              );

                              _loadItems();
                            },
                            onLongPress: () {
                              HapticFeedback.mediumImpact();
                              _showActionMenu(context, item);
                            },
                          );
                        },
                        childCount: items.length + 1,
                      ),
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ),
      ),
    );
  }
}