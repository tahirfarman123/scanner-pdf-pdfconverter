import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
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

enum OutputFormat { pdf, pdfText, word, jpg, png }

class ScannerScreen extends ConsumerStatefulWidget {
  final OutputFormat? initialFormat;
  const ScannerScreen({super.key, this.initialFormat});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final TextEditingController _titleController = TextEditingController();
  bool _busy = false;
  bool _grayscale = true;
  late OutputFormat _outputFormat;
  List<String> _imagePaths = const [];

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Scan ${DateTime.now().millisecondsSinceEpoch}';
    _outputFormat = widget.initialFormat ?? OutputFormat.pdf;
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

  Future<void> _finalizeDocument() async {
    if (_imagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one page first.')),
      );
      return;
    }

    setState(() => _busy = true);
    debugPrint('ScannerScreen: Starting document generation in $_outputFormat format.');

    try {
      final imageService = ref.read(imageProcessingServiceProvider);
      final repository = ref.read(documentRepositoryProvider);
      final title = _titleController.text.trim().isEmpty ? 'Scan' : _titleController.text.trim();
      String savedPath = '';

      if (_outputFormat == OutputFormat.pdf) {
        final pdfService = ref.read(pdfServiceProvider);
        final pages = <Uint8List>[];
        for (final path in _imagePaths) {
          final raw = await File(path).readAsBytes();
          final prepared = await imageService.preparePage(raw, grayscale: _grayscale);
          pages.add(prepared);
        }
        final pdfBytes = await pdfService.imagesToPdf(pages);
        savedPath = await repository.savePdf(bytes: pdfBytes, suggestedName: title);
      } else if (_outputFormat == OutputFormat.pdfText) {
        final pdfService = ref.read(pdfServiceProvider);
        final ocrService = ref.read(ocrServiceProvider);

        final buffer = StringBuffer();
        for (final path in _imagePaths) {
          final text = await ocrService.extractText(path);
          buffer.writeln(text);
          buffer.writeln('\n');
        }

        final pdfBytes = await pdfService.textToPdf(buffer.toString());
        savedPath = await repository.savePdf(bytes: pdfBytes, suggestedName: title);
      } else if (_outputFormat == OutputFormat.word) {
        final wordService = ref.read(wordServiceProvider);
        final pages = <Uint8List>[];
        for (final path in _imagePaths) {
          final raw = await File(path).readAsBytes();
          final prepared = await imageService.preparePage(raw, grayscale: _grayscale);
          pages.add(prepared);
        }
        final wordBytes = await wordService.imagesToWord(pages);
        savedPath = await repository.saveWord(bytes: wordBytes, suggestedName: title);
      } else {
        // Save as Image (takes first page for simplicity in this version)
        final formatStr = _outputFormat == OutputFormat.jpg ? 'jpg' : 'png';
        final raw = await File(_imagePaths.first).readAsBytes();
        final prepared = await imageService.preparePage(raw, grayscale: _grayscale, format: formatStr);
        savedPath = await repository.saveImage(
          bytes: prepared,
          suggestedName: title,
          extension: formatStr,
        );
      }

      await ref.read(documentListProvider.notifier).addDocument(
            title: title,
            pdfPath: savedPath,
            pageCount: (_outputFormat == OutputFormat.pdf || _outputFormat == OutputFormat.pdfText) ? _imagePaths.length : 1,
          );

      if (!mounted) return;

      context.go('${AppRoutes.home}preview?path=${Uri.encodeComponent(savedPath)}');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create document: $error')));
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
            _buildSectionLabel('OUTPUT FORMAT'),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FormatChip(
                    label: 'Image PDF',
                    icon: Icons.picture_as_pdf_rounded,
                    selected: _outputFormat == OutputFormat.pdf,
                    onTap: () => setState(() => _outputFormat = OutputFormat.pdf),
                  ),
                  const SizedBox(width: 8),
                  _FormatChip(
                    label: 'Text PDF',
                    icon: Icons.text_snippet_rounded,
                    selected: _outputFormat == OutputFormat.pdfText,
                    onTap: () => setState(() => _outputFormat = OutputFormat.pdfText),
                  ),
                  const SizedBox(width: 8),
                  _FormatChip(
                    label: 'Word Doc',
                    icon: Icons.description_rounded,
                    selected: _outputFormat == OutputFormat.word,
                    onTap: () => setState(() => _outputFormat = OutputFormat.word),
                  ),
                  const SizedBox(width: 8),
                  _FormatChip(
                    label: 'JPG Image',
                    icon: Icons.image_rounded,
                    selected: _outputFormat == OutputFormat.jpg,
                    onTap: () => setState(() => _outputFormat = OutputFormat.jpg),
                  ),
                  const SizedBox(width: 8),
                  _FormatChip(
                    label: 'PNG Image',
                    icon: Icons.camera_rounded,
                    selected: _outputFormat == OutputFormat.png,
                    onTap: () => setState(() => _outputFormat = OutputFormat.png),
                  ),
                ],
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
                        icon: Icons.text_fields_rounded,
                        color: Colors.deepPurple,
                        onTap: () => _runOcr(index),
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

  Future<void> _runOcr(int index) async {
    final path = _imagePaths[index];
    setState(() => _busy = true);

    try {
      final ocrService = ref.read(ocrServiceProvider);
      final text = await ocrService.extractText(path);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Extracted Text'),
          content: SingleChildScrollView(
            child: SelectableText(text),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OCR Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
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
        onPressed: _busy || _imagePaths.isEmpty ? null : _finalizeDocument,
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
          _busy ? 'ALCHEMIZING...' : 'GENERATE ${_outputFormat.name.toUpperCase()}',
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

class _FormatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FormatChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.surfaceLight,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : AppColors.surfaceLight,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
