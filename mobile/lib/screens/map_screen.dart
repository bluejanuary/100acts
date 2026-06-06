import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/act.dart';
import '../services/api.dart';
import 'act_detail_screen.dart';

const _categoryColors = {
  'tree_mangrove': BitmapDescriptor.hueGreen,
  'wildlife': BitmapDescriptor.hueOrange,
  'recycling': BitmapDescriptor.hueBlue,
  'litter_cleanup': BitmapDescriptor.hueRed,
  'road_street': BitmapDescriptor.hueYellow,
};

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

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  List<Act> _acts = [];
  Set<Marker> _markers = {};
  bool _loading = true;
  String? _selectedCategory;
  Position? _userPosition;

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
    await Future.wait([_loadActs(), _moveToCurrentLocation()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

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
      final acts = await getActs();
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
          final hue = _categoryColors[act.category] ?? BitmapDescriptor.hueGreen;
          return Marker(
            markerId: MarkerId(act.id),
            position: LatLng(act.lat, act.long),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            onTap: () => _mapController?.animateCamera(
              CameraUpdate.newLatLng(LatLng(act.lat, act.long)),
            ),
          );
        }).toSet();
  }

  void _onCategoryChanged(String? category) {
    setState(() {
      _selectedCategory = category;
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
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 12,
                              offset: Offset(0, -2)),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Drag handle
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
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 16),
                                    itemCount: acts.length,
                                    separatorBuilder: (_, __) => const Divider(
                                        height: 1, color: Color(0xFFF1F5F9)),
                                    itemBuilder: (context, i) =>
                                        _NearbyTile(
                                      act: acts[i],
                                      distance: _formatDistance(acts[i]),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ActDetailScreen(act: acts[i]),
                                        ),
                                      ),
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
  final String? selectedCategory;
  final ValueChanged<String?> onChanged;

  const _CategoryFilterChip(
      {required this.selectedCategory, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<String?>(
          context: context,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (_) => _CategoryPicker(selected: selectedCategory),
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
              selectedCategory == null
                  ? 'All Categories'
                  : (_categoryLabels[selectedCategory] ?? selectedCategory!),
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
  final String? selected;
  const _CategoryPicker({required this.selected});

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
          ..._categoryLabels.entries.map((e) => ListTile(
                leading: Icon(_categoryIcons[e.key] ?? Icons.category_outlined,
                    color: const Color(0xFF64748b)),
                title: Text(e.value,
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
                trailing: selected == e.key
                    ? const Icon(Icons.check, color: Color(0xFF22c55e), size: 18)
                    : null,
                onTap: () => Navigator.pop(context, e.key),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Nearby Report Tile ─────────────────────────────────────────────────────────

class _NearbyTile extends StatelessWidget {
  final Act act;
  final String distance;
  final VoidCallback onTap;

  const _NearbyTile(
      {required this.act, required this.distance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = _categoryLabels[act.category] ?? act.category;
    final icon = _categoryIcons[act.category] ?? Icons.eco_outlined;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Category icon circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFdcfce7),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF16a34a)),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    act.description.isEmpty ? label : act.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0f172a)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [if (distance.isNotEmpty) distance, label]
                        .join(' • '),
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: const Color(0xFF94a3b8)),
                  ),
                ],
              ),
            ),

            // Status badge
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

    return Text(
      label,
      style: GoogleFonts.dmSans(
          fontSize: 12, fontWeight: FontWeight.w600, color: fg),
    );
  }
}
