import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf_scanner_app/core/constants/app_strings.dart';
import 'package:pdf_scanner_app/core/router/app_router.dart';
import 'package:pdf_scanner_app/core/theme/app_colors.dart';
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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            _buildHeader(context),
            _buildQuickActions(context),
            _buildRecentSectionHeader(context),
            _buildDocumentsContent(context, docsAsync, ref),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('${AppRoutes.home}scanner'),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.appName,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryLight,
              ),
            ),
            IconButton(
              onPressed: () => context.push('${AppRoutes.home}settings'),
              icon: Icon(Icons.settings_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, Ready to Scan?',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Transform your paperwork into digital brilliance.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel(context, 'SMART TOOLS'),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: [
                _QuickActionTile(
                  title: 'Scanner',
                  icon: Icons.document_scanner_rounded,
                  color: AppColors.primary,
                  onTap: () => context.push('${AppRoutes.home}scanner'),
                ),
                _QuickActionTile(
                  title: 'Img to PDF',
                  icon: Icons.picture_as_pdf_rounded,
                  color: AppColors.secondary,
                  onTap: () => context.push('${AppRoutes.home}converter'),
                ),
                _QuickActionTile(
                  title: 'Word to PDF',
                  icon: Icons.description_rounded,
                  color: const Color(0xFF2B579A),
                  onTap: () => context.push('${AppRoutes.tool}?type=wordToPdf'),
                ),
                _QuickActionTile(
                  title: 'Excel to PDF',
                  icon: Icons.table_chart_rounded,
                  color: const Color(0xFF217346),
                  onTap: () => context.push('${AppRoutes.tool}?type=excelToPdf'),
                ),
                _QuickActionTile(
                  title: 'PDF to Word',
                  icon: Icons.history_edu_rounded,
                  color: const Color(0xFFE4405F),
                  onTap: () => context.push('${AppRoutes.tool}?type=pdfToWord'),
                ),
                _QuickActionTile(
                  title: 'Excel to Word',
                  icon: Icons.swap_horiz_rounded,
                  color: const Color(0xFF217346),
                  onTap: () => context.push('${AppRoutes.tool}?type=excelToWord'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildRecentSectionHeader(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Documents',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsContent(
    BuildContext context,
    AsyncValue<List<ScannedDocument>> docsAsync,
    WidgetRef ref,
  ) {
    return docsAsync.when(
      data: (docs) {
        if (docs.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final doc = docs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DocumentCard(
                    doc: doc,
                    onTap: () => context.push(
                      '${AppRoutes.home}preview?path=${Uri.encodeComponent(doc.pdfPath)}',
                    ),
                    onAction: (action) => _handleAction(context, ref, doc, action),
                  ),
                );
              },
              childCount: docs.length,
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Could not load documents: $error'),
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
          backgroundColor: AppColors.surface,
          title: const Text('Delete document?'),
          content: Text('"${doc.title}" will be removed from this device.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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
          backgroundColor: AppColors.surface,
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

class _QuickActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: color.withOpacity(0.12),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final ScannedDocument doc;
  final VoidCallback onTap;
  final Function(_DocMenuAction) onAction;

  const _DocumentCard({
    required this.doc,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primaryLight),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${doc.pageCount} pages | ${DateFormatters.compact(doc.createdAt)}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_DocMenuAction>(
                onSelected: onAction,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: _DocMenuAction.share, child: Text('Share')),
                  PopupMenuItem(value: _DocMenuAction.rename, child: Text('Rename')),
                  PopupMenuItem(value: _DocMenuAction.delete, child: Text('Delete')),
                ],
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
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
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.description_outlined, size: 64, color: AppColors.primaryLight),
            ),
            const SizedBox(height: 24),
            Text(
              'No documents yet',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan your first paper and convert it into a premium, shareable PDF.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

