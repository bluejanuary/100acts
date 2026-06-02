import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/act.dart';
import '../services/api.dart';
import 'act_detail_screen.dart';

const _categoryLabels = {
  'tree_mangrove': 'Tree / Mangrove',
  'wildlife': 'Wildlife',
  'recycling': 'Recycling',
  'litter_cleanup': 'Litter Cleanup',
};

const _categoryIcons = {
  'tree_mangrove': Icons.park_outlined,
  'wildlife': Icons.pets_outlined,
  'recycling': Icons.recycling_outlined,
  'litter_cleanup': Icons.delete_outline,
};

class ActsScreen extends StatefulWidget {
  const ActsScreen({super.key});

  @override
  State<ActsScreen> createState() => _ActsScreenState();
}

class _ActsScreenState extends State<ActsScreen> {
  List<Act> _acts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final acts = await getActs();
      if (mounted) setState(() => _acts = acts);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        title: const Text('My Acts'),
        actions: [
          if (_acts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFdcfce7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_acts.length} logged',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF16a34a),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF22c55e)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_outlined, size: 48, color: Color(0xFFcbd5e1)),
                      const SizedBox(height: 12),
                      Text(_error!, style: GoogleFonts.dmSans(color: Colors.grey)),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _acts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFdcfce7),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(Icons.eco_outlined, size: 40, color: Color(0xFF22c55e)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No acts yet',
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0f172a),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Log your first act of kindness!',
                            style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: const Color(0xFF22c55e),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _acts.length,
                        itemBuilder: (context, i) => _ActCard(act: _acts[i]),
                      ),
                    ),
    );
  }
}

class _ActCard extends StatelessWidget {
  final Act act;
  const _ActCard({required this.act});

  @override
  Widget build(BuildContext context) {
    final label = _categoryLabels[act.category] ?? act.category;
    final icon = _categoryIcons[act.category] ?? Icons.eco_outlined;
    final date = act.createdAt.toLocal();
    final dateStr = '${date.day} ${_month(date.month)} ${date.year}';
    final hasMultiple = act.photoUrls.length > 1;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ActDetailScreen(act: act)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              child: Stack(
                children: [
                  act.photoUrl.isNotEmpty
                      ? Image.network(
                          act.photoUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _photoPlaceholder(icon),
                        )
                      : _photoPlaceholder(icon),
                  // Multi-photo badge
                  if (hasMultiple)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library_outlined, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '${act.photoUrls.length}',
                              style: GoogleFonts.dmSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFdcfce7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 12, color: const Color(0xFF16a34a)),
                            const SizedBox(width: 4),
                            Text(
                              label,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF16a34a),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateStr,
                        style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF94a3b8)),
                      ),
                    ],
                  ),
                  if (act.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      act.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: const Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder(IconData icon) => Container(
        height: 180,
        color: const Color(0xFFf1f5f9),
        child: Center(
          child: Icon(icon, size: 48, color: const Color(0xFFcbd5e1)),
        ),
      );

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}
