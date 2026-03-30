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

class _EventResultScreenState extends State<EventResultScreen> with TickerProviderStateMixin {
  bool _startAnimation = false;
  bool _showReward = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _startAnimation = true);
    });

    Future.delayed(const Duration(milliseconds: 1400), () {  // tăng nhẹ để phù hợp delay 700ms
      if (mounted) setState(() => _showReward = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.maybePop(context)),
        title: const Text("Kết quả sự kiện", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<EventLeaderboardModel>>(
        future: EventService().getLeaderboard(widget.event.eventId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
          }

          final list = snapshot.data!;
          if (list.isEmpty) {
            return const Center(child: Text("Chưa có bảng xếp hạng", style: TextStyle(color: Colors.white)));
          }

          final podiumParticipants = list.take(3).toList();
          final others = list.length > 3 ? list.sublist(3) : [];

          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: screenHeight * 0.45,
                child: Image.network(widget.event.imageUrl, fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black45, Colors.transparent, Color(0xFF0A0A0A)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.35, 1.0],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      SizedBox(
                        height: 340,   // tăng nhẹ để có thêm không gian
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: _buildDynamicPodium(podiumParticipants, widget.event),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      AnimatedOpacity(
                        opacity: _startAnimation ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeInOut,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 180),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: others.length,
                          itemBuilder: (context, index) => _buildLeaderboardItem(others[index]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildMyStickyBottom(context),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildDynamicPodium(List<EventLeaderboardModel> participants, EventModel event) {
    if (participants.isEmpty) return [];

    List<EventLeaderboardModel?> displayOrder = List.filled(3, null);
    if (participants.length == 1) {
      displayOrder[1] = participants[0];
    } else if (participants.length == 2) {
      displayOrder[0] = participants[1];
      displayOrder[1] = participants[0];
    } else if (participants.length >= 3) {
      displayOrder[0] = participants[1]; // hạng 2
      displayOrder[1] = participants[0]; // hạng 1
      displayOrder[2] = participants[2]; // hạng 3
    }

    return displayOrder.where((p) => p != null).map((p) {
      double targetHeight = p!.rank == 1 ? 150 : (p.rank == 2 ? 118 : 92);
      Color color = p.rank == 1 ? Colors.amberAccent : (p.rank == 2 ? Colors.grey : Colors.orangeAccent);

      // Mỗi hạng trễ 700ms
      int delayMs = (p.rank - 1) * 700;   // Top1: 0ms, Top2: 700ms, Top3: 1400ms

      return _buildEnhancedPodium(p, targetHeight, color, delayMs);
    }).toList();
  }

  Widget _buildEnhancedPodium(EventLeaderboardModel p, double targetHeight, Color color, int delayMs) {
    bool isFirst = p.rank == 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // === AVATAR - HIỆN MỜ DẦN THEO THỨ TỰ ===
          AnimatedOpacity(
            opacity: _startAnimation ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 600 + delayMs),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (isFirst) BoxShadow(color: color.withOpacity(0.6), blurRadius: 20, spreadRadius: 3),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: isFirst ? 42 : 32,
                      backgroundColor: color,
                      child: CircleAvatar(
                        radius: isFirst ? 39 : 29,
                        backgroundImage: p.avatarUrl != null ? NetworkImage(p.avatarUrl!) : null,
                        backgroundColor: Colors.white10,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Tên (hiện cùng avatar)
          AnimatedOpacity(
            opacity: _startAnimation ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            child: Text(
              p.userName,
              style: TextStyle(
                color: Colors.white,
                fontSize: isFirst ? 15 : 13,
                fontWeight: FontWeight.bold,
                shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),

          // Điểm số
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: _startAnimation ? p.finalScore : 0.0),
            duration: const Duration(seconds: 2),
            builder: (context, value, child) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: isFirst ? 14 : 10, vertical: isFirst ? 5 : 3),
                decoration: BoxDecoration(
                  color: isFirst ? Colors.pinkAccent : Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(isFirst ? 22 : 14),
                  boxShadow: isFirst
                      ? [BoxShadow(color: Colors.pinkAccent.withOpacity(0.5), blurRadius: 10)]
                      : [],
                ),
                child: Text(
                  "${value.toStringAsFixed(1)} pt",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isFirst ? 14 : 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          // === CỘT PODIUM - HIỆN MỜ DẦN THEO THỨ TỰ ===
          AnimatedOpacity(
            opacity: _startAnimation ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 700 + delayMs),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Container(
                    width: 88,
                    height: targetHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.85), color.withOpacity(0.15)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      border: Border.all(color: color.withOpacity(0.4), width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          "${p.rank}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const Spacer(),

                        if (p.rewardAmount != null && p.rewardAmount! > 0)
                          AnimatedOpacity(
                            opacity: _showReward ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${NumberFormat.compact().format(p.rewardAmount)}đ",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Phần sticky bottom và leaderboard item giữ nguyên
  Widget _buildMyStickyBottom(BuildContext context) {
    return FutureBuilder<MyEventResultModel?>(
      future: EventService().getMyResult(widget.event.eventId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final myRes = snapshot.data!;

        return Align(
          alignment: Alignment.bottomCenter,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                decoration: BoxDecoration(
                  color: widget.event.themeColors.first.withOpacity(0.15),
                  border: Border(top: BorderSide(color: widget.event.themeColors.first.withOpacity(0.3))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          "${myRes.rank}",
                          style: TextStyle(
                            color: widget.event.themeColors.first,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Kết quả của bạn",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: myRes.myScore),
                          duration: const Duration(seconds: 2),
                          builder: (context, value, child) => Text(
                            "${value.toStringAsFixed(1)} pt",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        SlideRoute(page: MyResultDetailScreen(event: widget.event)),
                      ),
                      child: const Text(
                        "XEM CHI TIẾT NHẬN XÉT",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildLeaderboardItem(EventLeaderboardModel item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: SizedBox(
          width: 60,
          child: Row(
            children: [
              Text("${item.rank}", style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundImage: item.avatarUrl != null ? NetworkImage(item.avatarUrl!) : null,
                backgroundColor: Colors.white10,
              ),
            ],
          ),
        ),
        title: Text(item.userName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: (item.rewardAmount != null && item.rewardAmount! > 0)
            ? Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const Icon(Icons.confirmation_num_outlined, color: Colors.greenAccent, size: 12),
              const SizedBox(width: 4),
              Text(
                "+${NumberFormat.decimalPattern().format(item.rewardAmount)}đ",
                style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        )
            : null,
        trailing: Text(
          "${item.finalScore} pt",
          style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
    );
  }
}