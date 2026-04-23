import 'package:flutter/material.dart';

class ActiveUserAvatar extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final bool isOnline;
  final VoidCallback? onTap;

  const ActiveUserAvatar({super.key, required this.avatarUrl, required this.name, this.isOnline = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 18),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Vòng ngoài gradient đen trắng cực sang
                Container(
                  width: 66, height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: isOnline ? [Colors.black, Colors.black26] : [Colors.transparent, Colors.transparent],
                        begin: Alignment.topLeft, end: Alignment.bottomRight
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(avatarUrl),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 2, bottom: 2,
                    child: Container(
                      height: 14, width: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF00), // Xanh Neon
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(name.split(" ")[0],
                style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}