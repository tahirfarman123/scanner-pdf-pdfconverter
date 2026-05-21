import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  Future<Uint8List> imagesToPdf(List<Uint8List> pages) async {
    debugPrint('PdfService: Starting conversion of ${pages.length} pages...');
    final doc = pw.Document();

    for (int i = 0; i < pages.length; i++) {
      debugPrint('PdfService: Processing page ${i + 1}...');
      final image = pw.MemoryImage(pages[i]);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    debugPrint('PdfService: Saving document...');
    final result = await doc.save();
    debugPrint('PdfService: Conversion complete. Size: ${result.length} bytes');
    return result;
  }

  Future<Uint8List> textToPdf(String text) async {
    debugPrint('PdfService: Starting text-to-pdf conversion...');
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Paragraph(
            text: text,
            style: pw.TextStyle(
              fontSize: 12,
              lineSpacing: 2,
            ),
          ),
        ],
      ),
    );

    debugPrint('PdfService: Saving text document...');
    final result = await doc.save();
    debugPrint('PdfService: Text conversion complete. Size: ${result.length} bytes');
    return result;
  }
}
