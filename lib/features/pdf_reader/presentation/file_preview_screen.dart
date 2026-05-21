import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:docx_file_viewer/docx_file_viewer.dart';

class FilePreviewScreen extends StatelessWidget {
  const FilePreviewScreen({super.key, required this.filePath});

  final String? filePath;

  @override
  Widget build(BuildContext context) {
    final path = filePath;

    final isPdf = path != null && path.toLowerCase().endsWith('.pdf');
    final isWord = path != null && (path.toLowerCase().endsWith('.docx') || path.toLowerCase().endsWith('.doc'));
    final isImage = path != null && (path.toLowerCase().endsWith('.jpg') || path.toLowerCase().endsWith('.jpeg') || path.toLowerCase().endsWith('.png'));

    String title = 'File Preview';
    if (isPdf) title = 'PDF Viewer';
    else if (isWord) title = 'Word Document';
    else if (isImage) title = 'Image Preview';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      body: path == null || path.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No file found.',
                  style: GoogleFonts.outfit(),
                ),
              ),
            )
          : _buildPreview(context, path, isPdf, isWord, isImage),
    );
  }

  Widget _buildPreview(BuildContext context, String path, bool isPdf, bool isWord, bool isImage) {
    if (isPdf) {
      return SfPdfViewer.file(File(path));
    }

    if (isWord) {
      return DocxFileViewer(filePath: path);
    }

    if (isImage) {
      return Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(path),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _buildErrorState('Failed to load image.'),
          ),
        ),
      );
    }

    // Fallback for other files (maybe text?)
    return FutureBuilder<String>(
      future: File(path).readAsString(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              snapshot.data!,
              style: GoogleFonts.firaCode(fontSize: 14),
            ),
          );
        }
        return _buildErrorState('Unsupported file format for preview.');
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
