import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/act.dart';
import 'edit_act_screen.dart';

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

class ActDetailScreen extends StatefulWidget {
  final Act act;
  const ActDetailScreen({super.key, required this.act});

  @override
  State<ActDetailScreen> createState() => _ActDetailScreenState();
}

class _ActDetailScreenState extends State<ActDetailScreen> {
  bool _edited = false;

  Future<void> _openEdit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditActScreen(act: widget.act)),
    );
    if (result == true) {
      setState(() => _edited = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Act updated')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final act = widget.act;
    final label = _categoryLabels[act.category] ?? act.category;
    final icon = _categoryIcons[act.category] ?? Icons.eco_outlined;
    final date = act.createdAt.toLocal();
    final dateStr =
        '${date.day} ${_month(date.month)} ${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _edited);
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      body: CustomScrollView(
        slivers: [
          // ── Full-bleed photo hero ────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context, _edited),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                    onPressed: _openEdit,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: act.photoUrls.isNotEmpty
                  ? _PhotoCarousel(urls: act.photoUrls)
                  : Container(color: const Color(0xFFf1f5f9),
                      child: Icon(icon, size: 64, color: const Color(0xFFcbd5e1))),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + date row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFdcfce7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 13, color: const Color(0xFF16a34a)),
                            const SizedBox(width: 5),
                            Text(
                              label,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
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

                  // Description
                  if (act.description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Description',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF94a3b8),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        act.description,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          color: const Color(0xFF334155),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],

                  // Location
                  const SizedBox(height: 24),
                  Text(
                    'Location',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94a3b8),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 200,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(act.lat, act.long),
                          zoom: 14,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId(act.id),
                            position: LatLng(act.lat, act.long),
                          ),
                        },
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        scrollGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

class _PhotoCarousel extends StatefulWidget {
  final List<String> urls;
  const _PhotoCarousel({required this.urls});

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: widget.urls.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (_, i) => Image.network(
            widget.urls[i],
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : Container(
                    color: const Color(0xFFf1f5f9),
                    child: const Center(child: CircularProgressIndicator(color: Color(0xFF22c55e))),
                  ),
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFf1f5f9),
              child: const Center(child: Icon(Icons.broken_image, size: 48, color: Color(0xFFcbd5e1))),
            ),
          ),
        ),

        // Dot indicators
        if (widget.urls.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.urls.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _current == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _current == i ? Colors.white : Colors.white54,
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),

        // Counter badge
        if (widget.urls.length > 1)
          Positioned(
            top: 56,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_current + 1} / ${widget.urls.length}',
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}
