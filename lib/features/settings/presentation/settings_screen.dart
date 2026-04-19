import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            title: Text('Permissions & privacy'),
            subtitle: Text(
              'Request camera and storage access only when needed.',
            ),
          ),
          Divider(),
          ListTile(
            title: Text('Future features'),
            subtitle: Text(
              'OCR, cloud sync, signatures, and password-protected PDFs.',
            ),
          ),
        ],
      ),
    );
  }
}
