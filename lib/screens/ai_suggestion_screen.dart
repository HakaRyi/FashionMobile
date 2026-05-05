import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../services/wallet_service.dart';
import '../services/wardrobe_service.dart';
import '../utils/route_transitions.dart';
import '../widgets/clothing_item.dart';
import 'ai_result_screen.dart';
import '../models/wardrobe_item_model.dart';
import 'edit_personal_information_screen.dart';

class AISuggestionScreen extends StatefulWidget {
  final dynamic selectedItem;

  const AISuggestionScreen({super.key, required this.selectedItem});

  @override
  State<AISuggestionScreen> createState() => _AISuggestionScreenState();
}

class _AISuggestionScreenState extends State<AISuggestionScreen> {
  List<String> _selectedRanges = ['My Wardrobe'];
  final TextEditingController _promptController = TextEditingController();

  // Lưu trữ danh sách người dùng đã chọn
  List<Map<String, dynamic>> _selectedOthers = [];

  final WalletService _walletService = WalletService();
  double _currentBalance = 0;
  final double _serviceCost = 2000;
  bool _isLoadingBalance = true;

  final NumberFormat _currencyFormatter = NumberFormat('#,##0', 'vi_VN');

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
    if (rangeId == 'Others') {
      _showOthersSearchMenu();
      return;
    }
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

  // --- MODAL SEARCH MENU ---
  void _showOthersSearchMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _OthersSearchContent(
          initialSelected: List.from(_selectedOthers),
          onChanged: (newSelection) {
            setState(() {
              _selectedOthers = newSelection;
              if (_selectedOthers.isNotEmpty) {
                if (!_selectedRanges.contains('Others')) _selectedRanges.add('Others');
              } else {
                _selectedRanges.remove('Others');
              }
            });
          },
        );
      },
    );
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                              "REFERENCE",
                              style: TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0)
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: 140,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                    "PERSONAL CONTEXT",
                                    style: TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0)
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.push(context, SlideRoute(page: const EditPersonalInformationScreen()));
                                  },
                                  child: const Text(
                                    "EDIT",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildCustomOptionBtn('StylePrefs', 'My Style', Icons.auto_awesome_mosaic_outlined),
                            const SizedBox(height: 10),
                            _buildCustomOptionBtn('PhysicalProfile', 'My Body', Icons.accessibility_new_outlined),
                            const SizedBox(height: 10),
                            _buildCustomOptionBtn('Saved', 'My Saved', Icons.bookmark_border),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
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

                  // HIỂN THỊ CHIP DANH SÁCH NGƯỜI ĐÃ CHỌN
                  if (_selectedOthers.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                        "TARGET WARDROBES",
                        style: TextStyle(color: Colors.black38, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedOthers.map((w) => Chip(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: BorderSide.none,
                        label: Text(w['name'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
                        onDeleted: () {
                          setState(() {
                            _selectedOthers.remove(w);
                            if (_selectedOthers.isEmpty) _selectedRanges.remove('Others');
                          });
                        },
                      )).toList(),
                    ),
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

  Widget _buildPromptBar() {
    bool hasEnoughBalance = _currentBalance >= _serviceCost;
    bool canGenerate = !_isLoadingBalance && hasEnoughBalance;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
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
            if (!_isLoadingBalance && !hasEnoughBalance)
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.redAccent, size: 14),
                    SizedBox(width: 4),
                    Text(
                      "Insufficient balance. Please top up to use this service.",
                      style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            if (_isLoadingBalance || hasEnoughBalance)
              const SizedBox(height: 8),
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
                      enabled: canGenerate,
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
                  onTap: canGenerate ? () async {
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
                    if (mounted) _fetchBalance();
                  } : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      color: canGenerate ? Colors.black : Colors.black12,
                      shape: BoxShape.circle,
                      boxShadow: canGenerate ? [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                      ] : [],
                    ),
                    child: Icon(
                        Icons.auto_awesome,
                        color: canGenerate ? Colors.white : Colors.black26,
                        size: 20
                    ),
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

// --- COMPONENT TÌM KIẾM RIÊNG BIỆT CHO MODAL ---
class _OthersSearchContent extends StatefulWidget {
  final List<Map<String, dynamic>> initialSelected;
  final Function(List<Map<String, dynamic>>) onChanged;

  const _OthersSearchContent({required this.initialSelected, required this.onChanged});

  @override
  State<_OthersSearchContent> createState() => _OthersSearchContentState();
}

class _OthersSearchContentState extends State<_OthersSearchContent> {
  late List<Map<String, dynamic>> _tempSelected;
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tempSelected = widget.initialSelected;
  }

  void _onSearch(String query) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          // Header Modal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Target Wardrobes", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black)),
              TextButton(
                onPressed: () {
                  widget.onChanged(_tempSelected);
                  Navigator.pop(context);
                },
                child: const Text("Done", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 16),

          // Thanh Search
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500),
              autofocus: true,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: "Search username...",
                border: InputBorder.none,
                icon: Icon(Icons.search, color: _isSearching ? Colors.blue : Colors.black38),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Danh sách đã chọn (Ngang)
          if (_tempSelected.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _tempSelected.map((u) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InputChip(
                    label: Text(u['name'], style: const TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: Colors.black,
                    deleteIconColor: Colors.white70,
                    onDeleted: () => setState(() => _tempSelected.remove(u)),
                  ),
                )).toList(),
              ),
            ),

          const Divider(height: 32),

          // Kết quả tìm kiếm
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : _searchResults.isEmpty
                ? const Center(child: Text("Search for users to add their wardrobe", style: TextStyle(color: Colors.black38)))
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                bool isAlreadySelected = _tempSelected.any((e) => e['id'] == user['wardrobeId']);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['avatarUrl'] != null ? NetworkImage(user['avatarUrl']) : null,
                    child: user['avatarUrl'] == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(user['userName'], style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                  trailing: Icon(
                    isAlreadySelected ? Icons.check_circle : Icons.add_circle_outline,
                    color: isAlreadySelected ? Colors.blue : Colors.black,
                  ),
                  onTap: () {
                    setState(() {
                      if (!isAlreadySelected) {
                        _tempSelected.add({'id': user['wardrobeId'], 'name': user['userName']});
                      } else {
                        _tempSelected.removeWhere((e) => e['id'] == user['wardrobeId']);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}