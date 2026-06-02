import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/act.dart';
import '../services/api.dart';

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
  Set<Marker> _markers = {};
  bool _loading = true;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _loadActs();
  }

  Future<void> _loadActs() async {
    try {
      final acts = await getActs();
      final markers = acts.map<Marker>((Act act) {
        final hue = _categoryColors[act.category] ?? BitmapDescriptor.hueGreen;
        return Marker(
          markerId: MarkerId(act.id),
          position: LatLng(act.lat, act.long),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: _categoryLabels[act.category] ?? act.category,
            snippet: act.createdAt.toLocal().toString().substring(0, 10),
          ),
        );
      }).toSet();

      if (mounted) {
        setState(() {
          _markers = markers;
          _count = acts.length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map'), backgroundColor: Colors.white),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF22c55e)))
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(0, 20),
                    zoom: 2,
                  ),
                  markers: _markers,
                  myLocationButtonEnabled: false,
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                    ),
                    child: Text(
                      '$_count acts',
                      style: const TextStyle(
                        color: Color(0xFF22c55e),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
