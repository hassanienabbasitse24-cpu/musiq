import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

class MusiqAudioHandler {
  final AudioPlayer player = AudioPlayer();
  bool _sessionConfigured = false;

  MusiqAudioHandler() {
    _init();
  }

  void _init() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      _sessionConfigured = true;
    } catch (e) {
      debugPrint('AudioSession config failed: $e');
    }
  }

  Future<void> loadAndPlay({
    required String url,
    required String id,
    required String title,
    required String artist,
    String? album,
    String? artUri,
  }) async {
    try {
      if (!_sessionConfigured) {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
        _sessionConfigured = true;
      }

      await player.setUrl(url);
      await player.play();
    } catch (e) {
      debugPrint('loadAndPlay error: $e');
    }
  }

  Future<void> play() async {
    try {
      await player.play();
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      await player.pause();
    } catch (_) {}
  }

  Future<void> seek(Duration position) async {
    try {
      await player.seek(position);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await player.stop();
    } catch (_) {}
  }

  Future<void> onTaskRemoved() async {
    await stop();
  }
}
