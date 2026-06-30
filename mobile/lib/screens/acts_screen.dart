import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/act.dart';
import '../services/api.dart';
import 'act_detail_screen.dart';

const _categoryLabels = {
  'tree_mangrove': 'Tree / Mangrove',
  'wildlife': 'Wildlife',
  'recycling': 'Recycling',
  'litter_cleanup': 'Litter Cleanup',
  'road_street': 'Road & Street',
};

const _categoryIcons = {
  'tree_mangrove': Icons.park_outlined,
  'wildlife': Icons.pets_outlined,
  'recycling': Icons.recycling_outlined,
  'litter_cleanup': Icons.delete_outline,
  'road_street': Icons.warning_amber_rounded,
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
  String _searchQuery = '';

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

  List<Act> get _filtered {
    if (_searchQuery.isEmpty) return _acts;
    final q = _searchQuery.toLowerCase();
    return _acts.where((a) =>
        a.description.toLowerCase().contains(q) ||
        (_categoryLabels[a.category] ?? a.category).toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0fdf4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'My Acts',
          style: GoogleFonts.dmSans(
              fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0f172a)),
        ),
        actions: [
          if (!_loading && _acts.isNotEmpty)
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
                    _searchQuery.isEmpty
                        ? '${_acts.length} logged'
                        : '${_filtered.length} of ${_acts.length}',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF16a34a)),
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
                          Text('No acts yet',
                              style: GoogleFonts.dmSans(
                                  fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0f172a))),
                          const SizedBox(height: 6),
                          Text('Log your first act of kindness!',
                              style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: const Color(0xFF22c55e),
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: _SearchBar(
                                onChanged: (q) => setState(() => _searchQuery = q),
                              ),
                            ),
                          ),
                          _filtered.isEmpty
                              ? SliverFillRemaining(
                                  child: Center(
                                    child: Text('No results for "$_searchQuery"',
                                        style: GoogleFonts.dmSans(color: const Color(0xFF94a3b8))),
                                  ),
                                )
                              : SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, i) => _ActCard(
                                        act: _filtered[i],
                                        onEditDone: _load,
                                      ),
                                      childCount: _filtered.length,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
    );
  }
}

// ── Search Bar ─────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: onChanged,
              style: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF0f172a)),
              decoration: InputDecoration(
                hintText: 'Search your reports...',
                hintStyle: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF94a3b8)),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94a3b8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF64748b)),
        ),
      ],
    );
  }
}

// ── Share helper ──────────────────────────────────────────────────────────────

void _shareAct(BuildContext context, Act act, String categoryLabel, String dateStr) {
  final buffer = StringBuffer();
  buffer.writeln('$categoryLabel reported via 100 Acts!');
  if (act.description.isNotEmpty) {
    buffer.writeln();
    buffer.writeln(act.description);
  }
  buffer.writeln();
  buffer.writeln('Logged on $dateStr');
  if (act.photoUrl.isNotEmpty) {
    buffer.writeln();
    buffer.write(act.photoUrl);
  }

  final box = context.findRenderObject() as RenderBox?;
  Share.share(
    buffer.toString().trim(),
    sharePositionOrigin: box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null,
  );
}

// ── Act Card ───────────────────────────────────────────────────────────────────

class _ActCard extends StatelessWidget {
  final Act act;
  final VoidCallback? onEditDone;
  const _ActCard({required this.act, this.onEditDone});

  @override
  Widget build(BuildContext context) {
    final label = _categoryLabels[act.category] ?? act.category;
    final icon = _categoryIcons[act.category] ?? Icons.eco_outlined;
    final date = act.createdAt.toLocal();
    final dateStr = '${date.day} ${_month(date.month)} ${date.year}';
    final hasMultiple = act.photoUrls.length > 1;

    return GestureDetector(
      onTap: () async {
        final edited = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => ActDetailScreen(act: act)),
        );
        if (edited == true) onEditDone?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Photo ────────────────────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
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
                            Text('${act.photoUrls.length}',
                                style: GoogleFonts.dmSans(
                                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Info ─────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFdcfce7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 11, color: const Color(0xFF16a34a)),
                            const SizedBox(width: 4),
                            Text(label,
                                style: GoogleFonts.dmSans(
                                    fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF16a34a))),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(dateStr,
                          style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF94a3b8))),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _shareAct(context, act, label, dateStr),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.share_outlined, size: 16, color: Color(0xFF94a3b8)),
                        ),
                      ),
                    ],
                  ),
                  if (act.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            act.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                                fontSize: 14, color: const Color(0xFF334155), height: 1.4),
                          ),
                        ),
                        if (act.status != null) ...[
                          const SizedBox(width: 8),
                          _StatusBadge(status: act.status!),
                        ],
                      ],
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
        child: Center(child: Icon(icon, size: 48, color: const Color(0xFFcbd5e1))),
      );

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

// ── Status Badge ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg, icon) = switch (status.toLowerCase()) {
      'resolved' => ('Resolved', const Color(0xFFdcfce7), const Color(0xFF16a34a), Icons.check_circle_outline),
      'in_progress' || 'in progress' => ('In Progress', const Color(0xFFFFF7ED), const Color(0xFFD97706), Icons.timelapse),
      'pending' => ('Pending', const Color(0xFFEFF6FF), const Color(0xFF3B82F6), Icons.schedule),
      _ => (status, const Color(0xFFF1F5F9), const Color(0xFF64748B), Icons.info_outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}
