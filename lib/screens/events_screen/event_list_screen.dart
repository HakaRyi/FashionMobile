import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../utils/route_transitions.dart';
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
          _error = "Failed to load event list";
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
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: AppBar(
          elevation: 0,
          title: const Text("FASHION EVENTS",
              style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.white, Color(0xFFF8F8F8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
            ),
          ),
          bottom: TabBar(
            indicatorColor: Colors.pinkAccent,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 4,
            labelColor: Colors.pinkAccent,
            unselectedLabelColor: Colors.black26,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            tabs: const [Tab(text: "EXPLORE"), Tab(text: "MY EVENTS")],
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
        Text(_error!, style: const TextStyle(color: Colors.black54)),
        TextButton(onPressed: _fetchInitialData, child: const Text("RETRY", style: TextStyle(color: Colors.pinkAccent)))
      ]));
    }

    final allEventsList = _allEvents ?? [];
    final discoveryEventsList = allEventsList.where((e) => e.status == "Active").toList();
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

  void _handleNavigation(BuildContext context) {
    if (event.isJoined) {
      if (event.status == "Completed") {
        Navigator.push(context, SlideRoute(page: EventResultScreen(event: event)));
      } else {
        Navigator.push(context, SlideRoute(page: EventDetailScreen(eventId: event.eventId)));
      }
    } else {
      Navigator.push(context, SlideRoute(page: EventDetailScreen(eventId: event.eventId)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = event.themeColors;

    final String startTimeStr = DateFormat('HH:mm - dd/MM').format(event.startTime.toLocal());
    final String endTimeStr = DateFormat('HH:mm - dd/MM/yyyy').format(event.endTime.toLocal());
    final String timeRange = "$startTimeStr - $endTimeStr";

    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleNavigation(context),
            splashColor: Colors.pinkAccent.withOpacity(0.1),
            highlightColor: Colors.pinkAccent.withOpacity(0.05),
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
                            radius: 16,
                            backgroundColor: Colors.black.withOpacity(0.05),
                            backgroundImage: event.creatorAvatarUrl != null ? NetworkImage(event.creatorAvatarUrl!) : null,
                            child: event.creatorAvatarUrl == null ? const Icon(Icons.person, color: Colors.white24, size: 16) : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(event.creatorName, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          _buildStatusBadge(event.status, colors.last,event.isJoined),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(event.title,
                          style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w900, height: 1.2, letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: Colors.pinkAccent, size: 12),
                          const SizedBox(width: 6),
                          Expanded(child: Text(timeRange, style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. PHẦN HÌNH ẢNH (Đã rộng ra và bo góc dưới mượt hơn)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: 1.5, // Giảm tỉ lệ để ảnh cao hơn, rộng hơn
                          child: Image.network(event.imageUrl, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildOverlayStat(Icons.group_rounded, "${event.participantCount}", "Participants"),
                            const SizedBox(width: 8),
                            _buildOverlayStat(Icons.military_tech_rounded, NumberFormat.compact().format(event.totalPrizePool), "Prize pools"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayStat(IconData icon, String value, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.pinkAccent, size: 14),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                  Text(label, style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color, bool isJoined) {
    String displayStatus;
    Color displayColor;

    // 1. Nếu sự kiện đã kết thúc, ưu tiên hiện COMPLETED bất kể user có tham gia hay không
    if (status.toUpperCase() == "COMPLETED") {
      displayStatus = "COMPLETED";
      displayColor = Colors.orangeAccent; // Hoặc màu vàng/cam để phân biệt với Active
    }
    // 2. Nếu sự kiện đang chạy mà user đã tham gia thì hiện JOINED
    else if (isJoined) {
      displayStatus = "JOINED";
      displayColor = Colors.lightGreen;
    }
    // 3. Các trường hợp còn lại hiện status mặc định (ACTIVE, INVITING...)
    else {
      displayStatus = status.toUpperCase();
      displayColor = color;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: displayColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: displayColor.withOpacity(0.3), width: 1),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
            color: displayColor,
            fontWeight: FontWeight.w900,
            fontSize: 9,
            letterSpacing: 0.5
        ),
      ),
    );
  }
}