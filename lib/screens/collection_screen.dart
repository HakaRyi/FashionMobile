import 'package:flutter/material.dart';
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

  // --- BỔ SUNG: HIỆN MENU KHI NHẤN GIỮ ---
  void _showDeleteMenu(BuildContext context, int collectionId, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white, // Nền trắng
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thanh gạt nhỏ ở trên cùng
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: Text(
                    "Delete '$title'",
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold), // Chữ đen
                  ),
                  onTap: () {
                    Navigator.pop(ctx); // Đóng menu
                    _deleteCollectionApi(collectionId); // Gọi hàm xóa
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- BỔ SUNG: GỌI API XÓA ---
  Future<void> _deleteCollectionApi(int collectionId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
      );

      await ItemService().deleteCollection(collectionId);

      if (mounted) {
        Navigator.pop(context); // Tắt loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Collection deleted successfully!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.black),
        );
        _fetchData(); // Load lại danh sách sau khi xóa
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tắt loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
  // ----------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("MY COLLECTIONS",
            style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w900)),
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
                return const Center(child: CircularProgressIndicator(color: Colors.black));
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              final collections = snapshot.data ?? [];
              if (collections.isEmpty) {
                return const Center(
                  child: Text("You don't have any collections yet.",
                      style: TextStyle(color: Colors.black38, fontWeight: FontWeight.w600)),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                physics: const BouncingScrollPhysics(),
                itemCount: collections.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final col = collections[index];
                  final items = col['items'] as List<dynamic>? ?? [];
                  final firstImageUrl = items.isNotEmpty ? items[0]['primaryImageUrl'] : null;

                  return InkWell(
                    // --- BỔ SUNG SỰ KIỆN onLongPress TẠI ĐÂY ---
                    onLongPress: () {
                      final colId = col['collectionId'] ?? 0;
                      if (colId != 0) {
                        _showDeleteMenu(context, colId, col['title'] ?? 'Untitled');
                      }
                    },
                    // -------------------------------------------
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CollectionDetailScreen(collectionData: col)),
                      );
                      if (result == true) {
                        _fetchData();
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: firstImageUrl != null
                                  ? Image.network(firstImageUrl, fit: BoxFit.cover)
                                  : const Icon(Icons.style, color: Colors.black12, size: 30),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  col['title'] ?? 'Untitled',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  col['description'] ?? 'No description',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${items.length} Items",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black38),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.black26),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}