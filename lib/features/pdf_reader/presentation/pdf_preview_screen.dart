import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({super.key, required this.filePath});

  final String? filePath;

  @override
  Widget build(BuildContext context) {
    final path = filePath;

    return Scaffold(
      appBar: AppBar(title: const Text('PDF Preview')),
      body: path == null || path.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No PDF path found. Generate and save a PDF first.',
                ),
              ),
            )
          : SfPdfViewer.file(File(path)),
    );
  }
}
