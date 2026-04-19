import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_scanner_app/core/constants/app_strings.dart';
import 'package:pdf_scanner_app/core/router/app_router.dart';
import 'package:pdf_scanner_app/core/theme/app_theme.dart';
import 'package:pdf_scanner_app/providers/theme_provider.dart';

void main() {
  runApp(const ProviderScope(child: ScanVaultApp()));
}

class ScanVaultApp extends ConsumerWidget {
  const ScanVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
