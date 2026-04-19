import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf_scanner_app/core/router/app_router.dart';
import 'package:pdf_scanner_app/core/theme/app_colors.dart';
import 'package:pdf_scanner_app/providers/document_list_provider.dart';
import 'package:pdf_scanner_app/providers/service_providers.dart';

class ConverterScreen extends ConsumerStatefulWidget {
  const ConverterScreen({super.key});

  @override
  ConsumerState<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends ConsumerState<ConverterScreen> {
  final TextEditingController _titleController = TextEditingController();
  bool _busy = false;
  bool _grayscale = false;
  List<String> _imagePaths = const [];

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Converted ${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    debugPrint('ConverterScreen: Picking images...');
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

    if (result == null || result.files.isEmpty) {
      debugPrint('ConverterScreen: No images selected.');
      return;
    }

    final paths = result.files.map((file) => file.path).whereType<String>().toList(growable: false);
    debugPrint('ConverterScreen: Added ${paths.length} images.');

    setState(() {
      _imagePaths = [..._imagePaths, ...paths];
    });
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

  Future<void> _editPage(int index) async {
    debugPrint('ConverterScreen: Launching editor for page $index');
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
      debugPrint('ConverterScreen: Page $index edited successfully.');
      final newPath = '${path}_edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(newPath).writeAsBytes(edited);
      setState(() {
        final updated = [..._imagePaths];
        updated[index] = newPath;
        _imagePaths = updated;
      });
    }
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final updated = [..._imagePaths];
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = updated.removeAt(oldIndex);
      updated.insert(newIndex, item);
      _imagePaths = updated;
    });
  }

  Future<void> _generatePdf() async {
    if (_imagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick images before converting.')),
      );
      return;
    }

    setState(() => _busy = true);
    debugPrint('ConverterScreen: Generating PDF with ${_imagePaths.length} pages...');

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
      final title = _titleController.text.trim().isEmpty ? 'Converted' : _titleController.text.trim();
      final savedPath = await repository.savePdf(bytes: pdfBytes, suggestedName: title);

      await ref
          .read(documentListProvider.notifier)
          .addDocument(title: title, pdfPath: savedPath, pageCount: _imagePaths.length);

      if (!mounted) return;

      context.go('${AppRoutes.home}preview?path=${Uri.encodeComponent(savedPath)}');
    } catch (error) {
      debugPrint('ConverterScreen: ERROR: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF conversion failed: $error')),
      );
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
        title: const Text('PDF Converter'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: Padding(
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
                onChanged: _busy ? null : (value) => setState(() => _grayscale = value),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionLabel('MANAGE PAGES (${_imagePaths.length})'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _pickImages,
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: const Text('Add Images to Queue'),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _imagePaths.isEmpty ? _buildEmptyState() : _buildReorderableList(),
            ),
            const SizedBox(height: 12),
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.collections_rounded, color: AppColors.surfaceLight, size: 64),
          const SizedBox(height: 16),
          Text(
            'Queue is empty.',
            style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableList() {
    return ReorderableListView.builder(
      onReorder: _reorder,
      itemBuilder: (context, index) {
        final path = _imagePaths[index];
        return Card(
          key: ValueKey('$path-$index'),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(File(path), width: 50, height: 50, fit: BoxFit.cover),
            ),
            title: Text(
              'Page ${index + 1}',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              path.split(Platform.pathSeparator).last,
              style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _busy ? null : () => _editPage(index),
                  icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                ),
                IconButton(
                  onPressed: _busy ? null : () => _removeAt(index),
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                ),
              ],
            ),
          ),
        );
      },
      itemCount: _imagePaths.length,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _busy || _imagePaths.isEmpty ? null : _generatePdf,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
        ),
        icon: _busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
              )
            : const Icon(Icons.picture_as_pdf_rounded),
        label: Text(
          _busy ? 'CONVERTING...' : 'CONVERT TO PDF',
          style: GoogleFonts.outfit(letterSpacing: 1.1, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

