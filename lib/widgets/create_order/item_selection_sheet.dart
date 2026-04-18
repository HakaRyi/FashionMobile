import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/wardrobe_service.dart';
import '../../models/wardrobe_item_model.dart';

class ItemSelectionSheet extends StatefulWidget {
  final WardrobeService wardrobeService;
  final List<WardrobeItemModel> initialSelectedItems;
  final Function(List<WardrobeItemModel>) onSelectionConfirmed;

  const ItemSelectionSheet({
    super.key,
    required this.wardrobeService,
    required this.initialSelectedItems,
    required this.onSelectionConfirmed,
  });

  @override
  State<ItemSelectionSheet> createState() => _ItemSelectionSheetState();
}

class _ItemSelectionSheetState extends State<ItemSelectionSheet> {
  List<WardrobeItemModel> _allItems = [];
  List<WardrobeItemModel> _filteredItems = [];
  List<WardrobeItemModel> _currentSelected = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _currentSelected = List.from(widget.initialSelectedItems);
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      final items = await widget.wardrobeService.getMyWardrobeItems();
      if (mounted) {
        setState(() {
          _allItems = items;
          _filteredItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems.where((item) {
          return item.itemName.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _toggleSelection(WardrobeItemModel item) {
    setState(() {
      final isSelected = _currentSelected.any((element) => element.itemId == item.itemId);
      if (isSelected) {
        _currentSelected.removeWhere((element) => element.itemId == item.itemId);
      } else {
        _currentSelected.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Chọn sản phẩm",
                      style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: () => widget.onSelectionConfirmed(_currentSelected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text("Xác nhận (${_currentSelected.length})", style: const TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: _filterItems,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm tên sản phẩm...',
                    hintStyle: const TextStyle(color: Colors.black54),
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
                    : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)))
                    : _filteredItems.isEmpty
                    ? const Center(child: Text("Không tìm thấy sản phẩm nào.", style: TextStyle(color: Colors.white54)))
                    : ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  itemCount: _filteredItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    final isSelected = _currentSelected.any((element) => element.itemId == item.itemId);

                    return GestureDetector(
                      onTap: () => _toggleSelection(item),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.pink.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? Colors.pinkAccent : Colors.white10),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.imageUrl != null && item.imageUrl!.isNotEmpty
                                    ? item.imageUrl!
                                    : 'https://via.placeholder.com/150',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 50, height: 50, color: Colors.grey[800],
                                  child: const Icon(Icons.image, color: Colors.white54),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.itemName,
                                    style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.brand ?? 'Không có thương hiệu',
                                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                              color: isSelected ? Colors.pinkAccent : AppColors.backgroundTertiary,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}