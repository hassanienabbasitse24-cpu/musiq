import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:html' if (dart.library.io) '../services/dummy_html.dart' as html;
import '../models/models.dart';

class StorageService {
  static const String _favoritesKey = 'musiq_space_favorites';
  static const String _historyKey = 'musiq_space_history';

  static Map<String, dynamic> _songToJson(Song s) => {
        'id': s.id,
        'title': s.title,
        'titleAr': s.titleAr,
        'artist': s.artist,
        'artistAr': s.artistAr,
        'imageUrl': s.imageUrl,
        'audioUrl': s.audioUrl,
        'videoId': s.videoId,
        'durationMs': s.duration?.inMilliseconds ?? 180000,
      };

  static Song _songFromJson(Map<String, dynamic> item) => Song(
        id: item['id'] ?? '',
        title: item['title'] ?? '',
        titleAr: item['titleAr'] ?? '',
        artist: item['artist'] ?? '',
        artistAr: item['artistAr'] ?? '',
        imageUrl: item['imageUrl'],
        audioUrl: item['audioUrl'],
        videoId: item['videoId'],
        duration: Duration(milliseconds: item['durationMs'] ?? 180000),
      );

  static void saveFavorites(List<Song> songs) {
    if (kIsWeb) {
      try {
        html.window.localStorage[_favoritesKey] =
            json.encode(songs.map(_songToJson).toList());
      } catch (e) {
        debugPrint('Storage save error: $e');
      }
    }
  }

  static List<Song> loadFavorites() {
    if (kIsWeb) {
      try {
        final raw = html.window.localStorage[_favoritesKey];
        if (raw != null && raw.isNotEmpty) {
          final List list = json.decode(raw);
          return list.map<Song>((item) => _songFromJson(item)).toList();
        }
      } catch (e) {
        debugPrint('Storage load error: $e');
      }
    }
    return [];
  }

  static void saveHistory(List<Song> history) {
    if (kIsWeb) {
      try {
        html.window.localStorage[_historyKey] =
            json.encode(history.take(30).map(_songToJson).toList());
      } catch (e) {
        debugPrint('History save error: $e');
      }
    }
  }

  static List<Song> loadHistory() {
    if (kIsWeb) {
      try {
        final raw = html.window.localStorage[_historyKey];
        if (raw != null && raw.isNotEmpty) {
          final List list = json.decode(raw);
          return list.map<Song>((item) => _songFromJson(item)).toList();
        }
      } catch (e) {
        debugPrint('History load error: $e');
      }
    }
    return [];
  }
}
