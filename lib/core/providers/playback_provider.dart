import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../api/api_repository.dart';
import '../models/models.dart';
import '../services/audio_handler.dart';
import '../services/offline_download_service.dart';
import '../services/web_audio_service.dart';
import 'audio_handler_provider.dart';

enum SongRepeatMode { off, all, one }

class PlaybackState {
  final Song? currentSong;
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isShuffle;
  final SongRepeatMode repeatMode;
  final bool isFavorite;
  final List<Song> queue;
  final int currentIndex;
  final bool isDownloading;
  final double downloadProgress;
  final bool isDownloaded;

  const PlaybackState({
    this.currentSong,
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = const Duration(seconds: 240),
    this.isShuffle = false,
    this.repeatMode = SongRepeatMode.off,
    this.isFavorite = false,
    this.queue = const [],
    this.currentIndex = 0,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.isDownloaded = false,
  });

  PlaybackState copyWith({
    Song? currentSong,
    bool clearSong = false,
    bool? isPlaying,
    Duration? currentPosition,
    Duration? totalDuration,
    bool? isShuffle,
    SongRepeatMode? repeatMode,
    bool? isFavorite,
    List<Song>? queue,
    int? currentIndex,
    bool? isDownloading,
    double? downloadProgress,
    bool? isDownloaded,
  }) {
    return PlaybackState(
      currentSong: clearSong ? null : (currentSong ?? this.currentSong),
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      isShuffle: isShuffle ?? this.isShuffle,
      repeatMode: repeatMode ?? this.repeatMode,
      isFavorite: isFavorite ?? this.isFavorite,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}

class PlaybackNotifier extends StateNotifier<PlaybackState> {
  MusiqAudioHandler? _audioHandler;
  final WebAudioService _webAudio = WebAudioService();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<LoopMode>? _loopSub;
  StreamSubscription<bool>? _shuffleSub;

  PlaybackNotifier({MusiqAudioHandler? audioHandler})
      : _audioHandler = audioHandler,
        super(
          const PlaybackState(
            currentSong: Song(
              id: '1',
              title: 'Tamally Maak',
              titleAr: 'تملي معاك',
              artist: 'Amr Diab',
              artistAr: 'عمرو دياب',
              imageUrl:
                  'https://is1-ssl.mzstatic.com/image/thumb/Music69/v4/31/4d/d4/314dd42d-3246-e7a3-107a-3d521fa9a7e2/dj.iiicnpub.jpg/300x300bb.jpg',
              duration: Duration(seconds: 240),
            ),
            isPlaying: false,
            totalDuration: Duration(seconds: 240),
          ),
        ) {
    if (kIsWeb) {
      _initWebListeners();
    } else if (_audioHandler != null) {
      _initNativeListeners();
    }
    _checkDefaultDownloadStatus();
  }

  void _initNativeListeners() {
    final player = _audioHandler!.player;

    _positionSub = player.positionStream.listen((pos) {
      state = state.copyWith(currentPosition: pos);
    });

    _durationSub = player.durationStream.listen((dur) {
      if (dur != null && dur > Duration.zero) {
        state = state.copyWith(totalDuration: dur);
      }
    });

    _playingSub = player.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });

    _loopSub = player.loopModeStream.listen((mode) {
      final repeatMode = switch (mode) {
        LoopMode.off => SongRepeatMode.off,
        LoopMode.one => SongRepeatMode.one,
        LoopMode.all => SongRepeatMode.all,
      };
      state = state.copyWith(repeatMode: repeatMode);
    });

    _shuffleSub = player.shuffleModeEnabledStream.listen((enabled) {
      state = state.copyWith(isShuffle: enabled);
    });
  }

  void _initWebListeners() {
    _webAudio.positionNotifier.addListener(() {
      state = state.copyWith(currentPosition: _webAudio.positionNotifier.value);
    });
    _webAudio.durationNotifier.addListener(() {
      final dur = _webAudio.durationNotifier.value;
      if (dur > Duration.zero) {
        state = state.copyWith(totalDuration: dur);
      }
    });
    _webAudio.isPlayingNotifier.addListener(() {
      state = state.copyWith(isPlaying: _webAudio.isPlayingNotifier.value);
    });
  }

  Future<void> _checkDefaultDownloadStatus() async {
    if (state.currentSong != null) {
      final downloaded =
          await OfflineDownloadService.isDownloaded(state.currentSong!.id);
      if (mounted) {
        state = state.copyWith(isDownloaded: downloaded);
      }
    }
  }

  void playSong(Song song) async {
    state = state.copyWith(
      currentSong: song,
      isPlaying: true,
      currentPosition: Duration.zero,
      totalDuration: song.duration ?? const Duration(seconds: 240),
    );

    final downloaded = await OfflineDownloadService.isDownloaded(song.id);
    if (mounted) {
      state = state.copyWith(isDownloaded: downloaded);
    }

    String? audioUrl;

    if (downloaded) {
      final localPath = await OfflineDownloadService.getLocalPath(song.id);
      if (localPath != null) audioUrl = localPath;
    }

    if (audioUrl == null && song.audioUrl != null && song.audioUrl!.isNotEmpty) {
      audioUrl = song.audioUrl;
      debugPrint('[Audio] Playing Jamendo audio: ${song.title}');
    }

    if (audioUrl == null && song.videoId != null && song.videoId!.isNotEmpty) {
      debugPrint('[Audio] YouTube song — searching Jamendo for playable audio...');
      final jamendoResults = await ApiRepository.searchSongs('${song.title} ${song.artist}', limit: 3);
      final match = jamendoResults.firstWhere(
        (s) => s.audioUrl != null && s.audioUrl!.isNotEmpty,
        orElse: () => Song(id: '', title: '', titleAr: '', artist: '', artistAr: ''),
      );
      if (match.audioUrl != null && match.audioUrl!.isNotEmpty) {
        audioUrl = match.audioUrl;
        debugPrint('[Audio] Found Jamendo match for: ${song.title}');
      } else {
        debugPrint('[Audio] No Jamendo match found for: ${song.title}');
      }
    }

    if (audioUrl == null || audioUrl.isEmpty) {
      debugPrint('[Audio] No audio available for: ${song.title}');
      state = state.copyWith(isPlaying: false);
      return;
    }

    if (!kIsWeb && _audioHandler != null) {
      _audioHandler!.loadAndPlay(
        url: audioUrl,
        id: song.id,
        title: song.titleAr.isNotEmpty ? song.titleAr : song.title,
        artist: song.artistAr.isNotEmpty ? song.artistAr : song.artist,
        album: 'Musiq',
        artUri: song.imageUrl,
      );
    } else if (kIsWeb) {
      _webAudio.playUrl(audioUrl);
    }
  }

  void togglePlayPause() {
    if (state.isPlaying) {
      if (!kIsWeb && _audioHandler != null) {
        _audioHandler!.pause();
      } else if (kIsWeb) {
        _webAudio.pause();
      } else {
        state = state.copyWith(isPlaying: false);
        return;
      }
    } else {
      if (!kIsWeb && _audioHandler != null) {
        _audioHandler!.play();
      } else if (kIsWeb) {
        _webAudio.resume();
      } else {
        state = state.copyWith(isPlaying: true);
        return;
      }
    }
  }

  void play() {
    if (!kIsWeb && _audioHandler != null) {
      _audioHandler!.play();
    } else if (kIsWeb) {
      _webAudio.resume();
    } else {
      state = state.copyWith(isPlaying: true);
    }
  }

  void pause() {
    if (!kIsWeb && _audioHandler != null) {
      _audioHandler!.pause();
    } else if (kIsWeb) {
      _webAudio.pause();
    } else {
      state = state.copyWith(isPlaying: false);
    }
  }

  void seekTo(Duration position) {
    state = state.copyWith(currentPosition: position);
    if (!kIsWeb && _audioHandler != null) {
      _audioHandler!.seek(position);
    } else if (kIsWeb) {
      _webAudio.seek(position);
    }
  }

  void toggleShuffle() {
    final newShuffle = !state.isShuffle;
    state = state.copyWith(isShuffle: newShuffle);
    if (!kIsWeb && _audioHandler != null) {
      _audioHandler!.player.setShuffleModeEnabled(newShuffle);
    }
  }

  void cycleRepeat() {
    final modes = SongRepeatMode.values;
    final nextIndex = (modes.indexOf(state.repeatMode) + 1) % modes.length;
    final newMode = modes[nextIndex];
    state = state.copyWith(repeatMode: newMode);

    if (!kIsWeb && _audioHandler != null) {
      final loopMode = switch (newMode) {
        SongRepeatMode.off => LoopMode.off,
        SongRepeatMode.one => LoopMode.one,
        SongRepeatMode.all => LoopMode.all,
      };
      _audioHandler!.player.setLoopMode(loopMode);
    }
  }

  void toggleFavorite() {
    state = state.copyWith(isFavorite: !state.isFavorite);
  }

  void setQueue(List<Song> songs, {int startIndex = 0}) {
    if (songs.isEmpty) return;
    state = state.copyWith(queue: songs, currentIndex: startIndex);
    playSong(songs[startIndex]);
  }

  void addToQueue(Song song) {
    state = state.copyWith(queue: [...state.queue, song]);
  }

  void playNext(Song song) {
    final queue = List<Song>.from(state.queue);
    final insertIndex = state.currentIndex + 1;
    queue.insert(insertIndex, song);
    state = state.copyWith(queue: queue);
  }

  void removeFromQueue(int index) {
    final queue = List<Song>.from(state.queue);
    if (index < 0 || index >= queue.length) return;
    queue.removeAt(index);
    final newIndex = index < state.currentIndex
        ? state.currentIndex - 1
        : state.currentIndex;
    state = state.copyWith(
      queue: queue,
      currentIndex: newIndex.clamp(0, queue.length - 1),
    );
  }

  void skipToNext() {
    if (state.queue.isEmpty) return;

    int nextIndex;
    if (state.isShuffle) {
      nextIndex = _getRandomIndex();
    } else {
      nextIndex = state.currentIndex + 1;
      if (nextIndex >= state.queue.length) {
        if (state.repeatMode == SongRepeatMode.all) {
          nextIndex = 0;
        } else {
          return;
        }
      }
    }

    state = state.copyWith(currentIndex: nextIndex);
    playSong(state.queue[nextIndex]);
  }

  void skipToPrevious() {
    if (state.queue.isEmpty) return;

    if (state.currentPosition.inSeconds > 3) {
      seekTo(Duration.zero);
      return;
    }

    int prevIndex = state.currentIndex - 1;
    if (prevIndex < 0) {
      if (state.repeatMode == SongRepeatMode.all) {
        prevIndex = state.queue.length - 1;
      } else {
        prevIndex = 0;
      }
    }

    state = state.copyWith(currentIndex: prevIndex);
    playSong(state.queue[prevIndex]);
  }

  int _getRandomIndex() {
    if (state.queue.length <= 1) return 0;
    int next;
    do {
      next = DateTime.now().millisecondsSinceEpoch % state.queue.length;
    } while (next == state.currentIndex);
    return next;
  }

  Future<void> downloadCurrentSong() async {
    final song = state.currentSong;
    if (song == null || kIsWeb) return;

    state = state.copyWith(isDownloading: true, downloadProgress: 0.0);

    String? fullUrl;
    if (song.audioUrl != null && song.audioUrl!.isNotEmpty) {
      fullUrl = song.audioUrl;
    }

    if (fullUrl == null || fullUrl.isEmpty) {
      state = state.copyWith(isDownloading: false, downloadProgress: 0.0);
      return;
    }

    final path = await OfflineDownloadService.downloadSong(
      songId: song.id,
      url: fullUrl,
      onProgress: (progress) {
        if (mounted) {
          state = state.copyWith(downloadProgress: progress);
        }
      },
    );

    if (mounted) {
      if (path != null) {
        state = state.copyWith(
            isDownloading: false, isDownloaded: true, downloadProgress: 1.0);
      } else {
        state = state.copyWith(isDownloading: false, downloadProgress: 0.0);
      }
    }
  }

  Future<void> deleteCurrentDownload() async {
    final song = state.currentSong;
    if (song == null || kIsWeb) return;

    await OfflineDownloadService.deleteSong(song.id);
    if (mounted) {
      state = state.copyWith(isDownloaded: false);
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playingSub?.cancel();
    _loopSub?.cancel();
    _shuffleSub?.cancel();
    super.dispose();
  }

  Future<void> stop() async {
    try {
      await _audioHandler?.stop();
    } catch (_) {}
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playingSub?.cancel();
    _loopSub?.cancel();
    _shuffleSub?.cancel();
    if (mounted) {
      state = PlaybackState();
    }
  }
}

final playbackProvider =
    StateNotifierProvider<PlaybackNotifier, PlaybackState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return PlaybackNotifier(audioHandler: handler);
});
