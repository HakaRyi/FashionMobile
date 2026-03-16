import 'package:flutter/material.dart';
import 'dart:ui';
import '../../models/event_model.dart';
import 'my_result_detail_screen.dart';

class EventResultScreen extends StatelessWidget {
  final EventModel event;

  const EventResultScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true, // Cho phép AppBar nằm đè lên ảnh nền
      appBar: AppBar(
        backgroundColor: Colors.transparent, // AppBar trong suốt
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        title: const Text(
          "Kết quả sự kiện",
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)] // Thêm shadow cho dễ đọc
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. Ảnh nền của Event (Ở lớp dưới cùng)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45, // Chiếm 45% màn hình trên
            child: Image.network(
              event.imageUrl,
              fit: BoxFit.cover,
            ),
          ),

          // 2. Lớp phủ Gradient mờ dần từ trên xuống dưới để làm nổi bật Podium
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black45,        // Làm mờ nhẹ phần đỉnh để thấy rõ AppBar
                    Colors.transparent,    // Giữa ảnh giữ nguyên
                    Color(0xFF0A0A0A)      // Đáy ảnh chuyển đen dần để khớp với màu nền dưới
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // 3. Nội dung chính (Podium và List) đè lên trên ảnh nền
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 10), // Khoảng cách so với AppBar
                // Bục Top 3
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildPodium(2, "Anna", 950, 120, event.themeColors.last),
                    _buildPodium(1, "David", 1200, 160, Colors.amberAccent),
                    _buildPodium(3, "Sarah", 890, 100, Colors.orangeAccent),
                  ],
                ),
                const SizedBox(height: 30),

                // Top 4 - 10
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(top: 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF121212),
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30)),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 150),
                      physics: const BouncingScrollPhysics(),
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        return _buildLeaderboardItem(
                            index + 4, "Participant ${index + 4}",
                            850 - (index * 20));
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Sticky Bottom (Bảng điểm của bạn)
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                  decoration: BoxDecoration(
                    color: event.themeColors.first.withOpacity(0.15),
                    border: Border(top: BorderSide(
                        color: event.themeColors.first.withOpacity(0.3))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text("24", style: TextStyle(
                              color: event.themeColors.first,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(shape: BoxShape.circle,
                                border: Border.all(
                                    color: event.themeColors.first, width: 2)),
                            child: const CircleAvatar(radius: 20,
                                backgroundImage: NetworkImage(
                                    "https://i.pravatar.cc/150?img=50")),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: Text("Bạn (Hải Đăng)",
                              style: TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16))),
                          const Text("450 điểm", style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: event.themeColors.first,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 10,
                            shadowColor: event.themeColors.first.withOpacity(
                                0.5),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MyResultDetailScreen(event: event),
                              ),
                            );
                          },
                          child: const Text("XEM CHI TIẾT CHẤM ĐIỂM CỦA BẠN",
                              style: TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Hàm build Podium và Item giữ nguyên ---

  Widget _buildPodium(int rank, String name, int score, double height, Color color) {
    bool isFirst = rank == 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isFirst) const Icon(Icons.workspace_premium, color: Colors.amberAccent, size: 36),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: isFirst ? 3 : 2)),
            child: CircleAvatar(radius: isFirst ? 35 : 28, backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=$rank")),
          ),
          const SizedBox(height: 8),
          Text(name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isFirst ? 16 : 14, shadows: const [Shadow(color: Colors.black, blurRadius: 4)])),
          Text("$score pt", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, shadows: const [Shadow(color: Colors.black, blurRadius: 4)])),
          const SizedBox(height: 12),
          Container(
            width: 80,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color.withOpacity(0.1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(top: BorderSide(color: color, width: 2), left: BorderSide(color: color.withOpacity(0.3)), right: BorderSide(color: color.withOpacity(0.3))),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, -5))],
            ),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 10),
            child: Text(rank.toString(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(int rank, String name, int score) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text(rank.toString(), style: const TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold))),
          CircleAvatar(radius: 20, backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=$rank")),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
          Text("$score pt", style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}