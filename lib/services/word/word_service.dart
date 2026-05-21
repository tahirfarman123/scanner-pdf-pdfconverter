import 'dart:typed_data';
import 'package:docx_creator/docx_creator.dart';
import 'package:flutter/foundation.dart';

class WordService {
  Future<Uint8List> imagesToWord(List<Uint8List> pages) async {
    debugPrint('WordService: Starting conversion of ${pages.length} pages...');
    
    final builder = docx();
    
    // Set some default section properties for a4
    builder.section(
      pageSize: DocxPageSize.a4,
      marginTop: 720, // 0.5 inch (720 twentieths of a point)
      marginBottom: 720,
      marginLeft: 720,
      marginRight: 720,
    );

    for (int i = 0; i < pages.length; i++) {
      debugPrint('WordService: Processing page ${i + 1}...');
      
      // Add image to builder
      // We use center alignment for better look
      builder.image(
        DocxImage(
          bytes: pages[i],
          extension: 'jpg',
          width: 450, // width in points, ~6.25 inches
          height: 600, // height in points, ~8.3 inches
          align: DocxAlign.center,
        ),
      );
      
      // Add page break after each page except the last one
      if (i < pages.length - 1) {
        builder.pageBreak();
      }
    }

    debugPrint('WordService: Building document...');
    final built = builder.build();
    
    debugPrint('WordService: Exporting to bytes...');
    final exporter = DocxExporter();
    final result = await exporter.exportToBytes(built);
    
    debugPrint('WordService: Conversion complete. Size: ${result.length} bytes');
    return result;
  }

  Future<Uint8List> textToWord(String text, String title) async {
    final builder = docx()
      .h1(title)
      .p(text);
      
    final built = builder.build();
    final exporter = DocxExporter();
    return await exporter.exportToBytes(built);
  }
}
