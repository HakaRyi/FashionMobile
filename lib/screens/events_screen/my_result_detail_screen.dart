import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/event_model.dart';
import 'package:fashion_mobile/constants/app_colors.dart';

class MyResultDetailScreen extends StatefulWidget {
  final EventModel event;

  const MyResultDetailScreen({super.key, required this.event});

  @override
  State<MyResultDetailScreen> createState() => _MyResultDetailScreenState();
}

class _MyResultDetailScreenState extends State<MyResultDetailScreen> {
  bool _isListExpanded = false;
  bool _isLoadingMore = false;

  final List<Map<String, String>> _allVoters = List.generate(
      35,
          (index) => {"name": "Fashionista ${index + 1}", "avatar": "https://i.pravatar.cc/150?img=${(index % 50) + 1}"}
  );

  List<Map<String, String>> _loadedVoters = [];

  void _toggleVoterList() {
    setState(() {
      _isListExpanded = !_isListExpanded;
      if (_isListExpanded && _loadedVoters.isEmpty) {
        _loadMoreVoters();
      }
    });
  }

  Future<void> _loadMoreVoters() async {
    if (_isLoadingMore || _loadedVoters.length >= _allVoters.length) return;

    setState(() => _isLoadingMore = true);

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        int nextCount = math.min(_loadedVoters.length + 10, _allVoters.length);
        _loadedVoters = _allVoters.sublist(0, nextCount);
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification info) {
          if (info.metrics.pixels >= info.metrics.maxScrollExtent - 50) {
            if (_isListExpanded && !_isLoadingMore) {
              _loadMoreVoters();
            }
          }
          return false;
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: const Color(0xFF0A0A0A),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
                title: Text(
                  widget.event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(widget.event.imageUrl, fit: BoxFit.cover),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Color(0xFF0A0A0A)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.3, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExpertEvaluation(),
                    const SizedBox(height: 24),
                    _buildCommunityVotingSummary(),
                  ],
                ),
              ),
            ),

            if (_isListExpanded)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      if (index == _loadedVoters.length) {
                        return _buildSkeletonLoader();
                      }

                      final voter = _loadedVoters[index];
                      return _buildVoterTile(voter);
                    },
                    childCount: _loadedVoters.length + (_isLoadingMore ? 1 : 0),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpertEvaluation() {
    final Color glowColor = widget.event.themeColors.first;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: glowColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: widget.event.themeColors),
                ),
                child: const CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=68"),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text("Katy Nguyen", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(width: 6),
                        Icon(Icons.verified, color: Colors.blueAccent, size: 16),
                      ],
                    ),
                    Text("Fashion Expert", style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("9.5", style: TextStyle(color: glowColor, fontSize: 28, fontWeight: FontWeight.w900)),
                  const Text("Điểm chuyên gia", style: TextStyle(color: Colors.white54, fontSize: 10)),
                ],
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10, height: 1),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.format_quote_rounded, color: glowColor.withOpacity(0.5), size: 28),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Sự kết hợp màu sắc neon rất táo bạo và thể hiện đúng tinh thần của sự kiện. Phụ kiện đi kèm làm tôn lên vẻ cá tính. Một bộ outfit xuất sắc!",
                  style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityVotingSummary() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_alt_outlined, color: Colors.white54, size: 20),
                      const SizedBox(width: 8),
                      const Text("Tổng lượt vote", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                        child: Text("${_allVoters.length}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.star_border_rounded, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Text("Điểm cộng đồng", style: TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Text(
                "+${_allVoters.length}",
                style: const TextStyle(color: Colors.amber, fontSize: 32, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.amberAccent, blurRadius: 10)]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _toggleVoterList,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isListExpanded ? "Thu gọn danh sách" : "Xem tất cả người đã vote",
                  style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isListExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.white54,
                  size: 20,
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildVoterTile(Map<String, String> voter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(voter["avatar"]!),
        ),
        title: Text(voter["name"]!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        trailing: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("+1", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
            Icon(Icons.star, color: Colors.amber, size: 16),
          ],
        ),
        onTap: () {
          // TODO: Điều hướng sang trang cá nhân của người dùng
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Chuyển đến trang cá nhân của ${voter["name"]}"), backgroundColor: const Color(0xFF2E0249)),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Column(
      children: List.generate(10, (index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.05),
          highlightColor: Colors.white.withOpacity(0.15),
          child: Container(
            height: 60,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          ),
        ),
      )),
    );
  }
}