import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_scanner_app/services/pdf/pdf_service.dart';
import 'package:pdf_scanner_app/services/scanner/scanner_service.dart';
import 'package:pdf_scanner_app/services/storage/document_repository.dart';
import 'package:pdf_scanner_app/services/storage/local_storage_service.dart';
import 'package:pdf_scanner_app/services/image/image_processing_service.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(ref.read(localStorageServiceProvider));
});

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});

final imageProcessingServiceProvider = Provider<ImageProcessingService>((ref) {
  return ImageProcessingService();
});

final scannerServiceProvider = Provider<ScannerService>((ref) {
  return const ScannerService();
});
