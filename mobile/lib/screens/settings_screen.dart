import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user.dart';
import '../services/api.dart';
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
  int _actsCount = 0;
  int _totalActsCount = 0;

  @override
  void initState() {
    super.initState();
    UserStorage.get().then((u) => setState(() => _user = u));
    getActs().then((acts) {
      if (mounted) setState(() => _actsCount = acts.length);
    }).catchError((_) {});
    getAllActs().then((acts) {
      if (mounted) setState(() => _totalActsCount = acts.length);
    }).catchError((_) {});
  }

  Future<void> _logout() async {
    await TokenStorage.clear();
    await UserStorage.clear();
    widget.onLogout();
  }

  String _displayName(String email) {
    final name = email.split('@').first.replaceAll(RegExp(r'[._\-+]'), ' ');
    return name.split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final email = _user?.email ?? '';
    final initial = email.isEmpty ? '?' : email[0].toUpperCase();
    final displayName = email.isEmpty ? 'User' : _displayName(email);

    return Scaffold(
      backgroundColor: const Color(0xFFf0fdf4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFf0fdf4),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.settings_outlined,
                  size: 18, color: Color(0xFF64748b)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            // ── Avatar + Name ─────────────────────────────────────────────────
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF22c55e),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.dmSans(
                      fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              displayName,
              style: GoogleFonts.dmSans(
                  fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF0f172a)),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF94a3b8)),
            ),

            const SizedBox(height: 24),

            // ── Stats Card ────────────────────────────────────────────────────
            _card(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    _StatItem(
                      icon: Icons.description_outlined,
                      iconColor: const Color(0xFF22c55e),
                      value: '$_actsCount',
                      label: 'My\nActs',
                    ),
                    _divider(),
                    _StatItem(
                      icon: Icons.eco_outlined,
                      iconColor: const Color(0xFF22c55e),
                      value: '$_totalActsCount',
                      label: 'Total\nActs',
                    ),
                    _divider(),
                    _StatItem(
                      icon: Icons.star_outline_rounded,
                      iconColor: const Color(0xFFD97706),
                      value: '0',
                      label: 'Community\nPoints',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Menu Items ────────────────────────────────────────────────────
            _card(
              Column(
                children: [
                  _menuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () => _comingSoon(context),
                  ),
                  _menuDivider(),
                  _menuItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => _comingSoon(context),
                  ),
                  _menuDivider(),
                  _menuItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Help Center',
                    onTap: () => _comingSoon(context),
                  ),
                  _menuDivider(),
                  _menuItem(
                    icon: Icons.info_outline_rounded,
                    label: 'About Us',
                    onTap: () => _comingSoon(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Log Out ───────────────────────────────────────────────────────
            _card(
              _menuItem(
                icon: Icons.logout_rounded,
                label: 'Log Out',
                iconColor: const Color(0xFFdc2626),
                labelColor: const Color(0xFFdc2626),
                onTap: _logout,
              ),
            ),

            const SizedBox(height: 24),
            Text(
              'Powered by BLUE JANUARY LLC',
              style: GoogleFonts.dmSans(
                  color: const Color(0xFFcbd5e1), fontSize: 12, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: const Color(0xFFF1F5F9),
      );

  Widget _menuDivider() => const Padding(
        padding: EdgeInsets.only(left: 44),
        child: Divider(height: 1, color: Color(0xFFF1F5F9)),
      );

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF64748b),
    Color labelColor = const Color(0xFF0f172a),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: FontWeight.w500, color: labelColor),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: labelColor == const Color(0xFFdc2626) ? labelColor : const Color(0xFFcbd5e1)),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon'), duration: Duration(seconds: 1)),
    );
  }
}

// ── Stat Item ──────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.dmSans(
                fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF0f172a)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF94a3b8), height: 1.3),
          ),
        ],
      ),
    );
  }
}
