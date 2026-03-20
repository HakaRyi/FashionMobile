import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> mockHistory = [
      {
        "title": "Nạp tiền từ ZaloPay",
        "amount": "+50.000",
        "date": "19/03/2026 14:30",
        "isPositive": true,
      },
      {
        "title": "Gia hạn gói Premium",
        "amount": "-29.000",
        "date": "18/03/2026 09:15",
        "isPositive": false,
      },
      {
        "title": "Nạp tiền từ ZaloPay",
        "amount": "+100.000",
        "date": "10/03/2026 18:20",
        "isPositive": true,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Biến động số dư'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: mockHistory.length,
        separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 32),
        itemBuilder: (context, index) {
          final item = mockHistory[index];
          final isPositive = item["isPositive"] as bool;

          return Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: isPositive ? Colors.green : Colors.redAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item["title"],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item["date"],
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                "${item["amount"]}đ",
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}