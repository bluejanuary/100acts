import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/act.dart';
import '../models/act_summary.dart';
import '../models/system_config.dart';
import '../services/api.dart';
import '../services/system_config_storage.dart';
import 'act_detail_screen.dart';

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

// ── Cluster data class ─────────────────────────────────────────────────────────

class _ClusterItem {
  final bool isCluster;
  final ActSummary? summary;       // single pin
  final List<ActSummary>? members; // cluster members
  final double lat;
  final double long;
  final int count;

  _ClusterItem.pin(ActSummary s)
      : isCluster = false,
        summary = s,
        members = null,
        lat = s.lat,
        long = s.long,
        count = 1;

  _ClusterItem.cluster(List<ActSummary> m, double clusterLat, double clusterLong)
      : isCluster = true,
        summary = null,
        members = m,
        lat = clusterLat,
        long = clusterLong,
        count = m.length;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  List<CategoryConfig> _categories = [];

  List<ActSummary> _allSummaries = []; // raw viewport results
  List<ActSummary> _summaries = [];    // filtered by category

  final Map<String, Act> _actCache = {}; // full act details, keyed by id
  final Map<int, BitmapDescriptor> _clusterIconCache = {};

  Set<Marker> _markers = {};
  bool _viewportLoading = false;
  String? _selectedCategory;
  Position? _userPosition;
  double _currentZoom = 2.0;

  // Selected pin state
  ActSummary? _selectedSummary;
  Act? _selectedActDetail;
  bool _selectedActLoading = false;

  static const _defaultPosition = CameraPosition(target: LatLng(0, 20), zoom: 2);

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _requestLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // ── Init ───────────────────────────────────────────────────────────────────

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

  Future<void> _requestLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      if (mounted) setState(() => _userPosition = pos);
    } catch (_) {}
  }

  Future<void> _moveToCurrentLocation() async {
    if (_mapController == null) return;
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      if (mounted) setState(() => _userPosition = pos);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 12),
        ),
      );
    } catch (_) {}
  }

  // ── Viewport loading ───────────────────────────────────────────────────────

  Future<void> _loadForViewport() async {
    if (_mapController == null) return;
    if (mounted) setState(() => _viewportLoading = true);
    try {
      final bounds = await _mapController!.getVisibleRegion();
      final summaries = await getActsSummary(
        swLat: bounds.southwest.latitude,
        swLng: bounds.southwest.longitude,
        neLat: bounds.northeast.latitude,
        neLng: bounds.northeast.longitude,
      );
      if (!mounted) return;
      _allSummaries = summaries;
      _applyFilter();
    } catch (_) {
      // silently keep existing markers
    } finally {
      if (mounted) setState(() => _viewportLoading = false);
    }
  }

  void _applyFilter() {
    _summaries = _selectedCategory == null
        ? List.from(_allSummaries)
        : _allSummaries.where((s) => s.category == _selectedCategory).toList();
    _rebuildMarkers();
  }

  // ── Clustering ─────────────────────────────────────────────────────────────

  /// Degrees per ~60px at the given zoom level — used as the cluster grid cell.
  double _cellDegrees(double zoom) =>
      60 * 360 / (256 * math.pow(2, zoom).toDouble());

  List<_ClusterItem> _clusterSummaries(List<ActSummary> summaries, double zoom) {
    final cell = _cellDegrees(zoom);
    final Map<String, List<ActSummary>> grid = {};
    for (final s in summaries) {
      final key = '${(s.lat / cell).floor()}_${(s.long / cell).floor()}';
      grid.putIfAbsent(key, () => []).add(s);
    }
    return grid.values.map((group) {
      if (group.length == 1) return _ClusterItem.pin(group.first);
      final avgLat = group.fold(0.0, (sum, s) => sum + s.lat) / group.length;
      final avgLng = group.fold(0.0, (sum, s) => sum + s.long) / group.length;
      return _ClusterItem.cluster(group, avgLat, avgLng); // clusterLat, clusterLong
    }).toList();
  }

  Future<void> _rebuildMarkers() async {
    // Snapshot to avoid reading a mutated list after an await
    final clusters = _clusterSummaries(List.from(_summaries), _currentZoom);
    final markers = <Marker>{};

    for (final item in clusters) {
      if (item.isCluster) {
        final icon = await _getClusterIcon(item.count);
        markers.add(Marker(
          markerId: MarkerId('cluster_${item.lat}_${item.long}_${item.count}'),
          position: LatLng(item.lat, item.long),
          icon: icon,
          onTap: () => _onClusterTap(item),
        ));
      } else {
        final s = item.summary!;
        final hue = _slugHues[s.category] ?? BitmapDescriptor.hueGreen;
        markers.add(Marker(
          markerId: MarkerId(s.id),
          position: LatLng(s.lat, s.long),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          onTap: () => _onPinTap(s),
        ));
      }
    }

    if (mounted) setState(() => _markers = markers);
  }

  Future<BitmapDescriptor> _getClusterIcon(int count) async {
    // Bucket so we don't create hundreds of unique icons
    final bucket = count >= 100 ? 100 : count >= 10 ? 10 : count;
    return _clusterIconCache[bucket] ??= await _buildClusterIcon(count);
  }

  Future<BitmapDescriptor> _buildClusterIcon(int count) async {
    const double size = 72;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    // Outer translucent ring
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = const Color(0xFF22c55e).withAlpha(70),
    );
    // Solid inner circle
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 8,
      Paint()..color = const Color(0xFF22c55e),
    );

    final label = count > 999 ? '999+' : '$count';
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size);
    tp.paint(canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2));

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to encode cluster icon');
    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  LatLngBounds _boundsFor(List<LatLng> points) {
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  // ── Interaction ────────────────────────────────────────────────────────────

  void _onPinTap(ActSummary summary) {
    final cached = _actCache[summary.id];
    setState(() {
      _selectedSummary = summary;
      _selectedActDetail = cached;
      _selectedActLoading = cached == null;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(summary.lat, summary.long)));

    if (cached == null) {
      getActById(summary.id).then((act) {
        _actCache[act.id] = act;
        if (mounted && _selectedSummary?.id == summary.id) {
          setState(() { _selectedActDetail = act; _selectedActLoading = false; });
        }
      }).catchError((_) {
        if (mounted && _selectedSummary?.id == summary.id) {
          setState(() => _selectedActLoading = false);
        }
      });
    }
  }

  void _onClusterTap(_ClusterItem item) {
    final members = item.members;
    if (members == null || members.isEmpty) return;
    if (members.length == 1) { _onPinTap(members.first); return; }
    final bounds = _boundsFor(members.map((s) => LatLng(s.lat, s.long)).toList());
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  void _onCategoryChanged(String? category) {
    setState(() {
      _selectedCategory = category;
      _selectedSummary = null;
      _selectedActDetail = null;
    });
    _applyFilter();
  }

  Future<void> _navigateToDetail(ActSummary summary) async {
    Act? act = _actCache[summary.id];
    if (act == null) {
      try {
        act = await getActById(summary.id);
        _actCache[act.id] = act;
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load act details')),
          );
        }
        return;
      }
    }
    if (!mounted) return;
    setState(() { _selectedSummary = null; _selectedActDetail = null; });
    final edited = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ActDetailScreen(act: act!)),
    );
    if (edited == true) {
      _actCache.remove(summary.id);
      _loadForViewport();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatDistance(ActSummary s) {
    if (_userPosition == null) return '';
    final m = Geolocator.distanceBetween(
        _userPosition!.latitude, _userPosition!.longitude, s.lat, s.long);
    return m < 1000 ? '${m.toInt()} m away' : '${(m / 1000).toStringAsFixed(1)} km away';
  }

  String _categoryName(String slug) {
    for (final c in _categories) {
      if (c.slug == slug) return c.name;
    }
    return slug;
  }

  IconData _categoryIcon(String slug) => _slugIcons[slug] ?? Icons.category_outlined;

  List<ActSummary> get _nearbySummaries {
    final list = List<ActSummary>.from(_summaries);
    if (_userPosition != null) {
      list.sort((a, b) {
        final da = Geolocator.distanceBetween(
            _userPosition!.latitude, _userPosition!.longitude, a.lat, a.long);
        final db = Geolocator.distanceBetween(
            _userPosition!.latitude, _userPosition!.longitude, b.lat, b.long);
        return da.compareTo(db);
      });
    }
    return list;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
      body: Stack(
        children: [
          // ── Map — shown immediately, no loading blocker ──────────────────
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
                Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
              },
              onMapCreated: (controller) {
                _mapController = controller;
                _moveToCurrentLocation();
              },
              onCameraMove: (pos) => _currentZoom = pos.zoom,
              onCameraIdle: _loadForViewport,
              onTap: (_) => setState(() {
                _selectedSummary = null;
                _selectedActDetail = null;
              }),
            ),
          ),

          // ── Acts count / loading badge ────────────────────────────────────
          Positioned(
            top: 16,
            left: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _viewportLoading
                  ? _badge(
                      key: const ValueKey('loading'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 12, height: 12,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF22c55e)),
                          ),
                          const SizedBox(width: 8),
                          Text('Loading...',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF22c55e))),
                        ],
                      ),
                    )
                  : _badge(
                      key: const ValueKey('count'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.eco_outlined,
                              size: 16, color: Color(0xFF22c55e)),
                          const SizedBox(width: 6),
                          Text(
                            '${_summaries.length} in view',
                            style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF22c55e)),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // ── My Location FAB ───────────────────────────────────────────────
          Positioned(
            top: 76,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              onPressed: _moveToCurrentLocation,
              backgroundColor: Colors.white,
              elevation: 2,
              child: const Icon(Icons.my_location_rounded,
                  color: Color(0xFF22c55e), size: 20),
            ),
          ),

          // ── Act preview card (single marker tap) ──────────────────────────
          if (_selectedSummary != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: MediaQuery.of(context).size.height * 0.37,
              child: _ActPreviewCard(
                summary: _selectedSummary!,
                fullAct: _selectedActDetail,
                isLoading: _selectedActLoading,
                categoryName: _categoryName(_selectedSummary!.category),
                categoryIcon: _categoryIcon(_selectedSummary!.category),
                onDismiss: () => setState(() {
                  _selectedSummary = null;
                  _selectedActDetail = null;
                }),
                onTap: () => _navigateToDetail(_selectedSummary!),
              ),
            ),

          // ── Nearby Reports bottom sheet ───────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.12,
            maxChildSize: 0.65,
            builder: (context, scrollController) {
              final nearby = _nearbySummaries;
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -2)),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                            color: const Color(0xFFe2e8f0),
                            borderRadius: BorderRadius.circular(2)),
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
                      child: _viewportLoading && nearby.isEmpty
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF22c55e), strokeWidth: 2))
                          : nearby.isEmpty
                              ? Center(
                                  child: Text('No reports in this area',
                                      style: GoogleFonts.dmSans(
                                          color: const Color(0xFF94a3b8))))
                              : ListView.separated(
                                  controller: scrollController,
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  itemCount: nearby.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                  itemBuilder: (context, i) => _NearbyTile(
                                    summary: nearby[i],
                                    categoryName: _categoryName(nearby[i].category),
                                    categoryIcon: _categoryIcon(nearby[i].category),
                                    distance: _formatDistance(nearby[i]),
                                    onTap: () => _navigateToDetail(nearby[i]),
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

  Widget _badge({required Key key, required Widget child}) => Container(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: child,
      );
}

// ── Category Filter ───────────────────────────────────────────────────────────

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
          builder: (_) =>
              _CategoryPicker(categories: categories, selected: selectedCategory),
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
            Text(_label(),
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF334155))),
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
            width: 40, height: 4,
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

// ── Act Preview Card ──────────────────────────────────────────────────────────

class _ActPreviewCard extends StatelessWidget {
  final ActSummary summary;
  final Act? fullAct;
  final bool isLoading;
  final String categoryName;
  final IconData categoryIcon;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _ActPreviewCard({
    required this.summary,
    required this.fullAct,
    required this.isLoading,
    required this.categoryName,
    required this.categoryIcon,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = fullAct?.createdAt.toLocal();
    final dateStr = date != null
        ? '${date.day} ${_month(date.month)} ${date.year}'
        : null;

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
            // Photo / loading placeholder
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 90, height: 90,
                child: isLoading
                    ? Container(
                        color: const Color(0xFFf1f5f9),
                        child: const Center(
                          child: SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF22c55e)),
                          ),
                        ),
                      )
                    : fullAct != null && fullAct!.photoUrl.isNotEmpty
                        ? Image.network(fullAct!.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder(),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    if (dateStr != null)
                      Text(dateStr,
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: const Color(0xFF94a3b8))),
                    const SizedBox(height: 3),
                    if (isLoading)
                      Text('Loading details...',
                          style: GoogleFonts.dmSans(
                              fontSize: 13, color: const Color(0xFF94a3b8)))
                    else if (fullAct != null && fullAct!.description.isNotEmpty)
                      Text(
                        fullAct!.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: const Color(0xFF334155)),
                      ),
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
        color: const Color(0xFFf1f5f9),
        child: const Icon(Icons.image_outlined, color: Color(0xFFcbd5e1)),
      );

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

// ── Nearby Tile ───────────────────────────────────────────────────────────────

class _NearbyTile extends StatelessWidget {
  final ActSummary summary;
  final String categoryName;
  final IconData categoryIcon;
  final String distance;
  final VoidCallback onTap;

  const _NearbyTile({
    required this.summary,
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
              width: 40, height: 40,
              decoration: const BoxDecoration(
                  color: Color(0xFFdcfce7), shape: BoxShape.circle),
              child: Icon(categoryIcon, size: 20, color: const Color(0xFF16a34a)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0f172a)),
                  ),
                  if (distance.isNotEmpty)
                    Text(distance,
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: const Color(0xFF94a3b8))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFcbd5e1), size: 20),
          ],
        ),
      ),
    );
  }
}
