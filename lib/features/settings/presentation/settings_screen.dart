import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf_scanner_app/core/theme/app_colors.dart';
import 'package:pdf_scanner_app/providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildThemeSection(ref, themeMode),
          const SizedBox(height: 24),
          _buildSettingsCard(
            title: 'Permissions & Privacy',
            subtitle: 'Camera and storage access are only used when scanning or saving documents.',
            icon: Icons.privacy_tip_outlined,
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            title: 'Future Features',
            subtitle: 'OCR, Cloud Sync, Signatures, and Password Protected PDFs are coming soon.',
            icon: Icons.rocket_launch_outlined,
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            title: 'App Version',
            subtitle: '1.0.0 (Premium UI Beta)',
            icon: Icons.info_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(WidgetRef ref, ThemeMode mode) {
    final isDark = mode == ThemeMode.dark;
    return Card(
      child: SwitchListTile(
        title: Text(
          'Dark Mode',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Experience the premium deep slate aesthetic.',
          style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
        ),
        secondary: Icon(
          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          color: AppColors.primaryLight,
        ),
        value: isDark,
        onChanged: (val) {
          ref.read(themeProvider.notifier).setTheme(val ? ThemeMode.dark : ThemeMode.light);
        },
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryLight),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
