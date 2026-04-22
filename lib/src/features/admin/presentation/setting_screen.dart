import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(title: const Text("Pengaturan"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Row(
              children: [
                const CircleAvatar(radius: 30, child: Icon(Icons.person)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Admin PKL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(user?.email ?? "admin@mail.com", style: const TextStyle(color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          _item(Icons.notifications_none, "Notifikasi"),
          _item(Icons.security, "Keamanan"),
          _item(Icons.help_outline, "Bantuan"),
          const Divider(),
          _item(Icons.logout, "Keluar", color: Colors.red, onTap: () async {
            await Supabase.instance.client.auth.signOut();
          }),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, {Color color = Colors.black, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 18),
    );
  }
}