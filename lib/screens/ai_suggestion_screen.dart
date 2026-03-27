import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/clothing_item.dart';
import '../widgets/ai_range_selector.dart';
import 'ai_result_screen.dart'; // Import màn hình kết quả

class AISuggestionScreen extends StatefulWidget {
  final Map<String, dynamic> selectedItem;

  const AISuggestionScreen({super.key, required this.selectedItem});

  @override
  State<AISuggestionScreen> createState() => _AISuggestionScreenState();
}

class _AISuggestionScreenState extends State<AISuggestionScreen> {
  List<String> _selectedRanges = ['My Wardrobe'];
  final TextEditingController _promptController = TextEditingController();
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
        title: const Text("AI Stylist", style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hiển thị món đồ gốc
                  const Text("Gợi ý đồ phối cùng với:", style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: 160,
                      height: 200,
                      child: ClothingItem(
                        title: widget.selectedItem['itemName'] ?? "Item",
                        imageUrl: widget.selectedItem['primaryImageUrl'],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Range Selector
                  const Text("Phạm vi tìm kiếm (có thể chọn nhiều):",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  AIRangeSelector(
                    selectedRanges: _selectedRanges,
                    onSelect: _toggleRange,
                  ),

                  // Ô search nếu chọn 'Others'
                  if (_selectedRanges.contains('Others')) ...[
                    const SizedBox(height: 16),
                    _buildSearchBox(),
                  ],
                ],
              ),
            ),
          ),

          // Prompt Input ở dưới cùng
          _buildPromptBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
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
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(25)),
                child: TextField(
                  controller: _promptController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Thêm yêu cầu (vd: màu xanh, đi tiệc...)",
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                // Giả lập gửi data và chuyển sang Screen 3
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => AIResultScreen(
                      baseItem: widget.selectedItem,
                      prompt: _promptController.text,
                    )
                ));
              },
              child: CircleAvatar(
                backgroundColor: AppColors.textPink,
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}