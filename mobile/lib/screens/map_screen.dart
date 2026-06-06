import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/act.dart';
import '../models/system_config.dart';
import '../services/api.dart';
import '../services/system_config_storage.dart';
import 'act_detail_screen.dart';

// Fallback icon per slug for known categories
const _slugIcons = {
  'tree_mangrove': Icons.park_outlined,
  'wildlife': Icons.pets_outlined,
  'recycling': Icons.recycling_outlined,
  'litter_cleanup': Icons.delete_outline,
  'road_street': Icons.warning_amber_rounded,
};

const _slugHues = {
  'tree_mangrove': BitmapDescriptor.hueGreen,
  'wildlife': BitmapDescriptor.hueOrange,
  'recycling': BitmapDescriptor.hueBlue,
  'litter_cleanup': BitmapDescriptor.hueRed,
  'road_street': BitmapDescriptor.hueYellow,
};

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  List<Act> _acts = [];
  List<CategoryConfig> _categories = [];
  Set<Marker> _markers = {};
  bool _loading = true;
  String? _selectedCategory;
  Position? _userPosition;
  Act? _selectedAct;

  static const _defaultPosition = CameraPosition(target: LatLng(0, 20), zoom: 2);

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await Future.wait([_loadCategories(), _loadActs(), _moveToCurrentLocation()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadCategories() async {
    try {
      var config = await SystemConfigStorage.get();
      if (config == null || config.categories.isEmpty) {
        config = await getSystemConfig();
        await SystemConfigStorage.save(config);
      }
      if (mounted) setState(() => _categories = config!.categories);
    } catch (_) {}
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      if (mounted) {
        setState(() => _userPosition = pos);
      }
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 12),
        ),
      );
    } catch (_) {}
  }

  Future<void> _loadActs() async {
    try {
      final acts = await getAllActs();
      if (mounted) {
        setState(() {
          _acts = acts;
          _markers = _buildMarkers(acts, null);
        });
      }
    } catch (_) {}
  }

  Set<Marker> _buildMarkers(List<Act> acts, String? categoryFilter) {
    return acts
        .where((a) => categoryFilter == null || a.category == categoryFilter)
        .map<Marker>((act) {
          final hue = _slugHues[act.category] ?? BitmapDescriptor.hueGreen;
          return Marker(
            markerId: MarkerId(act.id),
            position: LatLng(act.lat, act.long),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            onTap: () {
              setState(() => _selectedAct = act);
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(LatLng(act.lat, act.long)),
              );
            },
          );
        }).toSet();
  }

  void _onCategoryChanged(String? category) {
    setState(() {
      _selectedCategory = category;
      _selectedAct = null;
      _markers = _buildMarkers(_acts, category);
    });
  }

  List<Act> get _nearbyActs {
    var acts = _selectedCategory == null
        ? List<Act>.from(_acts)
        : _acts.where((a) => a.category == _selectedCategory).toList();

    if (_userPosition != null) {
      acts.sort((a, b) {
        final da = Geolocator.distanceBetween(
            _userPosition!.latitude, _userPosition!.longitude, a.lat, a.long);
        final db = Geolocator.distanceBetween(
            _userPosition!.latitude, _userPosition!.longitude, b.lat, b.long);
        return da.compareTo(db);
      });
    }
    return acts;
  }

  String _formatDistance(Act act) {
    if (_userPosition == null) return '';
    final m = Geolocator.distanceBetween(
        _userPosition!.latitude, _userPosition!.longitude, act.lat, act.long);
    if (m < 1000) return '${m.toInt()} m away';
    return '${(m / 1000).toStringAsFixed(1)} km away';
  }

  String _categoryName(String slug) {
    for (final c in _categories) {
      if (c.slug == slug) return c.name;
    }
    return slug;
  }

  IconData _categoryIcon(String slug) =>
      _slugIcons[slug] ?? Icons.category_outlined;

  void _navigateToDetail(Act act) {
    setState(() => _selectedAct = null);
    Navigator.push(context, MaterialPageRoute(builder: (_) => ActDetailScreen(act: act)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Map',
          style: GoogleFonts.dmSans(
              fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0f172a)),
        ),
        actions: [
          _CategoryFilterChip(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onChanged: _onCategoryChanged,
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFe2e8f0), width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.menu_rounded, size: 18, color: Color(0xFF64748b)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF22c55e)))
          : Stack(
              children: [
                // ── Map ──────────────────────────────────────────────────────
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: _defaultPosition,
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    zoomGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    rotateGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                    gestureRecognizers: {
                      Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer()),
                    },
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _moveToCurrentLocation();
                    },
                    onTap: (_) => setState(() => _selectedAct = null),
                  ),
                ),

                // ── Total acts count badge ───────────────────────────────────
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.eco_outlined, size: 16, color: Color(0xFF22c55e)),
                        const SizedBox(width: 6),
                        Text(
                          '${_acts.length} acts',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF22c55e),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Act preview card (shown on marker tap) ───────────────────
                if (_selectedAct != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: MediaQuery.of(context).size.height * 0.37,
                    child: _ActPreviewCard(
                      act: _selectedAct!,
                      categoryName: _categoryName(_selectedAct!.category),
                      categoryIcon: _categoryIcon(_selectedAct!.category),
                      onDismiss: () => setState(() => _selectedAct = null),
                      onTap: () => _navigateToDetail(_selectedAct!),
                    ),
                  ),

                // ── My Location FAB ──────────────────────────────────────────
                Positioned(
                  right: 16,
                  bottom: MediaQuery.of(context).size.height * 0.37,
                  child: FloatingActionButton.small(
                    heroTag: 'my_location',
                    onPressed: _moveToCurrentLocation,
                    backgroundColor: Colors.white,
                    elevation: 2,
                    child: const Icon(Icons.my_location_rounded,
                        color: Color(0xFF22c55e), size: 20),
                  ),
                ),

                // ── Nearby Reports Bottom Sheet ───────────────────────────────
                DraggableScrollableSheet(
                  initialChildSize: 0.35,
                  minChildSize: 0.12,
                  maxChildSize: 0.65,
                  builder: (context, scrollController) {
                    final acts = _nearbyActs;
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 12,
                              offset: Offset(0, -2)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFe2e8f0),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Nearby Reports',
                                style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0f172a)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: acts.isEmpty
                                ? Center(
                                    child: Text('No reports yet',
                                        style: GoogleFonts.dmSans(
                                            color: const Color(0xFF94a3b8))),
                                  )
                                : ListView.separated(
                                    controller: scrollController,
                                    padding:
                                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    itemCount: acts.length,
                                    separatorBuilder: (_, __) => const Divider(
                                        height: 1, color: Color(0xFFF1F5F9)),
                                    itemBuilder: (context, i) => _NearbyTile(
                                      act: acts[i],
                                      categoryName: _categoryName(acts[i].category),
                                      categoryIcon: _categoryIcon(acts[i].category),
                                      distance: _formatDistance(acts[i]),
                                      onTap: () => _navigateToDetail(acts[i]),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

// ── Category Filter Chip ────────────────────────────────────────────────────────

class _CategoryFilterChip extends StatelessWidget {
  final List<CategoryConfig> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onChanged;

  const _CategoryFilterChip({
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
  });

  String _label() {
    if (selectedCategory == null) return 'All Categories';
    for (final c in categories) {
      if (c.slug == selectedCategory) return c.name;
    }
    return selectedCategory!;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<String?>(
          context: context,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (_) => _CategoryPicker(
            categories: categories,
            selected: selectedCategory,
          ),
        );
        if (result != null) onChanged(result == '__all__' ? null : result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFf1f5f9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _label(),
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF334155)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: Color(0xFF64748b)),
          ],
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final List<CategoryConfig> categories;
  final String? selected;

  const _CategoryPicker({required this.categories, required this.selected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFFe2e8f0),
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.layers_outlined, color: Color(0xFF22c55e)),
            title: Text('All Categories',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
            trailing: selected == null
                ? const Icon(Icons.check, color: Color(0xFF22c55e), size: 18)
                : null,
            onTap: () => Navigator.pop(context, '__all__'),
          ),
          ...categories.map((cat) => ListTile(
                leading: Icon(
                    _slugIcons[cat.slug] ?? Icons.category_outlined,
                    color: const Color(0xFF64748b)),
                title: Text(cat.name,
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
                trailing: selected == cat.slug
                    ? const Icon(Icons.check, color: Color(0xFF22c55e), size: 18)
                    : null,
                onTap: () => Navigator.pop(context, cat.slug),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Act Preview Card (marker tap) ──────────────────────────────────────────────

class _ActPreviewCard extends StatelessWidget {
  final Act act;
  final String categoryName;
  final IconData categoryIcon;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _ActPreviewCard({
    required this.act,
    required this.categoryName,
    required this.categoryIcon,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = act.createdAt.toLocal();
    final dateStr = '${date.day} ${_month(date.month)} ${date.year}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            // Photo
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: act.photoUrl.isNotEmpty
                  ? Image.network(act.photoUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),

            // Info
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFdcfce7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(categoryIcon, size: 11, color: const Color(0xFF16a34a)),
                          const SizedBox(width: 4),
                          Text(categoryName,
                              style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF16a34a))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(dateStr,
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: const Color(0xFF94a3b8))),
                    if (act.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        act.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: const Color(0xFF334155)),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Dismiss + arrow
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: onDismiss,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 8, right: 10),
                    child: Icon(Icons.close, size: 16, color: Color(0xFF94a3b8)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8, right: 10),
                  child: Icon(Icons.arrow_forward_ios,
                      size: 13, color: Color(0xFF22c55e)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 90,
        height: 90,
        color: const Color(0xFFf1f5f9),
        child: const Icon(Icons.image_outlined, color: Color(0xFFcbd5e1)),
      );

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

// ── Nearby Report Tile ─────────────────────────────────────────────────────────

class _NearbyTile extends StatelessWidget {
  final Act act;
  final String categoryName;
  final IconData categoryIcon;
  final String distance;
  final VoidCallback onTap;

  const _NearbyTile({
    required this.act,
    required this.categoryName,
    required this.categoryIcon,
    required this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFdcfce7),
                shape: BoxShape.circle,
              ),
              child: Icon(categoryIcon, size: 20, color: const Color(0xFF16a34a)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    act.description.isEmpty ? categoryName : act.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0f172a)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [if (distance.isNotEmpty) distance, categoryName].join(' • '),
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: const Color(0xFF94a3b8)),
                  ),
                ],
              ),
            ),
            if (act.status != null)
              _StatusPill(status: act.status!)
            else
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFcbd5e1), size: 20),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, fg) = switch (status.toLowerCase()) {
      'resolved' => ('Resolved', const Color(0xFF16a34a)),
      'in_progress' || 'in progress' => ('In Progress', const Color(0xFFD97706)),
      'pending' => ('Pending', const Color(0xFF3B82F6)),
      _ => (status, const Color(0xFF64748B)),
    };
    return Text(label,
        style: GoogleFonts.dmSans(
            fontSize: 12, fontWeight: FontWeight.w600, color: fg));
  }
}
