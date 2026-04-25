import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "HELP CENTER",
          style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          // Khung tìm kiếm (UI)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: "How can we help you?",
                hintStyle: TextStyle(color: Colors.black26, fontSize: 14),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.black38),
              ),
            ),
          ),
          const SizedBox(height: 30),

          _buildSectionTitle("FREQUENTLY ASKED QUESTIONS"),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            child: Column(
              children: [
                _buildFAQItem(
                  "How does the Virtual Try-On work?",
                  "Our Virtual Try-On uses advanced AI models to overlay selected clothing items onto your chosen model or your own uploaded photo with high accuracy.",
                ),
                _buildFAQItem(
                  "How is the service cost calculated?",
                  "Each AI Stylist or Virtual Try-On request consumes a small amount of balance from your Wallet to cover the AI processing power.",
                ),
                _buildFAQItem(
                  "How to manage my wardrobe?",
                  "Go to your Profile and tap 'Wardrobe'. Here you can add new items, categorize them, and delete items you no longer own.",
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          _buildSectionTitle("CONTACT US"),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            child: ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.black),
              title: const Text("Customer Support", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
              subtitle: const Text("Response time: 24 hours"),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black12, size: 14),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 20, 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w700)),
      iconColor: Colors.black,
      collapsedIconColor: Colors.black26,
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      children: [
        Text(answer, style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.5)),
      ],
    );
  }
}