import 'package:document_scanner_flutter/configs/configs.dart';
import 'package:document_scanner_flutter/document_scanner_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScannerService {
  const ScannerService();

  Future<String?> scanWithCamera(BuildContext context) async {
    try {
      final file = await DocumentScannerFlutter.launch(
        context,
        source: ScannerFileSource.CAMERA,
        labelsConfig: const {
          ScannerLabelsConfig.PICKER_CAMERA_LABEL: 'Camera',
          ScannerLabelsConfig.PICKER_GALLERY_LABEL: 'Gallery',
          ScannerLabelsConfig.PICKER_CANCEL_LABEL: 'Cancel',
        },
      );
      return file?.path;
    } on PlatformException catch (error) {
      throw ScannerException(
        'Could not scan document: ${error.message ?? error.code}',
      );
    }
  }
}

class ScannerException implements Exception {
  final String message;

  const ScannerException(this.message);

  @override
  String toString() => message;
}
