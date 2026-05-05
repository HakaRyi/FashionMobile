import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Ní nên thêm package này để hiệu ứng mượt hơn
import '../../services/item_service.dart';
import '../../widgets/animated_fabric_background.dart';
import 'collection_detail.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  late Future<List<dynamic>> _collectionsFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _collectionsFuture = ItemService().getCollections();
    });
  }

  // --- Hàm xóa giữ nguyên logic cũ nhưng tút lại UI Modal ---
  void _showDeleteMenu(BuildContext context, int collectionId, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withOpacity(0.3),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
              leading: const CircleAvatar(backgroundColor: Color(0xFFFFEBEE), child: Icon(Icons.delete_sweep, color: Colors.redAccent)),
              title: Text("Remove '$title'", style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.red)),
              subtitle: const Text("This action cannot be undone", style: const TextStyle(color: Colors.black),),
              onTap: () {
                Navigator.pop(ctx);
                _deleteCollectionApi(collectionId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCollectionApi(int collectionId) async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.black)));
      await ItemService().deleteCollection(collectionId);
      if (mounted) {
        Navigator.pop(context);
        _fetchData();
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
        title: const Text("EDITORIAL COLLECTIONS",
            style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 0)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedFabricBackground(
        child: SafeArea(
          child: FutureBuilder<List<dynamic>>(
            future: _collectionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 1));
              }
              final collections = snapshot.data ?? [];
              if (collections.isEmpty) return _buildEmptyState();

              return AnimationLimiter(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: collections.length,
                  itemBuilder: (context, index) {
                    final col = collections[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 600),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildCollectionCard(col),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionCard(dynamic col) {
    final List<dynamic> items = col['items'] as List<dynamic>? ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: GestureDetector(
        onLongPress: () => _showDeleteMenu(context, col['collectionId'], col['title'] ?? 'Untitled'),
        onTap: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => CollectionDetailScreen(collectionData: col)));
          if (result == true) _fetchData();
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 15)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Phần hình ảnh (Thiết kế Magazine) ---
              Padding(
                padding: const EdgeInsets.all(12),
                child: _buildImageGrid(items),
              ),

              // --- Phần text (Thiết kế Minimal) ---
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            col['title']?.toUpperCase() ?? 'UNTITLED',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 0, color: Colors.black),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            col['description'] ?? 'No description available',
                            style: TextStyle(color: Colors.black, fontSize: 13, height: 1.3,),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildItemCountBadge(items.length),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid(List<dynamic> items) {
    const double mainHeight = 280;

    // TRƯỜNG HỢP: KHÔNG CÓ MÓN NÀO
    if (items.isEmpty) {
      return Container(
        height: mainHeight,
        width: double.infinity,
        decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.style_outlined, size: 40, color: Colors.black12),
      );
    }

    // TRƯỜNG HỢP: 1 MÓN ĐỒ (Full khung)
    if (items.length == 1) {
      return SizedBox(
        height: mainHeight,
        width: double.infinity,
        child: _buildImageWithRadius(
          items[0]['primaryImageUrl'],
          BorderRadius.circular(24),
        ),
      );
    }

    // TRƯỜNG HỢP: 2 MÓN ĐỒ (Chia dọc 50-50, không bị trống)
    if (items.length == 2) {
      return SizedBox(
        height: mainHeight,
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildImageWithRadius(
                items[0]['primaryImageUrl'],
                const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8)
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: _buildImageWithRadius(
                items[1]['primaryImageUrl'],
                const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                    topRight: Radius.circular(24),
                    bottomRight: Radius.circular(24)
                ),
              ),
            ),
          ],
        ),
      );
    }

    // TRƯỜNG HỢP: 3 MÓN TRỞ LÊN (1 lớn trái, 2 nhỏ phải)
    return SizedBox(
      height: mainHeight,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildImageWithRadius(
              items[0]['primaryImageUrl'],
              const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8)
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: _buildImageWithRadius(
                    items[1]['primaryImageUrl'],
                    const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                        topRight: Radius.circular(24),
                        bottomRight: Radius.circular(8)
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildImageWithRadius(
                    items[2]['primaryImageUrl'],
                    const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(24)
                    ),
                    overlayCount: items.length > 3 ? items.length - 3 : 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hàm gộp chung render ảnh và xử lý logic bo góc
  Widget _buildImageWithRadius(String? url, BorderRadius borderRadius, {int overlayCount = 0}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        image: url != null ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
        color: const Color(0xFFF5F5F5), // Màu nền placeholder nếu không có ảnh
      ),
      child: overlayCount > 0
          ? Container(
        decoration: BoxDecoration(color: Colors.black38, borderRadius: borderRadius),
        child: Center(
            child: Text(
                "+$overlayCount",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)
            )
        ),
      )
          : null,
    );
  }

  Widget _buildHeroImage(String? url) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24), topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
        image: url != null ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
        color: const Color(0xFFF5F5F5),
      ),
    );
  }

  Widget _buildSubImage(String? url, {int overlayCount = 0}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: url != null ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
        color: const Color(0xFFF5F5F5),
      ),
      child: overlayCount > 0 ? Container(
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)),
        child: Center(child: Text("+$overlayCount", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
      ) : null,
    );
  }

  Widget _buildItemCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text("$count", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const Text("PCS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 8)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_motion, size: 60, color: Colors.black.withOpacity(0.05)),
          const SizedBox(height: 20),
          const Text("EMPTY ARCHIVE", style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w900, color: Colors.black26)),
        ],
      ),
    );
  }
}