import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/notification_manager.dart';
import '../widgets/empty_notification_state.dart';
import '../widgets/real_notification_item.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    notificationManager.initialize();
    notificationManager.fetchNotificationHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background.withOpacity(0.95),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Thông báo",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListenableBuilder(
        listenable: notificationManager,
        builder: (context, child) {
          if (notificationManager.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final notifications = notificationManager.notifications;

          if (notifications.isEmpty) {
            return const EmptyNotificationState();
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 20, top: 10),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              return RealNotificationItem(item: item);
            },
          );
        },
      ),
    );
  }
}