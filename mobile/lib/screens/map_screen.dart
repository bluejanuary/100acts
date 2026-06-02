import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/act.dart';
import '../services/api.dart';
import 'act_detail_screen.dart';

const _categoryColors = {
  'tree_mangrove': BitmapDescriptor.hueGreen,
  'wildlife': BitmapDescriptor.hueOrange,
  'recycling': BitmapDescriptor.hueBlue,
  'litter_cleanup': BitmapDescriptor.hueRed,
};

const _categoryLabels = {
  'tree_mangrove': 'Tree / Mangrove',
  'wildlife': 'Wildlife',
  'recycling': 'Recycling',
  'litter_cleanup': 'Litter Cleanup',
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
  Act? _selectedAct;

  // Default fallback if location permission denied
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
      final markers = acts.map<Marker>((act) {
        final hue = _categoryColors[act.category] ?? BitmapDescriptor.hueGreen;
        return Marker(
          markerId: MarkerId(act.id),
          position: LatLng(act.lat, act.long),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          onTap: () => setState(() => _selectedAct = act),
        );
      }).toSet();

      if (mounted) setState(() { _acts = acts; _markers = markers; });
    } catch (_) {}
  }

  void _dismissCard() => setState(() => _selectedAct = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map'), backgroundColor: Colors.white),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF22c55e)))
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _defaultPosition,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _moveToCurrentLocation();
                  },
                  onTap: (_) => _dismissCard(),
                ),

                // Acts count badge
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                    ),
                    child: Text(
                      '${_acts.length} acts',
                      style: const TextStyle(
                        color: Color(0xFF22c55e),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                // Act preview card
                if (_selectedAct != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 24,
                    child: _ActPreviewCard(
                      act: _selectedAct!,
                      onDismiss: _dismissCard,
                      onTap: () {
                        final act = _selectedAct!;
                        _dismissCard();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ActDetailScreen(act: act)),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ActPreviewCard extends StatelessWidget {
  final Act act;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _ActPreviewCard({required this.act, required this.onDismiss, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = _categoryLabels[act.category] ?? act.category;
    final date = act.createdAt.toLocal();
    final dateStr = '${date.day} ${_month(date.month)} ${date.year}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            // Photo
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: act.photoUrl.isNotEmpty
                  ? Image.network(
                      act.photoUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoPlaceholder(),
                    )
                  : _photoPlaceholder(),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFdcfce7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFF16a34a),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    if (act.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        act.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
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
                    padding: EdgeInsets.only(top: 10, right: 10),
                    child: Icon(Icons.close, size: 18, color: Colors.grey),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10, right: 10),
                  child: Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF22c55e)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
        width: 90,
        height: 90,
        color: const Color(0xFFf0f0f0),
        child: const Icon(Icons.image_outlined, color: Color(0xFFcccccc)),
      );

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}
