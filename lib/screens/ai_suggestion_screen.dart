import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/clothing_item.dart';
import '../widgets/ai_range_selector.dart';
import 'ai_result_screen.dart';
import '../models/wardrobe_item_model.dart';
class AISuggestionScreen extends StatefulWidget {
  final dynamic selectedItem;
  //final Map<String, dynamic> selectedItem;

  const AISuggestionScreen({super.key, required this.selectedItem});

  @override
  State<AISuggestionScreen> createState() => _AISuggestionScreenState();
}

class _AISuggestionScreenState extends State<AISuggestionScreen> {
  // Mặc định chọn tìm trong tủ đồ cá nhân
  List<String> _selectedRanges = ['My Wardrobe'];
  final TextEditingController _promptController = TextEditingController();

  String get _itemName {
    if (widget.selectedItem is WardrobeItemModel) {
      return (widget.selectedItem as WardrobeItemModel).itemName;
    }
    return widget.selectedItem['itemName'] ?? "Item";
  }

  String? get _imageUrl {
    if (widget.selectedItem is WardrobeItemModel) {
      return (widget.selectedItem as WardrobeItemModel).imageUrl;
    }
    return widget.selectedItem['primaryImageUrl'] ?? widget.selectedItem['imageUrl'];
  }
  void _toggleRange(String rangeId) {
    setState(() {
      if (_selectedRanges.contains(rangeId)) {
        if (_selectedRanges.length > 1) {
          _selectedRanges.remove(rangeId);
        }
      } else {
        _selectedRanges.add(rangeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("AI Stylist", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Gợi ý đồ phối cùng với:", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: 160,
                      height: 200,
                      child: ClothingItem(
                        title: _itemName,
                        imageUrl: _imageUrl,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text("Phạm vi tìm kiếm (có thể chọn nhiều):",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 16),
                  AIRangeSelector(
                    selectedRanges: _selectedRanges,
                    onSelect: _toggleRange,
                  ),

                  if (_selectedRanges.contains('Others')) ...[
                    const SizedBox(height: 16),
                    _buildSearchBox(),
                  ],
                ],
              ),
            ),
          ),
          _buildPromptBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
      child: const TextField(
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Nhập tên người dùng hoặc ID tủ đồ...",
          hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.white24, size: 20),
        ),
      ),
    );
  }

  Widget _buildPromptBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(25), border: Border.all(color: AppColors.divider)),
                child: TextField(
                  controller: _promptController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Thêm yêu cầu (vd: đi tiệc, năng động...)",
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                // CHUYỂN DỮ LIỆU SANG MÀN HÌNH KẾT QUẢ
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => AIResultScreen(
                      baseItem: widget.selectedItem,
                      prompt: _promptController.text,
                      useMyWardrobe: _selectedRanges.contains('My Wardrobe'),
                      useCommunityItems: _selectedRanges.contains('Others'),
                    )
                ));
              },
              child: const CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.textPink,
                child: Icon(Icons.auto_awesome, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}