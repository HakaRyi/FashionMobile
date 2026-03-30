import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/route_transitions.dart';
import '../../widgets/clothing_item.dart';
import '../../widgets/add_clothing_card.dart';
import '../../widgets/action_button.dart';
import '../../services/item_service.dart';
import '../ai_suggestion_screen.dart';
import '../clothing_detail_screen.dart';
import '../../utils/upload_utils.dart';
import '../../screens/suggestion_screen.dart';
import '../../screens/try_on_screen.dart';
import '../../screens/fashion_news_screen.dart';
import 'package:flutter/services.dart';
class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  late Future<List<dynamic>> _itemsFuture;
  Key _gridKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _gridKey = UniqueKey();
      _itemsFuture = ItemService().getMyItems();
    });
  }

  Future<void> _handleRefresh() async {
    _loadItems();
    await _itemsFuture;
  }
  Future<void> _confirmDelete(BuildContext context, dynamic item) async {
    // Luôn kiểm tra mounted trước khi show dialog
    if (!mounted) return;

    final bool? confirm = await showDialog<bool>(
      context: context,                    // context gốc của WardrobeScreen
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Xác nhận xóa", style: TextStyle(color: Colors.white)),
        content: Text("Món đồ '${item['itemName']}' sẽ bị xóa vĩnh viễn."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho user tắt bằng cách bấm ra ngoài
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.textPink),
      ),
    );
    //if (!mounted) return;

    try {
      final bool success = await ItemService().deleteItem(item['itemId']);

      //if (!mounted) return;
      if (mounted) Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(   // context gốc an toàn
          const SnackBar(
            content: Text("Đã xóa món đồ thành công!"),
            backgroundColor: Colors.greenAccent,
            duration: Duration(seconds: 2),
          ),
        );
        _loadItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Xóa thất bại!"), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi: $e"), backgroundColor: Colors.redAccent),
      );
    }
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
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              const SliverToBoxAdapter(child: Divider(color: AppColors.divider, thickness: 1)),
              FutureBuilder<List<dynamic>>(
                future: _itemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator(color: AppColors.textPink)),
                    );
                  }

                  final items = snapshot.data ?? [];

                  return SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverGrid(
                      key: _gridKey,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          if (index == items.length) {
                            return AddClothingCard(
                              // Chúng ta truyền hàm callback vào đây
                              onUploadSuccess: () => _loadItems(),
                            );
                          }

                          final item = items[index];
                          return ClothingItem(
                            title: item['itemName'] ?? "Không tên",
                            imageUrl: item['primaryImageUrl'],
                            onTap: () async {
                              // Đợi xem người dùng có xóa đồ trong trang chi tiết không
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ClothingDetailScreen(itemData: item)),
                              );
                              _loadItems(); // Luôn load lại cho chắc
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
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }
  void _showActionMenu(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: Colors.white),
                title: const Text("AI gợi ý phối đồ", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, SlideRoute(page: AISuggestionScreen(selectedItem: item)
                  ));
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.white),
                title: const Text("Thêm vào outfit yêu thích", style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.white),
                title: const Text("Xóa khỏi tủ đồ", style: TextStyle(color: Colors.white)),
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
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          const Text("Tủ Đồ", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 20),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                _wrapAction(
                  ActionButton(
                    icon: Icons.add_a_photo,
                    label: "Thêm đồ",
                    color: AppColors.accent,
                    onTap: () async {
                      // Hứng kết quả trả về từ toàn bộ luồng upload
                      final result = await UploadUtils.showUploadMenu(context);
                      if (result == true) {
                        _loadItems(); // Chỉ load lại nếu upload thành công
                      }
                    },
                  ),
                ),
                _wrapAction(
                  ActionButton(
                    icon: Icons.lightbulb_outline,
                    label: "Gợi ý",
                    color: Colors.orangeAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SuggestionScreen())),
                  ),
                ), // Đóng ngoặc của _wrapAction
                _wrapAction(
                  ActionButton(
                    icon: Icons.face,
                    label: "Thử đồ",
                    color: AppColors.textPink,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TryOnScreen())),
                  ),
                ), // Đóng ngoặc của _wrapAction
                _wrapAction(
                  ActionButton(
                    icon: Icons.style,
                    label: "Phong cách",
                    color: Colors.blueAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FashionNewsScreen())),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapAction(Widget child) {
    return Padding(padding: const EdgeInsets.only(right: 16.0), child: child);
  }
}