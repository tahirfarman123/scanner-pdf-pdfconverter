import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class LocalStorageService {
  Future<Directory> appDocsDirectory() async {
    return getApplicationDocumentsDirectory();
  }

  Future<Directory> scansDirectory() async {
    final base = await appDocsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}scans');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> writeBytes({required String fileName, required Uint8List bytes}) async {
    final scans = await scansDirectory();
    final file = File('${scans.path}${Platform.pathSeparator}$fileName');
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<File> writeText({required String fileName, required String contents}) async {
    final scans = await scansDirectory();
    final file = File('${scans.path}${Platform.pathSeparator}$fileName');
    return file.writeAsString(contents, flush: true);
  }

  Future<File> fileInScans(String fileName) async {
    final scans = await scansDirectory();
    return File('${scans.path}${Platform.pathSeparator}$fileName');
  }
}
