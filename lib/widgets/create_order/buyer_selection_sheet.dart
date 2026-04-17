import 'package:flutter/material.dart';
import '../../services/follow_service.dart';
import '../../models/search_model.dart';

class BuyerSelectionSheet extends StatefulWidget {
  final FollowService followService;
  final Function(UserSuggestionModel) onBuyerSelected;

  const BuyerSelectionSheet({
    super.key,
    required this.followService,
    required this.onBuyerSelected,
  });

  @override
  State<BuyerSelectionSheet> createState() => _BuyerSelectionSheetState();
}

class _BuyerSelectionSheetState extends State<BuyerSelectionSheet> {
  List<UserSuggestionModel> _allFollowers = [];
  List<UserSuggestionModel> _filteredFollowers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowers();
  }

  Future<void> _fetchFollowers() async {
    try {
      final followers = await widget.followService.getFollowers();
      if (mounted) {
        setState(() {
          _allFollowers = followers;
          _filteredFollowers = followers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterFollowers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFollowers = _allFollowers;
      } else {
        _filteredFollowers = _allFollowers.where((user) {
          return user.fullName.toLowerCase().contains(query.toLowerCase()) ||
              user.username.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Chọn người mua",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: _filterFollowers,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên hoặc username...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
                    : _filteredFollowers.isEmpty
                    ? const Center(child: Text("Không có ai theo dõi bạn.", style: TextStyle(color: Colors.white54)))
                    : ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  itemCount: _filteredFollowers.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 24),
                  itemBuilder: (context, index) {
                    final user = _filteredFollowers[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => widget.onBuyerSelected(user),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white10,
                        backgroundImage: NetworkImage(
                            user.avatarUrl.isNotEmpty
                                ? user.avatarUrl
                                : 'https://i.pravatar.cc/150?u=${user.accountId}'
                        ),
                      ),
                      title: Text(
                        user.fullName.isNotEmpty ? user.fullName : user.username,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '@${user.username}',
                        style: const TextStyle(color: Colors.pinkAccent, fontSize: 13),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}