import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf_scanner_app/features/converter/presentation/converter_screen.dart' as conv;
import 'package:pdf_scanner_app/features/converter/presentation/converter_tool_screen.dart';
import 'package:pdf_scanner_app/features/home/presentation/home_screen.dart';
import 'package:pdf_scanner_app/features/pdf_reader/presentation/file_preview_screen.dart';
import 'package:pdf_scanner_app/features/scanner/presentation/scanner_screen.dart';
import 'package:pdf_scanner_app/features/settings/presentation/settings_screen.dart';
import 'package:pdf_scanner_app/features/ocr/presentation/ocr_screen.dart';
import 'package:pdf_scanner_app/features/tools/presentation/compress_image_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRoutes {
  static const home = '/';
  static const scanner = '/scanner';
  static const converter = '/converter';
  static const preview = '/preview';
  static const settings = '/settings';
  static const ocr = '/ocr';
  static const compress = '/compress';

  // New Tool Hub
  static const tool = '/tool';

  const AppRoutes._();
}

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'scanner',
          builder: (context, state) {
            final formatStr = state.uri.queryParameters['format'];
            final initialFormat = formatStr != null 
                ? OutputFormat.values.firstWhere((e) => e.name == formatStr, orElse: () => OutputFormat.pdf)
                : null;
            return ScannerScreen(initialFormat: initialFormat);
          },
        ),
        GoRoute(
          path: 'converter',
          builder: (context, state) {
            final formatStr = state.uri.queryParameters['format'];
            final initialFormat = formatStr != null
                ? conv.OutputFormat.values.firstWhere((e) => e.name == formatStr, orElse: () => conv.OutputFormat.pdf)
                : null;
            return conv.ConverterScreen(initialFormat: initialFormat);
          },
        ),
        GoRoute(
          path: 'tool',
          builder: (context, state) {
            final type = state.uri.queryParameters['type'] ?? 'unknown';
            return ConverterToolScreen(toolType: type);
          },
        ),
        GoRoute(
          path: 'preview',
          builder: (context, state) {
            final path = state.uri.queryParameters['path'];
            return FilePreviewScreen(filePath: path);
          },
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: 'ocr',
          builder: (context, state) => const OcrScreen(),
        ),
        GoRoute(
          path: 'compress',
          builder: (context, state) => const CompressImageScreen(),
        ),
      ],
    ),
  ],
);
