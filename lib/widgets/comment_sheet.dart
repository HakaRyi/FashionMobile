// // lib/widgets/comment_sheet.dart
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../constants/app_colors.dart';
// import '../utils/post_manager.dart';
//
// class CommentSheet extends StatefulWidget {
//   final int postId;
//
//   const CommentSheet({super.key, required this.postId});
//
//   @override
//   State<CommentSheet> createState() => _CommentSheetState();
// }
//
// class _CommentSheetState extends State<CommentSheet> {
//   final TextEditingController controller = TextEditingController();
//   final ScrollController scrollController = ScrollController();
//
//   List comments = [];
//
//   bool loading = true;
//   bool sending = false;
//
//   @override
//   void initState() {
//     super.initState();
//     loadComments();
//   }
//
//   @override
//   void dispose() {
//     controller.dispose();
//     scrollController.dispose();
//     super.dispose();
//   }
//
//   /// LOAD COMMENTS
//   Future<void> loadComments() async {
//     try {
//       final result = await SocialService.getComments(widget.postId);
//
//       if (!mounted) return;
//
//       setState(() {
//         comments = result;
//         loading = false;
//       });
//     } catch (e) {
//       debugPrint("Load comment error: $e");
//
//       if (!mounted) return;
//
//       setState(() {
//         loading = false;
//       });
//     }
//   }
//
//   /// SEND COMMENT
//   Future<void> sendComment() async {
//     if (sending) return;
//
//     final text = controller.text.trim();
//
//     if (text.isEmpty) return;
//
//     controller.clear();
//     FocusScope.of(context).unfocus();
//
//     sending = true;
//
//     /// optimistic UI
//     final fake = {
//       "userName": "Bạn",
//       "content": text,
//       "createdAt": DateTime.now().toIso8601String()
//     };
//
//     setState(() {
//       comments.insert(0, fake);
//     });
//
//     _scrollToTop();
//
//     try {
//       final result =
//       await SocialService.createComment(widget.postId, text);
//
//       if (result != null) {
//         setState(() {
//           comments[0] = result;
//         });
//
//         postManager.increaseCommentCount(widget.postId);
//       }
//     } catch (e) {
//       debugPrint("Send comment error: $e");
//     }
//
//     sending = false;
//   }
//
//   void _scrollToTop() {
//     if (scrollController.hasClients) {
//       scrollController.animateTo(
//         0,
//         duration: const Duration(milliseconds: 200),
//         curve: Curves.easeOut,
//       );
//     }
//   }
//
//   /// FORMAT TIME
//   String formatTime(String? time) {
//     if (time == null) return "";
//
//     final date = DateTime.tryParse(time);
//     if (date == null) return "";
//
//     final diff = DateTime.now().difference(date);
//
//     if (diff.inSeconds < 60) return "vừa xong";
//     if (diff.inMinutes < 60) return "${diff.inMinutes}p";
//     if (diff.inHours < 24) return "${diff.inHours}h";
//     if (diff.inDays < 7) return "${diff.inDays}d";
//
//     return DateFormat("dd/MM").format(date);
//   }
//
//   /// BUILD AVATAR
//   Widget buildAvatar(Map c) {
//     final avatar = c['avatarUrl'];
//     final name = c['userName'] ?? "U";
//
//     return CircleAvatar(
//       radius: 18,
//       backgroundImage: avatar != null ? NetworkImage(avatar) : null,
//       child: avatar == null
//           ? Text(
//         name[0].toUpperCase(),
//         style: const TextStyle(fontSize: 13),
//       )
//           : null,
//     );
//   }
//
//   /// BUILD COMMENT ITEM
//   Widget buildCommentItem(Map c) {
//     final name = c['userName'] ?? '';
//     final content = c['content'] ?? '';
//     final time = formatTime(c['createdAt']);
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 12,
//         vertical: 6,
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           buildAvatar(c),
//
//           const SizedBox(width: 10),
//
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 /// BUBBLE
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 8,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white10,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         name,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 13,
//                         ),
//                       ),
//
//                       const SizedBox(height: 3),
//
//                       Text(
//                         content,
//                         style: const TextStyle(fontSize: 14),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 const SizedBox(height: 4),
//
//                 /// TIME
//                 Text(
//                   time,
//                   style: const TextStyle(
//                     fontSize: 11,
//                     color: Colors.white38,
//                   ),
//                 ),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
//
//   /// LOADING PLACEHOLDER
//   Widget buildLoading() {
//     return const Center(
//       child: CircularProgressIndicator(),
//     );
//   }
//
//   /// EMPTY COMMENT
//   Widget buildEmpty() {
//     return const Center(
//       child: Text(
//         "Chưa có bình luận",
//         style: TextStyle(
//           color: Colors.white38,
//         ),
//       ),
//     );
//   }
//
//   /// COMMENT LIST
//   Widget buildCommentList() {
//     if (loading) return buildLoading();
//     if (comments.isEmpty) return buildEmpty();
//
//     return ListView.builder(
//       controller: scrollController,
//       reverse: true,
//       itemCount: comments.length,
//       itemBuilder: (context, index) {
//         final c = comments[index];
//         return buildCommentItem(c);
//       },
//     );
//   }
//
//   /// INPUT BAR
//   Widget buildInput() {
//     return SafeArea(
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Row(
//           children: [
//             Expanded(
//               child: TextField(
//                 controller: controller,
//                 decoration: const InputDecoration(
//                   hintText: "Viết bình luận...",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//             ),
//
//             const SizedBox(width: 8),
//
//             IconButton(
//               icon: sending
//                   ? const SizedBox(
//                 width: 18,
//                 height: 18,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   color: AppColors.textPink,
//                 ),
//               )
//                   : const Icon(
//                 Icons.send,
//                 color: AppColors.textPink,
//               ),
//               onPressed: sendComment,
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// HEADER
//   Widget buildHeader() {
//     return Column(
//       children: [
//         const SizedBox(height: 10),
//
//         Container(
//           width: 40,
//           height: 4,
//           decoration: BoxDecoration(
//             color: Colors.white24,
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//
//         const SizedBox(height: 10),
//
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               "Bình luận",
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//
//             const SizedBox(width: 6),
//
//             Text(
//               "${comments.length}",
//               style: const TextStyle(
//                 color: Colors.white54,
//               ),
//             )
//           ],
//         ),
//
//         const Divider(),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () => FocusScope.of(context).unfocus(),
//       child: Container(
//         height: MediaQuery.of(context).size.height * 0.85,
//         decoration: const BoxDecoration(
//           color: AppColors.surface,
//           borderRadius: BorderRadius.vertical(
//             top: Radius.circular(20),
//           ),
//         ),
//         child: Column(
//           children: [
//             buildHeader(),
//
//             Expanded(
//               child: buildCommentList(),
//             ),
//
//             const Divider(height: 1),
//
//             buildInput(),
//           ],
//         ),
//       ),
//     );
//   }
// }