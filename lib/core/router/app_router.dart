import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf_scanner_app/features/converter/presentation/converter_screen.dart';
import 'package:pdf_scanner_app/features/converter/presentation/converter_tool_screen.dart';
import 'package:pdf_scanner_app/features/home/presentation/home_screen.dart';
import 'package:pdf_scanner_app/features/pdf_reader/presentation/pdf_preview_screen.dart';
import 'package:pdf_scanner_app/features/scanner/presentation/scanner_screen.dart';
import 'package:pdf_scanner_app/features/settings/presentation/settings_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRoutes {
  static const home = '/';
  static const scanner = '/scanner';
  static const converter = '/converter';
  static const preview = '/preview';
  static const settings = '/settings';

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
          builder: (context, state) => const ScannerScreen(),
        ),
        GoRoute(
          path: 'converter',
          builder: (context, state) => const ConverterScreen(),
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
            return PdfPreviewScreen(filePath: path);
          },
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
