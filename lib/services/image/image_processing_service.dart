import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

class ImageProcessingService {
  Future<Uint8List> preparePage(Uint8List input, {bool grayscale = false}) async {
    Uint8List transformed = input;

    final decoded = img.decodeImage(input);
    if (decoded != null) {
      final processed = grayscale ? img.grayscale(decoded) : decoded;
      transformed = Uint8List.fromList(img.encodeJpg(processed, quality: 92));
    }

    final compressed = await FlutterImageCompress.compressWithList(
      transformed,
      quality: 80,
      format: CompressFormat.jpeg,
      minWidth: 1600,
      minHeight: 1600,
    );

    return compressed;
  }
}
