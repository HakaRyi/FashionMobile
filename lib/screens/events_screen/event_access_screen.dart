import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import 'event_detail.dart' hide EventModel;

class EventAccessScreen extends StatelessWidget {
  final EventModel event;

  const EventAccessScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFF1E1E1E),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                event.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(event.imageUrl, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.8), Colors.transparent, const Color(0xFF0D0D0D)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Bài đăng sự kiện", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Icon(Icons.filter_list, color: event.themeColors.first),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return EventPostCard(
                  index: index,
                  themeColor: event.themeColors.first,
                );
              },
              childCount: 5,
            ),
          )
        ],
      ),
    );
  }
}

class EventPostCard extends StatefulWidget {
  final int index;
  final Color themeColor;

  const EventPostCard({
    super.key,
    required this.index,
    required this.themeColor,
  });

  @override
  State<EventPostCard> createState() => _EventPostCardState();
}

class _EventPostCardState extends State<EventPostCard> {
  bool isLiked = false;
  int likeCount = 0;

  @override
  void initState() {
    super.initState();
    likeCount = 120 + (widget.index * 15);
  }

  void _toggleLike() {
    setState(() {
      if (isLiked) {
        likeCount--;
        isLiked = false;
      } else {
        likeCount++;
        isLiked = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=${widget.index + 10}"),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("User Name ${widget.index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Text("2 giờ trước", style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.white54),
                onPressed: () {},
              )
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Tham gia sự kiện tuyệt vời này với outfit neon rực rỡ! ✨ Chờ đón những màn trình diễn đỉnh cao.",
            style: TextStyle(color: Colors.white, height: 1.4),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=1000&auto=format&fit=crop",
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                label: "$likeCount",
                color: isLiked ? widget.themeColor : Colors.white54,
                onTap: _toggleLike,
              ),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: "${24 + widget.index}",
                color: Colors.white54,
                onTap: () {},
              ),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: "Chia sẻ",
                color: Colors.white54,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}