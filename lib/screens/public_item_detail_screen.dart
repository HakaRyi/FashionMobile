import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../models/item_variant_model.dart';
import '../models/public_item_detail_model.dart';
import '../models/try_on_source_item.dart';
import '../services/item_service.dart';
import '../services/order_service.dart';
import '../utils/app_toast.dart';
import '../utils/route_transitions.dart';
import 'chat_screen.dart';
import 'try_on_screen.dart';
import 'package:provider/provider.dart';

import '../managers/item_manager.dart';
import '../models/wardrobe_item_model.dart';
import 'publish_item_for_sale_screen.dart';

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
  final ItemService _itemService = ItemService();
  final OrderService _orderService = OrderService();
  final PageController _pageController = PageController();

  bool _isLoading = true;
  bool _isCreatingOrder = false;
  bool _isConsulting = false;

  String? _error;
  PublicItemDetailModel? _item;
  ItemVariantModel? _selectedVariant;

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

    return DateFormat('dd/MM/yyyy').format(date);
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

      AppToast.show(context, _normalizeError(e));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildOwnerSaleAction(PublicItemDetailModel item) {
    if (!item.isForSale) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _openPublishItemForSaleScreen,
          icon: const Icon(Icons.sell_outlined),
          label: const Text(
            'Sell this item',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.textPink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.storefront_outlined,
                color: AppColors.textPink,
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'This item is currently for sale.',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
                color: AppColors.textPink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (_hasText(item.condition)) ...[
            const SizedBox(height: 4),
            Text(
              'Condition: ${item.condition}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
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
                'Unpublish item',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _isOwnItem {
    return widget.isOwnerView;
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

    final receiverNameController = TextEditingController();
    final receiverPhoneController = TextEditingController();
    final addressController = TextEditingController();
    final noteController = TextEditingController();

    int quantity = 1;
    bool isSubmitting = false;
    bool isSheetClosed = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final double subTotal = variant.price * quantity;
            const double serviceFee = 15000;
            final double totalAmount = subTotal + serviceFee;

            Future<void> submitOrder() async {
              final receiverName = receiverNameController.text.trim();
              final receiverPhone = receiverPhoneController.text.trim();
              final address = addressController.text.trim();
              final note = noteController.text.trim();

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

              if (quantity <= 0) {
                AppToast.show(context, 'Quantity must be greater than 0.');
                return;
              }

              if (quantity > variant.availableQuantity) {
                AppToast.show(context, 'Not enough stock.');
                return;
              }

              final buyerId = await _getCurrentUserId();

              if (buyerId == null || buyerId <= 0) {
                AppToast.show(
                  context,
                  'Cannot get current user. Please login again.',
                );
                return;
              }

              final int? sellerId = item.ownerId;

              if (sellerId == null || sellerId <= 0) {
                AppToast.show(context, 'Seller information is missing.');
                return;
              }

              if (buyerId == sellerId) {
                AppToast.show(context, 'You cannot buy your own item.');
                return;
              }

              if (isSheetClosed) {
                return;
              }

              setSheetState(() {
                isSubmitting = true;
              });

              if (mounted) {
                setState(() {
                  _isCreatingOrder = true;
                });
              }

              try {
                final body = {
                  'buyerId': buyerId,
                  'note': note.isEmpty ? null : note,
                  'receiverName': receiverName,
                  'receiverPhone': receiverPhone,
                  'shippingAddress': address,
                  'details': [
                    {
                      'itemVariantId': variant.itemVariantId,
                      'quantity': quantity,
                    }
                  ],
                };

                final order = await _orderService.createOrder(
                  sellerId,
                  body,
                );

                if (!mounted) {
                  return;
                }

                isSheetClosed = true;

                if (Navigator.canPop(sheetContext)) {
                  Navigator.pop(sheetContext);
                }

                await _loadItem();

                if (!mounted) {
                  return;
                }

                _showOrderCreatedDialog(order.orderId);
              } catch (e) {
                if (!mounted || isSheetClosed) {
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
                    _isCreatingOrder = false;
                  });
                }

                if (!isSheetClosed) {
                  setSheetState(() {
                    isSubmitting = false;
                  });
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
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
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Create Order',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildOrderItemPreview(item, variant),
                      const SizedBox(height: 16),
                      _buildQuantitySelector(
                        quantity: quantity,
                        maxQuantity: variant.availableQuantity,
                        onMinus: quantity <= 1
                            ? null
                            : () {
                          if (isSheetClosed) {
                            return;
                          }

                          setSheetState(() {
                            quantity--;
                          });
                        },
                        onPlus: quantity >= variant.availableQuantity
                            ? null
                            : () {
                          if (isSheetClosed) {
                            return;
                          }

                          setSheetState(() {
                            quantity++;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildBuyTextField(
                        controller: receiverNameController,
                        label: 'Receiver name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                      _buildBuyTextField(
                        controller: receiverPhoneController,
                        label: 'Receiver phone',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _buildBuyTextField(
                        controller: addressController,
                        label: 'Shipping address',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _buildBuyTextField(
                        controller: noteController,
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
                          onPressed: isSubmitting ? null : submitOrder,
                          icon: isSubmitting
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
                            isSubmitting ? 'Creating...' : 'Create Order',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
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
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showOrderCreatedDialog(int orderId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Order created',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Your order #$orderId has been created successfully. Please go to Order History to pay.',
            style: const TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                AppToast.show(
                  context,
                  'Open Order History and pay this order.',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPink,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
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
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.textPink,
        ),
      )
          : _error != null
          ? _buildError()
          : item == null
          ? _buildEmpty()
          : RefreshIndicator(
        onRefresh: _loadItem,
        color: AppColors.textPink,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 360,
              pinned: true,
              backgroundColor: AppColors.background,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                _hasText(item.itemName)
                    ? item.itemName!
                    : 'Item Details',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _buildImageSlider(item),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                const EdgeInsets.fromLTRB(16, 18, 16, 32),
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
                        if (_hasText(item.itemType))
                          _buildTag(item.itemType!),
                        if (_hasText(item.category))
                          _buildTag(item.category!),
                        if (_hasText(item.style))
                          _buildTag(item.style!),
                        if (_hasText(item.mainColor))
                          _buildTag(item.mainColor!),
                        if (item.isForSale) _buildSaleTag(),
                      ],
                    ),
                    if (_isOwnItem) ...[
                      const SizedBox(height: 16),
                      _buildOwnerNotice(),
                      const SizedBox(height: 12),
                      _buildOwnerSaleAction(item),
                    ],
                    if (item.isForSale && !_isOwnItem) ...[
                      const SizedBox(height: 20),
                      _buildCommerceSection(item),
                      const SizedBox(height: 24),
                    ],
                    _buildTryOnButton(item),
                    if (!_isOwnItem) ...[
                      const SizedBox(height: 12),
                      _buildConsultButton(),
                    ],
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
            ),
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
                if (progress == null) {
                  return child;
                }

                return Container(
                  color: AppColors.surface,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(
                    color: AppColors.textPink,
                  ),
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
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white38,
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
              ? const Icon(
            Icons.person,
            color: Colors.white70,
          )
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

  Widget _buildOwnerNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.textPink,
            size: 22,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This is your own item. Buying and consultation actions are disabled.',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
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
            color: AppColors.textPink,
          ),
        )
            : Icon(
          isCooldown ? Icons.timer_outlined : Icons.chat_bubble_outline,
          size: 20,
        ),
        label: Text(
          isCooldown
              ? 'Resend in (${_cooldownSeconds}s)'
              : 'Get styling advice',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPink,
          side: const BorderSide(
            color: AppColors.textPink,
            width: 1.5,
          ),
          disabledForegroundColor: Colors.white24,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildCommerceSection(PublicItemDetailModel item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available for purchase',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (item.listedPrice != null)
            Text(
              _formatPrice(item.listedPrice),
              style: const TextStyle(
                color: AppColors.textPink,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (_hasText(item.condition)) ...[
            const SizedBox(height: 8),
            Text(
              'Condition: ${item.condition}',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (item.variants.isEmpty)
            const Text(
              'No variants available.',
              style: TextStyle(color: AppColors.text),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.textPink.withOpacity(0.18)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                        isSelected ? AppColors.textPink : AppColors.divider,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          variant.sizeCode ?? 'Default',
                          style: TextStyle(
                            color:
                            isOutOfStock ? Colors.white38 : AppColors.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatPrice(variant.price),
                          style: TextStyle(
                            color: isOutOfStock
                                ? Colors.white38
                                : AppColors.textPink,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOutOfStock
                              ? 'Out of stock'
                              : 'Stock: ${variant.availableQuantity}',
                          style: TextStyle(
                            color:
                            isOutOfStock ? Colors.white38 : Colors.white70,
                            fontSize: 11,
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
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
                'Buy this item',
                style: TextStyle(fontWeight: FontWeight.bold),
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
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl == null || imageUrl.trim().isEmpty
                ? Container(
              width: 72,
              height: 72,
              color: AppColors.surface,
              child: const Icon(
                Icons.checkroom_outlined,
                color: Colors.white38,
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
                  color: AppColors.surface,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white38,
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
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Variant: ${variant.sizeCode ?? 'Default'}'
                      '${variant.color != null ? ' - ${variant.color}' : ''}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatPrice(variant.price),
                  style: const TextStyle(
                    color: AppColors.textPink,
                    fontWeight: FontWeight.bold,
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
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Quantity\nAvailable: $maxQuantity',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onMinus,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.textPink,
            disabledColor: Colors.white24,
          ),
          Text(
            '$quantity',
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          IconButton(
            onPressed: onPlus,
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.textPink,
            disabledColor: Colors.white24,
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
      style: const TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: AppColors.textPink),
        filled: true,
        fillColor: AppColors.backgroundSecondary,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.textPink),
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
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _buildPriceRow('Subtotal', subTotal),
          const SizedBox(height: 8),
          _buildPriceRow('Service fee', serviceFee),
          const Divider(color: AppColors.divider, height: 22),
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
              color: isTotal ? AppColors.text : Colors.white70,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          _formatPrice(value),
          style: TextStyle(
            color: isTotal ? AppColors.textPink : AppColors.text,
            fontSize: isTotal ? 17 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
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

  Widget _buildSaleTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.textPink.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.textPink),
      ),
      child: const Text(
        'For Sale',
        style: TextStyle(
          color: AppColors.textPink,
          fontSize: 12,
          fontWeight: FontWeight.bold,
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
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Failed to load item details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unexpected error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPink,
                foregroundColor: Colors.white,
              ),
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
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}