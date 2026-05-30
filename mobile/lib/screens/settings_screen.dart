import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/token.dart';
import '../services/user_storage.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const SettingsScreen({super.key, required this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? _user;

  @override
  void initState() {
    super.initState();
    UserStorage.get().then((u) => setState(() => _user = u));
  }

  Future<void> _logout() async {
    await TokenStorage.clear();
    await UserStorage.clear();
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf5f5f5),
      appBar: AppBar(title: const Text('Settings'), backgroundColor: Colors.white),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFdcfce7),
                child: Text(
                  (_user?.email ?? '?')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF16a34a),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: const Text('Signed in as',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              subtitle: Text(
                _user?.email ?? '—',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1a1a1a),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFdc2626)),
              title: const Text(
                'Log out',
                style: TextStyle(color: Color(0xFFdc2626), fontWeight: FontWeight.w600),
              ),
              onTap: _logout,
            ),
          ),
        ],
      ),
    );
  }
}
