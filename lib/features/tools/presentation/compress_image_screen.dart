import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf_scanner_app/core/theme/app_colors.dart';
import 'package:pdf_scanner_app/providers/service_providers.dart';

class CompressImageScreen extends ConsumerStatefulWidget {
  const CompressImageScreen({super.key});

  @override
  ConsumerState<CompressImageScreen> createState() => _CompressImageScreenState();
}

class _CompressImageScreenState extends ConsumerState<CompressImageScreen> {
  String? _selectedPath;
  Uint8List? _compressedBytes;
  bool _isProcessing = false;
  int _originalSize = 0;
  int _compressedSize = 0;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final size = await file.length();
      setState(() {
        _selectedPath = result.files.single.path;
        _originalSize = size;
        _compressedBytes = null;
        _compressedSize = 0;
      });
      _compress();
    }
  }

  Future<void> _compress() async {
    if (_selectedPath == null) return;

    setState(() => _isProcessing = true);

    try {
      final imageService = ref.read(imageProcessingServiceProvider);
      final rawBytes = await File(_selectedPath!).readAsBytes();
      
      // We'll use the existing preparePage which compresses
      final compressed = await imageService.preparePage(rawBytes, grayscale: false);
      
      setState(() {
        _compressedBytes = compressed;
        _compressedSize = compressed.length;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Compression failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _save() async {
    if (_compressedBytes == null) return;

    try {
      final repository = ref.read(documentRepositoryProvider);
      final name = 'Compressed_${DateTime.now().millisecondsSinceEpoch}';
      final path = await repository.saveImage(
        bytes: _compressedBytes!,
        suggestedName: name,
        extension: 'jpg',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compress Image', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageDisplay(),
            const SizedBox(height: 32),
            if (_selectedPath != null) _buildStats(),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickImage,
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('SELECT IMAGE'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
            if (_compressedBytes != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _save,
                icon: const Icon(Icons.save_rounded),
                label: const Text('SAVE COMPRESSED IMAGE'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceLight, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: _selectedPath == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_search_rounded, size: 64, color: AppColors.surfaceLight),
                  const SizedBox(height: 16),
                  Text('No image selected', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
                ],
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.file(File(_selectedPath!), fit: BoxFit.contain),
                if (_isProcessing)
                  Container(
                    color: Colors.black45,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }

  Widget _buildStats() {
    final reduction = _originalSize > 0 && _compressedSize > 0
        ? ((_originalSize - _compressedSize) / _originalSize * 100).toInt()
        : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatRow('Original Size', _formatSize(_originalSize)),
            const Divider(height: 24),
            _buildStatRow('Compressed Size', _isProcessing ? '...' : _formatSize(_compressedSize)),
            if (!_isProcessing && _compressedSize > 0) ...[
              const Divider(height: 24),
              _buildStatRow('Reduction', '$reduction%', isHighlight: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isHighlight ? AppColors.secondary : null,
          ),
        ),
      ],
    );
  }
}
