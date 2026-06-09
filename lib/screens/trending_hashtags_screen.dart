import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../managers/post_manager.dart';
import 'hashtag_feed_screen.dart';

class TrendingHashtagsScreen extends StatefulWidget {
  const TrendingHashtagsScreen({super.key});

  @override
  State<TrendingHashtagsScreen> createState() => _TrendingHashtagsScreenState();
}

class _TrendingHashtagsScreenState extends State<TrendingHashtagsScreen> {
  final PostManager _manager = postManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _manager.loadTrendingHashtags();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Trending',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        centerTitle: false,
      ),
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, _) {
          if (_manager.isLoadingTrendingHashtags && _manager.trendingHashtagsList.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.textPink,
              ),
            );
          }

          final trendingList = _manager.trendingHashtagsList;

          if (trendingList.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => _manager.loadTrendingHashtags(),
              color: AppColors.textPink,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.trending_down_rounded,
                          size: 64,
                          color: Colors.grey.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No trending hashtags found.',
                          style: TextStyle(
                            color: Colors.black45,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pull down to retry',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _manager.loadTrendingHashtags(),
            color: AppColors.textPink,
            child: ListView.separated(
              itemCount: trendingList.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: Color(0xFFF1F1F1),
                indent: 64,
              ),
              itemBuilder: (context, index) {
                final item = trendingList[index];
                final rank = index + 1;

                Color rankColor = Colors.grey.shade600;
                if (rank == 1) rankColor = const Color(0xFFFF3B30);
                if (rank == 2) rankColor = const Color(0xFFFF9500);
                if (rank == 3) rankColor = const Color(0xFFFFCC00);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HashtagFeedScreen(tag: item.keyword ?? ''),
                      ),
                    );
                  },
                  leading: Container(
                    width: 32,
                    alignment: Alignment.center,
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: rankColor,
                      ),
                    ),
                  ),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          '#${item.keyword ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      if (rank <= 3) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEA),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'HOT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF3B30),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      rank == 1
                          ? 'Top trending topic right now'
                          : rank <= 3
                          ? 'Highly popular community choice'
                          : 'Gaining recent momentum',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: rank <= 3 ? const Color(0xFFFF9500) : Colors.grey.shade500,
                        fontWeight: rank <= 3 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.totalPosts ?? 0} posts',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}