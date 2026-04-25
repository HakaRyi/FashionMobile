import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';

class StoreItemModel {
  final int id;
  final String imageUrl;
  final String name;
  final double price;
  final double aspectRatio;

  StoreItemModel({
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.price,
    required this.aspectRatio,
  });
}

class UserStorefrontScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const UserStorefrontScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserStorefrontScreen> createState() => _UserStorefrontScreenState();
}

class _UserStorefrontScreenState extends State<UserStorefrontScreen>
    with TickerProviderStateMixin {
  late AnimationController _cloudAnimationController;

  final List<StoreItemModel> _mockItems = [
    StoreItemModel(
        id: 1,
        imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=1000',
        name: 'Noir Avant-Garde Dress',
        price: 299.0,
        aspectRatio: 0.7),
    StoreItemModel(
        id: 2,
        imageUrl: 'https://images.unsplash.com/photo-1581044777550-4cfa60707c03?q=80&w=1000',
        name: 'Minimalist Structure Coat',
        price: 450.0,
        aspectRatio: 1.0),
    StoreItemModel(
        id: 3,
        imageUrl: 'https://images.unsplash.com/photo-1576185040190-b9a0397a99a9?q=80&w=1000',
        name: 'Abstract Monochrome Knit',
        price: 180.0,
        aspectRatio: 0.65),
    StoreItemModel(
        id: 4,
        imageUrl: 'https://images.unsplash.com/photo-1596704017254-9b121068fb31?q=80&w=1000',
        name: 'Shadow Pleated Skirt',
        price: 220.0,
        aspectRatio: 0.8),
    StoreItemModel(
        id: 5,
        imageUrl: 'https://images.unsplash.com/photo-1539109136881-3be0616cbd4b?q=80&w=1000',
        name: 'Urban Linear Jacket',
        price: 380.0,
        aspectRatio: 0.75),
    StoreItemModel(
        id: 6,
        imageUrl: 'https://images.unsplash.com/photo-1554520735-096073b09228?q=80&w=1000',
        name: 'Geometric Void Tote',
        price: 150.0,
        aspectRatio: 1.1),
  ];

  @override
  void initState() {
    super.initState();
    _cloudAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _cloudAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const serifTitleStyle = TextStyle(
      fontFamily: 'Playfair Display',
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      fontSize: 60,
      color: Colors.black,
      letterSpacing: -2,
      height: 0.9,
    );

    const sansTitleStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: Colors.black26,
      letterSpacing: 2,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _cloudAnimationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: CloudBackgroundPainter(_cloudAnimationController.value),
                );
              },
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.black),
                      onPressed: () {},
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 0, 40),
                    child: Stack(
                      children: [
                        const Positioned(
                          top: 0,
                          left: 5,
                          child: Text(
                            "THE COLLECTION OF",
                            style: sansTitleStyle,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Transform.translate(
                            offset: const Offset(-15, 0),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "${widget.userName.toUpperCase()}'S\n",
                                    style: serifTitleStyle,
                                  ),
                                  const TextSpan(
                                    text: "BOUTIQUE",
                                    style: serifTitleStyle,
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.visible,
                              softWrap: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    itemBuilder: (context, index) {
                      final item = _mockItems[index];
                      return StoreItemCard(item: item);
                    },
                    childCount: _mockItems.length,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CloudBackgroundPainter extends CustomPainter {
  final double progress;

  CloudBackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

    void drawCloud(double startX, double startY, double scale) {
      final x = startX - (progress * size.width * 1.5 * scale) % (size.width * 2) + size.width * 0.5;
      canvas.drawCircle(Offset(x, startY), 100 * scale, paint);
      canvas.drawCircle(Offset(x + 80 * scale, startY + 30 * scale), 70 * scale, paint);
      canvas.drawCircle(Offset(x - 70 * scale, startY + 40 * scale), 60 * scale, paint);
    }

    drawCloud(size.width * 0.2, size.height * 0.1, 1.2);
    drawCloud(size.width * 0.8, size.height * 0.4, 0.8);
    drawCloud(size.width * 0.5, size.height * 0.7, 1.5);
    drawCloud(size.width * 1.2, size.height * 0.9, 1.0);
  }

  @override
  bool shouldRepaint(covariant CloudBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class StoreItemCard extends StatelessWidget {
  final StoreItemModel item;

  const StoreItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: item.aspectRatio,
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0, 0, 0, 1, 0,
              ]),
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Shimmer.fromColors(
                    baseColor: const Color(0xFFE0E0E0),
                    highlightColor: const Color(0xFFF5F5F5),
                    child: Container(color: Colors.white),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(width: 20, height: 1, color: Colors.black12),
                const SizedBox(height: 8),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: const Text(
                            'BUY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: const BorderSide(color: Colors.black12),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: const BorderSide(color: Colors.black12),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}