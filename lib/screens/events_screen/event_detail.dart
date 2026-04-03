// lib/screens/event_detail.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../models/event_model.dart';
import '../../models/post_feed_model.dart';
import '../../services/event_service.dart';
import 'package:intl/intl.dart';

import '../../utils/route_transitions.dart';
import '../../widgets/post_item.dart';
import '../create_post_screens.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _pulseController;
  late TabController _tabController;

  EventModel? _event;
  List<PostFeedModel> _eventPosts = [];
  bool _isLoading = true;
  bool _isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabController = TabController(length: 2, vsync: this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadAllData();
  }
  Future<void> _handleRefreshPosts() async {
    // Chỉ tải lại danh sách bài post
    final updatedPosts = await EventService().getEventPosts(widget.eventId);
    if (mounted) {
      setState(() {
        _eventPosts = updatedPosts;
      });
    }
  }
  Future<void> _loadAllData() async {
    final results = await Future.wait([
      EventService().getEventById(widget.eventId),
      EventService().getEventPosts(widget.eventId),
    ]);

    if (mounted) {
      setState(() {
        _event = results[0] as EventModel?;
        _eventPosts = results[1] as List<PostFeedModel>;
        _isLoading = false;
        _isLoadingPosts = false;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy • HH:mm').format(dateTime.toLocal());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)),
      );
    }

    if (_event == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(child: Text("Lỗi tải dữ liệu", style: TextStyle(color: Colors.white))),
      );
    }
    final bool isPastDeadline = _event!.submissionDeadline != null &&
        DateTime.now().isAfter(_event!.submissionDeadline!);
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildSliverAppBar(),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.pinkAccent,
                      indicatorWeight: 3,
                      labelColor: Colors.pinkAccent,
                      unselectedLabelColor: Colors.white38,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      tabs: const [
                        Tab(text: "THÔNG TIN"),
                        Tab(text: "BÀI DỰ THI"),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildPostsTab(),
              ],
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      backgroundColor: const Color(0xFF0D0D0D),
      leading: IconButton(
        icon: const CircleAvatar(
            backgroundColor: Colors.black45,
            child: Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white)),
        onPressed: () => Navigator.maybePop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(_event!.imageUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.1), Colors.black],
                ),
              ),
            ),
            const ParticleOverlay(),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _event!.title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(color: Colors.pinkAccent, blurRadius: 25),
                      Shadow(color: Colors.black, offset: Offset(2, 2)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: THÔNG TIN SỰ KIỆN ---
  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMainStats(),
          const SizedBox(height: 32),
          _buildSectionTitle("Giới thiệu sự kiện"),
          Text(
            _event!.description,
            style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.6, fontSize: 15),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle("Cơ chế tính điểm"),
          _buildWeightSection(),

          const SizedBox(height: 32),
          _buildSectionTitle("Lịch trình sự kiện"),
          _buildTimelineSection(),
          const SizedBox(height: 32),
          _buildSectionTitle("Cơ cấu giải thưởng"),
          _buildFlexiblePrizeUI(_event!.prizes),


          const SizedBox(height: 32),
          _buildSectionTitle("Ban giám khảo chuyên gia"),
          _buildExpertGrid(_event!.experts),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // --- TAB 2: DANH SÁCH BÀI ĐĂNG ---
  Widget _buildPostsTab() {
    if (_isLoadingPosts) {
      return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
    }

    return RefreshIndicator(
      color: Colors.pinkAccent,
      backgroundColor: const Color(0xFF1A1A1A),
      onRefresh: _handleRefreshPosts,
      child: _eventPosts.isEmpty
          ? SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.4,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 16),
              const Text("Chưa có bài dự thi nào", style: TextStyle(color: Colors.white38)),
              const Text("Kéo xuống để cập nhật bài mới!", style: TextStyle(color: Colors.white24, fontSize: 12)),
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 120),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _eventPosts.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 0, top: 0),
            child: PostItem(post: _eventPosts[index]),
          );
        },
      ),
    );
  }

  Widget _buildMainStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(Icons.people_alt_outlined, "${_event!.participantCount}", "Tham gia"),
        _buildStatItem(Icons.emoji_events_outlined, NumberFormat.compact().format(_event!.totalPrizePool), "Giải thưởng"),
        _buildStatItem(Icons.verified_user_outlined, "Miễn phí", "Lệ phí"),
      ],
    );
  }

  Widget _buildWeightSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _buildWeightItem("Ban giám khảo", _event!.expertWeight, Colors.amberAccent),
          Container(width: 1, height: 40, color: Colors.white10),
          _buildWeightItem("Cộng đồng", _event!.userWeight, Colors.cyanAccent),
        ],
      ),
    );
  }

  Widget _buildWeightItem(String label, double weight, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            "${(weight * 100).toInt()}%",
            style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildTimelineRow("Bắt đầu sự kiện", _event!.startTime, Colors.greenAccent),
          _buildTimelineDivider(),
          _buildTimelineRow("Hạn nộp bài thi", _event!.submissionDeadline ?? _event!.endTime, Colors.orangeAccent),
          _buildTimelineDivider(),
          _buildTimelineRow("Kết thúc sự kiện", _event!.endTime, Colors.pinkAccent),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(String label, DateTime time, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text(_formatDateTime(time), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 5, top: 4, bottom: 4),
      height: 20,
      width: 2,
      color: Colors.white10,
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.pinkAccent, size: 22),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildFlexiblePrizeUI(List<PrizeModel> prizes) {
    if (prizes.isEmpty) return const Text("Đang cập nhật...", style: TextStyle(color: Colors.white24));
    return Column(children: prizes.map((p) => _buildPrizeCard(p)).toList());
  }

  Widget _buildPrizeCard(PrizeModel p) {
    IconData prizeIcon;
    Color prizeColor;
    switch (p.ranked) {
      case 1:
        prizeIcon = Icons.emoji_events;
        prizeColor = const Color(0xFFFFD700);
        break;
      case 2:
        prizeIcon = Icons.military_tech;
        prizeColor = const Color(0xFFC0C0C0);
        break;
      case 3:
        prizeIcon = Icons.stars;
        prizeColor = const Color(0xFFCD7F32);
        break;
      default:
        prizeIcon = Icons.card_giftcard;
        prizeColor = Colors.pinkAccent.withOpacity(0.6);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.02)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: prizeColor.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: prizeColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(prizeIcon, color: prizeColor, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("HẠNG ${p.ranked}",
                    style: TextStyle(color: prizeColor, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 13)),
                const SizedBox(height: 6),
                Text("${NumberFormat.decimalPattern().format(p.rewardAmount)} VNĐ",
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertGrid(List<ExpertModel> experts) {
    if (experts.isEmpty) return const Text("Đang cập nhật ban giám khảo...", style: TextStyle(color: Colors.white24));
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: experts.length,
      itemBuilder: (context, index) {
        final exp = experts[index];
        return Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white10,
              backgroundImage: exp.avatarUrl != null ? NetworkImage(exp.avatarUrl!) : null,
              child: exp.avatarUrl == null ? const Icon(Icons.person, color: Colors.white24) : null,
            ),
            const SizedBox(height: 8),
            Text(
              exp.fullName,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text("Expert", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
          ],
        );
      },
    );
  }

  Widget _buildBottomAction() {
    final bool joined = _event?.isJoined ?? false;
    final bool isPastDeadline = _event!.submissionDeadline != null &&
        DateTime.now().isAfter(_event!.submissionDeadline!);
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Trạng thái", style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(
                        isPastDeadline ? "Hết hạn nộp" : "Đang mở",
                        style: TextStyle(
                          color: isPastDeadline ? Colors.redAccent : Colors.greenAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 54,
                  width: 180,
                  child: (joined || isPastDeadline) ? _buildDisabledState(isPastDeadline) : _buildActiveState(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledState(bool isPastDeadline) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: Colors.white10),
      ),
      child:  Center(
        child: Text(
          isPastDeadline ? "HẾT HẠN NỘP" : "ĐÃ THAM GIA",
          style: TextStyle(
            color: Colors.white24,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveState() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF4081), Color(0xFFFF80AB)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.pinkAccent.withOpacity(0.4 * _pulseController.value),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  SlideRoute(
                    page: CreatePostScreen(
                      eventId: _event!.eventId,
                      eventName: _event!.title,
                    ),
                  ),
                );
              },
              child: const Center(
                child: Text(
                  "THAM GIA NGAY",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4081), Color(0xFFFF80AB)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- HELPER DELEGATE CHO TABBAR ---
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF0D0D0D), // Nền tối để hòa hợp với thiết kế
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

// ParticleOverlay và Particle class giữ nguyên phần cuối...
class ParticleOverlay extends StatefulWidget {
  const ParticleOverlay({super.key});
  @override
  State<ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<ParticleOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = List.generate(15, (index) => Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: _particles.map((p) {
            double y = (p.initialY - _controller.value * p.speed * 500) % 400;
            double opacity = (math.sin(_controller.value * 2 * math.pi * p.blinkSpeed) + 1) / 2 * 0.8;
            return Positioned(
              top: y,
              left: p.initialX,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: p.size,
                  height: p.size,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class Particle {
  final double initialX = math.Random().nextDouble() * 400;
  final double initialY = math.Random().nextDouble() * 400;
  final double size = math.Random().nextDouble() * 3 + 1;
  final double speed = math.Random().nextDouble() * 0.5 + 0.2;
  final double blinkSpeed = math.Random().nextDouble() * 2 + 1;
}