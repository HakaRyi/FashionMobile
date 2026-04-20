import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/model_manager.dart';
import '../../screens/create_model_screen.dart';
import '../../models/try_on_model_source.dart';

class ModelOutfitBottomSheet extends StatelessWidget {
  final List<dynamic> outfits;
  final bool isLoadingOutfits;
  final Function(TryOnModelSource) onSelectModel;

  const ModelOutfitBottomSheet({
    super.key,
    required this.outfits,
    required this.isLoadingOutfits,
    required this.onSelectModel,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                  "Đổi Model / Outfit",
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)
              ),
            ),
            const SizedBox(height: 12),
            const TabBar(
              indicatorColor: AppColors.textPink,
              labelColor: AppColors.textPink,
              unselectedLabelColor: AppColors.textPrimary,
              dividerColor: AppColors.divider,
              tabs: [
                Tab(text: "Model của tôi"),
                Tab(text: "Outfit của tôi"),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  ListenableBuilder(
                    listenable: modelManager,
                    builder: (context, child) {
                      final models = modelManager.userModels;
                      final isLoading = modelManager.isLoading;

                      if (isLoading) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.textPink));
                      }

                      if (models.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_off_outlined, color: AppColors.textPrimary, size: 60),
                              const SizedBox(height: 16),
                              const Text("Chưa có model, thêm ngay đi!", style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateModelScreen()));
                                },
                                icon: const Icon(Icons.add_photo_alternate_outlined),
                                label: const Text("Thêm model mới", style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.textPink,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              )
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                        itemCount: models.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateModelScreen()));
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.textPink.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.textPink, width: 2),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, color: AppColors.textPink, size: 40),
                                    SizedBox(height: 8),
                                    Text("Thêm mới", style: TextStyle(color: AppColors.textPink, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            );
                          }

                          final modelData = models[index - 1];
                          final String status = modelData['status']?.toString() ?? "Active";
                          final bool isReady = status == "Active";

                          return GestureDetector(
                            onTap: isReady ? () {
                              onSelectModel(TryOnModelSource(
                                imageUrl: modelData['imageUrl'],
                                displayName: modelData['name']?.toString() ?? "Model của tôi",
                              ));
                              Navigator.pop(context);
                            } : null,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.borderPrimary, width: 1),
                                    image: DecorationImage(
                                      image: NetworkImage(modelData['imageUrl'] ?? 'https://via.placeholder.com/150'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                if (!isReady)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            status == "Rejected" ? Icons.error_outline : Icons.hourglass_empty,
                                            color: status == "Rejected" ? Colors.redAccent : Colors.orangeAccent,
                                            size: 32,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            status == "Rejected" ? "Từ chối" : "Đang xử lý",
                                            style: TextStyle(
                                              color: status == "Rejected" ? Colors.redAccent : Colors.orangeAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  isLoadingOutfits
                      ? const Center(child: CircularProgressIndicator(color: AppColors.textPink))
                      : outfits.isEmpty
                      ? const Center(child: Text("Chưa có outfit nào", style: TextStyle(color: Colors.white54, fontSize: 16)))
                      : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: outfits.length,
                    itemBuilder: (context, index) {
                      final outfit = outfits[index];
                      return GestureDetector(
                        onTap: () {
                          onSelectModel(TryOnModelSource(
                            imageUrl: outfit['imageUrl'],
                            displayName: outfit['outfitName'] ?? "Outfit",
                          ));
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderPrimary, width: 2),
                            image: DecorationImage(
                              image: NetworkImage(outfit['imageUrl'] ?? 'https://via.placeholder.com/150'),
                              fit: BoxFit.contain,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                              ),
                              child: Text(
                                outfit['outfitName'] ?? "Outfit",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}