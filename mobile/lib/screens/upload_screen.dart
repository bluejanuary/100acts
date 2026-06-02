import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../models/system_config.dart';
import '../services/api.dart';
import '../services/system_config_storage.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  List<CategoryConfig> _categories = [];
  bool _categoriesLoading = true;
  String? _selectedSlug;
  XFile? _photo;
  final _descriptionController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (mounted) setState(() => _categoriesLoading = true);
    try {
      var config = await SystemConfigStorage.get();
      debugPrint('[config] cached: ${config?.categories.length} categories');

      if (config == null || config.categories.isEmpty) {
        debugPrint('[config] cache empty — fetching from /config');
        config = await getSystemConfig();
        debugPrint('[config] fetched ${config.categories.length} categories: ${config.categories.map((c) => c.slug).join(', ')}');
        await SystemConfigStorage.save(config);
      }

      if (mounted) setState(() => _categories = config!.categories);
    } catch (e) {
      debugPrint('[config] error: $e');
      _snack('Could not load categories');
    } finally {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (img != null) setState(() => _photo = img);
  }

  Future<void> _submit() async {
    if (_selectedSlug == null || _photo == null || _descriptionController.text.trim().isEmpty) return;

    setState(() => _loading = true);
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _snack('Location permission is required');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final presign = await getPresignedUrl(filename);

      final bytes = await File(_photo!.path).readAsBytes();
      await uploadToS3(presign['uploadUrl'], bytes);

      await createAct(
        category: _selectedSlug!,
        description: _descriptionController.text.trim(),
        photoUrl: presign['publicUrl'],
        lat: pos.latitude,
        long: pos.longitude,
        gpsAccuracy: pos.accuracy,
      );

      if (mounted) {
        _snack('Act recorded successfully!');
        setState(() {
          _photo = null;
          _selectedSlug = null;
          _descriptionController.clear();
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
    final categorySelected = _selectedSlug != null;
    final photoTaken = _photo != null;
    final descriptionFilled = _descriptionController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Log Act'), backgroundColor: Colors.white),
      body: RefreshIndicator(
        onRefresh: () async {
          // Force fetch from API and update cache
          try {
            final config = await getSystemConfig();
            debugPrint('[config] refreshed: ${config.categories.length} categories');
            await SystemConfigStorage.save(config);
            if (mounted) setState(() => _categories = config.categories);
          } catch (e) {
            debugPrint('[config] refresh error: $e');
            _snack('Could not refresh categories');
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Category dropdown ────────────────────────────────────────
              const Text(
                'CATEGORY',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),
              _categoriesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedSlug != null ? const Color(0xFF22c55e) : const Color(0xFFdddddd),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedSlug,
                        hint: const Text('Select a category'),
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: _categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat.slug,
                            child: Text(cat.name),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedSlug = val),
                      ),
                    ),

              const SizedBox(height: 28),

              // ── Camera box ───────────────────────────────────────────────
              const Text(
                'PHOTO',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: categorySelected ? _pickPhoto : null,
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: categorySelected ? const Color(0xFFfafafa) : const Color(0xFFf0f0f0),
                    border: Border.all(
                      color: categorySelected ? const Color(0xFFdddddd) : const Color(0xFFe5e5e5),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _photo != null
                      ? Image.file(File(_photo!.path), fit: BoxFit.cover)
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 36,
                                color: categorySelected ? Colors.grey : const Color(0xFFcccccc),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                categorySelected ? 'Tap to take photo' : 'Select a category first',
                                style: TextStyle(
                                  color: categorySelected ? Colors.grey : const Color(0xFFcccccc),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Description ──────────────────────────────────────────────
              const Text(
                'DESCRIPTION',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                enabled: photoTaken,
                maxLines: 3,
                maxLength: 280,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: photoTaken ? 'Describe your act...' : 'Take a photo first',
                  hintStyle: TextStyle(color: photoTaken ? Colors.grey : const Color(0xFFcccccc)),
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
                  fillColor: photoTaken ? const Color(0xFFfafafa) : const Color(0xFFf0f0f0),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),

              const SizedBox(height: 16),

              // ── Submit ───────────────────────────────────────────────────
              ElevatedButton(
                onPressed: (_loading || !categorySelected || !photoTaken || !descriptionFilled) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22c55e),
                  disabledBackgroundColor: const Color(0xFFd1d5db),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Submit Act', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
