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
    final allowed = await _ensureMediaPermission();
    if (!allowed) {
      if (!mounted) {
        return;
      }
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
      return;
    }

    final paths = result.files
        .map((file) => file.path)
        .whereType<String>()
        .toList(growable: false);

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
      if (photos.isGranted) {
        return true;
      }
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
      final title = _titleController.text.trim().isEmpty
          ? 'Converted document'
          : _titleController.text.trim();
      final savedPath = await repository.savePdf(bytes: pdfBytes, suggestedName: title);

      await ref
          .read(documentListProvider.notifier)
          .addDocument(title: title, pdfPath: savedPath, pageCount: _imagePaths.length);

      if (!mounted) {
        return;
      }

      context.go('${AppRoutes.home}preview?path=${Uri.encodeComponent(savedPath)}');
    } catch (error) {
      if (!mounted) {
        return;
      }
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
      appBar: AppBar(title: const Text('Converter')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
              onChanged: _busy ? null : (value) => setState(() => _grayscale = value),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _pickImages,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Add images'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Pages (${_imagePaths.length}) - drag to reorder'),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _imagePaths.isEmpty
                  ? const Center(child: Text('No pages selected yet.'))
                  : ReorderableListView.builder(
                      onReorder: _reorder,
                      itemBuilder: (context, index) {
                        final path = _imagePaths[index];
                        return Card(
                          key: ValueKey('$path-$index'),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(path),
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text('Page ${index + 1}'),
                            subtitle: Text(path.split(Platform.pathSeparator).last),
                            trailing: IconButton(
                              onPressed: _busy ? null : () => _removeAt(index),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ),
                        );
                      },
                      itemCount: _imagePaths.length,
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _generatePdf,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Generate PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
