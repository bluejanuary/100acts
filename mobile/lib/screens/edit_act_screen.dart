import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/act.dart';
import '../models/system_config.dart';
import '../services/api.dart';
import '../services/system_config_storage.dart';

const _kGreen = Color(0xFF22c55e);
const int _maxPhotos = 5;

class EditActScreen extends StatefulWidget {
  final Act act;
  const EditActScreen({super.key, required this.act});

  @override
  State<EditActScreen> createState() => _EditActScreenState();
}

class _EditActScreenState extends State<EditActScreen> {
  List<CategoryConfig> _categories = [];
  bool _categoriesLoading = true;
  late String? _selectedSlug;
  late TextEditingController _descriptionController;

  // Existing photo URLs (can be removed)
  late List<String> _existingUrls;
  // Newly added local photos (to be uploaded)
  final List<XFile> _newPhotos = [];

  bool _loading = false;
  String _uploadProgress = '';

  int get _totalPhotoCount => _existingUrls.length + _newPhotos.length;

  @override
  void initState() {
    super.initState();
    _selectedSlug = widget.act.category;
    _descriptionController = TextEditingController(text: widget.act.description);
    _existingUrls = List<String>.from(widget.act.photoUrls);
    _loadCategories();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      var config = await SystemConfigStorage.get();
      if (config == null || config.categories.isEmpty) {
        config = await getSystemConfig();
        await SystemConfigStorage.save(config);
      }
      if (mounted) setState(() => _categories = config!.categories);
    } catch (_) {
      _snack('Could not load categories');
    } finally {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  Future<void> _pickPhoto() async {
    if (_totalPhotoCount >= _maxPhotos) return;
    final img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
    if (img != null) setState(() => _newPhotos.add(img));
  }

  void _removeExisting(int index) {
    setState(() => _existingUrls.removeAt(index));
  }

  void _removeNew(int index) {
    setState(() => _newPhotos.removeAt(index));
  }

  Future<void> _save() async {
    if (_selectedSlug == null || _descriptionController.text.trim().isEmpty) return;
    if (_totalPhotoCount == 0) {
      _snack('At least one photo is required');
      return;
    }

    setState(() { _loading = true; _uploadProgress = ''; });
    try {
      // Upload any new photos
      final uploadedUrls = <String>[];
      for (int i = 0; i < _newPhotos.length; i++) {
        if (mounted) setState(() => _uploadProgress = 'Uploading photo ${i + 1} of ${_newPhotos.length}...');
        final filename = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final presign = await getPresignedUrl(filename);
        final bytes = await File(_newPhotos[i].path).readAsBytes();
        await uploadToS3(presign['uploadUrl'], bytes);
        uploadedUrls.add(presign['publicUrl']);
      }

      if (mounted) setState(() => _uploadProgress = 'Saving...');

      await updateAct(
        widget.act.id,
        category: _selectedSlug!,
        description: _descriptionController.text.trim(),
        photoUrls: [..._existingUrls, ...uploadedUrls],
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() { _loading = false; _uploadProgress = ''; });
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _sectionHeader(int step, String title, String subtitle, {Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text('$step',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0f172a))),
              Text(subtitle,
                  style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF94a3b8))),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final descFilled = _descriptionController.text.trim().isNotEmpty;
    final canSave = !_loading && _selectedSlug != null && descFilled && _totalPhotoCount > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFf0fdf4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Edit Act',
          style: GoogleFonts.dmSans(
              fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0f172a)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF64748b)),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Section 1: Category ──────────────────────────────────────────
            _card(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(1, 'Category', 'Choose the category that fits'),
                const SizedBox(height: 14),
                _categoriesLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(color: _kGreen, strokeWidth: 2),
                        ),
                      )
                    : _CategoryDropdown(
                        categories: _categories,
                        selectedSlug: _selectedSlug,
                        onChanged: (val) => setState(() => _selectedSlug = val),
                      ),
              ],
            )),

            const SizedBox(height: 16),

            // ── Section 2: Photos ────────────────────────────────────────────
            _card(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  2,
                  'Photos',
                  'Remove or add photos',
                  trailing: Text(
                    '$_totalPhotoCount / $_maxPhotos',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: const Color(0xFF94a3b8), fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 14),
                _EditPhotoGrid(
                  existingUrls: _existingUrls,
                  newPhotos: _newPhotos,
                  maxPhotos: _maxPhotos,
                  onAddPhoto: _pickPhoto,
                  onRemoveExisting: _removeExisting,
                  onRemoveNew: _removeNew,
                ),
              ],
            )),

            const SizedBox(height: 16),

            // ── Section 3: Description ───────────────────────────────────────
            _card(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(3, 'Description', 'Update the details about this act'),
                const SizedBox(height: 14),
                TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  maxLength: 280,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF0f172a)),
                  decoration: InputDecoration(
                    hintText: 'Describe the act...',
                    hintStyle: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFFcbd5e1)),
                    counterStyle: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF94a3b8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFe2e8f0), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFe2e8f0), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _kGreen, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            )),

            const SizedBox(height: 24),

            // ── Save button ──────────────────────────────────────────────────
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: canSave ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  disabledBackgroundColor: const Color(0xFFd1d5db),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                            const SizedBox(height: 4),
                            Text(_uploadProgress,
                                style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white)),
                          ],
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Save Changes',
                              style: GoogleFonts.dmSans(
                                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(width: 10),
                          const Icon(Icons.check_rounded, size: 20, color: Colors.white),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Photo Grid (existing network images + new local files) ────────────────────

class _EditPhotoGrid extends StatelessWidget {
  final List<String> existingUrls;
  final List<XFile> newPhotos;
  final int maxPhotos;
  final VoidCallback onAddPhoto;
  final void Function(int) onRemoveExisting;
  final void Function(int) onRemoveNew;

  const _EditPhotoGrid({
    required this.existingUrls,
    required this.newPhotos,
    required this.maxPhotos,
    required this.onAddPhoto,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  int get _total => existingUrls.length + newPhotos.length;

  @override
  Widget build(BuildContext context) {
    // Build slots: existing photos, then new photos, then add button (if space), then empty slots
    final slots = <Widget>[];

    for (int i = 0; i < existingUrls.length; i++) {
      slots.add(_networkTile(existingUrls[i], () => onRemoveExisting(i)));
    }
    for (int i = 0; i < newPhotos.length; i++) {
      slots.add(_localTile(newPhotos[i], () => onRemoveNew(i)));
    }
    if (_total < maxPhotos) {
      slots.add(_addTile());
    }
    while (slots.length < maxPhotos) {
      slots.add(_emptyTile());
    }

    return Row(
      children: slots.asMap().entries.map((e) {
        final isLast = e.key == maxPhotos - 1;
        return Expanded(
          child: Padding(
            padding: isLast ? EdgeInsets.zero : const EdgeInsets.only(right: 8),
            child: e.value,
          ),
        );
      }).toList(),
    );
  }

  Widget _networkTile(String url, VoidCallback onRemove) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFf1f5f9),
                child: const Icon(Icons.broken_image_outlined,
                    color: Color(0xFFcbd5e1)),
              ),
            ),
          ),
          Positioned(
            top: 3,
            right: 3,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration:
                    const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _localTile(XFile photo, VoidCallback onRemove) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(photo.path),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // "New" indicator
          Positioned(
            bottom: 3,
            left: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('New',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          ),
          Positioned(
            top: 3,
            right: 3,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration:
                    const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addTile() {
    return GestureDetector(
      onTap: onAddPhoto,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFf0fdf4),
            border: Border.all(color: _kGreen.withValues(alpha: 0.5), width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 22, color: _kGreen),
              const SizedBox(height: 4),
              Text('Add',
                  style: GoogleFonts.dmSans(
                      fontSize: 10, color: _kGreen, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyTile() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          border: Border.all(color: const Color(0xFFe2e8f0), width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.image_outlined, size: 20, color: Color(0xFFcbd5e1)),
      ),
    );
  }
}

// ── Category Dropdown ─────────────────────────────────────────────────────────

class _CategoryDropdown extends StatelessWidget {
  final List<CategoryConfig> categories;
  final String? selectedSlug;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.categories,
    required this.selectedSlug,
    required this.onChanged,
  });

  IconData _iconFor(String slug) {
    return switch (slug) {
      'road_street' => Icons.warning_amber_rounded,
      'tree_mangrove' => Icons.park_outlined,
      'wildlife' => Icons.pets_outlined,
      'recycling' => Icons.recycling_outlined,
      'litter_cleanup' => Icons.delete_outline,
      _ => Icons.category_outlined,
    };
  }

  Widget _iconBox(String slug, {bool selected = true}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: selected ? _kGreen : const Color(0xFFf0fdf4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(_iconFor(slug), size: 20,
          color: selected ? Colors.white : const Color(0xFF94a3b8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFe2e8f0), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: selectedSlug,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748b)),
        hint: Row(
          children: [
            _iconBox('_none', selected: false),
            const SizedBox(width: 10),
            Text('Select a category',
                style: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF94a3b8))),
          ],
        ),
        items: categories.map((cat) => DropdownMenuItem(
          value: cat.slug,
          child: Row(
            children: [
              _iconBox(cat.slug),
              const SizedBox(width: 10),
              Text(cat.name,
                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        )).toList(),
        selectedItemBuilder: (_) => categories.map((cat) => Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              _iconBox(cat.slug),
              const SizedBox(width: 10),
              Text(cat.name,
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF0f172a))),
            ],
          ),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
