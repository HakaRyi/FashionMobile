import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../managers/item_manager.dart';
import '../models/item_variant_model.dart';
import '../models/order_model.dart';
import '../models/public_item_detail_model.dart';
import '../models/try_on_source_item.dart';
import '../models/wardrobe_item_model.dart';
import '../services/item_service.dart';
import '../services/order_service.dart';
import '../utils/app_toast.dart';
import '../utils/route_transitions.dart';
import 'chat_screen.dart';
import 'manage_item_variants_screen.dart';
import 'publish_item_for_sale_screen.dart';
import 'try_on_screen.dart';
import 'order_detail_screen.dart';

class PublicItemDetailScreen extends StatefulWidget {
  final int itemId;
  final bool isOwnerView;

  const PublicItemDetailScreen({
    super.key,
    required this.itemId,
    this.isOwnerView = false,
  });

  @override
  State<PublicItemDetailScreen> createState() => _PublicItemDetailScreenState();
}

class _PublicItemDetailScreenState extends State<PublicItemDetailScreen> {
  static const Color _pageBackground = Color(0xFFFAF8F5);
  static const Color _cardBackground = Colors.white;
  static const Color _softBackground = Color(0xFFF4F1ED);
  static const Color _warmAccent = Color(0xFFEDE4D8);
  static const Color _darkText = Color(0xFF111111);
  static const Color _mutedText = Color(0xFF6F6A64);
  static const Color _borderColor = Color(0xFFE8E1D8);

  final ItemService _itemService = ItemService();
  final OrderService _orderService = OrderService();
  final PageController _pageController = PageController();

  bool _isLoading = true;
  bool _isCreatingOrder = false;
  bool _isConsulting = false;
  bool _isLoadingOwnerVariants = false;

  String? _error;
  PublicItemDetailModel? _item;
  ItemVariantModel? _selectedVariant;
  List<ItemVariantModel> _ownerVariants = [];

  int _currentImageIndex = 0;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

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

  Future<void> _loadItem() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final result = await _itemService.getPublicItemDetail(widget.itemId);

      if (!mounted) {
        return;
      }

      ItemVariantModel? initialVariant;

      if (result.variants.isNotEmpty) {
        try {
          initialVariant = result.variants.firstWhere(
                (variant) => variant.availableQuantity > 0,
          );
        } catch (_) {
          initialVariant = result.variants.first;
        }
      }

      setState(() {
        _item = result;
        _selectedVariant = initialVariant;
      });

      if (_isOwnItem) {
        await _loadOwnerVariants();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _normalizeError(e);
      });
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOwnerVariants() async {
    final item = _item;

    if (item == null || !_isOwnItem) {
      return;
    }

    try {
      setState(() {
        _isLoadingOwnerVariants = true;
      });

      final variants = await _itemService.getItemVariants(item.itemId);

      if (!mounted) {
        return;
      }

      setState(() {
        _ownerVariants = variants;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _ownerVariants = [];
      });
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingOwnerVariants = false;
      });
    }
  }

  bool get _isOwnItem {
    return widget.isOwnerView;
  }

  bool get _canPublishAgain {
    return _ownerVariants.any((variant) {
      return variant.status == 1 &&
          variant.availableQuantity > 0 &&
          variant.price > 0;
    });
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  String _normalizeError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '').trim();
    }

    return text;
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    return DateFormat('dd/MM/yyyy').format(date.toLocal());
  }

  String _formatPrice(double? value) {
    if (value == null) {
      return '';
    }

    final formatter = NumberFormat('#,##0', 'en_US');
    return '${formatter.format(value)} VND';
  }

  WardrobeItemModel _mapPublicItemToWardrobeItem(PublicItemDetailModel item) {
    return WardrobeItemModel(
      itemId: item.itemId,
      itemName: item.itemName ?? 'Unnamed Item',
      description: item.description,
      mainColor: item.mainColor,
      brand: item.brand,
      status: null,
      imageUrl: item.firstImageUrl,
      size: item.size,
      isSaved: false,
      isOwner: true,
      category: item.category,
      isForSale: item.isForSale,
      listedPrice: item.listedPrice,
      condition: item.condition,
    );
  }

  Future<void> _openPublishItemForSaleScreen() async {
    final item = _item;

    if (item == null) {
      return;
    }

    if (!_isOwnItem) {
      AppToast.show(context, 'Only the owner can publish this item for sale.');
      return;
    }

    final wardrobeItem = _mapPublicItemToWardrobeItem(item);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ItemManager(),
          child: PublishItemForSaleScreen(
            item: wardrobeItem,
          ),
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      await _loadItem();
    }
  }

  Future<void> _openManageVariantsScreen() async {
    final item = _item;

    if (item == null) {
      return;
    }

    if (!_isOwnItem) {
      AppToast.show(context, 'Only the owner can manage variants.');
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ItemManager(),
          child: ManageItemVariantsScreen(
            itemId: item.itemId,
            itemName: item.itemName ?? 'Unnamed Item',
          ),
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      await _loadItem();
    }
  }

  Future<void> _publishAgainItem() async {
    final item = _item;

    if (item == null) {
      return;
    }

    if (!_isOwnItem) {
      AppToast.show(context, 'Only the owner can publish this item.');
      return;
    }

    final sellableVariants = _ownerVariants
        .where(
          (variant) =>
      variant.status == 1 &&
          variant.availableQuantity > 0 &&
          variant.price > 0,
    )
        .toList();

    if (sellableVariants.isEmpty) {
      AppToast.show(
        context,
        'Please add at least one active variant with available stock before publishing.',
        isError: true,
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final lowestPrice = sellableVariants
          .map((variant) => variant.price)
          .reduce((a, b) => a < b ? a : b);

      await _itemService.publishItem(
        itemId: item.itemId,
        listedPrice: lowestPrice,
        condition: item.condition ?? 'Used - Good',
        variants: const [],
      );

      if (!mounted) {
        return;
      }

      AppToast.show(context, 'Item has been published again.');
      await _loadItem();
    } catch (e) {
      if (!mounted) {
        return;
      }

      AppToast.show(
        context,
        _normalizeError(e),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unpublishItem() async {
    final item = _item;

    if (item == null) {
      return;
    }

    if (!_isOwnItem) {
      AppToast.show(context, 'Only the owner can unpublish this item.');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await _itemService.unpublishItem(item.itemId);

      if (!mounted) {
        return;
      }

      AppToast.show(context, 'Item has been unpublished.');
      await _loadItem();
    } catch (e) {
      if (!mounted) {
        return;
      }

      AppToast.show(
        context,
        _normalizeError(e),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteItem() async {
    final item = _item;

    if (item == null) {
      return;
    }

    if (!_isOwnItem) {
      AppToast.show(context, 'Only the owner can delete this item.');
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Delete item?',
            style: TextStyle(
              color: _darkText,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'This item will be removed from your wardrobe. You cannot delete it if it has reserved variants or active orders.',
            style: TextStyle(
              color: _mutedText,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: Colors.black38,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'DELETE',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await _itemService.deleteItem(item.itemId);

      if (!mounted) {
        return;
      }

      AppToast.show(context, 'Item has been deleted.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      AppToast.show(
        context,
        _normalizeError(e),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<int?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();

    final rawId = prefs.getString('userId') ??
        prefs.getString('accountId') ??
        prefs.getString('id') ??
        prefs.getString('currentUserId');

    if (rawId == null) {
      return null;
    }

    return int.tryParse(rawId);
  }

  Future<void> _handleConsult() async {
    if (_item == null) {
      return;
    }

    if (_isOwnItem) {
      AppToast.show(context, 'You cannot request advice from yourself.');
      return;
    }

    setState(() {
      _isConsulting = true;
    });

    try {
      final groupId = await _itemService.sendConsultRequest(widget.itemId);

      if (!mounted) {
        return;
      }

      if (groupId != null) {
        _startCooldown();

        Navigator.push(
          context,
          SlideRoute(
            page: ChatScreen(
              groupId: groupId,
              userName: _item!.ownerUserName ?? 'Owner',
              avatarUrl: _item!.ownerAvatarUrl ?? '',
              isOnline: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_normalizeError(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConsulting = false;
        });
      }
    }
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 5;
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_cooldownSeconds <= 1) {
          setState(() {
            _cooldownSeconds = 0;
          });
          timer.cancel();
        } else {
          setState(() {
            _cooldownSeconds--;
          });
        }
      },
    );
  }

  Future<void> _openBuySheet() async {
    final item = _item;
    final variant = _selectedVariant;

    if (_isOwnItem) {
      AppToast.show(context, 'You cannot buy your own item.');
      return;
    }

    if (item == null) {
      return;
    }

    if (variant == null) {
      AppToast.show(context, 'Please select a variant.');
      return;
    }

    if (variant.availableQuantity <= 0) {
      AppToast.show(context, 'This variant is out of stock.');
      return;
    }

    final OrderModel? order = await showModalBottomSheet<OrderModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateOrderSheet(
        item: item,
        variant: variant,
        orderService: _orderService,
        getCurrentUserId: _getCurrentUserId,
        normalizeError: _normalizeError,
      ),
    );

    if (!mounted || order == null) {
      return;
    }

    await _loadItem();

    if (!mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: order.orderId,
          isPurchase: true,
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final item = _item;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.black,
        ),
      )
          : _error != null
          ? _buildError()
          : item == null
          ? _buildEmpty()
          : RefreshIndicator(
        onRefresh: _loadItem,
        color: Colors.black,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              expandedHeight: 390,
              pinned: true,
              backgroundColor: _pageBackground,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                _hasText(item.itemName)
                    ? item.itemName!.toUpperCase()
                    : 'ITEM DETAILS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Colors.black,
                  letterSpacing: 0.4,
                ),
              ),
              centerTitle: true,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildImageSlider(item),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMainInfoCard(item),
                    const SizedBox(height: 14),
                    if (_isOwnItem) ...[
                      _buildOwnerNotice(),
                      const SizedBox(height: 14),
                      _buildOwnerSaleAction(item),
                      const SizedBox(height: 14),
                    ],
                    if (item.isForSale && !_isOwnItem) ...[
                      _buildCommerceSection(item),
                      const SizedBox(height: 14),
                    ],
                    _buildTryOnButton(item),
                    if (!_isOwnItem) ...[
                      const SizedBox(height: 12),
                      _buildConsultButton(),
                    ],
                    if (_hasText(item.description)) ...[
                      const SizedBox(height: 18),
                      _buildDescriptionCard(item),
                    ],
                    const SizedBox(height: 18),
                    _buildInfoCard(item),
                    if (item.createdAt != null) ...[
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          'Added on ${_formatDate(item.createdAt)}',
                          style: const TextStyle(
                            color: Colors.black38,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSlider(PublicItemDetailModel item) {
    if (item.imageUrls.isEmpty) {
      return Container(
        color: _softBackground,
        alignment: Alignment.center,
        child: const Icon(
          Icons.checkroom_outlined,
          size: 72,
          color: Colors.black26,
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
                  color: _softBackground,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: Colors.black26,
                  ),
                );
              },
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }

                return Container(
                  color: _softBackground,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(
                    color: Colors.black,
                  ),
                );
              },
            );
          },
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.18),
                _pageBackground,
              ],
            ),
          ),
        ),
        if (item.imageUrls.length > 1)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                item.imageUrls.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? Colors.black
                        : Colors.black26,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMainInfoCard(PublicItemDetailModel item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOwnerSection(item),
          const SizedBox(height: 18),
          Text(
            _hasText(item.itemName) ? item.itemName! : 'Unnamed Item',
            style: const TextStyle(
              color: _darkText,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_hasText(item.itemType)) _buildTag(item.itemType!),
              if (_hasText(item.category)) _buildTag(item.category!),
              if (_hasText(item.style)) _buildTag(item.style!),
              if (_hasText(item.mainColor)) _buildTag(item.mainColor!),
              if (item.isForSale) _buildSaleTag(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerSection(PublicItemDetailModel item) {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: _softBackground,
          backgroundImage:
          _hasText(item.ownerAvatarUrl) ? NetworkImage(item.ownerAvatarUrl!) : null,
          child: !_hasText(item.ownerAvatarUrl)
              ? const Icon(
            Icons.person,
            color: Colors.black26,
          )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'OWNER',
                style: TextStyle(
                  color: Colors.black38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _hasText(item.ownerUserName) ? item.ownerUserName! : 'User',
                style: const TextStyle(
                  color: _darkText,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.black,
            size: 22,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This is your own item. Buying and consultation actions are disabled.',
              style: TextStyle(
                color: _mutedText,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerSaleAction(PublicItemDetailModel item) {
    if (!item.isForSale) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.storefront_outlined,
                  color: Colors.black,
                  size: 22,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Owner actions',
                    style: TextStyle(
                      color: _darkText,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoadingOwnerVariants)
              _buildCheckingVariantsButton()
            else if (_canPublishAgain)
              _buildPublishAgainButton()
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openPublishItemForSaleScreen,
                  icon: const Icon(Icons.sell_outlined),
                  label: const Text(
                    'SELL THIS ITEM',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  style: _primaryButtonStyle(),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              _canPublishAgain
                  ? 'This item already has active variants and can be published again.'
                  : 'Create variants first if this item has not been sold before.',
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _buildManageVariantsButton(),
            const SizedBox(height: 10),
            _buildDeleteItemButton(),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.storefront_outlined,
                color: Colors.black,
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'This item is currently for sale.',
                  style: TextStyle(
                    color: _darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (item.listedPrice != null)
            Text(
              'Listed price: ${_formatPrice(item.listedPrice)}',
              style: const TextStyle(
                color: _darkText,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          if (_hasText(item.condition)) ...[
            const SizedBox(height: 4),
            Text(
              'Condition: ${item.condition}',
              style: const TextStyle(
                color: _mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _unpublishItem,
              icon: const Icon(Icons.visibility_off_outlined),
              label: const Text(
                'UNPUBLISH ITEM',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildManageVariantsButton(),
          const SizedBox(height: 10),
          _buildDeleteItemButton(),
        ],
      ),
    );
  }

  Widget _buildCheckingVariantsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
        label: const Text(
          'CHECKING VARIANTS...',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        style: _primaryButtonStyle(),
      ),
    );
  }

  Widget _buildPublishAgainButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _publishAgainItem,
        icon: const Icon(Icons.storefront_outlined),
        label: const Text(
          'PUBLISH AGAIN',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        style: _primaryButtonStyle(),
      ),
    );
  }

  Widget _buildManageVariantsButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _openManageVariantsScreen,
        icon: const Icon(Icons.category_outlined),
        label: const Text(
          'MANAGE VARIANTS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(
            color: Colors.black,
            width: 1.1,
          ),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteItemButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _deleteItem,
        icon: const Icon(Icons.delete_outline),
        label: const Text(
          'DELETE ITEM',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(
            color: Colors.redAccent,
            width: 1.1,
          ),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
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
          'TRY-ON THIS ITEM',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        style: _primaryButtonStyle(),
      ),
    );
  }

  Widget _buildConsultButton() {
    final bool isCooldown = _cooldownSeconds > 0;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: (_isConsulting || isCooldown) ? null : _handleConsult,
        icon: _isConsulting
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.black,
          ),
        )
            : Icon(
          isCooldown ? Icons.timer_outlined : Icons.chat_bubble_outline,
          size: 20,
        ),
        label: Text(
          isCooldown
              ? 'RESEND IN (${_cooldownSeconds}S)'
              : 'GET STYLING ADVICE',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(
            color: Colors.black,
            width: 1.2,
          ),
          disabledForegroundColor: Colors.black26,
          backgroundColor: _cardBackground,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildCommerceSection(PublicItemDetailModel item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('AVAILABLE FOR PURCHASE', Icons.shopping_bag_outlined),
          const SizedBox(height: 12),
          if (item.listedPrice != null)
            Text(
              _formatPrice(item.listedPrice),
              style: const TextStyle(
                color: _darkText,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          if (_hasText(item.condition)) ...[
            const SizedBox(height: 8),
            Text(
              'Condition: ${item.condition}',
              style: const TextStyle(
                color: _mutedText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (item.variants.isEmpty)
            const Text(
              'No variants available.',
              style: TextStyle(
                color: _mutedText,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.variants.map((variant) {
                final bool isSelected =
                    _selectedVariant?.itemVariantId == variant.itemVariantId;
                final bool isOutOfStock = variant.availableQuantity <= 0;

                return GestureDetector(
                  onTap: isOutOfStock
                      ? null
                      : () {
                    setState(() {
                      _selectedVariant = variant;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : _softBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? Colors.black : _borderColor,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          variant.sizeCode ?? 'Default',
                          style: TextStyle(
                            color: isOutOfStock
                                ? Colors.black26
                                : isSelected
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (_hasText(variant.color)) ...[
                          const SizedBox(height: 3),
                          Text(
                            variant.color!,
                            style: TextStyle(
                              color: isOutOfStock
                                  ? Colors.black26
                                  : isSelected
                                  ? Colors.white70
                                  : _mutedText,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          _formatPrice(variant.price),
                          style: TextStyle(
                            color: isOutOfStock
                                ? Colors.black26
                                : isSelected
                                ? Colors.white70
                                : _mutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOutOfStock
                              ? 'Out of stock'
                              : 'Stock: ${variant.availableQuantity}',
                          style: TextStyle(
                            color: isOutOfStock
                                ? Colors.black26
                                : isSelected
                                ? Colors.white70
                                : Colors.black45,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          if (_selectedVariant != null) ...[
            const SizedBox(height: 16),
            Text(
              'Selected: ${_selectedVariant!.sizeCode ?? 'Default'}'
                  '${_selectedVariant!.color != null ? ' - ${_selectedVariant!.color}' : ''}',
              style: const TextStyle(
                color: _darkText,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedVariant == null ||
                  _selectedVariant!.availableQuantity <= 0 ||
                  _isCreatingOrder)
                  ? null
                  : _openBuySheet,
              style: _primaryButtonStyle(),
              child: _isCreatingOrder
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'BUY THIS ITEM',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemPreview(
      PublicItemDetailModel item,
      ItemVariantModel variant,
      ) {
    final imageUrl = item.imageUrls.isNotEmpty ? item.imageUrls.first : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _softCardDecoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl == null || imageUrl.trim().isEmpty
                ? Container(
              width: 72,
              height: 72,
              color: _softBackground,
              child: const Icon(
                Icons.checkroom_outlined,
                color: Colors.black26,
              ),
            )
                : Image.network(
              imageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  width: 72,
                  height: 72,
                  color: _softBackground,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.black26,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName ?? 'Unnamed Item',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _darkText,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Variant: ${variant.sizeCode ?? 'Default'}'
                      '${variant.color != null ? ' - ${variant.color}' : ''}',
                  style: const TextStyle(
                    color: _mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatPrice(variant.price),
                  style: const TextStyle(
                    color: _darkText,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector({
    required int quantity,
    required int maxQuantity,
    required VoidCallback? onMinus,
    required VoidCallback? onPlus,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _softCardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Quantity\nAvailable: $maxQuantity',
              style: const TextStyle(
                color: _darkText,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onMinus,
            icon: const Icon(Icons.remove_circle_outline),
            color: Colors.black,
            disabledColor: Colors.black26,
          ),
          Text(
            '$quantity',
            style: const TextStyle(
              color: _darkText,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          IconButton(
            onPressed: onPlus,
            icon: const Icon(Icons.add_circle_outline),
            color: Colors.black,
            disabledColor: Colors.black26,
          ),
        ],
      ),
    );
  }

  Widget _buildBuyTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        color: _darkText,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.black45,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.black,
        ),
        filled: true,
        fillColor: _softBackground,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: _borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSummary({
    required double subTotal,
    required double serviceFee,
    required double totalAmount,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _softCardDecoration(),
      child: Column(
        children: [
          _buildPriceRow('Subtotal', subTotal),
          const SizedBox(height: 8),
          _buildPriceRow('Service fee', serviceFee),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              color: _borderColor,
              height: 1,
            ),
          ),
          _buildPriceRow('Total', totalAmount, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
      String label,
      double value, {
        bool isTotal = false,
      }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal ? _darkText : _mutedText,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          _formatPrice(value),
          style: TextStyle(
            color: _darkText,
            fontSize: isTotal ? 17 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _warmAccent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: _darkText,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildSaleTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Text(
        'FOR SALE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(PublicItemDetailModel item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('DESCRIPTION', Icons.notes_rounded),
          const SizedBox(height: 12),
          Text(
            item.description!,
            style: const TextStyle(
              color: _mutedText,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(PublicItemDetailModel item) {
    final attributes = _buildAttributes(item);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'TECHNICAL SPECIFICATIONS',
            Icons.tune_rounded,
          ),
          const SizedBox(height: 12),
          if (attributes.isEmpty)
            const Text(
              'No detailed information available.',
              style: TextStyle(
                color: _mutedText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...attributes.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 118,
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          color: _darkText,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.black,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Failed to load item details',
                style: TextStyle(
                  color: _darkText,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'An unexpected error occurred',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _mutedText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loadItem,
                  style: _primaryButtonStyle(),
                  child: const Text(
                    'TRY AGAIN',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        'Item data is empty.',
        style: TextStyle(
          color: _mutedText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _softBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _borderColor,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.black,
            size: 17,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _darkText,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFFE6E1DA),
      disabledForegroundColor: Colors.black38,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _cardBackground,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: _borderColor,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.055),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  BoxDecoration _softCardDecoration() {
    return BoxDecoration(
      color: _softBackground,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: _borderColor,
      ),
    );
  }
}

class _CreateOrderSheet extends StatefulWidget {
  final PublicItemDetailModel item;
  final ItemVariantModel variant;
  final OrderService orderService;
  final Future<int?> Function() getCurrentUserId;
  final String Function(Object error) normalizeError;

  const _CreateOrderSheet({
    required this.item,
    required this.variant,
    required this.orderService,
    required this.getCurrentUserId,
    required this.normalizeError,
  });

  @override
  State<_CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends State<_CreateOrderSheet> {
  static const Color _cardBackground = Colors.white;
  static const Color _softBackground = Color(0xFFF4F1ED);
  static const Color _darkText = Color(0xFF111111);
  static const Color _mutedText = Color(0xFF6F6A64);
  static const Color _borderColor = Color(0xFFE8E1D8);

  final TextEditingController _receiverNameController =
  TextEditingController();
  final TextEditingController _receiverPhoneController =
  TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  int _quantity = 1;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatPrice(double? value) {
    if (value == null) {
      return '';
    }

    final formatter = NumberFormat('#,##0', 'en_US');
    return '${formatter.format(value)} VND';
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  Future<void> _submitOrder() async {
    final receiverName = _receiverNameController.text.trim();
    final receiverPhone = _receiverPhoneController.text.trim();
    final address = _addressController.text.trim();
    final note = _noteController.text.trim();

    if (receiverName.isEmpty) {
      AppToast.show(context, 'Please enter receiver name.');
      return;
    }

    if (receiverName.length < 2) {
      AppToast.show(context, 'Receiver name is too short.');
      return;
    }

    if (receiverPhone.isEmpty) {
      AppToast.show(context, 'Please enter receiver phone.');
      return;
    }

    if (!RegExp(r'^\d+$').hasMatch(receiverPhone)) {
      AppToast.show(context, 'Phone number must contain digits only.');
      return;
    }

    if (!RegExp(r'^(0\d{9,10})$').hasMatch(receiverPhone)) {
      AppToast.show(context, 'Invalid phone number.');
      return;
    }

    if (address.isEmpty) {
      AppToast.show(context, 'Please enter shipping address.');
      return;
    }

    if (address.length < 5) {
      AppToast.show(context, 'Shipping address is too short.');
      return;
    }

    if (_quantity <= 0) {
      AppToast.show(context, 'Quantity must be greater than 0.');
      return;
    }

    if (_quantity > widget.variant.availableQuantity) {
      AppToast.show(context, 'Not enough stock.');
      return;
    }

    final buyerId = await widget.getCurrentUserId();

    if (!mounted) {
      return;
    }

    if (buyerId == null || buyerId <= 0) {
      AppToast.show(context, 'Cannot get current user. Please login again.');
      return;
    }

    final int? sellerId = widget.item.ownerId;

    if (sellerId == null || sellerId <= 0) {
      AppToast.show(context, 'Seller information is missing.');
      return;
    }

    if (buyerId == sellerId) {
      AppToast.show(context, 'You cannot buy your own item.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final body = {
        'buyerId': buyerId,
        'note': note.isEmpty ? null : note,
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'shippingAddress': address,
        'details': [
          {
            'itemVariantId': widget.variant.itemVariantId,
            'quantity': _quantity,
          }
        ],
      };

      final order = await widget.orderService.createOrder(
        sellerId,
        body,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, order);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.normalizeError(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double subTotal = widget.variant.price * _quantity;
    const double serviceFee = 15000;
    final double totalAmount = subTotal + serviceFee;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        decoration: const BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'CREATE ORDER',
                style: TextStyle(
                  color: _darkText,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 14),
              _buildOrderItemPreview(),
              const SizedBox(height: 16),
              _buildQuantitySelector(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _receiverNameController,
                label: 'Receiver name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _receiverPhoneController,
                label: 'Receiver phone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _addressController,
                label: 'Shipping address',
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _noteController,
                label: 'Note',
                icon: Icons.note_alt_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildPriceSummary(
                subTotal: subTotal,
                serviceFee: serviceFee,
                totalAmount: totalAmount,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  icon: _isSubmitting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.shopping_bag_outlined),
                  label: Text(
                    _isSubmitting ? 'CREATING...' : 'CREATE ORDER',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  style: _primaryButtonStyle(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItemPreview() {
    final imageUrl =
    widget.item.imageUrls.isNotEmpty ? widget.item.imageUrls.first : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _softCardDecoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl == null || imageUrl.trim().isEmpty
                ? Container(
              width: 72,
              height: 72,
              color: _softBackground,
              child: const Icon(
                Icons.checkroom_outlined,
                color: Colors.black26,
              ),
            )
                : Image.network(
              imageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  width: 72,
                  height: 72,
                  color: _softBackground,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.black26,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.itemName ?? 'Unnamed Item',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _darkText,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Variant: ${widget.variant.sizeCode ?? 'Default'}'
                      '${_hasText(widget.variant.color) ? ' - ${widget.variant.color}' : ''}',
                  style: const TextStyle(
                    color: _mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatPrice(widget.variant.price),
                  style: const TextStyle(
                    color: _darkText,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _softCardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Quantity\nAvailable: ${widget.variant.availableQuantity}',
              style: const TextStyle(
                color: _darkText,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: _quantity <= 1
                ? null
                : () {
              setState(() {
                _quantity--;
              });
            },
            icon: const Icon(Icons.remove_circle_outline),
            color: Colors.black,
            disabledColor: Colors.black26,
          ),
          Text(
            '$_quantity',
            style: const TextStyle(
              color: _darkText,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          IconButton(
            onPressed: _quantity >= widget.variant.availableQuantity
                ? null
                : () {
              setState(() {
                _quantity++;
              });
            },
            icon: const Icon(Icons.add_circle_outline),
            color: Colors.black,
            disabledColor: Colors.black26,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        color: _darkText,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.black45,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.black,
        ),
        filled: true,
        fillColor: _softBackground,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: _borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSummary({
    required double subTotal,
    required double serviceFee,
    required double totalAmount,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _softCardDecoration(),
      child: Column(
        children: [
          _buildPriceRow('Subtotal', subTotal),
          const SizedBox(height: 8),
          _buildPriceRow('Service fee', serviceFee),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              color: _borderColor,
              height: 1,
            ),
          ),
          _buildPriceRow('Total', totalAmount, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
      String label,
      double value, {
        bool isTotal = false,
      }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal ? _darkText : _mutedText,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          _formatPrice(value),
          style: TextStyle(
            color: _darkText,
            fontSize: isTotal ? 17 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFFE6E1DA),
      disabledForegroundColor: Colors.black38,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  BoxDecoration _softCardDecoration() {
    return BoxDecoration(
      color: _softBackground,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: _borderColor,
      ),
    );
  }
}