import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _notifEnabled = true;
  bool _biometricEnabled = false;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Console Settings", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildUserProfile(user),
          const SizedBox(height: 40),
          _sectionTitle("Preferences"),
          _buildSwitchTile("Push Notifications", "Alerts for new journal entries", _notifEnabled, (v) => setState(() => _notifEnabled = v)),
          _buildSwitchTile("Biometric Access", "Secure console with FaceID/TouchID", _biometricEnabled, (v) => setState(() => _biometricEnabled = v)),
          const SizedBox(height: 32),
          _sectionTitle("Security & Support"),
          _buildActionItem(Icons.lock_outline_rounded, "Change Password", () {}),
          _buildActionItem(Icons.help_center_outlined, "Developer Documentation", () {}),
          _buildActionItem(Icons.info_outline_rounded, "Nexus Console v1.0.4", () {}),
          const SizedBox(height: 40),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildUserProfile(User? user) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.15), blurRadius: 25, offset: const Offset(0, 15))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.blue.shade400, shape: BoxShape.circle),
            child: const CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.admin_panel_settings_rounded, size: 30, color: Color(0xFF0F172A))),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Global Admin", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text(user?.email ?? "system@nexus.corp", style: TextStyle(color: Colors.blue.shade200, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Icon(Icons.verified_rounded, color: Colors.blue, size: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
    );
  }

  Widget _buildSwitchTile(String title, String sub, bool val, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        value: val,
        onChanged: onChanged,
        activeColor: Colors.blue,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF1E293B), size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B))),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async => await Supabase.instance.client.auth.signOut(),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.red.shade100),
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text("Terminate Session", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
    );
  }
}