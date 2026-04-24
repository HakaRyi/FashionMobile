import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutWapoScreen extends StatelessWidget {
  const AboutWapoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "ABOUT WAPO",
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
          //const SizedBox(height: 30),
          // Logo & App Name
          Center(
            child: Column(
              children: [
                // Container(
                //   padding: const EdgeInsets.all(24),
                //   decoration: BoxDecoration(
                //     color: Colors.black,
                //     borderRadius: BorderRadius.circular(30),
                //     boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                //   ),
                //   child: const Icon(Icons.checkroom, color: Colors.white, size: 60),
                // ),
                //const SizedBox(height: 20),
                Text(
                  "WAPO",
                  style: GoogleFonts.playfairDisplay(
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0, // Tăng giãn chữ cho sang
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text("Version 1.0.0", style: TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 50),

          // Links
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            child: Column(
              children: [
                _buildActionItem("Terms of Service"),
                const Divider(height: 1, color: Colors.black12, indent: 20),
                _buildActionItem("Privacy Policy"),
                const Divider(height: 1, color: Colors.black12, indent: 20),
                _buildActionItem("Open Source Libraries"),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Copyright
          const Center(
            child: Text(
              "© 2026 Wapo Fashion Tech.\nAll rights reserved.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black26, fontSize: 10, fontWeight: FontWeight.w600, height: 1.5),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionItem(String title) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black12, size: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: () {},
    );
  }
}