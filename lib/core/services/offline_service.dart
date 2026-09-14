import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:html' if (dart.library.io) '../services/dummy_html.dart' as html;
import '../models/models.dart';

class OfflineService {
  static const String _offlineKey = 'musiq_offline_tracks_data';

  static Future<bool> downloadAndSaveSong(Song song) async {
    try {
      String? audioBase64;
      final audioSource = song.audioUrl;
      if (audioSource != null && audioSource.isNotEmpty) {
        try {
          final res = await http.get(Uri.parse(audioSource)).timeout(const Duration(seconds: 30));
          if (res.statusCode == 200) {
            audioBase64 = base64.encode(res.bodyBytes);
          }
        } catch (_) {}
      }

      final existing = loadOfflineSongs();
      final filtered = existing.where((s) => s.id != song.id).toList();

      final newItem = {
        'id': song.id,
        'title': song.title,
        'titleAr': song.titleAr,
        'artist': song.artist,
        'artistAr': song.artistAr,
        'imageUrl': song.imageUrl,
        'audioUrl': song.audioUrl,
        'durationMs': song.duration?.inMilliseconds ?? 180000,
        'audioData': audioBase64,
        'isOffline': true,
      };

      if (kIsWeb) {
        final updatedList = [newItem, ...filtered.map((s) => {
          'id': s.id,
          'title': s.title,
          'titleAr': s.titleAr,
          'artist': s.artist,
          'artistAr': s.artistAr,
          'imageUrl': s.imageUrl,
          'audioUrl': s.audioUrl,
          'durationMs': s.duration?.inMilliseconds ?? 180000,
          'isOffline': true,
        })];
        html.window.localStorage[_offlineKey] = json.encode(updatedList);
      }
      return true;
    } catch (e) {
      debugPrint('Offline save error: $e');
      return false;
    }
  }

  static List<Song> loadOfflineSongs() {
    if (kIsWeb) {
      try {
        final raw = html.window.localStorage[_offlineKey];
        if (raw != null && raw.isNotEmpty) {
          final List list = json.decode(raw);
          return list.map((item) => Song(
            id: item['id'] ?? '',
            title: item['title'] ?? '',
            titleAr: item['titleAr'] ?? '',
            artist: item['artist'] ?? '',
            artistAr: item['artistAr'] ?? '',
            imageUrl: item['imageUrl'],
            audioUrl: item['audioUrl'],
            duration: Duration(milliseconds: item['durationMs'] ?? 180000),
          )).toList();
        }
      } catch (e) {
        debugPrint('Offline load error: $e');
      }
    }
    return [];
  }

  static void deleteOfflineSong(String songId) {
    if (kIsWeb) {
      try {
        final existing = loadOfflineSongs();
        final updated = existing.where((s) => s.id != songId).toList();
        final data = updated.map((s) => {
          'id': s.id,
          'title': s.title,
          'titleAr': s.titleAr,
          'artist': s.artist,
          'artistAr': s.artistAr,
          'imageUrl': s.imageUrl,
          'audioUrl': s.audioUrl,
          'durationMs': s.duration?.inMilliseconds ?? 180000,
          'isOffline': true,
        }).toList();
        html.window.localStorage[_offlineKey] = json.encode(data);
      } catch (e) {
        debugPrint('Offline delete error: $e');
      }
    }
  }
}
