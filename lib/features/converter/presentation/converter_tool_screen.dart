import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf_scanner_app/core/theme/app_colors.dart';

class ConverterToolScreen extends StatefulWidget {
  final String toolType;

  const ConverterToolScreen({super.key, required this.toolType});

  @override
  State<ConverterToolScreen> createState() => _ConverterToolScreenState();
}

class _ConverterToolScreenState extends State<ConverterToolScreen> {
  bool _isProcessing = false;

  String get _title {
    switch (widget.toolType) {
      case 'wordToPdf':
        return 'Word to PDF';
      case 'excelToPdf':
        return 'Excel to PDF';
      case 'pdfToWord':
        return 'PDF to Word';
      case 'excelToWord':
        return 'Excel to Word';
      default:
        return 'Document Converter';
    }
  }

  Color get _toolColor {
    switch (widget.toolType) {
      case 'wordToPdf':
        return const Color(0xFF2B579A); // Word Blue
      case 'excelToPdf':
        return const Color(0xFF217346); // Excel Green
      case 'pdfToWord':
        return const Color(0xFFE4405F); // PDF Red
      case 'excelToWord':
        return const Color(0xFF217346);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIconStack(),
              const SizedBox(height: 40),
              Text(
                'Convert ${_title}',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Select a file from your device to begin the premium conversion process.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),
              if (!_isProcessing)
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: _startConversion,
                    style: ElevatedButton.styleFrom(backgroundColor: _toolColor),
                    icon: const Icon(Icons.file_upload_rounded),
                    label: Text('SELECT FILE', style: GoogleFonts.outfit(letterSpacing: 1.2)),
                  ),
                )
              else
                _buildProcessingState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconStack() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: _toolColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
        Icon(Icons.cached_rounded, size: 80, color: _toolColor),
      ],
    );
  }

  Widget _buildProcessingState() {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          'ALCHEMIZING YOUR DOCUMENT...',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: _toolColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please wait while we perform the high-fidelity conversion.',
          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  void _startConversion() {
    setState(() => _isProcessing = true);
    // Simulate processing for the shell
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showCloudDialog();
      }
    });
  }

  void _showCloudDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Premium Feature Note', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'Advanced Office-to-PDF conversion requires our Cloud Processing engine. \n\nThis basic version supports text extraction. For full formatting, please upgrade to Pro.',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
