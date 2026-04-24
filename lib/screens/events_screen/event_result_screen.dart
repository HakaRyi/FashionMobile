import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../models/event_model.dart';
import '../../models/event_result_model.dart';
import '../../services/event_service.dart';
import '../../utils/route_transitions.dart';
import 'my_result_detail_screen.dart';

class EventResultScreen extends StatefulWidget {
  final EventModel event;

  const EventResultScreen({super.key, required this.event});

  @override
  State<EventResultScreen> createState() => _EventResultScreenState();
}

class _EventResultScreenState extends State<EventResultScreen> {
  bool _startAnimation = false;

  @override
  void initState() {
    super.initState();
    // Kích hoạt hiệu ứng sau khi build khung sườn (giúp mượt hơn)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _startAnimation = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Nền xám cực nhạt chuẩn Minimalist
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6), // Tăng độ trắng lên một chút cho dễ nhìn
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 16),
              ),
            ),
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        // GIẢI PHÁP: Bọc title trong lớp kính mờ (Glassmorphism) giống hệt nút Back
        title: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4), // Nền trắng mờ che đi phần ảnh tối
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                  "EVENT RESULTS",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontSize: 14, // Thu nhỏ font một xíu để nằm gọn trong badge
                  )
              ),
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<EventLeaderboardModel>>(
        future: EventService().getLeaderboard(widget.event.eventId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          final list = snapshot.data!;
          if (list.isEmpty) {
            return const Center(child: Text("No leaderboard data available", style: TextStyle(color: Colors.black54)));
          }

          return Stack(
            children: [
              // Ảnh bìa sự kiện làm mờ dần xuống nền xám
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: screenHeight * 0.35,
                child: Image.network(widget.event.imageUrl, fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.4),
                        const Color(0xFFF5F5F5).withOpacity(0.9),
                        const Color(0xFFF5F5F5)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.25, 1.0],
                    ),
                  ),
                ),
              ),

              // Danh sách Leaderboard
              SafeArea(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 20, bottom: 140),
                  physics: const BouncingScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return _buildLeaderboardItem(item, index);
                  },
                ),
              ),

              // Thanh Sticky Bottom
              _buildMyStickyBottom(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardItem(EventLeaderboardModel item, int index) {
    // Hiệu ứng trượt (Slide) và mờ (Fade) nhẹ nhàng cho từng item
    // Delay theo index để tạo cảm giác "rớt" từng cái một từ trên xuống
    final int delay = (index * 100).clamp(0, 1000);

    // Màu nhấn cho Top 3
    Color rankColor = Colors.transparent;
    if (item.rank == 1) rankColor = const Color(0xFFD4AF37); // Gold
    else if (item.rank == 2) rankColor = const Color(0xFF9E9E9E); // Silver
    else if (item.rank == 3) rankColor = const Color(0xFF8D6E63); // Bronze

    return AnimatedOpacity(
      opacity: _startAnimation ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 600 + delay),
        curve: Curves.easeOutQuart,
        transform: Matrix4.translationValues(0, _startAnimation ? 0 : -30, 0), // Trượt từ Y = -30 xuống 0
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4)
              )
            ]
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Vạch màu nhấn cho Top 3
              if (item.rank <= 3)
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                      color: rankColor,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16))
                  ),
                ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Số Hạng
                      SizedBox(
                        width: 32,
                        child: Text(
                          "${item.rank}",
                          style: TextStyle(
                              color: item.rank <= 3 ? Colors.black : Colors.black38,
                              fontWeight: FontWeight.w900,
                              fontSize: 18
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFF5F5F5),
                        backgroundImage: item.avatarUrl != null ? NetworkImage(item.avatarUrl!) : null,
                        child: item.avatarUrl == null ? const Icon(Icons.person, color: Colors.black26, size: 20) : null,
                      ),
                      const SizedBox(width: 12),

                      // Tên & Giải thưởng
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.userName,
                              style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.rewardAmount != null && item.rewardAmount! > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.redeem_rounded, color: Colors.black54, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    "+${NumberFormat.decimalPattern().format(item.rewardAmount)} VNĐ",
                                    style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ]
                          ],
                        ),
                      ),

                      // Điểm số
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text(
                          "${item.finalScore} pt",
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyStickyBottom(BuildContext context) {
    return FutureBuilder<MyEventResultModel?>(
      future: EventService().getMyResult(widget.event.eventId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final myRes = snapshot.data!;

        return Align(
          alignment: Alignment.bottomCenter,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  border: const Border(top: BorderSide(color: Color(0xFFE0E0E0))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8)
                          ),
                          child: Text(
                            "#${myRes.rank}",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "YOUR RESULT",
                            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.0),
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: myRes.myScore),
                          duration: const Duration(seconds: 2),
                          builder: (context, value, child) => Text(
                            "${value.toStringAsFixed(1)} PT",
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // Đen quyền lực
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        SlideRoute(page: MyResultDetailScreen(event: widget.event)),
                      ),
                      child: const Text(
                        "VIEW REVIEW DETAILS",
                        style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.0, fontSize: 13),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}