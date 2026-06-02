import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../models/system_config.dart';
import '../services/api.dart';
import '../services/system_config_storage.dart';

const int _maxPhotos = 5;

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  List<CategoryConfig> _categories = [];
  bool _categoriesLoading = true;
  String? _selectedSlug;
  final List<XFile> _photos = [];
  final _descriptionController = TextEditingController();
  bool _loading = false;
  String _uploadProgress = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (mounted) setState(() => _categoriesLoading = true);
    try {
      var config = await SystemConfigStorage.get();
      if (config == null || config.categories.isEmpty) {
        config = await getSystemConfig();
        await SystemConfigStorage.save(config);
      }
      if (mounted) setState(() => _categories = config!.categories);
    } catch (e) {
      _snack('Could not load categories');
    } finally {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  Future<void> _takePhoto() async {
    if (_photos.length >= _maxPhotos) return;
    final img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
    if (img != null) setState(() => _photos.add(img));
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _submit() async {
    if (_selectedSlug == null || _photos.isEmpty || _descriptionController.text.trim().isEmpty) return;

    setState(() { _loading = true; _uploadProgress = ''; });
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) setState(() { _loading = false; _uploadProgress = ''; });
        _snack('Location permission is required');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Upload all photos, collecting public URLs
      final photoUrls = <String>[];
      for (int i = 0; i < _photos.length; i++) {
        if (mounted) setState(() => _uploadProgress = 'Uploading photo ${i + 1} of ${_photos.length}...');
        final filename = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final presign = await getPresignedUrl(filename);
        final bytes = await File(_photos[i].path).readAsBytes();
        await uploadToS3(presign['uploadUrl'], bytes);
        photoUrls.add(presign['publicUrl']);
      }

      if (mounted) setState(() => _uploadProgress = 'Saving act...');

      await createAct(
        category: _selectedSlug!,
        description: _descriptionController.text.trim(),
        photoUrls: photoUrls,
        lat: pos.latitude,
        long: pos.longitude,
        gpsAccuracy: pos.accuracy,
      );

      if (mounted) {
        _snack('Act recorded successfully!');
        setState(() {
          _photos.clear();
          _selectedSlug = null;
          _descriptionController.clear();
          _uploadProgress = '';
        });
      }
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() { _loading = false; _uploadProgress = ''; });
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final categorySelected = _selectedSlug != null;
    final hasPhotos = _photos.isNotEmpty;
    final descriptionFilled = _descriptionController.text.trim().isNotEmpty;
    final canAddMore = _photos.length < _maxPhotos;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Log Act')),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            final config = await getSystemConfig();
            await SystemConfigStorage.save(config);
            if (mounted) setState(() => _categories = config.categories);
          } catch (_) {
            _snack('Could not refresh categories');
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Category ─────────────────────────────────────────────────
              const Text('CATEGORY',
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF94a3b8), letterSpacing: 0.8)),
              const SizedBox(height: 10),
              _categoriesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: categorySelected ? const Color(0xFF22c55e) : const Color(0xFFdddddd),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedSlug,
                        hint: const Text('Select a category'),
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: _categories
                            .map((cat) => DropdownMenuItem(value: cat.slug, child: Text(cat.name)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedSlug = val),
                      ),
                    ),

              const SizedBox(height: 28),

              // ── Photos ───────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('PHOTOS',
                      style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF94a3b8), letterSpacing: 0.8)),
                  Text(
                    '${_photos.length} / $_maxPhotos',
                    style: TextStyle(
                      fontSize: 12,
                      color: _photos.length == _maxPhotos ? const Color(0xFF22c55e) : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Existing photo thumbnails
                    ..._photos.asMap().entries.map((entry) {
                      final i = entry.key;
                      final photo = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(photo.path),
                                width: 100,
                                height: 110,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removePhoto(i),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Add photo tile
                    if (categorySelected && canAddMore)
                      GestureDetector(
                        onTap: _takePhoto,
                        child: Container(
                          width: 100,
                          height: 110,
                          decoration: BoxDecoration(
                            color: const Color(0xFFfafafa),
                            border: Border.all(
                              color: hasPhotos ? const Color(0xFF22c55e) : const Color(0xFFdddddd),
                              width: 1.5,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  size: 28, color: hasPhotos ? const Color(0xFF22c55e) : Colors.grey),
                              const SizedBox(height: 6),
                              Text(
                                hasPhotos ? 'Add more' : 'Take photo',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: hasPhotos ? const Color(0xFF22c55e) : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Disabled placeholder when no category
                    if (!categorySelected)
                      Container(
                        width: 100,
                        height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFFf0f0f0),
                          border: Border.all(color: const Color(0xFFe5e5e5), width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 28, color: Color(0xFFcccccc)),
                            SizedBox(height: 6),
                            Text('Category first', style: TextStyle(fontSize: 11, color: Color(0xFFcccccc))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Description ──────────────────────────────────────────────
              const Text('DESCRIPTION',
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF94a3b8), letterSpacing: 0.8)),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                enabled: hasPhotos,
                maxLines: 3,
                maxLength: 280,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: hasPhotos ? 'Describe your act...' : 'Take a photo first',
                  hintStyle: TextStyle(color: hasPhotos ? Colors.grey : const Color(0xFFcccccc)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: descriptionFilled ? const Color(0xFF22c55e) : const Color(0xFFdddddd),
                      width: 1.5,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFe5e5e5), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF22c55e), width: 1.5),
                  ),
                  filled: true,
                  fillColor: hasPhotos ? const Color(0xFFfafafa) : const Color(0xFFf0f0f0),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),

              const SizedBox(height: 16),

              // ── Submit ───────────────────────────────────────────────────
              ElevatedButton(
                onPressed: (_loading || !categorySelected || !hasPhotos || !descriptionFilled) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22c55e),
                  disabledBackgroundColor: const Color(0xFFd1d5db),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          if (_uploadProgress.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(_uploadProgress, style: const TextStyle(fontSize: 12, color: Colors.white)),
                          ],
                        ],
                      )
                    : Text('Submit Act', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
