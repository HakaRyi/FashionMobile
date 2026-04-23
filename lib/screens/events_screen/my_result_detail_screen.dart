import 'package:flutter/material.dart';
import 'dart:ui';
import '../../constants/app_colors.dart';
import '../../models/event_model.dart';
import '../../models/event_result_model.dart';
import '../../services/event_service.dart';

class MyResultDetailScreen extends StatelessWidget {
  final EventModel event;
  const MyResultDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Nền xám cực nhạt
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 16),
              ),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
            "REVIEW DETAILS",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 14
            )
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<MyEventResultModel?>(
        future: EventService().getMyResult(event.eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
                child: Text(
                    "No result details available",
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)
                )
            );
          }
          final data = snapshot.data!;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("YOUR SUBMISSION"),

                // Hình ảnh bài thi (Lookbook Style)
                if (data.myPostImageUrl != null && data.myPostImageUrl!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 10)
                          )
                        ]
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: Image.network(
                          data.myPostImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: const Color(0xFFEBEBEB),
                            child: const Icon(Icons.broken_image_outlined, color: Colors.black26, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),

                Row(
                  children: [
                    Expanded(child: _buildStatBox("FINAL RANK", "#${data.rank}", isPrimary: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatBox("TOTAL SCORE", "${data.myScore} pt", isPrimary: false)),
                  ],
                ),
                const SizedBox(height: 36),

                _buildSectionTitle("EXPERT REVIEWS"),

                if (data.expertReviews.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEBEBEB))
                    ),
                    child: const Text(
                      "The judges have not left any reviews for your submission yet.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black45, fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  ...data.expertReviews.map((rev) => _buildExpertCard(rev)),
              ],
            ),
          );
        },
      ),
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
              color: Colors.black, // Vạch đen dọc làm điểm nhấn
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
              title,
              style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2
              )
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isPrimary ? null : Border.all(color: const Color(0xFFEBEBEB), width: 1),
        boxShadow: isPrimary ? [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))
        ] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              label,
              style: TextStyle(
                  color: isPrimary ? Colors.white70 : Colors.black45,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5
              )
          ),
          const SizedBox(height: 8),
          Text(
              value,
              style: TextStyle(
                  color: isPrimary ? Colors.white : Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5
              )
          ),
        ],
      ),
    );
  }

  Widget _buildExpertCard(ExpertReviewModel rev) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
          ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFF5F5F5),
                backgroundImage: rev.expertAvatar != null ? NetworkImage(rev.expertAvatar!) : null,
                child: rev.expertAvatar == null ? const Icon(Icons.person, color: Colors.black26) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rev.expertName,
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                        "EXPERT JUDGE",
                        style: TextStyle(color: Colors.black45, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8)
                ),
                child: Text(
                    "${rev.score} pt",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9), // Nền xám siêu nhạt cho phần bình luận
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                    left: BorderSide(color: Colors.black, width: 3) // Vạch nhấn Quote bên trái
                )
            ),
            child: Text(
                (rev.reason != null && rev.reason!.trim().isNotEmpty)
                    ? rev.reason!
                    : "The judge did not leave a specific comment for this score.",
                style: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontStyle: (rev.reason != null && rev.reason!.trim().isNotEmpty) ? FontStyle.italic : FontStyle.normal,
                  fontSize: 13,
                  height: 1.5,
                )
            ),
          ),
        ],
      ),
    );
  }
}