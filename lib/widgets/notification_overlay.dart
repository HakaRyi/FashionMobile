import 'package:flutter/material.dart';

import '../models/order_model.dart';
import 'package:fashion_mobile/screens/order_detail_screen.dart';

class NotificationOverlay {
  static void showNewOrderNotification(
      BuildContext context,
      OrderModel order, {
        bool isPurchase = true,
      }) {
    late OverlayEntry overlayEntry;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              if (overlayEntry.mounted) {
                overlayEntry.remove();
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(
                    orderId: order.orderId,
                    isPurchase: isPurchase,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.pinkAccent.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.pink.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag,
                      color: Colors.pinkAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Updated',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _buildMessage(order, isPurchase),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      if (overlayEntry.mounted) {
                        overlayEntry.remove();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  static String _buildMessage(OrderModel order, bool isPurchase) {
    final orderCode = order.orderCode.isNotEmpty
        ? order.orderCode
        : '#${order.orderId}';

    if (isPurchase) {
      return 'Your order $orderCode has been updated by ${order.sellerName}.';
    }

    return 'You have a new update for order $orderCode from ${order.buyerName}.';
  }
}