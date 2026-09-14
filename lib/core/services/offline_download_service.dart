import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class OfflineDownloadService {
  static Future<Directory> _getDownloadDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${dir.path}/musiq_downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  static String _sanitizeFilename(String id) {
    return id.replaceAll(RegExp(r'[^\w\-]'), '_');
  }

  static Future<String?> getLocalPath(String songId) async {
    if (kIsWeb) return null;
    try {
      final dir = await _getDownloadDir();
      final file = File('${dir.path}/${_sanitizeFilename(songId)}.mp3');
      if (await file.exists()) {
        return file.path;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> isDownloaded(String songId) async {
    final path = await getLocalPath(songId);
    return path != null;
  }

  static Future<String?> downloadSong({
    required String songId,
    required String url,
    void Function(double progress)? onProgress,
  }) async {
    if (kIsWeb) return null;

    try {
      final existing = await getLocalPath(songId);
      if (existing != null) return existing;

      final dir = await _getDownloadDir();
      final filePath = '${dir.path}/${_sanitizeFilename(songId)}.mp3';
      final file = File(filePath);

      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        await file.writeAsBytes(bytes);

        if (onProgress != null) onProgress(1.0);

        if (await file.exists() && await file.length() > 0) {
          return filePath;
        }
      }
    } catch (e) {
      debugPrint('Download error: $e');
    }
    return null;
  }

  static Future<bool> deleteSong(String songId) async {
    if (kIsWeb) return false;
    try {
      final path = await getLocalPath(songId);
      if (path != null) {
        await File(path).delete();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
