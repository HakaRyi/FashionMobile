import 'package:flutter/material.dart';

class PrivacySafetyScreen extends StatefulWidget {
  const PrivacySafetyScreen({super.key});

  @override
  State<PrivacySafetyScreen> createState() => _PrivacySafetyScreenState();
}

class _PrivacySafetyScreenState extends State<PrivacySafetyScreen> {
  bool _isPrivateAccount = false;
  bool _showActivityStatus = true;
  bool _personalizeAds = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "PRIVACY & SAFETY",
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
          _buildSectionTitle("ACCOUNT PRIVACY"),
          _buildSettingsGroup([
            _buildSwitchItem("Private Account", "Only approved followers can see your wardrobe and posts.", _isPrivateAccount, (val) {
              setState(() => _isPrivateAccount = val);
            }),
            _buildSwitchItem("Activity Status", "Allow others to see when you are online.", _showActivityStatus, (val) {
              setState(() => _showActivityStatus = val);
            }),
          ]),

          _buildSectionTitle("CONNECTIONS"),
          _buildSettingsGroup([
            _buildActionItem(Icons.block, "Blocked Users"),
            _buildActionItem(Icons.visibility_off_outlined, "Hidden Accounts"),
            _buildActionItem(Icons.comment_outlined, "Comment Controls"),
          ]),

          _buildSectionTitle("DATA & ADS"),
          _buildSettingsGroup([
            _buildSwitchItem("Personalized Ads", "Use my wardrobe data to show relevant fashion ads.", _personalizeAds, (val) {
              setState(() => _personalizeAds = val);
            }),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 20, 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: items),
    );
  }

  Widget _buildSwitchItem(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.green,
      title: Text(title, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.black45, fontSize: 12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildActionItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.black, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black12, size: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: () {},
    );
  }
}