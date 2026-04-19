import 'package:document_scanner_flutter/configs/configs.dart';
import 'package:document_scanner_flutter/document_scanner_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScannerService {
  const ScannerService();

  Future<String?> scanWithCamera(BuildContext context) async {
    debugPrint('ScannerService: Launching camera scanner...');
    try {
      final file = await DocumentScannerFlutter.launch(
        context,
        source: ScannerFileSource.CAMERA,
        // Removed labelsConfig to prevent NoSuchMethodError on certain versions
      );
      
      if (file != null) {
        debugPrint('ScannerService: Scan successful. Path: ${file.path}');
      } else {
        debugPrint('ScannerService: Scan cancelled by user.');
      }
      
      return file?.path;
    } on PlatformException catch (e, stack) {
      debugPrint('ScannerService: PLATFORM ERROR: $e');
      debugPrint('ScannerService: STACK TRACE: $stack');
      throw ScannerException(
        'Could not scan document: ${e.message ?? e.code}',
      );
    } catch (e, stack) {
      debugPrint('ScannerService: UNKNOWN ERROR: $e');
      debugPrint('ScannerService: STACK TRACE: $stack');
      rethrow;
    }
  }
}

class ScannerException implements Exception {
  final String message;

  const ScannerException(this.message);

  @override
  String toString() => message;
}
