import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_scanner_app/models/scanned_document.dart';
import 'package:pdf_scanner_app/providers/service_providers.dart';
import 'package:uuid/uuid.dart';

final documentListProvider =
    AsyncNotifierProvider<DocumentListNotifier, List<ScannedDocument>>(
      DocumentListNotifier.new,
    );

class DocumentListNotifier extends AsyncNotifier<List<ScannedDocument>> {
  final _uuid = const Uuid();

  @override
  Future<List<ScannedDocument>> build() async {
    final repository = ref.read(documentRepositoryProvider);
    return repository.loadDocuments();
  }

  Future<void> addDocument({
    required String title,
    required String pdfPath,
    required int pageCount,
  }) async {
    final current = state.valueOrNull ?? const <ScannedDocument>[];
    final item = ScannedDocument(
      id: _uuid.v4(),
      title: title,
      pdfPath: pdfPath,
      createdAt: DateTime.now(),
      pageCount: pageCount,
    );

    final next = [item, ...current];
    state = AsyncData(next);
    await ref.read(documentRepositoryProvider).saveDocuments(next);
  }

  Future<void> rename({required String id, required String title}) async {
    final current = state.valueOrNull ?? const <ScannedDocument>[];
    final next = [
      for (final doc in current)
        if (doc.id == id) doc.copyWith(title: title) else doc,
    ];
    state = AsyncData(next);
    await ref.read(documentRepositoryProvider).saveDocuments(next);
  }

  Future<void> removeById(String id) async {
    final current = state.valueOrNull ?? const <ScannedDocument>[];
    ScannedDocument? doc;
    for (final item in current) {
      if (item.id == id) {
        doc = item;
        break;
      }
    }
    final next = current.where((item) => item.id != id).toList(growable: false);

    state = AsyncData(next);
    final repo = ref.read(documentRepositoryProvider);
    await repo.saveDocuments(next);
    if (doc != null) {
      await repo.deleteDocumentFile(doc.pdfPath);
    }
  }
}
