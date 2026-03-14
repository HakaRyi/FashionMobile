import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../../models/event_model.dart';
import 'event_access_screen.dart';
import 'event_detail.dart' hide EventModel;
import 'event_result_screen.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<EventModel> allEvents = [
      EventModel(
        title: "Neon Night Party 2026",
        time: "20/10/2026 · 18:00 – 23:00",
        host: "Tổ chức bởi Fashion Club",
        location: "Sky Bar, Quận 1",
        participants: "350+ tham gia",
        status: "Sắp diễn ra",
        imageUrl: "https://images.unsplash.com/photo-1492684223066-81342ee5ff30?q=80&w=2070&auto=format&fit=crop",
        themeColors: [Colors.purpleAccent, Colors.blueAccent],
      ),
      EventModel(
        title: "Summer Vibes Festival",
        time: "25/10/2026 · 09:00 – 21:00",
        host: "Tổ chức bởi Saigon Events",
        location: "Phố đi bộ Nguyễn Huệ",
        participants: "1.2K tham gia",
        status: "Đang diễn ra",
        imageUrl: "https://images.unsplash.com/photo-1533174072545-e8d4aa97edf9?q=80&w=2070&auto=format&fit=crop",
        themeColors: [Colors.orangeAccent, Colors.pinkAccent],
      ),
    ];

    final List<EventModel> joinedEvents = [
      EventModel(
        title: "Tech Fashion Week",
        time: "01/11/2026 · 18:00 – 21:00",
        host: "Tổ chức bởi Vogue Tech",
        location: "SECC, Quận 7",
        participants: "500 tham gia",
        status: "Đã kết thúc",
        imageUrl: "https://images.unsplash.com/photo-1506157786151-b8491531f436?q=80&w=2070&auto=format&fit=crop",
        themeColors: [Colors.cyanAccent, Colors.greenAccent],
      ),
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          title: const Text(
            "Sự kiện",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1),
          ),
          centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
              child: IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
            ),
          ],
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2E0249), Color(0xFF0D0D0D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.pinkAccent,
            indicatorWeight: 3,
            labelColor: Colors.pinkAccent,
            unselectedLabelColor: Colors.white54,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: "Tất cả sự kiện"),
              Tab(text: "Đã tham gia"),
            ],
          ),
        ),
        body: TabBarView(
          physics: const BouncingScrollPhysics(),
          children: [
            ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: allEvents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (context, index) => EventCard(event: allEvents[index], isJoined: false),
            ),
            ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: joinedEvents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (context, index) => EventCard(event: joinedEvents[index], isJoined: true),
            ),
          ],
        ),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final EventModel event;
  final bool isJoined;

  const EventCard({super.key, required this.event, required this.isJoined});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: event.themeColors.first.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.themeColors.last.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: event.themeColors.last.withOpacity(0.5)),
                  ),
                  child: Text(
                    event.status.toUpperCase(),
                    style: TextStyle(color: event.themeColors.last, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                const SizedBox(height: 12),
                Text(event.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_filled, color: Colors.orangeAccent, size: 16),
                    const SizedBox(width: 6),
                    Text(event.time, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_pin, color: Colors.blueAccent, size: 16),
                    const SizedBox(width: 6),
                    Text(event.host, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(image: NetworkImage(event.imageUrl), fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      SparkleJoinButton(
                        colors: event.themeColors,
                        label: isJoined ? "Truy cập" : "Tham gia",
                        onTap: () {
                          if (isJoined) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => EventAccessScreen(event: event)));
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () {
                            if (isJoined) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => EventResultScreen(event: event)));
                            } else {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)));
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(isJoined ? "Kết quả" : "Chi tiết", style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                _buildFooterInfo(Icons.location_on, event.location),
                const SizedBox(width: 16),
                _buildFooterInfo(Icons.group, event.participants),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterInfo(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white38),
          const SizedBox(width: 6),
          Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12))),
        ],
      ),
    );
  }
}

class SparkleJoinButton extends StatefulWidget {
  final List<Color> colors;
  final String label;
  final VoidCallback? onTap;

  const SparkleJoinButton({super.key, required this.colors, required this.label, this.onTap});

  @override
  State<SparkleJoinButton> createState() => _SparkleJoinButtonState();
}

class _SparkleJoinButtonState extends State<SparkleJoinButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        _buildStar(const Offset(-35, -15), 0.0, 10),
        _buildStar(const Offset(35, 20), 0.5, 8),
        _buildStar(const Offset(30, -20), 0.8, 6),
        _buildStar(const Offset(-30, 20), 0.3, 7),
        GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => _controller.stop(),
          onTapUp: (_) => _controller.repeat(reverse: true),
          child: Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: widget.colors.first.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            alignment: Alignment.center,
            child: Text(widget.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildStar(Offset offset, double delay, double size) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = math.sin((_controller.value * math.pi * 2) + delay);
        return Positioned(
          top: 22 + offset.dy,
          left: 50 + offset.dx,
          child: Opacity(
            opacity: 0.3 + (0.7 * value.abs()),
            child: Transform.scale(scale: 0.5 + (0.5 * value.abs()), child: Icon(Icons.star, color: widget.colors.last, size: size)),
          ),
        );
      },
    );
  }
}
