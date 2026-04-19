import 'dart:io';
import 'dart:typed_data';

import 'package:pdf_scanner_app/models/scanned_document.dart';
import 'package:pdf_scanner_app/services/storage/local_storage_service.dart';

class DocumentRepository {
  DocumentRepository(this._storage);

  static const _indexName = 'documents_index.json';

  final LocalStorageService _storage;

  Future<List<ScannedDocument>> loadDocuments() async {
    final indexFile = await _storage.fileInScans(_indexName);
    if (!await indexFile.exists()) {
      return const [];
    }

    final raw = await indexFile.readAsString();
    return ScannedDocument.decodeList(raw);
  }

  Future<void> saveDocuments(List<ScannedDocument> docs) async {
    await _storage.writeText(fileName: _indexName, contents: ScannedDocument.encodeList(docs));
  }

  Future<String> savePdf({required Uint8List bytes, required String suggestedName}) async {
    final safeBase = _sanitizeFileName(suggestedName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${safeBase}_$timestamp.pdf';
    final file = await _storage.writeBytes(fileName: fileName, bytes: bytes);
    return file.path;
  }

  Future<void> deleteDocumentFile(String path) async {
    if (path.isEmpty) {
      return;
    }

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  String _sanitizeFileName(String input) {
    final cleaned = input
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    if (cleaned.isEmpty) {
      return 'scan';
    }

    return cleaned;
  }
}
