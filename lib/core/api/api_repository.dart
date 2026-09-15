import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import '../models/models.dart';

class ApiRepository {
  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse(ApiClient.healthUrl))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Song>> searchSongs(String query, {int limit = 20}) async {
    final jamendoResults = await _searchJamendo(query, limit: limit);
    final youtubeResults = await searchYouTube(query, limit: limit);

    final combined = <Song>[...jamendoResults, ...youtubeResults];
    if (combined.isNotEmpty) return combined;

    return [];
  }

  static Future<List<Song>> searchYouTube(String query, {int limit = 15}) async {
    try {
      final uri = Uri.parse(ApiClient.youtubeSearchUrl(query, limit: limit));
      final response = await http
          .get(uri, headers: ApiClient.headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];

        return results.map<Song>((item) => Song(
          id: 'yt_${item['videoId']}',
          title: item['title'] ?? '',
          titleAr: item['title'] ?? '',
          artist: item['artist'] ?? '',
          artistAr: item['artist'] ?? '',
          imageUrl: item['imageUrl'],
          videoId: item['videoId'],
          duration: const Duration(seconds: 240),
        )).toList();
      }
    } catch (e) {
      debugPrint('[YouTube] Search error: $e');
    }
    return [];
  }

  static Future<List<Song>> browseSongs({int limit = 20, int offset = 0, String order = 'popularity_total'}) async {
    return _searchJamendo('', limit: limit, offset: offset, order: order);
  }

  static Future<List<Song>> _searchJamendo(String query, {int limit = 20, int offset = 0, String order = 'popularity_total'}) async {
    try {
      String url;
      if (query.isNotEmpty) {
        url = '${ApiClient.jamendoSearchUrl}?q=${Uri.encodeComponent(query)}&limit=$limit';
      } else {
        url = '${ApiClient.jamendoBrowseUrl}?limit=$limit&offset=$offset&order=$order';
      }

      final response = await http
          .get(Uri.parse(url), headers: ApiClient.headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['tracks'] as List? ?? [];
        return tracks.map<Song>((t) => Song(
          id: t['id'] ?? '',
          title: t['title'] ?? '',
          titleAr: t['title'] ?? '',
          artist: t['artist'] ?? '',
          artistAr: t['artist'] ?? '',
          imageUrl: t['imageUrl'],
          audioUrl: t['audioUrl'],
          duration: Duration(milliseconds: t['duration'] ?? 180000),
        )).toList();
      }
    } catch (e) {
      debugPrint('[Jamendo] Search error: $e');
    }
    return [];
  }

  static Future<List<Song>> getAiRecommendations({
    String? freeTextPrompt,
    String? mood,
  }) async {
    final query = freeTextPrompt?.isNotEmpty == true
        ? freeTextPrompt!
        : mood?.isNotEmpty == true
            ? '$mood music'
            : 'popular music';
    return searchSongs(query);
  }
}
