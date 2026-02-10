import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/try_on_item.dart';
import '../widgets/add_clothing_card.dart';
import '../screens/model_management_screen.dart';
import '../widgets/price_info_widget.dart';
class TryOnScreen extends StatefulWidget {
  const TryOnScreen({super.key});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  int selectedClothIndex = -1;

  //data demo
  final int currentBalance = 0; //demo cho 0
  final int tryOnCost = 10;

  @override
  Widget build(BuildContext context) {
    // Kiểm tra điều kiện: Đã chọn đồ VÀ đủ tiền
    bool canProceed = selectedClothIndex != -1 && currentBalance >= tryOnCost;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Thử đồ ảo",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- PHẦN 1: KHU VỰC MODEL (Giữ nguyên) ---
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                      image: const DecorationImage(
                        image: AssetImage("assets/images/human1.jpg"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 15,
                    right: 15,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ModelManagementScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.textPink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text(
              "Chọn món đồ để thử",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),

          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const SizedBox(
                    width: 100,
                    child: AddClothingCard(),
                  );
                }
                return TryOnItem(
                  imagePath: "assets/images/vietnamjersey.png",
                  isSelected: selectedClothIndex == index,
                  onTap: () => setState(() => selectedClothIndex = index),
                );
              },
            ),
          ),

          const Spacer(),

          // --- PHẦN 3: BOTTOM PANEL (ĐÃ CẢI TIẾN) ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Cột hiển thị Số dư & Chi phí
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PriceInfoWidget(
                          label: "Số dư:",
                          value: currentBalance.toString(),
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        PriceInfoWidget(
                          label: "Chi phí:",
                          value: tryOnCost.toString(),
                          color: AppColors.textPink,
                          valueTextColor: Colors.white,
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Nút bấm thu nhỏ lại một chút
                    Container(
                      height: 55,
                      width: MediaQuery.of(context).size.width * 0.45,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: canProceed
                            ? const LinearGradient(colors: [Color(0xFFFC00A6), Color(0xFFB50076)])
                            : null,
                        color: !canProceed ? Colors.white.withOpacity(0.05) : null,
                      ),
                      child: ElevatedButton(
                        onPressed: canProceed ? () => print("Đang xử lý...") : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: Text(
                          "THỬ ĐỒ NGAY",
                          style: TextStyle(
                            color: canProceed ? Colors.white : Colors.white24,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Cảnh báo nếu không đủ tiền
                // if (selectedClothIndex != -1 && currentBalance < tryOnCost)
                //   const Padding(
                //     padding: EdgeInsets.only(top: 12),
                //     child: Text(
                //       "Số dư không đủ để thực hiện",
                //       style: TextStyle(color: Colors.redAccent, fontSize: 15),
                //     ),
                //   ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}