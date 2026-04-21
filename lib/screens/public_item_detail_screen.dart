// lib/screens/public_item_detail_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/public_item_detail_model.dart';
import '../services/item_service.dart';
import '../models/try_on_source_item.dart';
import '../utils/route_transitions.dart';
import 'chat_screen.dart';
import 'try_on_screen.dart';

class PublicItemDetailScreen extends StatefulWidget {
  final int itemId;

  const PublicItemDetailScreen({
    super.key,
    required this.itemId,

  });

  @override
  State<PublicItemDetailScreen> createState() => _PublicItemDetailScreenState();
}

class _PublicItemDetailScreenState extends State<PublicItemDetailScreen> {
  final ItemService _itemService = ItemService();
  final PageController _pageController = PageController();

  bool _isLoading = true;
  String? _error;
  PublicItemDetailModel? _item;
  int _currentImageIndex = 0;

  bool _isConsulting = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  OverlayEntry? _overlayEntry;
  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
  void _removeToast() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // HÀM HIỂN THỊ TOAST CHUYÊN NGHIỆP Ở GÓC TRÊN PHẢI
  void _showCustomToast(int groupId, String ownerName, String avatarUrl) {
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.textPink.withOpacity(0.5), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.textPink.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded, color: AppColors.textPink, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Success",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        "Consultation request sent to $ownerName",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _removeToast();
                    Navigator.push(
                      context,
                      SlideRoute(
                        page: ChatScreen(
                          groupId: groupId,
                          userName: ownerName,
                          avatarUrl: avatarUrl,
                          isOnline: true,
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.textPink,
                  ),
                  child: const Text("CHAT", style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    // Tự động xóa sau 5 giây
    Future.delayed(const Duration(seconds: 5), () {
      if (_overlayEntry != null) _removeToast();
    });
  }
  Future<void> _loadItem() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final result = await _itemService.getPublicItemDetail(widget.itemId);

      if (!mounted) return;
      setState(() {
        _item = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _handleConsult() async {
    if (_item == null) return;

    setState(() => _isConsulting = true);

    try {
      final groupId = await _itemService.sendConsultRequest(widget.itemId);

      if (groupId != null && mounted) {
        setState(() => _cooldownSeconds = 5);

        _cooldownTimer?.cancel();
        _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }

          if (_cooldownSeconds <= 1) {
            setState(() => _cooldownSeconds = 0);
            timer.cancel();
          } else {
            setState(() => _cooldownSeconds--);
          }
        });

        Navigator.push(
          context,
          SlideRoute(
            page: ChatScreen(
              groupId: groupId,
              userName: _item!.ownerUserName ?? "Owner",
              avatarUrl: _item!.ownerAvatarUrl ?? "",
              isOnline: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isConsulting = false);
    }
  }
  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  List<MapEntry<String, String>> _buildAttributes(PublicItemDetailModel item) {
    final result = <MapEntry<String, String>>[];

    void addField(String label, String? value) {
      if (_hasText(value)) {
        result.add(MapEntry(label, value!.trim()));
      }
    }

    addField('Item Type', item.itemType);
    addField('Category', item.category);
    addField('Sub-Category', item.subCategory);
    addField('Style', item.style);
    addField('Gender', item.gender);
    addField('Primary Color', item.mainColor);
    addField('Secondary Color', item.subColor);
    addField('Material', item.material);
    addField('Pattern', item.pattern);
    addField('Fit', item.fit);
    addField('Neckline', item.neckline);
    addField('Sleeve Length', item.sleeveLength);
    addField('Length', item.length);
    addField('Size', item.size);
    addField('Brand', item.brand);

    return result;
  }

  Widget _buildTryOnButton(PublicItemDetailModel item) {
    final String? imageUrl =
    item.imageUrls.isNotEmpty ? item.imageUrls.first : null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (imageUrl == null || imageUrl.trim().isEmpty)
            ? null
            : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TryOnScreen(
                sourceItem: TryOnSourceItem(
                  itemId: item.itemId,
                  itemName: item.itemName,
                  imageUrl: imageUrl,
                  category: item.category,
                  brand: item.brand,
                ),
              ),
            ),
          );
        },
        icon: const Icon(Icons.checkroom),
        label: const Text(
          'Try-on this item',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textPink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.white10,
          disabledForegroundColor: Colors.white38,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
  Widget _buildConsultButton() {
    bool isCooldown = _cooldownSeconds > 0;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: (_isConsulting || isCooldown) ? null : _handleConsult,
        icon: _isConsulting
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPink),
        )
            : Icon(isCooldown ? Icons.timer_outlined : Icons.chat_bubble_outline, size: 20),
        label: Text(
          isCooldown ? "Resend in (${_cooldownSeconds}s)" : "Get styling advice",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPink,
          side: const BorderSide(color: AppColors.textPink, width: 1.5),
          disabledForegroundColor: Colors.white24,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final item = _item;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : item == null
          ? _buildEmpty()
          : RefreshIndicator(
        onRefresh: _loadItem,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 360,
              pinned: true,
              backgroundColor: AppColors.background,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                _hasText(item.itemName) ? item.itemName! : 'Item Details',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 1))
                  ],
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _buildImageSlider(item),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOwnerSection(item),
                    const SizedBox(height: 18),

                    Text(
                      _hasText(item.itemName)
                          ? item.itemName!
                          : 'Unnamed Item',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_hasText(item.itemType)) _buildTag(item.itemType!),
                        if (_hasText(item.category)) _buildTag(item.category!),
                        if (_hasText(item.style)) _buildTag(item.style!),
                        if (_hasText(item.mainColor)) _buildTag(item.mainColor!),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildTryOnButton(item),
                    const SizedBox(height: 12),
                    _buildConsultButton(),
                    const SizedBox(height: 32),

                    if (_hasText(item.description)) ...[
                      const Text(
                        'Description',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.description!,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const Text(
                      'Technical Specifications',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildInfoCard(item),

                    if (item.createdAt != null) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Added on: ${_formatDate(item.createdAt)}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildImageSlider(PublicItemDetailModel item) {
    if (item.imageUrls.isEmpty) {
      return Container(
        color: AppColors.surface,
        alignment: Alignment.center,
        child: const Icon(
          Icons.checkroom_outlined,
          size: 72,
          color: Colors.white38,
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: item.imageUrls.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return Image.network(
              item.imageUrls[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  color: AppColors.surface,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: Colors.white38,
                  ),
                );
              },
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: AppColors.surface,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                );
              },
            );
          },
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppColors.background,
              ],
            ),
          ),
        ),
        if (item.imageUrls.length > 1)
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                item.imageUrls.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index ? Colors.white : Colors.white38,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOwnerSection(PublicItemDetailModel item) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white12,
          backgroundImage: _hasText(item.ownerAvatarUrl)
              ? NetworkImage(item.ownerAvatarUrl!)
              : null,
          child: !_hasText(item.ownerAvatarUrl)
              ? const Icon(Icons.person, color: Colors.white70)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Owner',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _hasText(item.ownerUserName) ? item.ownerUserName! : 'User',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withOpacity(0.35)),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoCard(PublicItemDetailModel item) {
    final attributes = _buildAttributes(item);

    if (attributes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Text(
          'No detailed information available.',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 14,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: attributes.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Failed to load item details',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unexpected error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadItem,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        'Item data is empty.',
        style: TextStyle(color: Colors.black87),
      ),
    );
  }
}