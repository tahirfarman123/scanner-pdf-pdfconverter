import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({super.key, required this.filePath});

  final String? filePath;

  @override
  Widget build(BuildContext context) {
    final path = filePath;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Document Preview',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      body: path == null || path.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No PDF path found. Generate and save a PDF first.',
                  style: GoogleFonts.outfit(),
                ),
              ),
            )
          : SfPdfViewer.file(File(path)),
    );
  }
}
