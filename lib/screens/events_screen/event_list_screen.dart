import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import 'event_access_screen.dart';
import 'event_detail.dart' hide EventModel;
import 'event_result_screen.dart';
import 'package:intl/intl.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final EventService _eventService = EventService();
  List<EventModel>? _allEvents;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      if (!_isLoading) setState(() => _isLoading = true);
      final data = await _eventService.getPublicEvents();
      if (mounted) {
        setState(() {
          _allEvents = data;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Không thể tải danh sách sự kiện";
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    try {
      final data = await _eventService.getPublicEvents();
      if (mounted) {
        setState(() {
          _allEvents = data;
          _error = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi cập nhật dữ liệu")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          elevation: 0,
          title: const Text("SỰ KIỆN FASHION",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
            ),
          ),
          bottom: TabBar(
            indicatorColor: Colors.pinkAccent,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 4,
            labelColor: Colors.pinkAccent,
            unselectedLabelColor: Colors.white30,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            tabs: const [Tab(text: "KHÁM PHÁ"), Tab(text: "CỦA TÔI")],
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
    if (_error != null && _allEvents == null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, color: Colors.white24, size: 60),
        const SizedBox(height: 16),
        Text(_error!, style: const TextStyle(color: Colors.white54)),
        TextButton(onPressed: _fetchInitialData, child: const Text("THỬ LẠI", style: TextStyle(color: Colors.pinkAccent)))
      ]));
    }

    final allEventsList = _allEvents ?? [];
    final discoveryEventsList = allEventsList.where((e) =>
    e.status == "Active"
    ).toList();
    final joinedEventsList = allEventsList.where((e) => e.isJoined).toList();

    return TabBarView(
      physics: const BouncingScrollPhysics(),
      children: [
        RefreshIndicator(color: Colors.pinkAccent, onRefresh: _handleRefresh, child: _buildEventList(discoveryEventsList)),
        RefreshIndicator(color: Colors.pinkAccent, onRefresh: _handleRefresh, child: _buildEventList(joinedEventsList)),
      ],
    );
  }

  Widget _buildEventList(List<EventModel> events) {
    if (events.isEmpty) return ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [SizedBox(height: 200), Center(child: Text("Hiện không có sự kiện nào", style: TextStyle(color: Colors.white24)))]);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 20),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) => EventCard(event: events[index]),
    );
  }
}

class EventCard extends StatelessWidget {
  final EventModel event;
  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = event.themeColors;

    // FIX MÚI GIỜ & HIỂN THỊ KHOẢNG THỜI GIAN
    final String startTimeStr = DateFormat('HH:mm - dd/MM').format(event.startTime.toLocal());
    final String endTimeStr = DateFormat('HH:mm - dd/MM/yyyy').format(event.endTime.toLocal());
    final String timeRange = "$startTimeStr - $endTimeStr";

    return Container(
      margin: const EdgeInsets.only(bottom: 30, left: 16, right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. PHẦN TIÊU ĐỀ
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white10,
                      backgroundImage: event.creatorAvatarUrl != null ? NetworkImage(event.creatorAvatarUrl!) : null,
                      child: event.creatorAvatarUrl == null ? const Icon(Icons.person, color: Colors.white24, size: 18) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(event.creatorName, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    _buildStatusBadge(event.status, colors.last),
                  ],
                ),
                const SizedBox(height: 16),
                Text(event.title,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.2, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Colors.pinkAccent, size: 14),
                    const SizedBox(width: 8),
                    Expanded(child: Text(timeRange, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500))),
                  ],
                ),
              ],
            ),
          ),

          // 2. PHẦN HÌNH ẢNH + THỐNG KÊ NẰM TRÊN ẢNH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 1.8,
                    child: Image.network(event.imageUrl, fit: BoxFit.cover),
                  ),
                ),
                // Lớp phủ Gradient để text bên trên dễ đọc hơn
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                      ),
                    ),
                  ),
                ),
                // CHI TIẾT NẰM TRÊN ẢNH
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildOverlayStat(Icons.group_rounded, "${event.participantCount}", "Tham gia"),
                      _buildOverlayStat(Icons.military_tech_rounded, NumberFormat.compact().format(event.totalPrizePool), "Thưởng"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. NÚT ACTION
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    // --- LOGIC MÀU SẮC GRADIENT ---
                    gradient: LinearGradient(
                      colors: event.status == "Completed"
                          ? [const Color(0xFFFFD700), const Color(0xFFFFA000)] // Vàng Gold cho Kết quả
                          : (event.isJoined
                          ? [const Color(0xFF6A11CB), const Color(0xFF2575FC)] // Xanh Tím cho bài liên quan
                          : [Colors.pinkAccent, Colors.pinkAccent.withOpacity(0.7)]), // Hồng cho mặc định
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (event.status == "Completed" ? Colors.amber : Colors.black).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ]
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (event.isJoined) {
                      if (event.status == "Completed") {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => EventResultScreen(event: event)));
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => EventAccessScreen(event: event)));
                      }
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(eventId: event.eventId)));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    // --- LOGIC TEXT TRÊN NÚT ---
                    event.status == "Completed"
                        ? "XEM KẾT QUẢ"
                        : (event.isJoined ? "XEM BÀI VIẾT LIÊN QUAN" : "XEM CHI TIẾT SỰ KIỆN"),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayStat(IconData icon, String value, String label) {
    return ClipRRect( // Phải có ClipRRect để hiệu ứng Blur không bị tràn ra ngoài
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Hiệu ứng làm mờ kính nằm ở đây
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4), // Giảm độ mờ một chút để thấy rõ hiệu ứng kính
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.pinkAccent, size: 16),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                  Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
    );
  }
}