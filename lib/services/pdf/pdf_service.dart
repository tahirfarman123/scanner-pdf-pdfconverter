import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  Future<Uint8List> imagesToPdf(List<Uint8List> pages) async {
    final doc = pw.Document();

    for (final page in pages) {
      final image = pw.MemoryImage(page);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    return doc.save();
  }
}
