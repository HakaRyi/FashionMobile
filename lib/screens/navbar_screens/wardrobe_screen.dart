import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/clothing_item.dart';
import '../../widgets/add_clothing_card.dart';
import '../../widgets/action_button.dart';
import '../../services/item_service.dart';
import '../clothing_detail_screen.dart';
import '../../utils/upload_utils.dart';
import '../../screens/suggestion_screen.dart';
import '../../screens/try_on_screen.dart';
import '../../screens/fashion_news_screen.dart';
class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  late Future<List<dynamic>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _itemsFuture = ItemService().getMyItems();
    });
  }

  Future<void> _handleRefresh() async {
    _loadItems();
    await _itemsFuture;
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