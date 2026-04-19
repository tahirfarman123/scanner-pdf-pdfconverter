import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf_scanner_app/core/router/app_router.dart';
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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Media permission is required to pick images.'),
        ),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final paths = result.files
        .map((file) => file.path)
        .whereType<String>()
        .toList(growable: false);

    setState(() {
      _imagePaths = paths;
    });
  }

  Future<void> _scanWithCamera() async {
    final allowed = await Permission.camera.request();
    if (!allowed.isGranted) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission is required to scan documents.'),
        ),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      if (!mounted) {
        return;
      }
      final scannerService = ref.read(scannerServiceProvider);
      final scannedPath = await scannerService.scanWithCamera(context);
      if (scannedPath == null || scannedPath.isEmpty) {
        return;
      }

      setState(() {
        _imagePaths = [..._imagePaths, scannedPath];
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
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
      if (photos.isGranted) {
        return true;
      }
      final storage = await Permission.storage.request();
      return storage.isGranted;
    }

    return true;
  }

  Future<void> _createPdf() async {
    if (_imagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one page first.')),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      final imageService = ref.read(imageProcessingServiceProvider);
      final pdfService = ref.read(pdfServiceProvider);
      final repository = ref.read(documentRepositoryProvider);

      final pages = <Uint8List>[];
      for (final path in _imagePaths) {
        final raw = await File(path).readAsBytes();
        final prepared = await imageService.preparePage(
          raw,
          grayscale: _grayscale,
        );
        pages.add(prepared);
      }

      final pdfBytes = await pdfService.imagesToPdf(pages);
      final title = _titleController.text.trim().isEmpty
          ? 'Scan'
          : _titleController.text.trim();
      final savedPath = await repository.savePdf(
        bytes: pdfBytes,
        suggestedName: title,
      );

      await ref
          .read(documentListProvider.notifier)
          .addDocument(
            title: title,
            pdfPath: savedPath,
            pageCount: _imagePaths.length,
          );

      if (!mounted) {
        return;
      }

      context.go(
        '${AppRoutes.home}preview?path=${Uri.encodeComponent(savedPath)}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not create PDF: $error')));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Document title'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _grayscale,
            title: const Text('Apply grayscale enhancement'),
            subtitle: const Text(
              'Improves readability for receipts and paperwork.',
            ),
            onChanged: _busy
                ? null
                : (value) => setState(() => _grayscale = value),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _busy ? null : _pickImages,
            icon: const Icon(Icons.collections_outlined),
            label: const Text('Pick document images'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _scanWithCamera,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Scan with camera'),
          ),
          const SizedBox(height: 12),
          Text('Selected pages: ${_imagePaths.length}'),
          const SizedBox(height: 8),
          if (_imagePaths.isNotEmpty)
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final path = _imagePaths[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(path),
                      width: 120,
                      fit: BoxFit.cover,
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemCount: _imagePaths.length,
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : _createPdf,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Generate PDF'),
          ),
        ],
      ),
    );
  }
}
