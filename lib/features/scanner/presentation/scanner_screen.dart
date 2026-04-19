import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf_scanner_app/core/router/app_router.dart';
import 'package:pdf_scanner_app/core/theme/app_colors.dart';
import 'package:pdf_scanner_app/providers/document_list_provider.dart';
import 'package:pdf_scanner_app/providers/service_providers.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final TextEditingController _titleController = TextEditingController();
  bool _busy = false;
  bool _grayscale = true;
  List<String> _imagePaths = const [];

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Scan ${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final allowed = await _ensureMediaPermission();
    if (!allowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media permission is required to pick images.')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final paths = result.files.map((file) => file.path).whereType<String>().toList(growable: false);

    setState(() {
      _imagePaths = [..._imagePaths, ...paths];
    });
  }

  Future<void> _scanWithCamera() async {
    final allowed = await Permission.camera.request();
    if (!allowed.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required to scan documents.')),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      if (!mounted) return;
      final scannerService = ref.read(scannerServiceProvider);
      final scannedPath = await scannerService.scanWithCamera(context);
      if (scannedPath == null || scannedPath.isEmpty) {
        return;
      }

      setState(() {
        _imagePaths = [..._imagePaths, scannedPath];
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<bool> _ensureMediaPermission() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    }

    if (Platform.isAndroid) {
      final photos = await Permission.photos.request();
      if (photos.isGranted) return true;
      final storage = await Permission.storage.request();
      return storage.isGranted;
    }

    return true;
  }

  void _removeAt(int index) {
    setState(() {
      _imagePaths = [
        for (int i = 0; i < _imagePaths.length; i++)
          if (i != index) _imagePaths[i],
      ];
    });
  }

  Future<void> _createPdf() async {
    if (_imagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one page first.')),
      );
      return;
    }

    setState(() => _busy = true);
    debugPrint('ScannerScreen: Starting PDF generation with ${_imagePaths.length} pages.');

    try {
      final imageService = ref.read(imageProcessingServiceProvider);
      final pdfService = ref.read(pdfServiceProvider);
      final repository = ref.read(documentRepositoryProvider);

      final pages = <Uint8List>[];
      for (final path in _imagePaths) {
        final raw = await File(path).readAsBytes();
        final prepared = await imageService.preparePage(raw, grayscale: _grayscale);
        pages.add(prepared);
      }

      final pdfBytes = await pdfService.imagesToPdf(pages);
      final title = _titleController.text.trim().isEmpty ? 'Scan' : _titleController.text.trim();
      final savedPath = await repository.savePdf(bytes: pdfBytes, suggestedName: title);

      await ref.read(documentListProvider.notifier).addDocument(
            title: title,
            pdfPath: savedPath,
            pageCount: _imagePaths.length,
          );

      if (!mounted) return;

      context.go('${AppRoutes.home}preview?path=${Uri.encodeComponent(savedPath)}');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create PDF: $error')));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanning Studio'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('DOCUMENT DETAILS'),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                labelText: 'Document title',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionLabel('PREFERENCES'),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                value: _grayscale,
                title: Text(
                  'Grayscale Enhancement',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Optimizes readability for documents.',
                  style: GoogleFonts.outfit(fontSize: 12),
                ),
                onChanged: _busy ? null : (value) => setState(() => _grayscale = value),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionLabel('PAGES (${_imagePaths.length})'),
            const SizedBox(height: 12),
            _buildActionButtons(),
            const SizedBox(height: 20),
            _imagePaths.isEmpty ? _buildEmptyPreview() : _buildPagesPreview(),
            const SizedBox(height: 40),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _pickImages,
            icon: const Icon(Icons.collections_rounded),
            label: const Text('Import'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _scanWithCamera,
            icon: const Icon(Icons.camera_rounded),
            label: const Text('Camera'),
          ),
        ),
      ],
    );
  }

  Widget _buildPagesPreview() {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _imagePaths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final path = _imagePaths[index];
          return Container(
            width: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceLight, width: 2),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(File(path), fit: BoxFit.cover, width: 120, height: 180),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ThumbnailAction(
                        icon: Icons.edit_note_rounded,
                        color: AppColors.primary,
                        onTap: () => _editPage(index),
                      ),
                      const SizedBox(width: 4),
                      _ThumbnailAction(
                        icon: Icons.close_rounded,
                        color: AppColors.error,
                        onTap: () => _removeAt(index),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PAGE ${index + 1}',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _editPage(int index) async {
    debugPrint('ScannerScreen: Launching editor for page $index');
    final path = _imagePaths[index];
    final bytes = await File(path).readAsBytes();

    if (!mounted) return;

    final edited = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditor(
          image: bytes,
        ),
      ),
    );

    if (edited != null && edited is Uint8List) {
      debugPrint('ScannerScreen: Page $index edited successfully.');
      final newPath = '${path}_edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(newPath).writeAsBytes(edited);
      setState(() {
        final updated = [..._imagePaths];
        updated[index] = newPath;
        _imagePaths = updated;
      });
    }
  }

  Widget _buildEmptyPreview() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, color: AppColors.surfaceLight, size: 48),
          const SizedBox(height: 12),
          Text(
            'No pages scanned yet.',
            style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _busy || _imagePaths.isEmpty ? null : _createPdf,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
        ),
        icon: _busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
              )
            : const Icon(Icons.auto_fix_high_rounded),
        label: Text(
          _busy ? 'ALCHEMIZING PDF...' : 'GENERATE PREMIUM PDF',
          style: GoogleFonts.outfit(letterSpacing: 1.1, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ThumbnailAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ThumbnailAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }
}
