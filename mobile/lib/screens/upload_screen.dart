import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api.dart';

const _categories = [
  {'id': 'tree_mangrove', 'label': 'Tree / Mangrove'},
  {'id': 'wildlife', 'label': 'Wildlife'},
  {'id': 'recycling', 'label': 'Recycling'},
  {'id': 'litter_cleanup', 'label': 'Litter Cleanup'},
];

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String? _category;
  XFile? _photo;
  bool _loading = false;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (img != null) setState(() => _photo = img);
  }

  Future<void> _submit() async {
    if (_category == null) {
      _snack('Please select a category');
      return;
    }
    if (_photo == null) {
      _snack('Please take a photo');
      return;
    }

    setState(() => _loading = true);
    try {
      // Get GPS
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _snack('Location permission is required');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Get pre-signed URL
      final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final presign = await getPresignedUrl(filename);

      // Upload to S3
      final bytes = await File(_photo!.path).readAsBytes();
      await uploadToS3(presign['uploadUrl'], bytes);

      // Save act
      await createAct(
        category: _category!,
        photoUrl: presign['publicUrl'],
        lat: pos.latitude,
        long: pos.longitude,
        gpsAccuracy: pos.accuracy,
      );

      if (mounted) {
        _snack('Act recorded successfully!');
        setState(() {
          _photo = null;
          _category = null;
        });
      }
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Log Act'), backgroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('SELECT CATEGORY',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categories.map((cat) {
                final selected = _category == cat['id'];
                return GestureDetector(
                  onTap: () => setState(() => _category = cat['id']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFf0fdf4) : const Color(0xFFf9f9f9),
                      border: Border.all(
                        color: selected ? const Color(0xFF22c55e) : const Color(0xFFdddddd),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cat['label']!,
                      style: TextStyle(
                        color: selected ? const Color(0xFF16a34a) : const Color(0xFF444444),
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFFfafafa),
                  border: Border.all(color: const Color(0xFFdddddd), width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.hardEdge,
                child: _photo != null
                    ? Image.file(File(_photo!.path), fit: BoxFit.cover)
                    : const Center(
                        child: Text('Tap to take photo', style: TextStyle(color: Colors.grey)),
                      ),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22c55e),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Act',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
