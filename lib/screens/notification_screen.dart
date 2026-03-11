import 'package:flutter/material.dart';
import '../constants/app_colors.dart'; // Đảm bảo bạn đã có file này hoặc dùng màu cứng

// Enum để định nghĩa loại thông báo
// enum NotificationType { like, comment, share, follow, bookmark }

// Model dữ liệu giả lập
class NotificationModel {
  final String userName;
  final String userAvatar;
  final String content;
  final String timeAgo;
  final String? postImage; // Có thể null nếu là thông báo follow
  // final NotificationType type;
  final bool isRead;

  NotificationModel({
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.timeAgo,
    this.postImage,
    // required this.type,
    this.isRead = false,
  });
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Dữ liệu giả lập (Mock Data)
  final List<NotificationModel> _allNotifications = [
    // HÔM NAY
    // NotificationModel(
    //   userName: "kylie_jenner",
    //   userAvatar: "https://i.pravatar.cc/150?img=1",
    //   content: "đã thích bài viết của bạn.",
    //   timeAgo: "2 phút trước",
    //   postImage: "https://picsum.photos/200/200?random=1",
    //   type: NotificationType.like,
    // ),
    // NotificationModel(
    //   userName: "fashion_weekly",
    //   userAvatar: "https://i.pravatar.cc/150?img=2",
    //   content: "đã bắt đầu theo dõi bạn.",
    //   timeAgo: "1 giờ trước",
    //   type: NotificationType.follow,
    // ),
    // NotificationModel(
    //   userName: "alex_design",
    //   userAvatar: "https://i.pravatar.cc/150?img=3",
    //   content: "đã bình luận: 'Outfit này đỉnh quá! 🔥'",
    //   timeAgo: "3 giờ trước",
    //   postImage: "https://picsum.photos/200/200?random=2",
    //   type: NotificationType.comment,
    // ),
    //
    // // HÔM QUA
    // NotificationModel(
    //   userName: "bella_hadid",
    //   userAvatar: "https://i.pravatar.cc/150?img=4",
    //   content: "đã chia sẻ bài viết của bạn.",
    //   timeAgo: "Hôm qua",
    //   postImage: "https://picsum.photos/200/200?random=3",
    //   type: NotificationType.share,
    // ),
    // NotificationModel(
    //   userName: "vogue_magazine",
    //   userAvatar: "https://i.pravatar.cc/150?img=5",
    //   content: "đã lưu bài viết vào bộ sưu tập.",
    //   timeAgo: "Hôm qua",
    //   postImage: "https://picsum.photos/200/200?random=4",
    //   type: NotificationType.bookmark,
    // ),
    //
    // // TRƯỚC ĐÓ
    // NotificationModel(
    //   userName: "zara_official",
    //   userAvatar: "https://i.pravatar.cc/150?img=6",
    //   content: "đã nhắc đến bạn trong một bình luận.",
    //   timeAgo: "3 ngày trước",
    //   postImage: "https://picsum.photos/200/200?random=5",
    //   // type: NotificationType.comment,
    // ),
  ];

  @override
  Widget build(BuildContext context) {
    bool isEmpty = _allNotifications.isEmpty;
    var todayList;
    var yesterdayList;
    var earlierList;
    if(!isEmpty){
       todayList = _allNotifications.take(3).toList();
       yesterdayList = _allNotifications.skip(3).take(2).toList();
       earlierList = _allNotifications.skip(5).toList();
    }else{
      todayList = [];
      yesterdayList = [];
      earlierList = [];
    }

    return Scaffold(
      backgroundColor: AppColors.background, // Màu nền tối (#0D0D0D)
      appBar: AppBar(
        backgroundColor: AppColors.background.withOpacity(0.95),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Thông báo",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 24),
            onPressed: () {},
          ),
        ],
      ),
      body:
      isEmpty ? const EmptyNotificationState() :
      ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          _buildSection("HÔM NAY", todayList),
          _buildSection("HÔM QUA", yesterdayList),
          _buildSection("TRƯỚC ĐÓ", earlierList),
        ],
      ),
    );
  }

  // Widget dựng Section (Ẩn nếu list rỗng)
  Widget _buildSection(String title, List<NotificationModel> notifications) {
    if (notifications.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.6), // Màu xám mờ
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...notifications.map((item) => NotificationItem(item: item)),
      ],
    );
  }
}

// Widget hiển thị từng Notification Item
class NotificationItem extends StatelessWidget {
  final NotificationModel item;

  const NotificationItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface, // Màu card (#1A1A1A)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Bên trái: Thumbnail + Badge Icon
          _buildThumbnail(),

          const SizedBox(width: 14),

          // 2. Bên phải: Nội dung
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textSecondary, // Màu xám nhạt
                      fontFamily: 'Roboto', // Hoặc font app của bạn
                    ),
                    children: [
                      TextSpan(
                        text: item.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary, // Màu trắng
                        ),
                      ),
                      const WidgetSpan(child: SizedBox(width: 4)),
                      TextSpan(text: item.content),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.timeAgo,
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    return Stack(
      clipBehavior: Clip.none, // Cho phép icon tràn ra ngoài viền nhẹ nếu muốn
      children: [
        // Ảnh nền (Post hoặc Avatar nếu là follow)
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            image: DecorationImage(
              image: NetworkImage(item.postImage ?? item.userAvatar),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Icon Badge ở góc phải dưới
        Positioned(
          bottom: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              // gradient: _getBadgeGradient(item.type),
              shape: BoxShape.circle,
              // Viền ngoài cùng màu với Card nền để tạo khoảng cách (Negative Space)
              border: Border.all(color: AppColors.surface, width: 2),
            ),
            // child: Icon(
            //   _getBadgeIcon(item.type),
            //   size: 12,
            //   color: Colors.white,
            // ),
          ),
        ),
      ],
    );
  }

  // Helper: Chọn icon theo loại
  // IconData _getBadgeIcon(NotificationType type) {
  //   switch (type) {
  //     case NotificationType.like: return Icons.favorite;
  //     case NotificationType.comment: return Icons.chat_bubble;
  //     case NotificationType.share: return Icons.share; // Hoặc Icons.repeat
  //     case NotificationType.bookmark: return Icons.bookmark;
  //     case NotificationType.follow: return Icons.person_add;
  //   }
  // }

  // Helper: Chọn màu gradient theo loại
  // LinearGradient _getBadgeGradient(NotificationType type) {
  //   switch (type) {
  //     case NotificationType.like:
  //       return const LinearGradient(colors: [Colors.pinkAccent, Colors.redAccent]);
  //     case NotificationType.comment:
  //       return const LinearGradient(colors: [Colors.blueAccent, Colors.cyan]);
  //     case NotificationType.share:
  //       return const LinearGradient(colors: [Colors.green, Colors.teal]);
  //     case NotificationType.bookmark:
  //       return const LinearGradient(colors: [Colors.orange, Colors.amber]);
  //     case NotificationType.follow:
  //       return const LinearGradient(colors: [Colors.purpleAccent, Colors.deepPurple]);
  //   }
  // }
}

class EmptyNotificationState extends StatelessWidget {
  const EmptyNotificationState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Icon minh họa với hiệu ứng Glow
            Stack(
              alignment: Alignment.center,
              children: [
                // Lớp Glow mờ phía sau
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.purpleAccent.withOpacity(0.15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purpleAccent.withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
                // Vòng tròn chứa Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface, // Màu nền card (#1A1A1A)
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.notifications_paused_outlined, // Icon cái chuông "ngủ"
                    size: 40,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 2. Tiêu đề
            const Text(
              "Mọi thứ đang yên tĩnh",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 12),

            // 3. Mô tả phụ
            Text(
              "Khi bạn tương tác với mọi người, thông báo sẽ xuất hiện ở đây. Hãy bắt đầu kết nối nhé!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 40),

            // 4. Nút hành động (Call to Action)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Điều hướng sang trang Khám phá hoặc Home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Nút trắng nổi bật trên nền đen
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  "Khám phá ngay",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}