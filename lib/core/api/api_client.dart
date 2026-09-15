import 'package:flutter/foundation.dart';

class ApiClient {
  static const String cloudBaseUrl = 'https://musiq-git-main-musiq1.vercel.app';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    return cloudBaseUrl;
  }

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  static String get healthUrl => '$baseUrl/health';
  static String get jamendoSearchUrl => '$baseUrl/jamendo/search';
  static String get jamendoBrowseUrl => '$baseUrl/jamendo/browse';
  static String jamendoTrackUrl(String id) => '$baseUrl/jamendo/track/$id';
  static String youtubeSearchUrl(String query, {int limit = 10}) =>
      '$baseUrl/youtube/search?q=${Uri.encodeComponent(query)}&limit=$limit';
}
