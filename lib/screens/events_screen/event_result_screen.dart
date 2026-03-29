import 'package:flutter/material.dart';
import 'dart:ui';
import '../../models/event_model.dart';
import '../../models/event_result_model.dart';
import '../../services/event_service.dart';
import 'my_result_detail_screen.dart';

class EventResultScreen extends StatelessWidget {
  final EventModel event;

  const EventResultScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        title: const Text("Kết quả sự kiện", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<EventLeaderboardModel>>(
        future: EventService().getLeaderboard(event.eventId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));

          final list = snapshot.data!;
          if (list.isEmpty) return const Center(child: Text("Chưa có bảng xếp hạng", style: TextStyle(color: Colors.white)));

          // Lấy Top 3 cho Podium
          final top1 = list.isNotEmpty ? list[0] : null;
          final top2 = list.length > 1 ? list[1] : null;
          final top3 = list.length > 2 ? list[2] : null;
          // Danh sách còn lại từ hạng 4
          final others = list.length > 3 ? list.sublist(3) : [];

          return Stack(
            children: [
              Positioned(
                top: 0, left: 0, right: 0, height: MediaQuery.of(context).size.height * 0.45,
                child: Image.network(event.imageUrl, fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black45, Colors.transparent, Color(0xFF0A0A0A)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      stops: [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Bục Podium Real Data
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (top2 != null) _buildPodium(2, top2.userName, top2.finalScore.toInt(), 120, event.themeColors.last, top2.avatarUrl),
                        if (top1 != null) _buildPodium(1, top1.userName, top1.finalScore.toInt(), 160, Colors.amberAccent, top1.avatarUrl),
                        if (top3 != null) _buildPodium(3, top3.userName, top3.finalScore.toInt(), 100, Colors.orangeAccent, top3.avatarUrl),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(top: 20),
                        decoration: const BoxDecoration(color: Color(0xFF121212), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 150),
                          itemCount: others.length,
                          itemBuilder: (context, index) => _buildLeaderboardItem(others[index]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildMyStickyBottom(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMyStickyBottom(BuildContext context) {
    return FutureBuilder<MyEventResultModel?>(
      future: EventService().getMyResult(event.eventId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final myRes = snapshot.data!;
        return Align(
          alignment: Alignment.bottomCenter,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                decoration: BoxDecoration(color: event.themeColors.first.withOpacity(0.15), border: Border(top: BorderSide(color: event.themeColors.first.withOpacity(0.3)))),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text("${myRes.rank}", style: TextStyle(color: event.themeColors.first, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        const Expanded(child: Text("Kết quả của bạn", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        Text("${myRes.myScore} pt", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: event.themeColors.first, minimumSize: const Size(double.infinity, 44)),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyResultDetailScreen(event: event))),
                      child: const Text("XEM CHI TIẾT NHẬN XÉT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildPodium(int rank, String name, int score, double height, Color color, String? avatar) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(radius: rank == 1 ? 35 : 28, backgroundColor: color, backgroundImage: avatar != null ? NetworkImage(avatar) : null),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1),
          const SizedBox(height: 12),
          Container(
            width: 70, height: height,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.8), color.withOpacity(0.1)], begin: Alignment.topCenter, end: Alignment.bottomCenter), borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
            child: Center(child: Text("$rank", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(EventLeaderboardModel item) {
    return ListTile(
      leading: Text("${item.rank}", style: const TextStyle(color: Colors.white54)),
      title: Text(item.userName, style: const TextStyle(color: Colors.white)),
      trailing: Text("${item.finalScore} pt", style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
    );
  }
}