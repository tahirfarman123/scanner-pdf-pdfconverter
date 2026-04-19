import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf_scanner_app/core/constants/app_strings.dart';
import 'package:pdf_scanner_app/core/router/app_router.dart';
import 'package:pdf_scanner_app/core/utils/date_formatters.dart';
import 'package:pdf_scanner_app/models/scanned_document.dart';
import 'package:pdf_scanner_app/providers/document_list_provider.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            onPressed: () => context.push('${AppRoutes.home}settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: docsAsync.when(
        data: (docs) {
          if (docs.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              return Card(
                child: ListTile(
                  title: Text(doc.title),
                  subtitle: Text(
                    '${doc.pageCount} pages | ${DateFormatters.compact(doc.createdAt)}',
                  ),
                  onTap: () => context.push(
                    '${AppRoutes.home}preview?path=${Uri.encodeComponent(doc.pdfPath)}',
                  ),
                  trailing: PopupMenuButton<_DocMenuAction>(
                    onSelected: (action) => _handleAction(context, ref, doc, action),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _DocMenuAction.share,
                        child: Text('Share'),
                      ),
                      PopupMenuItem(
                        value: _DocMenuAction.rename,
                        child: Text('Rename'),
                      ),
                      PopupMenuItem(
                        value: _DocMenuAction.delete,
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Could not load documents: $error'),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('${AppRoutes.home}scanner'),
        label: const Text('Start Scan'),
        icon: const Icon(Icons.document_scanner_outlined),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: OutlinedButton.icon(
            onPressed: () => context.push('${AppRoutes.home}converter'),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Image to PDF Converter'),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    ScannedDocument doc,
    _DocMenuAction action,
  ) async {
    if (action == _DocMenuAction.share) {
      await Share.shareXFiles([XFile(doc.pdfPath)], text: doc.title);
      return;
    }

    if (action == _DocMenuAction.rename) {
      final renamed = await _renameDialog(context, doc.title);
      if (renamed != null && renamed.trim().isNotEmpty) {
        await ref
            .read(documentListProvider.notifier)
            .rename(id: doc.id, title: renamed.trim());
      }
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete document?'),
          content: Text('"${doc.title}" will be removed from this device.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await ref.read(documentListProvider.notifier).removeById(doc.id);
    }
  }

  Future<String?> _renameDialog(BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename document'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Document name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

enum _DocMenuAction { share, rename, delete }

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.description_outlined, size: 56),
            SizedBox(height: 16),
            Text(
              'No documents yet',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Scan your first paper and convert it into a searchable, shareable PDF.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
