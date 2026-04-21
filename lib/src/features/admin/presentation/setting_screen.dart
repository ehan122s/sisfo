import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _notifEnabled = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildProfileSection(),
                const SizedBox(height: 30),
                _sectionTitle("Preferensi Aplikasi"),
                _settingTile(Icons.notifications_active_outlined, "Notifikasi Real-time", "Dapatkan update jurnal siswa", trailing: Switch(value: _notifEnabled, onChanged: (v) => setState(() => _notifEnabled = v))),
                _settingTile(Icons.dark_mode_outlined, "Mode Gelap", "Tampilan hemat baterai", trailing: Switch(value: _darkMode, onChanged: (v) => setState(() => _darkMode = v))),
                
                const SizedBox(height: 30),
                _sectionTitle("Sistem & Keamanan"),
                _settingTile(Icons.lock_outline_rounded, "Ganti Password", "Amankan akun Anda", color: Colors.blue),
                _settingTile(Icons.cloud_sync_rounded, "Sinkronisasi Data", "Update database Supabase", color: Colors.teal),
                _settingTile(Icons.info_outline_rounded, "Tentang PKL Hub v1.0", "Informasi aplikasi & pengembang"),

                const SizedBox(height: 40),
                _buildLogoutButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
      child: const Row(
        children: [
          Icon(Icons.settings_suggest_rounded, color: Colors.blueGrey, size: 28),
          SizedBox(width: 15),
          Text("Pengaturan", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: Row(
        children: [
          const CircleAvatar(radius: 30, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=admin')),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Admin Utama", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              Text("admin@sekolah.id", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.edit_note_rounded, color: Colors.blue)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(left: 10, bottom: 15), child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.blueGrey)));
  }

  Widget _settingTile(IconData icon, String title, String subtitle, {Widget? trailing, Color color = Colors.blueGrey}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      onPressed: () => Supabase.instance.client.auth.signOut(),
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: const Text("Keluar dari Sesi", style: TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    );
  }
}