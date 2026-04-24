import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../services/wallet_service.dart';
import '../services/wardrobe_service.dart';
import '../widgets/clothing_item.dart';
import 'ai_result_screen.dart';
import '../models/wardrobe_item_model.dart';

class AISuggestionScreen extends StatefulWidget {
  final dynamic selectedItem;

  const AISuggestionScreen({super.key, required this.selectedItem});

  @override
  State<AISuggestionScreen> createState() => _AISuggestionScreenState();
}

class _AISuggestionScreenState extends State<AISuggestionScreen> {
  // Mặc định chọn tìm trong tủ đồ cá nhân
  List<String> _selectedRanges = ['My Wardrobe'];
  final TextEditingController _promptController = TextEditingController();
  Timer? _debounce;
  List<dynamic> _searchResults = [];
  List<Map<String, dynamic>> _selectedOthers = [];
  bool _isSearching = false;

  final WalletService _walletService = WalletService();
  double _currentBalance = 0;
  final double _serviceCost = 2000;
  bool _isLoadingBalance = true;

  final NumberFormat _currencyFormatter = NumberFormat('#,##0', 'vi_VN');

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() { _searchResults = []; _isSearching = false; });
        return;
      }
      setState(() => _isSearching = true);
      final results = await WardrobeService().searchWardrobeByUsername(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
  }

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
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    try {
      final balance = await _walletService.getMyWalletBalance();
      if (mounted) {
        setState(() {
          _currentBalance = balance;
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
            "AI STYLIST",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 0)
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // BỐ CỤC MỚI: HÌNH BÊN TRÁI, 3 NÚT BÊN PHẢI
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Trái: Khung hình Reference Item
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                              "REFERENCE",
                              style: TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0)
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: 140, // Độ rộng vừa phải
                            height: 180,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))
                                ]
                            ),
                            child: ClothingItem(
                              itemData: {
                                'itemName': _itemName,
                                'primaryImageUrl': _imageUrl,
                                'itemId': widget.selectedItem is WardrobeItemModel
                                    ? (widget.selectedItem as WardrobeItemModel).itemId
                                    : (widget.selectedItem['itemId'] ?? 0),
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),

                      // Phải: 3 nút Personal Context
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                                "PERSONAL CONTEXT",
                                style: TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0)
                            ),
                            const SizedBox(height: 12),
                            _buildCustomOptionBtn('Saved', 'My Saved', Icons.bookmark_border),
                            const SizedBox(height: 10),
                            _buildCustomOptionBtn('StylePrefs', 'My Style', Icons.auto_awesome_mosaic_outlined),
                            const SizedBox(height: 10),
                            _buildCustomOptionBtn('PhysicalProfile', 'My Body', Icons.accessibility_new_outlined),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // DƯỚI: 2 NÚT NGUỒN WARDROBE
                  const Text(
                      "DATA SOURCES",
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0)
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildCustomOptionBtn('My Wardrobe', 'My Wardrobe', Icons.inventory_2_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCustomOptionBtn('Others', 'Other Users', Icons.people_outline)),
                    ],
                  ),

                  // SEARCH BOX CHO "OTHERS"
                  if (_selectedRanges.contains('Others')) ...[
                    const SizedBox(height: 24),
                    _buildSearchBox(),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildPromptBar(),
        ],
      ),
    );
  }

  // HÀM TẠO NÚT CUSTOM MỚI CHO TRANG NÀY
  Widget _buildCustomOptionBtn(String id, String label, IconData icon) {
    bool isSelected = _selectedRanges.contains(id);
    return GestureDetector(
      onTap: () => _toggleRange(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.2)),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black45, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black45,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
            "TARGET WARDROBES",
            style: TextStyle(color: Colors.black38, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
          ),
          child: TextField(
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: "Enter username to search...",
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
              border: InputBorder.none,
              icon: Icon(Icons.search, color: _isSearching ? Colors.black : Colors.black38, size: 20),
            ),
          ),
        ),

        // HIỂN THỊ KẾT QUẢ GỢI Ý
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: _searchResults.map((user) => Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundImage: user['avatarUrl'] != null ? NetworkImage(user['avatarUrl']) : null,
                      backgroundColor: Colors.black12,
                      child: user['avatarUrl'] == null ? const Icon(Icons.person, size: 16, color: Colors.white) : null,
                    ),
                    title: Text(user['userName'], style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.add_circle_outline, size: 18, color: Colors.black38),
                    onTap: () {
                      setState(() {
                        if (!_selectedOthers.any((element) => element['id'] == user['wardrobeId'])) {
                          _selectedOthers.add({'id': user['wardrobeId'], 'name': user['userName']});
                        }
                        _searchResults = [];
                      });
                    },
                  ),
                )).toList(),
              ),
            ),
          ),

        // HIỂN THỊ CHIPS TÀI KHOẢN ĐÃ CHỌN
        if (_selectedOthers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedOthers.map((w) => Chip(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: BorderSide.none,
                label: Text(w['name'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
                onDeleted: () => setState(() => _selectedOthers.remove(w)),
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildPromptBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SERVICE COST",
                        style: TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${_currencyFormatter.format(_serviceCost)} ₫",
                        style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withOpacity(0.04)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, size: 14, color: Colors.black87),
                        const SizedBox(width: 6),
                        Text(
                          "Balance: ${_isLoadingBalance ? "..." : "${_currencyFormatter.format(_currentBalance)} ₫"}",
                          style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(27),
                      border: Border.all(color: Colors.black.withOpacity(0.03)),
                    ),
                    child: TextField(
                      controller: _promptController,
                      style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        hintText: "Add details (e.g., party, vintage...)",
                        hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(
                        builder: (context) => AIResultScreen(
                          baseItem: widget.selectedItem,
                          prompt: _promptController.text,
                          useMyWardrobe: _selectedRanges.contains('My Wardrobe'),
                          includeSavedItems: _selectedRanges.contains('Saved'),
                          useMyStylePreferences: _selectedRanges.contains('StylePrefs'),
                          useMyPhysicalProfile: _selectedRanges.contains('PhysicalProfile'),
                          targetWardrobeIds: _selectedOthers.map((e) => e['id'] as int).toList(),
                        )
                    ));
                    if (mounted) {
                      debugPrint("Returning to Suggestion, reloading balance...");
                      _fetchBalance();
                    }
                  },
                  child: Container(
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}