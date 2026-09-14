import 'package:flutter/foundation.dart';

// Conditional import for Flutter Web HTML Audio
import 'dart:html' if (dart.library.io) 'dummy_html.dart' as html;

class WebAudioService {
  static final WebAudioService _instance = WebAudioService._internal();
  factory WebAudioService() => _instance;
  WebAudioService._internal();

  html.AudioElement? _audioElement;
  String? _currentUrl;
  bool _isPlaying = false;

  ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);
  ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);

  Future<bool> playUrl(String url) async {
    if (kIsWeb) {
      try {
        if (_audioElement == null) {
          _audioElement = html.AudioElement();
          _audioElement!.onTimeUpdate.listen((_) {
            if (_audioElement != null) {
              final cur = _audioElement!.currentTime;
              final dur = _audioElement!.duration;
              positionNotifier.value = Duration(milliseconds: (cur * 1000).round());
              if (dur.isFinite && dur > 0) {
                durationNotifier.value = Duration(milliseconds: (dur * 1000).round());
              }
            }
          });
          _audioElement!.onError.listen((_) {
            _isPlaying = false;
            isPlayingNotifier.value = false;
          });
          _audioElement!.onEnded.listen((_) {
            _isPlaying = false;
            isPlayingNotifier.value = false;
            positionNotifier.value = Duration.zero;
          });
        }

        if (_currentUrl != url) {
          _currentUrl = url;
          _audioElement!.src = url;
        }

        final dynamic playResult = _audioElement!.play();
        if (playResult is Future) {
          await playResult;
        }
        _isPlaying = true;
        isPlayingNotifier.value = true;
        return true;
      } catch (e) {
        debugPrint('WebAudio error: $e');
        _isPlaying = false;
        isPlayingNotifier.value = false;
        return false;
      }
    }
    return false;
  }

  void pause() {
    if (kIsWeb && _audioElement != null) {
      _audioElement!.pause();
      _isPlaying = false;
      isPlayingNotifier.value = false;
    }
  }

  void resume() {
    if (kIsWeb && _audioElement != null && _currentUrl != null) {
      _audioElement!.play();
      _isPlaying = true;
      isPlayingNotifier.value = true;
    }
  }

  void togglePlayPause() {
    if (_isPlaying) {
      pause();
    } else if (_currentUrl != null) {
      resume();
    }
  }

  void seek(Duration position) {
    if (kIsWeb && _audioElement != null) {
      _audioElement!.currentTime = position.inMilliseconds / 1000.0;
      positionNotifier.value = position;
    }
  }

  void setVolume(double volume) {
    if (kIsWeb && _audioElement != null) {
      _audioElement!.volume = volume.clamp(0.0, 1.0);
    }
  }
}
