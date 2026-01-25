import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui'; // Để dùng ImageFilter.blur
import '../../models/event_model.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event; // Nhận data từ màn hình trước

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> with TickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _isAppBarCollapsed = false;

  // Animation controllers cho hiệu ứng Pulse (Nhịp đập)
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset > 250 && !_isAppBarCollapsed) {
        setState(() => _isAppBarCollapsed = true);
      } else if (_scrollController.offset <= 250 && _isAppBarCollapsed) {
        setState(() => _isAppBarCollapsed = false);
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Màu chủ đạo
    final primaryColor = widget.event.themeColors.first;
    final secondaryColor = widget.event.themeColors.last;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1 & 2. AppBar & Banner (SliverAppBar)
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFF0D0D0D),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_ios_new, size: 18),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                      child: const Icon(Icons.bookmark_border, size: 20),
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                      child: const Icon(Icons.share, size: 20),
                    ),
                    onPressed: () {},
                  ),
                ],
                // Hiệu ứng Gradient Title khi cuộn lên
                title: _isAppBarCollapsed
                    ? Text(
                  widget.event.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: primaryColor, blurRadius: 10)],
                  ),
                )
                    : null,
                centerTitle: true,

                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Ảnh nền
                      Image.network(widget.event.imageUrl, fit: BoxFit.cover),

                      // Overlay Gradient tối dần xuống dưới
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                              const Color(0xFF0D0D0D), // Hoà vào nền body
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),

                      // Hiệu ứng hạt lấp lánh (Particle System)
                      const ParticleOverlay(),

                      // Nội dung trên Banner
                      Positioned(
                        bottom: 60, // Chừa chỗ cho Floating Card
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.5), blurRadius: 10)],
                              ),
                              child: const Text(
                                "SẮP DIỄN RA",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.event.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  widget.event.time, // Ví dụ: 20/10/2026
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Nội dung chính
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3. Khối hành động nhanh (Floating Card)
                      Transform.translate(
                        offset: const Offset(0, -30), // Kéo lên đè vào banner
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Bạn có muốn tham gia?", style: TextStyle(color: Colors.white54, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text("1.2K người đã đăng ký", style: TextStyle(color: secondaryColor, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              _buildPulseButton(primaryColor, "Quan tâm"),
                            ],
                          ),
                        ),
                      ),

                      // 4. Thông tin chi tiết
                      _buildInfoRow(Icons.access_time_filled, "Thời gian", "18:00 - 23:00 (5 tiếng)", primaryColor),
                      _buildInfoRow(Icons.location_on, "Địa điểm", "Sky Bar, Tầng thượng Bitexco, Q1", secondaryColor),
                      const SizedBox(height: 24),

                      // 5. Mô tả
                      const Text("Giới thiệu sự kiện", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                        "Hãy sẵn sàng cho đêm tiệc ánh sáng lớn nhất năm! Không gian Neon cực chất, DJ hàng đầu và những bộ cánh thời trang ấn tượng nhất. Đừng bỏ lỡ cơ hội tỏa sáng!",
                        style: TextStyle(color: Colors.white.withOpacity(0.8), height: 1.5, fontSize: 14),
                      ),
                      const SizedBox(height: 24),

                      // 6. Timeline
                      const Text("Lịch trình", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildTimelineItem("18:00", "Check-in & Welcome Drink", secondaryColor, isFirst: true),
                      _buildTimelineItem("19:00", "Khai mạc & Fashion Show", primaryColor),
                      _buildTimelineItem("20:30", "DJ Performance", secondaryColor),
                      _buildTimelineItem("22:00", "Lucky Draw & Kết thúc", primaryColor, isLast: true),
                      const SizedBox(height: 24),

                      // 7. Người tham gia
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Người tham gia", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("Xem tất cả", style: TextStyle(color: primaryColor, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 6,
                          itemBuilder: (context, index) {
                            return Align(
                              widthFactor: 0.7, // Xếp chồng avatar
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF0D0D0D), width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=${index + 10}'),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 8. Đơn vị tổ chức
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const CircleAvatar(radius: 20, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=60')),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Fashion Club", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  Text("25 Sự kiện đã tổ chức", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: const Text("Theo dõi", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),

                      // Khoảng trống cho Bottom Bar
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 9. Bottom Action Bar (Cố định, Glassmorphism)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D0D).withOpacity(0.8),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Vé vào cửa", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          Text("Miễn phí", style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [primaryColor, secondaryColor],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.6 * _pulseController.value),
                                    blurRadius: 10 + (10 * _pulseController.value),
                                    spreadRadius: 2 * _pulseController.value,
                                  )
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.stars, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text("THAM GIA NGAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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

  // --- Helper Widgets ---

  Widget _buildPulseButton(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(30),
        color: color.withOpacity(0.1),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String time, String title, Color color, {bool isFirst = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Column(
              children: [
                if (!isFirst) Expanded(child: Container(width: 2, color: Colors.white10)),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  width: 12, height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: Colors.white10)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: color, width: 4)),
              ),
              child: Row(
                children: [
                  Text(time, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget tạo hiệu ứng hạt lấp lánh (Particle System)
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
            // Cập nhật vị trí hạt
            double y = (p.initialY - _controller.value * p.speed * 500) % 400; // 400 là height của banner
            double opacity = (math.sin(_controller.value * 2 * math.pi * p.blinkSpeed) + 1) / 2 * 0.8;

            return Positioned(
              top: y,
              left: p.initialX,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: p.size,
                  height: p.size,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.white, blurRadius: p.size * 2)],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// Class hỗ trợ hạt
class Particle {
  final double initialX = math.Random().nextDouble() * 400; // Random width
  final double initialY = math.Random().nextDouble() * 400;
  final double size = math.Random().nextDouble() * 3 + 1;
  final double speed = math.Random().nextDouble() * 0.5 + 0.2;
  final double blinkSpeed = math.Random().nextDouble() * 2 + 1;
}