import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/offline_service.dart';

class LibraryState {
  final List<Song> favoriteSongs;
  final List<Song> recentHistory;
  final List<Song> downloadedSongs;
  final List<Playlist> customPlaylists;

  const LibraryState({
    this.favoriteSongs = const [],
    this.recentHistory = const [],
    this.downloadedSongs = const [],
    this.customPlaylists = const [],
  });

  LibraryState copyWith({
    List<Song>? favoriteSongs,
    List<Song>? recentHistory,
    List<Song>? downloadedSongs,
    List<Playlist>? customPlaylists,
  }) {
    return LibraryState(
      favoriteSongs: favoriteSongs ?? this.favoriteSongs,
      recentHistory: recentHistory ?? this.recentHistory,
      downloadedSongs: downloadedSongs ?? this.downloadedSongs,
      customPlaylists: customPlaylists ?? this.customPlaylists,
    );
  }
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  LibraryNotifier() : super(const LibraryState()) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final favs = StorageService.loadFavorites();
    final hist = StorageService.loadHistory();
    final offline = OfflineService.loadOfflineSongs();
    state = state.copyWith(
      favoriteSongs: favs,
      recentHistory: hist,
      downloadedSongs: offline,
    );
  }

  void toggleFavorite(Song song) {
    final exists = state.favoriteSongs.any((s) => s.id == song.id);
    List<Song> updated;
    if (exists) {
      updated = state.favoriteSongs.where((s) => s.id != song.id).toList();
    } else {
      updated = [song, ...state.favoriteSongs];
    }
    state = state.copyWith(favoriteSongs: updated);
    StorageService.saveFavorites(updated);
  }

  void addToHistory(Song song) {
    final filtered = state.recentHistory.where((s) => s.id != song.id).toList();
    final updated = [song, ...filtered];
    state = state.copyWith(recentHistory: updated);
    StorageService.saveHistory(updated);
  }

  Future<bool> toggleDownload(Song song) async {
    final isDownloaded = state.downloadedSongs.any((s) => s.id == song.id);
    if (isDownloaded) {
      OfflineService.deleteOfflineSong(song.id);
      final updated = state.downloadedSongs.where((s) => s.id != song.id).toList();
      state = state.copyWith(downloadedSongs: updated);
      return false;
    } else {
      final success = await OfflineService.downloadAndSaveSong(song);
      if (success) {
        final updated = [song, ...state.downloadedSongs.where((s) => s.id != song.id)];
        state = state.copyWith(downloadedSongs: updated);
        return true;
      }
      return false;
    }
  }

  bool isDownloaded(String songId) {
    return state.downloadedSongs.any((s) => s.id == songId);
  }

  bool isFavorite(String songId) {
    return state.favoriteSongs.any((s) => s.id == songId);
  }
}

final libraryProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier();
});
