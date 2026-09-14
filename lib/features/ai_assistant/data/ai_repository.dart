import '../../../core/api/api_repository.dart';
import '../../../core/models/models.dart';

enum MoodType {
  calm,
  energetic,
  sad,
  focus,
  party,
}

extension MoodTypeX on MoodType {
  String get labelAr {
    switch (this) {
      case MoodType.calm: return '🌌 هادئ';
      case MoodType.energetic: return '⚡ طاقة';
      case MoodType.sad: return '🌙 حزين';
      case MoodType.focus: return '🪐 تركيز';
      case MoodType.party: return '🎆 صخب';
    }
  }

  String get labelEn {
    switch (this) {
      case MoodType.calm: return 'calm chill';
      case MoodType.energetic: return 'energetic upbeat';
      case MoodType.sad: return 'sad emotional';
      case MoodType.focus: return 'focus ambient';
      case MoodType.party: return 'party dance';
    }
  }

  String get searchQuery {
    switch (this) {
      case MoodType.calm: return 'chill relaxing ambient';
      case MoodType.energetic: return 'upbeat energetic pop';
      case MoodType.sad: return 'sad emotional ballad';
      case MoodType.focus: return 'focus ambient study';
      case MoodType.party: return 'party dance electronic';
    }
  }
}

class AiRepository {
  static Future<List<Song>> getAiRecommendations(
    String prompt, {
    MoodType? mood,
  }) async {
    final query = mood != null ? '${mood.searchQuery} $prompt' : prompt;
    return ApiRepository.searchSongs(query);
  }

  static Future<bool> isServerOnline() {
    return ApiRepository.checkHealth();
  }
}
