import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'dart:io';
import 'shared_post_card.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final List<String>? photos;
  final bool isMe;
  final List<dynamic>? reactions;
  final Map<String, dynamic>? sharedPost;
  final VoidCallback? onTapSharedPost;

  const ChatBubble({
    super.key,
    required this.message,
    this.photos,
    required this.isMe,
    this.reactions,
    this.sharedPost,
    this.onTapSharedPost,
  });

  bool get _hasSharedPost {
    return sharedPost != null && sharedPost!['sharedPostId'] != null;
  }

  String _getEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'haha': return '😆';
      case 'like': return '❤️';
      case 'mad': return '😡';
      case 'sad': return '😥';
      case 'suprise': return '😲';
      default: return '👍';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Stack( // Dùng Stack để đè reaction lên góc bubble
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (photos != null && photos!.isNotEmpty) _buildPhotosGrid(context),

            if (message.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.textPink : AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 16),
                  ),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),

            if (_hasSharedPost) ...[
              if (message.isNotEmpty || (photos != null && photos!.isNotEmpty))
                const SizedBox(height: 6),
              SharedPostCard(
                sharedPost: sharedPost!,
                isMe: isMe,
                onTap: onTapSharedPost,
              ),
            ],
          ],
        ),
        // HIỂN THỊ REACTION
        if (reactions != null && reactions!.isNotEmpty)
          Positioned(
            bottom: -8,
            left: isMe ? 10 : null,
            right: !isMe ? 10 : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.background, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: reactions!.map((r) => Text(
                  _getEmoji(r['reactionType'] ?? ""),
                  style: const TextStyle(fontSize: 12),
                )).toList(),
              ),
            ),
          ),
      ],
    );
  }
  Widget _buildPhotosGrid(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
        children: photos!.map((url) => _buildImageItem(url)).toList(),
      ),
    );
  }
  Widget _buildImageItem(String url) {
    bool isLocalFile = !url.startsWith('http');

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          isLocalFile
              ? Image.file(File(url), width: 120, height: 120, fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(.5))
              : Image.network(url, width: 120, height: 120, fit: BoxFit.cover),

          // Nếu là file local (đang gửi), hiện thêm vòng xoay nhỏ ở góc
          if (isLocalFile)
            const Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}