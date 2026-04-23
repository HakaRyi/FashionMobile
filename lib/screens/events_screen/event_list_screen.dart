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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi cập nhật dữ liệu", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.black,
          )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5), // Nền xám cực nhạt để nổi bật thẻ trắng
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFF5F5F5),
          titleSpacing: 20, // Canh lề trái cho chuẩn
          title: const Text(
              "Fashion Events",
              style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  letterSpacing: -0.5
              )
          ),
          centerTitle: false, // Tiêu đề nằm bên trái giống Wardrobe
          bottom: const TabBar(
            indicatorColor: Colors.black, // Đổi từ hồng sang đen
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3, // Giảm độ dày một xíu cho tinh tế
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black45,
            labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.0),
            tabs: [
              Tab(text: "EXPLORE"),
              Tab(text: "MY EVENTS")
            ],
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.black));

    if (_error != null && _allEvents == null) {
      return Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.black26, size: 60),
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextButton(
                    onPressed: _fetchInitialData,
                    child: const Text("RETRY", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
                )
              ]
          )
      );
    }

    final allEventsList = _allEvents ?? [];
    final discoveryEventsList = allEventsList.where((e) => e.status == "Active").toList();
    final joinedEventsList = allEventsList.where((e) => e.isJoined).toList();

    return TabBarView(
      physics: const BouncingScrollPhysics(),
      children: [
        RefreshIndicator(
            color: Colors.black,
            backgroundColor: Colors.white,
            onRefresh: _handleRefresh,
            child: _buildEventList(discoveryEventsList)
        ),
        RefreshIndicator(
            color: Colors.black,
            backgroundColor: Colors.white,
            onRefresh: _handleRefresh,
            child: _buildEventList(joinedEventsList)
        ),
      ],
    );
  }

  Widget _buildEventList(List<EventModel> events) {
    if (events.isEmpty) {
      return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 200),
            Center(
                child: Text(
                    "Hiện không có sự kiện nào",
                    style: TextStyle(color: Colors.black38, fontSize: 15, fontWeight: FontWeight.w500)
                )
            )
          ]
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 24, bottom: 40),
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
    final String startTimeStr = DateFormat('HH:mm - dd/MM').format(event.startTime.toLocal());
    final String endTimeStr = DateFormat('HH:mm - dd/MM/yyyy').format(event.endTime.toLocal());
    final String timeRange = "$startTimeStr - $endTimeStr";

    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Bo góc mượt mà
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1), // Viền xám tinh tế
        boxShadow: [
          // Bóng đổ cực nhẹ, không làm nặng mắt
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleNavigation(context),
            splashColor: Colors.black.withOpacity(0.05),
            highlightColor: Colors.black.withOpacity(0.02),
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
                            radius: 14,
                            backgroundColor: const Color(0xFFF0F0F0),
                            backgroundImage: event.creatorAvatarUrl != null ? NetworkImage(event.creatorAvatarUrl!) : null,
                            child: event.creatorAvatarUrl == null ? const Icon(Icons.person, color: Colors.black26, size: 16) : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                                event.creatorName,
                                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 13)
                            ),
                          ),
                          _buildStatusBadge(event.status, event.isJoined),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                          event.title,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.3,
                              letterSpacing: -0.3
                          )
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: Colors.black54, size: 14), // Đổi màu icon
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(
                                  timeRange,
                                  style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600)
                              )
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. PHẦN HÌNH ẢNH
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 1.6, // Tỉ lệ đẹp cho hình ảnh banner
                          child: Image.network(
                            event.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFF5F5F5),
                              child: const Icon(Icons.image_not_supported_outlined, color: Colors.black26, size: 40),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
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
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16), // Chuyển từ hồng sang trắng
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                  Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isJoined) {
    String displayStatus;
    Color textColor;
    Color bgColor;
    Color borderColor;

    // Logic phối màu Monochrome chuẩn
    if (status.toUpperCase() == "COMPLETED") {
      displayStatus = "COMPLETED";
      textColor = Colors.black45; // Xám nhạt cho sự kiện đã qua
      bgColor = const Color(0xFFF5F5F5);
      borderColor = const Color(0xFFEEEEEE);
    }
    else if (isJoined) {
      displayStatus = "JOINED";
      textColor = Colors.white; // Chữ trắng nền đen nổi bật việc đã tham gia
      bgColor = Colors.black;
      borderColor = Colors.black;
    }
    else {
      displayStatus = status.toUpperCase();
      textColor = Colors.black; // Chữ đen viền đen cho sự kiện mới
      bgColor = Colors.transparent;
      borderColor = Colors.black26;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 9,
            letterSpacing: 0.8
        ),
      ),
    );
  }
}