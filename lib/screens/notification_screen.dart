import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../utils/notification_manager.dart';
import '../widgets/empty_notification_state.dart';
import '../widgets/real_notification_item.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({
    super.key,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await notificationManager.initialize();
    await notificationManager.fetchNotificationHistory();
  }

  Future<void> _handleRefresh() async {
    await notificationManager.fetchNotificationHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: notificationManager,
          builder: (context, child) {
            if (notificationManager.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2.4,
                ),
              );
            }

            final notifications = notificationManager.notifications;

            if (notifications.isEmpty) {
              return RefreshIndicator(
                onRefresh: _handleRefresh,
                color: Colors.black,
                backgroundColor: Colors.white,
                child: const SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: 540,
                    child: EmptyNotificationState(),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: Colors.black,
              backgroundColor: Colors.white,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildTopSection(),
                  ),
                  SliverList.separated(
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) {
                      return const Padding(
                        padding: EdgeInsets.only(left: 82),
                        child: Divider(
                          height: 1,
                          thickness: 0.6,
                          color: Color(0xFFEAEAEA),
                        ),
                      );
                    },
                    itemBuilder: (context, index) {
                      final item = notifications[index];

                      return RealNotificationItem(
                        item: item,
                      );
                    },
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leadingWidth: 52,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.black,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Notifications',
        style: TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _handleRefresh,
          icon: const Icon(
            Icons.refresh_rounded,
            color: Colors.black,
            size: 24,
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildTopSection() {
    final unreadCount = notificationManager.unreadCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Text(
            unreadCount > 0 ? 'New' : 'Recent',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1877F2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}