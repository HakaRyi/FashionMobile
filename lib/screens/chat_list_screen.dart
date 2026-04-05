// import 'package:flutter/material.dart';
// import '../../constants/app_colors.dart';
// import '../../widgets/chat_item.dart';
// import 'chat_screen.dart';
// import '../../utils/route_transitions.dart';
// import '../../widgets/active_user_avatar.dart';
// import '../../services/chat_service.dart';
//
// class ChatListScreen extends StatefulWidget {
//   const ChatListScreen({super.key});
//
//   @override
//   State<ChatListScreen> createState() => _ChatListScreenState();
// }
//
// class _ChatListScreenState extends State<ChatListScreen> {
//   final ChatService _chatService = ChatService();
//   late Future<List<dynamic>> _groupsFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     // Gọi API lấy danh sách nhóm chat thực tế từ BE
//     _groupsFuture = _chatService.getMyGroups();
//   }
//
//   // Hàm để refresh danh sách khi kéo xuống
//   Future<void> _refreshGroups() async {
//     setState(() {
//       _groupsFuture = _chatService.getMyGroups();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         backgroundColor: AppColors.background,
//         elevation: 0,
//         centerTitle: true,
//         title: const Text("TIN NHẮN",
//             style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.edit_note, color: AppColors.textPink),
//             onPressed: () {
//               // Logic tạo nhóm mới hoặc tìm stylist
//             },
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _refreshGroups,
//         color: AppColors.textPink,
//         child: FutureBuilder<List<dynamic>>(
//           future: _groupsFuture,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(
//                   child: CircularProgressIndicator(color: AppColors.textPink));
//             }
//
//             if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
//               return _buildEmptyState();
//             }
//
//             final groups = snapshot.data!;
//
//             return Column(
//               children: [
//                 // 1. THANH TÌM KIẾM
//                 _buildSearchField(),
//
//                 // 2. DANH SÁCH NGƯỜI ĐANG HOẠT ĐỘNG (Dựa trên data thật)
//                 SizedBox(
//                   height: 105,
//                   child: ListView.builder(
//                     padding: const EdgeInsets.only(left: 16, top: 5),
//                     scrollDirection: Axis.horizontal,
//                     itemCount: groups.length,
//                     itemBuilder: (context, index) {
//                       final group = groups[index];
//                       // Chỉ hiện ở phần "Đang hoạt động" nếu là Online
//                       if (group['isOnline'] != "Online") return const SizedBox.shrink();
//
//                       return ActiveUserAvatar(
//                         avatarUrl: group['avatar'] ?? "https://cdn-icons-png.flaticon.com/512/8377/8377384.png",
//                         name: group['name'],
//                         isOnline: true,
//                         onTap: () => _navigateToChat(group),
//                       );
//                     },
//                   ),
//                 ),
//
//                 // 3. DANH SÁCH CHAT CHÍNH
//                 Expanded(
//                   child: Container(
//                     decoration: const BoxDecoration(
//                       color: AppColors.surface,
//                       borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
//                     ),
//                     child: ClipRRect(
//                       borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
//                       child: ListView.separated(
//                         padding: const EdgeInsets.only(top: 10, bottom: 20),
//                         itemCount: groups.length,
//                         separatorBuilder: (context, index) =>
//                         const Divider(color: Colors.white10, indent: 85),
//                         itemBuilder: (context, index) {
//                           final group = groups[index];
//                           return ChatItem(
//                             name: group['name'],
//                             lastMessage: group['isGroup'] ? "Tin nhắn nhóm" : "Bấm để trò chuyện",
//                             time: "", // Có thể bổ sung trường LastMessageAt từ BE
//                             avatarUrl: group['avatar'] ?? "https://cdn-icons-png.flaticon.com/512/8377/8377384.png",
//                             isOnline: group['isOnline'] == "Online",
//                             onTap: () => _navigateToChat(group),
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   void _navigateToChat(dynamic group) {
//     Navigator.push(
//       context,
//       SlideRoute(
//         page: ChatScreen(
//           groupId: group['groupId'],
//           userName: group['name'],
//           avatarUrl: group['avatar'] ?? "https://cdn-icons-png.flaticon.com/512/8377/8377384.png",
//           isOnline: group['isOnline'] == "Online",
//         ),
//       ),
//     ).then((_) => _refreshGroups());
//   }
//
//   Widget _buildSearchField() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         decoration: BoxDecoration(
//           color: AppColors.surface,
//           borderRadius: BorderRadius.circular(15),
//         ),
//         child: const TextField(
//           style: TextStyle(color: Colors.white),
//           decoration: InputDecoration(
//             icon: Icon(Icons.search, color: Colors.grey),
//             hintText: "Tìm kiếm cuộc trò chuyện...",
//             hintStyle: TextStyle(color: Colors.grey),
//             border: InputBorder.none,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.chat_bubble_outline, size: 80, color: Colors.white24),
//           const SizedBox(height: 16),
//           const Text("Chưa có cuộc hội thoại nào",
//               style: TextStyle(color: Colors.white54)),
//         ],
//       ),
//     );
//   }
// }