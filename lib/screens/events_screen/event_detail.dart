// lib/screens/event_detail.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../models/event_model.dart';
import '../../models/post_feed_model.dart';
import '../../services/event_service.dart';
import '../../services/wallet_service.dart'; // IMPORT WalletService
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

  // Wallet
  final WalletService _walletService = WalletService();
  double _currentBalance = 0;
  bool _isLoadingBalance = true;

  final NumberFormat _currencyFormatter = NumberFormat('#,##0', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabController = TabController(length: 2, vsync: this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _loadAllData();
  }

  Future<void> _handleRefreshPosts() async {
    final updatedPosts = await EventService().getEventPosts(widget.eventId);
    if (mounted) {
      setState(() {
        _eventPosts = updatedPosts;
      });
    }
  }

  Future<void> _loadAllData() async {
    // Chạy song song cả 3 API: Event, Posts và Balance
    final results = await Future.wait([
      EventService().getEventById(widget.eventId),
      EventService().getEventPosts(widget.eventId),
      _fetchBalanceSafe(), // Hàm lấy số dư bọc try-catch
    ]);

    if (mounted) {
      setState(() {
        _event = results[0] as EventModel?;
        _eventPosts = results[1] as List<PostFeedModel>;
        _currentBalance = results[2] as double;
        _isLoading = false;
        _isLoadingPosts = false;
        _isLoadingBalance = false;
      });
    }
  }

  Future<double> _fetchBalanceSafe() async {
    try {
      return await _walletService.getMyWalletBalance();
    } catch (e) {
      return 0.0;
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
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    if (_event == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("Data loading failed", style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w500))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
                      indicatorColor: Colors.black,
                      indicatorWeight: 2.5,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.black45,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.0),
                      tabs: const [
                        Tab(text: "DETAILS"),
                        Tab(text: "SUBMISSIONS"),
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
      expandedHeight: 380,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
            ),
          ),
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              _event!.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFFE0E0E0)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.8)],
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
                    height: 1.2,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 4)),
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

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMainStats(),
          const SizedBox(height: 36),
          _buildSectionTitle("EVENT DESCRIPTION"),
          Text(
            _event!.description,
            style: const TextStyle(color: Colors.black87, height: 1.6, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 36),
          _buildSectionTitle("SCORING CRITERIA"),
          _buildWeightSection(),

          const SizedBox(height: 36),
          _buildSectionTitle("EVENT TIMELINE"),
          _buildTimelineSection(),
          const SizedBox(height: 36),
          _buildSectionTitle("PRIZE STRUCTURE"),
          _buildFlexiblePrizeUI(_event!.prizes),

          const SizedBox(height: 36),
          _buildSectionTitle("EXPERT JUDGES"),
          _buildExpertGrid(_event!.experts),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_isLoadingPosts) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    return RefreshIndicator(
      color: Colors.black,
      backgroundColor: Colors.white,
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
              Icon(Icons.camera_alt_outlined, size: 64, color: Colors.black.withOpacity(0.1)),
              const SizedBox(height: 16),
              const Text("No submissions yet", style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text("Pull down to refresh!", style: TextStyle(color: Colors.black26, fontSize: 12)),
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
            padding: const EdgeInsets.only(bottom: 8),
            child: PostItem(post: _eventPosts[index]),
          );
        },
      ),
    );
  }

  Widget _buildMainStats() {
    String feeText = _event!.entryFee <= 0 ? "Free" : "${_currencyFormatter.format(_event!.entryFee)} ₫";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(Icons.people_alt_outlined, "${_event!.participantCount}", "JOINED"),
          Container(width: 1, height: 30, color: const Color(0xFFE0E0E0)),
          _buildStatItem(Icons.emoji_events_outlined, NumberFormat.compact().format(_event!.totalPrizePool), "PRIZE POOL"),
          Container(width: 1, height: 30, color: const Color(0xFFE0E0E0)),
          _buildStatItem(Icons.account_balance_wallet_outlined, feeText, "ENTRY FEE"),
        ],
      ),
    );
  }

  Widget _buildWeightSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Row(
        children: [
          _buildWeightItem("EXPERT JUDGES", _event!.expertWeight, Colors.black),
          Container(width: 1, height: 40, color: const Color(0xFFE0E0E0)),
          _buildWeightItem("COMMUNITY", _event!.userWeight, Colors.black54),
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
            style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        children: [
          _buildTimelineRow("EVENT STARTS", _event!.startTime, Colors.black87),
          _buildTimelineDivider(),
          _buildTimelineRow("SUBMISSION DEADLINE", _event!.submissionDeadline ?? _event!.endTime, Colors.black54),
          _buildTimelineDivider(),
          _buildTimelineRow("EVENT ENDS", _event!.endTime, Colors.black26),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(String label, DateTime time, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(_formatDateTime(time), style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
      height: 24,
      width: 2,
      color: const Color(0xFFEEEEEE),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.black87, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.black45, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildFlexiblePrizeUI(List<PrizeModel> prizes) {
    if (prizes.isEmpty) return const Text("Updating...", style: TextStyle(color: Colors.black26));
    return Column(children: prizes.map((p) => _buildPrizeCard(p)).toList());
  }

  Widget _buildPrizeCard(PrizeModel p) {
    IconData prizeIcon;
    Color prizeColor;

    switch (p.ranked) {
      case 1:
        prizeIcon = Icons.emoji_events;
        prizeColor = const Color(0xFFD4AF37);
        break;
      case 2:
        prizeIcon = Icons.military_tech;
        prizeColor = const Color(0xFF9E9E9E);
        break;
      case 3:
        prizeIcon = Icons.stars;
        prizeColor = const Color(0xFF8D6E63);
        break;
      default:
        prizeIcon = Icons.card_giftcard;
        prizeColor = Colors.black87;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: Icon(prizeIcon, color: prizeColor, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("RANK ${p.ranked}",
                    style: TextStyle(color: prizeColor, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12)),
                const SizedBox(height: 4),
                Text("${NumberFormat.decimalPattern().format(p.rewardAmount)} VNĐ",
                    style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertGrid(List<ExpertModel> experts) {
    if (experts.isEmpty) return const Text("Judges are being updated...", style: TextStyle(color: Colors.black26));
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: experts.length,
      itemBuilder: (context, index) {
        final exp = experts[index];
        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              ),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFFF5F5F5),
                backgroundImage: exp.avatarUrl != null ? NetworkImage(exp.avatarUrl!) : null,
                child: exp.avatarUrl == null ? const Icon(Icons.person, color: Colors.black26) : null,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              exp.fullName,
              style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 12, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            const Text("EXPERT", style: TextStyle(color: Colors.black45, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        );
      },
    );
  }

  Widget _buildBottomAction() {
    final bool joined = _event?.isJoined ?? false;
    final bool isPastDeadline = _event!.submissionDeadline != null &&
        DateTime.now().isAfter(_event!.submissionDeadline!);

    // Kiểm tra số dư nếu sự kiện có phí
    bool hasEnoughBalance = true;
    if (_event!.entryFee > 0) {
      hasEnoughBalance = _currentBalance >= _event!.entryFee;
    }

    String btnText = "JOIN NOW";
    if (_event!.entryFee > 0 && !joined && !isPastDeadline) {
      btnText = "JOIN - ${_currencyFormatter.format(_event!.entryFee)}đ";
    }

    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              border: const Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dòng cảnh báo khi không đủ tiền
                if (_event!.entryFee > 0 && !hasEnoughBalance && !joined && !isPastDeadline && !_isLoadingBalance)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: const [
                        Icon(Icons.error_outline, color: Colors.redAccent, size: 14),
                        SizedBox(width: 4),
                        Text(
                          "Insufficient balance. Please top up.",
                          style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("STATUS", style: TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text(
                            isPastDeadline ? "EXPIRED" : "ACTIVE",
                            style: TextStyle(
                                color: isPastDeadline ? Colors.black45 : Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 52,
                      width: 180,
                      child: (joined || isPastDeadline)
                          ? _buildDisabledState(isPastDeadline ? "EXPIRED" : "JOINED")
                          : (!hasEnoughBalance && !_isLoadingBalance)
                          ? _buildDisabledState("INSUFFICIENT FUNDS") // Disable button nếu không đủ tiền
                          : _buildActiveState(btnText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledState(String label) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF5F5F5),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black45,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveState(String btnText) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15 * _pulseController.value),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
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
              child: Center(
                child: Text(
                  btnText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.0,
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
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        ],
      ),
    );
  }
}

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
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

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
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
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
            double y = (p.initialY - _controller.value * p.speed * 300) % 400;
            double opacity = (math.sin(_controller.value * 2 * math.pi * p.blinkSpeed) + 1) / 2 * 0.4;
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
  final double size = math.Random().nextDouble() * 2 + 1;
  final double speed = math.Random().nextDouble() * 0.3 + 0.1;
  final double blinkSpeed = math.Random().nextDouble() * 1.5 + 0.5;
}